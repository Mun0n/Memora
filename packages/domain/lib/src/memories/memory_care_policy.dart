import '../identity/family_membership.dart';
import '../identity/family_role.dart';

/// Role gates for family memories (manage / contribute / approved view).
///
/// Uses [FamilyRole] checks only — does not widen the Slice 2
/// [FamilyCapability] SQL wire catalogue. Deny-by-default for inactive
/// membership.
abstract final class MemoryCarePolicy {
  /// Create/edit/order/approve/archive and manage media metadata.
  static bool canManageMemories(FamilyMembership actor) {
    if (!actor.isActive) {
      return false;
    }
    return actor.role == FamilyRole.primaryCaregiver ||
        actor.role == FamilyRole.caregiver;
  }

  /// Propose/add memories when granted (active family contributor).
  static bool canContributeMemories(FamilyMembership actor) {
    if (!actor.isActive) {
      return false;
    }
    return actor.role == FamilyRole.familyContributor;
  }

  /// View approved memories (supported person and active caregivers/managers).
  static bool canViewApprovedMemories(FamilyMembership actor) {
    if (!actor.isActive) {
      return false;
    }
    return actor.role == FamilyRole.supportedPerson ||
        actor.role == FamilyRole.primaryCaregiver ||
        actor.role == FamilyRole.caregiver ||
        actor.role == FamilyRole.familyContributor;
  }
}
