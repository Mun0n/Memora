import 'package:domain/domain.dart';

import 'in_memory_offline_store.dart';

/// Deterministic local pastime repository. Immediate read-after-write.
final class InMemoryPastimeRepository implements PastimeRepository {
  InMemoryPastimeRepository(this._store);

  final InMemoryOfflineStore _store;

  @override
  Future<Pastime> save({
    required Pastime pastime,
    required IdempotencyKey idempotencyKey,
  }) async {
    final pending = pastime.copyWith(syncState: SyncState.pending);
    _store.putPastime(pending);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.pastime,
      aggregateId: pending.id.value,
      baseVersion: pending.version,
      enqueuedAt: DateTime.now().toUtc(),
    );
    return pending;
  }

  @override
  Future<Pastime?> findById(PastimeId id) async => _store.pastimeById(id);

  @override
  Future<List<Pastime>> listForFamily(FamilySpaceId familySpaceId) async {
    return _store.pastimesForFamily(familySpaceId);
  }

  @override
  Future<List<Pastime>> listActiveForFamily(FamilySpaceId familySpaceId) async {
    return _store.activePastimesForFamily(familySpaceId);
  }

  @override
  Future<Pastime> softDelete({
    required PastimeId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) async {
    final current = _store.pastimeById(id);
    if (current == null) {
      throw StateError('pastime not found: ${id.value}');
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
    _store.putPastime(deleted);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.pastime,
      aggregateId: id.value,
      baseVersion: baseVersion,
      enqueuedAt: deletedAt.toUtc(),
    );
    return deleted;
  }
}
