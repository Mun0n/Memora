import 'package:domain/domain.dart';

import 'in_memory_offline_store.dart';

/// Append-only local weight observations. Never merges values.
final class InMemoryWeightObservationRepository
    implements WeightObservationRepository {
  InMemoryWeightObservationRepository(this._store);

  final InMemoryOfflineStore _store;

  @override
  Future<WeightObservation> append({
    required WeightObservation observation,
    required IdempotencyKey idempotencyKey,
  }) async {
    final existing = _store.weightById(observation.id);
    if (existing != null) {
      // Idempotent re-append of the same observation id returns the stored row.
      await _store.enqueueMutation(
        idempotencyKey: idempotencyKey,
        aggregateType: OutboxAggregateType.weightObservation,
        aggregateId: existing.id.value,
        baseVersion: existing.version,
        enqueuedAt: existing.recordedAt.toUtc(),
      );
      return existing;
    }

    final pending = observation.copyWith(syncState: SyncState.pending);
    _store.putWeight(pending);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.weightObservation,
      aggregateId: pending.id.value,
      baseVersion: pending.version,
      enqueuedAt: pending.recordedAt.toUtc(),
    );
    return pending;
  }

  @override
  Future<WeightObservation?> findById(ObservationId id) async {
    return _store.weightById(id);
  }

  @override
  Future<List<WeightObservation>> listForFamily(
    FamilySpaceId familySpaceId,
  ) async {
    return _store.weightsForFamily(familySpaceId);
  }
}

/// Append-only local blood-pressure observations. Never merges values.
final class InMemoryBloodPressureObservationRepository
    implements BloodPressureObservationRepository {
  InMemoryBloodPressureObservationRepository(this._store);

  final InMemoryOfflineStore _store;

  @override
  Future<BloodPressureObservation> append({
    required BloodPressureObservation observation,
    required IdempotencyKey idempotencyKey,
  }) async {
    final existing = _store.bloodPressureById(observation.id);
    if (existing != null) {
      await _store.enqueueMutation(
        idempotencyKey: idempotencyKey,
        aggregateType: OutboxAggregateType.bloodPressureObservation,
        aggregateId: existing.id.value,
        baseVersion: existing.version,
        enqueuedAt: existing.recordedAt.toUtc(),
      );
      return existing;
    }

    final pending = observation.copyWith(syncState: SyncState.pending);
    _store.putBloodPressure(pending);
    await _store.enqueueMutation(
      idempotencyKey: idempotencyKey,
      aggregateType: OutboxAggregateType.bloodPressureObservation,
      aggregateId: pending.id.value,
      baseVersion: pending.version,
      enqueuedAt: pending.recordedAt.toUtc(),
    );
    return pending;
  }

  @override
  Future<BloodPressureObservation?> findById(ObservationId id) async {
    return _store.bloodPressureById(id);
  }

  @override
  Future<List<BloodPressureObservation>> listForFamily(
    FamilySpaceId familySpaceId,
  ) async {
    return _store.bloodPressuresForFamily(familySpaceId);
  }
}
