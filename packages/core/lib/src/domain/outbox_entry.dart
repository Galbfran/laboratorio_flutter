import 'backoff.dart';
import 'job_status.dart';
import 'upload_job.dart';

class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.job,
    required this.status,
    required this.retryCount,
    required this.createAt,
    required this.nextAttemptAt,
    this.lastError,
  });

  static const maxAttempts = 5;

  final String id;
  final UploadJob job;
  final JobStatus status;
  final int retryCount;
  final DateTime createAt;
  final DateTime nextAttemptAt;
  final String? lastError;

  factory OutboxEntry.create({
    required String id,
    required UploadJob job,
    required DateTime now,
  }) {
    return OutboxEntry(
      id: id,
      job: job,
      status: JobStatus.pending,
      retryCount: 0,
      createAt: now,
      nextAttemptAt: now,
    );
  }

  bool isDue(DateTime now) {
    return !status.isTerminal && !nextAttemptAt.isAfter(now);
  }

  OutboxEntry markSucceeded() {
    return OutboxEntry(
      id: id,
      job: job,
      status: JobStatus.done,
      retryCount: retryCount,
      createAt: createAt,
      nextAttemptAt: nextAttemptAt,
      lastError: null,
    );
  }

  OutboxEntry markFailed({required DateTime now, required String reason}) {
    final newRetryCount = retryCount + 1;

    if (newRetryCount >= maxAttempts) {
      return OutboxEntry(
        id: id,
        job: job,
        status: JobStatus.permanentlyFailed,
        retryCount: newRetryCount,
        createAt: createAt,
        nextAttemptAt: nextAttemptAt,
        lastError: reason,
      );
    }

    final delay = backoffFor(newRetryCount);
    final newNextAttemptAt = now.add(delay);

    return OutboxEntry(
      id: id,
      job: job,
      status: JobStatus.failed,
      retryCount: newRetryCount,
      createAt: createAt,
      nextAttemptAt: newNextAttemptAt,
      lastError: reason,
    );
  }

  OutboxEntry markPermanentlyFailed(String reason) {
    return OutboxEntry(
      id: id,
      job: job,
      status: JobStatus.permanentlyFailed,
      retryCount: retryCount,
      createAt: createAt,
      nextAttemptAt: nextAttemptAt,
      lastError: reason,
    );
  }
}
