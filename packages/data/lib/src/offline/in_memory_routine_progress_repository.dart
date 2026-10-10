import 'package:domain/domain.dart';

import 'in_memory_offline_store.dart';

/// Deterministic local routine day-progress repository.
final class InMemoryRoutineProgressRepository
    implements RoutineProgressRepository {
  InMemoryRoutineProgressRepository(this._store);

  final InMemoryOfflineStore _store;

  @override
  Future<RoutineDayProgress> save({
    required RoutineDayProgress progress,
    required IdempotencyKey idempotencyKey,
  }) async {
    final pending = progress.copyWith(syncState: SyncState.pending);
    _store.putProgress(pending);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.routineProgress,
      aggregateId: pending.id.value,
      baseVersion: pending.version,
      enqueuedAt: DateTime.now().toUtc(),
    );
    return pending;
  }

  @override
  Future<RoutineDayProgress?> findById(RoutineProgressId id) async =>
      _store.progressById(id);

  @override
  Future<RoutineDayProgress?> findByRoutineAndDate({
    required RoutineId routineId,
    required DateTime localDate,
  }) async {
    return _store.progressByRoutineAndDate(
      routineId: routineId,
      localDate: localDate,
    );
  }

  @override
  Future<List<RoutineDayProgress>> listForFamily(
    FamilySpaceId familySpaceId,
  ) async {
    return _store.progressForFamily(familySpaceId);
  }

  @override
  Future<RoutineDayProgress> softDelete({
    required RoutineProgressId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) async {
    final current = _store.progressById(id);
    if (current == null) {
      throw StateError('routine progress not found: ${id.value}');
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
    _store.putProgress(deleted);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.routineProgress,
      aggregateId: id.value,
      baseVersion: baseVersion,
      enqueuedAt: deletedAt.toUtc(),
    );
    return deleted;
  }
}
