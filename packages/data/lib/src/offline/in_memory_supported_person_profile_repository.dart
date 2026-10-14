import 'package:domain/domain.dart';

import 'in_memory_offline_store.dart';

/// Deterministic local preferred-name profile repository.
final class InMemorySupportedPersonProfileRepository
    implements SupportedPersonProfileRepository {
  InMemorySupportedPersonProfileRepository(this._store);

  final InMemoryOfflineStore _store;

  @override
  Future<SupportedPersonProfile> save({
    required SupportedPersonProfile profile,
    required IdempotencyKey idempotencyKey,
  }) async {
    final existing = _store.supportedPersonProfileForFamily(
      profile.familySpaceId,
    );
    if (existing != null && !existing.isDeleted && existing.id != profile.id) {
      throw StateError(
        'family already has a supported-person profile: ${existing.id.value}',
      );
    }
    final pending = profile.copyWith(syncState: SyncState.pending);
    _store.putSupportedPersonProfile(pending);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.supportedPersonProfile,
      aggregateId: pending.id.value,
      baseVersion: pending.version,
      enqueuedAt: DateTime.now().toUtc(),
    );
    return pending;
  }

  @override
  Future<SupportedPersonProfile?> findById(SupportedPersonProfileId id) async =>
      _store.supportedPersonProfileById(id);

  @override
  Future<SupportedPersonProfile?> findForFamily(
    FamilySpaceId familySpaceId,
  ) async {
    return _store.supportedPersonProfileForFamily(familySpaceId);
  }

  @override
  Future<SupportedPersonProfile> softDelete({
    required SupportedPersonProfileId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) async {
    final current = _store.supportedPersonProfileById(id);
    if (current == null) {
      throw StateError('supported-person profile not found: ${id.value}');
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
    _store.putSupportedPersonProfile(deleted);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.supportedPersonProfile,
      aggregateId: id.value,
      baseVersion: baseVersion,
      enqueuedAt: deletedAt.toUtc(),
    );
    return deleted;
  }
}
