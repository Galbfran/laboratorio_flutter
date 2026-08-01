import '../../../domain/outbox_entry.dart';

abstract interface class OutboxPort {
  Future<void> enqueue(OutboxEntry job);
  Future<List<OutboxEntry>> dueEntries({
    required int limit,
    required DateTime now,
  });
  Future<void> update(OutboxEntry entry);
  Future<int> pendingCount();
  Future<List<OutboxEntry>> all();
  Stream<List<OutboxEntry>> watchAll();
  Future<void> removeTerminal();
}
