import '../identity/family_membership.dart';
import '../identity/family_role.dart';

/// Role gates for routine/reminder care structure and step progress.
///
/// Uses [FamilyRole] checks only — does not widen the Slice 2
/// [FamilyCapability] SQL wire catalogue. Active caregiver membership is
/// treated as granted for care-structure edits in this fictional vertical.
abstract final class RoutineCarePolicy {
  /// Create/edit/order/activate/archive routines and configure reminders.
  static bool canConfigureCareContent(FamilyMembership actor) {
    if (!actor.isActive) {
      return false;
    }
    return actor.role == FamilyRole.primaryCaregiver ||
        actor.role == FamilyRole.caregiver;
  }

  /// Complete or correct routine steps (supported-person local use).
  static bool canRecordStepProgress(FamilyMembership actor) {
    if (!actor.isActive) {
      return false;
    }
    return actor.role == FamilyRole.supportedPerson;
  }
}
