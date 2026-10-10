import '../identity/identifiers.dart';
import '../observations/blood_pressure_observation.dart';
import '../observations/weight_observation.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';

/// Append-only weight observation port. Never merges values silently.
abstract interface class WeightObservationRepository {
  Future<WeightObservation> append({
    required WeightObservation observation,
    required IdempotencyKey idempotencyKey,
  });

  Future<WeightObservation?> findById(ObservationId id);

  Future<List<WeightObservation>> listForFamily(FamilySpaceId familySpaceId);

  /// Chronological history (oldest first), including corrections and tombstones.
  Future<List<WeightObservation>> listChronological(
    FamilySpaceId familySpaceId,
  );

  Future<WeightObservation> softDelete({
    required ObservationId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  });
}

/// Append-only blood-pressure observation port. Never merges values silently.
abstract interface class BloodPressureObservationRepository {
  Future<BloodPressureObservation> append({
    required BloodPressureObservation observation,
    required IdempotencyKey idempotencyKey,
  });

  Future<BloodPressureObservation?> findById(ObservationId id);

  Future<List<BloodPressureObservation>> listForFamily(
    FamilySpaceId familySpaceId,
  );

  /// Chronological history (oldest first), including corrections and tombstones.
  Future<List<BloodPressureObservation>> listChronological(
    FamilySpaceId familySpaceId,
  );

  Future<BloodPressureObservation> softDelete({
    required ObservationId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  });
}
