import 'package:domain/domain.dart';

import 'in_memory_offline_store.dart';

/// Deterministic local routine repository. Immediate read-after-write.
final class InMemoryRoutineRepository implements RoutineRepository {
  InMemoryRoutineRepository(this._store);

  final InMemoryOfflineStore _store;

  @override
  Future<Routine> save({
    required Routine routine,
    required IdempotencyKey idempotencyKey,
  }) async {
    final pending = routine.copyWith(syncState: SyncState.pending);
    _store.putRoutine(pending);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.routine,
      aggregateId: pending.id.value,
      baseVersion: pending.version,
      enqueuedAt: DateTime.now().toUtc(),
    );
    return pending;
  }

  @override
  Future<Routine?> findById(RoutineId id) async => _store.routineById(id);

  @override
  Future<List<Routine>> listForFamily(FamilySpaceId familySpaceId) async {
    return _store.routinesForFamily(familySpaceId);
  }

  @override
  Future<Routine> softDelete({
    required RoutineId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) async {
    final current = _store.routineById(id);
    if (current == null) {
      throw StateError('routine not found: ${id.value}');
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
    _store.putRoutine(deleted);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.routine,
      aggregateId: id.value,
      baseVersion: baseVersion,
      enqueuedAt: deletedAt.toUtc(),
    );
    return deleted;
  }
}
