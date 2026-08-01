import '../../domain/errors.dart';
import '../../domain/job_status.dart';
import '../../domain/outbox_entry.dart';
import '../ports/driven/clock_port.dart';
import '../ports/driven/connectivity_port.dart';
import '../ports/driven/heavy_compute_port.dart';
import '../ports/driven/logger_port.dart';
import '../ports/driven/outbox_port.dart';
import '../ports/driven/uploader_port.dart';

class SyncRequest {
  const SyncRequest({
    this.maxItems = 10,
    this.deadline = const Duration(seconds: 25), // iOS penaliza cerca de 30
    this.source = TriggerSource.ui,
  });

  final int maxItems;
  final Duration deadline;
  final TriggerSource source;
}

class SyncResult {
  const SyncResult({
    required this.succeeded,
    required this.retryable,
    required this.givenUp,
    required this.hitDeadline,
  });

  final int succeeded;
  final int retryable;
  final int givenUp;
  final bool hitDeadline;

  /// false ⇒ Android reintenta con BackoffPolicy.
  bool get isSuccess => retryable == 0;
}

class SyncPendingUploads {
  const SyncPendingUploads({
    required OutboxPort outbox,
    required UploaderPort uploader,
    required HeavyComputePort compute,
    required ConnectivityPort connectivity,
    required ClockPort clock,
    required LoggerPort logger,
  }) : _outbox = outbox,
       _uploader = uploader,
       _compute = compute,
       _connectivity = connectivity,
       _clock = clock,
       _logger = logger;

  final OutboxPort _outbox;
  final UploaderPort _uploader;
  final HeavyComputePort _compute;
  final ConnectivityPort _connectivity;
  final ClockPort _clock;
  final LoggerPort _logger;

  Future<SyncResult> call([SyncRequest request = const SyncRequest()]) async {
    await _logger.info('Sync iniciado', source: request.source);

    if (!await _connectivity.isConnected()) {
      throw const NoConnectivityError();
    }

    final now = _clock.now();
    final entries = await _outbox.dueEntries(limit: request.maxItems, now: now);

    int succeeded = 0;
    int retryable = 0;
    int givenUp = 0;
    bool hitDeadline = false;

    final deadlineAt = now.add(request.deadline);

    for (final entry in entries) {
      if (!_clock.now().isBefore(deadlineAt)) {
        hitDeadline = true;
        break;
      }

      final updatedEntry = await _process(entry);
      await _outbox.update(updatedEntry);

      switch (updatedEntry.status) {
        case JobStatus.done:
          succeeded++;
          break;
        case JobStatus.permanentlyFailed:
          givenUp++;
          break;
        case JobStatus.pending:
        case JobStatus.uploading:
        case JobStatus.failed:
          retryable++;
          break;
      }
    }

    return SyncResult(
      succeeded: succeeded,
      retryable: retryable,
      givenUp: givenUp,
      hitDeadline: hitDeadline,
    );
  }

  Future<OutboxEntry> _process(OutboxEntry entry) async {
    try {
      final bytes = await _compute.compressImage(
        entry.job.localPath,
        quality: entry.job.quality,
      );
      await _uploader.upload(entry.job, bytes);
      return entry.markSucceeded();
    } on PermanentUploadError catch (e) {
      return entry.markPermanentlyFailed(e.message);
    } on InvalidJobError catch (e) {
      return entry.markPermanentlyFailed(e.message);
    } on TransientUploadError catch (e) {
      return entry.markFailed(now: _clock.now(), reason: e.message);
    } catch (e, stackTrace) {
      await _logger.error('Fallo en upload ${entry.id}', e, stackTrace);
      return entry.markFailed(now: _clock.now(), reason: e.toString());
    }
  }
}
