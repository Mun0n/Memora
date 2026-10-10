import '../identity/identifiers.dart';
import '../observations/blood_pressure_observation.dart';
import '../observations/weight_observation.dart';
import '../offline/offline_identifiers.dart';
import '../sync/idempotency_key.dart';

/// Append-only weight observation port. Never merges values silently.
abstract interface class WeightObservationRepository {
  Future<WeightObservation> append({
    required WeightObservation observation,
    required IdempotencyKey idempotencyKey,
  });

  Future<WeightObservation?> findById(ObservationId id);

  Future<List<WeightObservation>> listForFamily(FamilySpaceId familySpaceId);
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
}
