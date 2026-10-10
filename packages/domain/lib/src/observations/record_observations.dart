import '../identity/family_membership.dart';
import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../repositories/observation_repository.dart';
import '../routines/unauthorized_care_action_exception.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';
import '../sync/sync_state.dart';
import 'blood_pressure_observation.dart';
import 'observation_care_policy.dart';
import 'weight_observation.dart';

/// Authorized caregiver use cases for non-clinical observation recording.
///
/// Corrections always append; prior values are never overwritten or merged.
final class RecordObservations {
  RecordObservations({
    required WeightObservationRepository weights,
    required BloodPressureObservationRepository bloodPressures,
  }) : _weights = weights,
       _bloodPressures = bloodPressures;

  final WeightObservationRepository _weights;
  final BloodPressureObservationRepository _bloodPressures;

  Future<WeightObservation> addWeight({
    required FamilyMembership actor,
    required ObservationId id,
    required FamilySpaceId familySpaceId,
    required double kilograms,
    required DateTime recordedAt,
    required IdempotencyKey idempotencyKey,
  }) async {
    _assertCanRecord(actor, familySpaceId);
    final observation = WeightObservation(
      id: id,
      familySpaceId: familySpaceId,
      kilograms: kilograms,
      recordedAt: recordedAt,
      authorId: actor.userId,
      version: AggregateVersion.initial,
      syncState: SyncState.local,
    );
    return _weights.append(
      observation: observation,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<WeightObservation> correctWeight({
    required FamilyMembership actor,
    required ObservationId sourceId,
    required ObservationId correctionId,
    required double kilograms,
    required DateTime recordedAt,
    required IdempotencyKey idempotencyKey,
  }) async {
    final source = await _weights.findById(sourceId);
    if (source == null) {
      throw StateError('weight observation not found: ${sourceId.value}');
    }
    _assertCanRecord(actor, source.familySpaceId);
    if (source.isDeleted) {
      throw StateError('cannot correct tombstoned weight: ${sourceId.value}');
    }
    // Preserve source values — append a linked correction row only.
    final correction = WeightObservation(
      id: correctionId,
      familySpaceId: source.familySpaceId,
      kilograms: kilograms,
      recordedAt: recordedAt,
      authorId: actor.userId,
      correctsObservationId: sourceId,
      version: AggregateVersion.initial,
      syncState: SyncState.local,
    );
    return _weights.append(
      observation: correction,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<WeightObservation> tombstoneWeight({
    required FamilyMembership actor,
    required ObservationId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
  }) async {
    final current = await _weights.findById(id);
    if (current == null) {
      throw StateError('weight observation not found: ${id.value}');
    }
    _assertCanRecord(actor, current.familySpaceId);
    return _weights.softDelete(
      id: id,
      baseVersion: baseVersion,
      deletedAt: deletedAt,
      idempotencyKey: idempotencyKey,
      deletedBy: actor.userId,
    );
  }

  Future<List<WeightObservation>> listWeightHistory({
    required FamilyMembership actor,
    required FamilySpaceId familySpaceId,
  }) async {
    _assertCanRecord(actor, familySpaceId);
    return _weights.listChronological(familySpaceId);
  }

  Future<BloodPressureObservation> addBloodPressure({
    required FamilyMembership actor,
    required ObservationId id,
    required FamilySpaceId familySpaceId,
    required int systolicMmHg,
    required int diastolicMmHg,
    required DateTime recordedAt,
    required IdempotencyKey idempotencyKey,
  }) async {
    _assertCanRecord(actor, familySpaceId);
    final observation = BloodPressureObservation(
      id: id,
      familySpaceId: familySpaceId,
      systolicMmHg: systolicMmHg,
      diastolicMmHg: diastolicMmHg,
      recordedAt: recordedAt,
      authorId: actor.userId,
      version: AggregateVersion.initial,
      syncState: SyncState.local,
    );
    return _bloodPressures.append(
      observation: observation,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<BloodPressureObservation> correctBloodPressure({
    required FamilyMembership actor,
    required ObservationId sourceId,
    required ObservationId correctionId,
    required int systolicMmHg,
    required int diastolicMmHg,
    required DateTime recordedAt,
    required IdempotencyKey idempotencyKey,
  }) async {
    final source = await _bloodPressures.findById(sourceId);
    if (source == null) {
      throw StateError(
        'blood-pressure observation not found: ${sourceId.value}',
      );
    }
    _assertCanRecord(actor, source.familySpaceId);
    if (source.isDeleted) {
      throw StateError(
        'cannot correct tombstoned blood pressure: ${sourceId.value}',
      );
    }
    final correction = BloodPressureObservation(
      id: correctionId,
      familySpaceId: source.familySpaceId,
      systolicMmHg: systolicMmHg,
      diastolicMmHg: diastolicMmHg,
      recordedAt: recordedAt,
      authorId: actor.userId,
      correctsObservationId: sourceId,
      version: AggregateVersion.initial,
      syncState: SyncState.local,
    );
    return _bloodPressures.append(
      observation: correction,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<BloodPressureObservation> tombstoneBloodPressure({
    required FamilyMembership actor,
    required ObservationId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
  }) async {
    final current = await _bloodPressures.findById(id);
    if (current == null) {
      throw StateError('blood-pressure observation not found: ${id.value}');
    }
    _assertCanRecord(actor, current.familySpaceId);
    return _bloodPressures.softDelete(
      id: id,
      baseVersion: baseVersion,
      deletedAt: deletedAt,
      idempotencyKey: idempotencyKey,
      deletedBy: actor.userId,
    );
  }

  Future<List<BloodPressureObservation>> listBloodPressureHistory({
    required FamilyMembership actor,
    required FamilySpaceId familySpaceId,
  }) async {
    _assertCanRecord(actor, familySpaceId);
    return _bloodPressures.listChronological(familySpaceId);
  }

  void _assertCanRecord(FamilyMembership actor, FamilySpaceId spaceId) {
    if (actor.familySpaceId != spaceId) {
      throw UnauthorizedCareActionException(
        'membership is outside family space ${spaceId.value}',
      );
    }
    if (!ObservationCarePolicy.canRecordObservations(actor)) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot record observations',
      );
    }
  }
}
