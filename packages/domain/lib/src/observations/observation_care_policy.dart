import '../identity/family_membership.dart';
import '../identity/family_role.dart';

/// Role gates for non-clinical weight/blood-pressure observation recording.
///
/// Authorized caregivers only. Does not widen [FamilyCapability] SQL wires.
/// No interpretation, thresholds or alerts are granted by this policy.
abstract final class ObservationCarePolicy {
  /// Add, correct, tombstone and view chronological observation history.
  static bool canRecordObservations(FamilyMembership actor) {
    if (!actor.isActive) {
      return false;
    }
    return actor.role == FamilyRole.primaryCaregiver ||
        actor.role == FamilyRole.caregiver;
  }
}
