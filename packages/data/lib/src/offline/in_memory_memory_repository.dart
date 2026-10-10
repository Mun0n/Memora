import 'package:domain/domain.dart';

import 'in_memory_offline_store.dart';

/// Deterministic local memory repository. Immediate read-after-write.
final class InMemoryMemoryRepository implements MemoryRepository {
  InMemoryMemoryRepository(this._store);

  final InMemoryOfflineStore _store;

  @override
  Future<MemoryEntry> save({
    required MemoryEntry memory,
    required IdempotencyKey idempotencyKey,
  }) async {
    final pending = memory.copyWith(syncState: SyncState.pending);
    _store.putMemory(pending);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.memory,
      aggregateId: pending.id.value,
      baseVersion: pending.version,
      enqueuedAt: DateTime.now().toUtc(),
    );
    return pending;
  }

  @override
  Future<MemoryEntry?> findById(MemoryId id) async => _store.memoryById(id);

  @override
  Future<List<MemoryEntry>> listForFamily(FamilySpaceId familySpaceId) async {
    return _store.memoriesForFamily(familySpaceId);
  }

  @override
  Future<List<MemoryEntry>> listApprovedForFamily(
    FamilySpaceId familySpaceId,
  ) async {
    return _store.approvedMemoriesForFamily(familySpaceId);
  }

  @override
  Future<MemoryEntry> softDelete({
    required MemoryId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) async {
    final current = _store.memoryById(id);
    if (current == null) {
      throw StateError('memory not found: ${id.value}');
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
    _store.putMemory(deleted);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.memory,
      aggregateId: id.value,
      baseVersion: baseVersion,
      enqueuedAt: deletedAt.toUtc(),
    );
    return deleted;
  }
}
