import '../identity/family_access_policy.dart';
import '../identity/family_capability.dart';
import '../identity/family_membership.dart';

/// Role gates for family pastimes (configure / view active).
///
/// Delegates to [FamilyAccessPolicy] for Dart↔SQL capability lockstep.
abstract final class PastimeCarePolicy {
  /// Create/edit/reorder/activate/archive pastimes.
  static bool canEditPastimes(FamilyMembership actor) {
    return FamilyAccessPolicy.allows(actor, FamilyCapability.editPastimes);
  }

  /// View active pastimes (supported person and caregiver roles).
  static bool canViewPastimes(FamilyMembership actor) {
    return FamilyAccessPolicy.allows(actor, FamilyCapability.viewPastimes);
  }
}
