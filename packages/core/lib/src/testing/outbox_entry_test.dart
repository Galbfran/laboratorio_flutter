import 'package:core/src/domain/job_status.dart';
import 'package:core/src/domain/outbox_entry.dart';
import 'package:core/src/domain/upload_job.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);

  UploadJob job() => UploadJob.create(localPath: '/tmp/a.jpg', sizeBytes: 100);

  OutboxEntry fresh() => OutboxEntry.create(id: '1', job: job(), now: t0);

  test('una entrada nueva está pending y lista de inmediato', () {
    final entry = fresh();
    expect(entry.status, JobStatus.pending);
    expect(entry.isDue(t0), isTrue);
  });

  test('markFailed pasa a failed y programa el próximo intento', () {
    final failed = fresh().markFailed(now: t0, reason: 'timeout');

    expect(failed.status, JobStatus.failed);
    expect(failed.retryCount, 1);
    expect(failed.isDue(t0), isFalse); // todavía no le toca
    expect(failed.nextAttemptAt.isAfter(t0), isTrue);
  });

  test('isDue vuelve a ser true cuando pasa el tiempo de espera', () {
    final failed = fresh().markFailed(now: t0, reason: 'timeout');
    final masTarde = failed.nextAttemptAt.add(const Duration(seconds: 1));

    expect(failed.isDue(masTarde), isTrue);
  });

  // ⭐ El test estrella — el que valida el >= y el newRetryCount.
  test('tras exactamente 5 fallos, queda permanentemente fallida', () {
    var entry = fresh();

    for (var i = 0; i < OutboxEntry.maxAttempts; i++) {
      entry = entry.markFailed(now: t0, reason: 'fallo $i');
    }

    expect(entry.status, JobStatus.permanentlyFailed);
    expect(entry.retryCount, OutboxEntry.maxAttempts);
  });

  test('una entrada permanentemente fallida nunca vuelve a estar due', () {
    var entry = fresh();
    for (var i = 0; i < OutboxEntry.maxAttempts; i++) {
      entry = entry.markFailed(now: t0, reason: 'x');
    }

    final muchoDespues = t0.add(const Duration(days: 365));
    expect(entry.isDue(muchoDespues), isFalse);
  });

  test('markSucceeded limpia el error previo', () {
    final done = fresh().markFailed(now: t0, reason: 'x').markSucceeded();

    expect(done.status, JobStatus.done);
    expect(done.lastError, isNull);
  });

  test('markPermanentlyFailed fuerza el estado sin pasar por retries', () {
    final entry = fresh().markPermanentlyFailed('cancelado a mano');

    expect(entry.status, JobStatus.permanentlyFailed);
    expect(entry.retryCount, 0); // no incrementa, es distinto a markFailed
  });
}
