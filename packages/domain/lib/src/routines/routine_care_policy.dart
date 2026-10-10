import '../identity/family_access_policy.dart';
import '../identity/family_capability.dart';
import '../identity/family_membership.dart';

/// Role gates for routine/reminder care structure and step progress.
///
/// Delegates to [FamilyAccessPolicy] so Dart and SQL capability wires stay
/// identical. Active caregiver membership is treated as granted for
/// care-structure edits in this fictional vertical.
abstract final class RoutineCarePolicy {
  /// Create/edit/order/activate/archive routines and configure reminders.
  static bool canConfigureCareContent(FamilyMembership actor) {
    return FamilyAccessPolicy.allows(actor, FamilyCapability.editRoutines) &&
        FamilyAccessPolicy.allows(actor, FamilyCapability.configureReminders);
  }

  /// Complete or correct routine steps (supported-person local use).
  static bool canRecordStepProgress(FamilyMembership actor) {
    return FamilyAccessPolicy.allows(
      actor,
      FamilyCapability.recordRoutineProgress,
    );
  }

  /// Resolve concurrent routine-edit conflicts.
  static bool canResolveSyncConflicts(FamilyMembership actor) {
    return FamilyAccessPolicy.allows(
      actor,
      FamilyCapability.resolveSyncConflicts,
    );
  }
}
