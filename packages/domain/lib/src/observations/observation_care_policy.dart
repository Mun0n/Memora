import '../identity/family_access_policy.dart';
import '../identity/family_capability.dart';
import '../identity/family_membership.dart';

/// Role gates for non-clinical weight/blood-pressure observation recording.
///
/// Authorized caregivers only. No interpretation, thresholds or alerts.
abstract final class ObservationCarePolicy {
  /// Add, correct, tombstone and view chronological observation history.
  static bool canRecordObservations(FamilyMembership actor) {
    return FamilyAccessPolicy.allows(
          actor,
          FamilyCapability.recordObservations,
        ) &&
        FamilyAccessPolicy.allows(actor, FamilyCapability.viewObservations);
  }
}
