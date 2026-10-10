import 'package:domain/domain.dart';

import 'in_memory_offline_store.dart';

/// Deterministic local reminder repository. Immediate read-after-write.
final class InMemoryReminderRepository implements ReminderRepository {
  InMemoryReminderRepository(this._store);

  final InMemoryOfflineStore _store;

  @override
  Future<Reminder> save({
    required Reminder reminder,
    required IdempotencyKey idempotencyKey,
  }) async {
    final pending = reminder.copyWith(syncState: SyncState.pending);
    _store.putReminder(pending);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.reminder,
      aggregateId: pending.id.value,
      baseVersion: pending.version,
      enqueuedAt: DateTime.now().toUtc(),
    );
    return pending;
  }

  @override
  Future<Reminder?> findById(ReminderId id) async => _store.reminderById(id);

  @override
  Future<List<Reminder>> listForFamily(FamilySpaceId familySpaceId) async {
    return _store.remindersForFamily(familySpaceId);
  }

  @override
  Future<Reminder> softDelete({
    required ReminderId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) async {
    final current = _store.reminderById(id);
    if (current == null) {
      throw StateError('reminder not found: ${id.value}');
    }
    final nextVersion = baseVersion.next();
    final deleted = current.copyWith(
      version: nextVersion,
      syncState: SyncState.pending,
      tombstone: Tombstone(
        aggregateId: id.value,
        version: nextVersion,
        deletedAt: deletedAt,
        deletedBy: deletedBy,
      ),
    );
    _store.putReminder(deleted);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.reminder,
      aggregateId: id.value,
      baseVersion: baseVersion,
      enqueuedAt: deletedAt.toUtc(),
    );
    return deleted;
  }
}
