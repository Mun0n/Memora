import '../identity/family_access_policy.dart';
import '../identity/family_capability.dart';
import '../identity/family_membership.dart';

/// Role gates for family memories (manage / contribute / approved view).
///
/// Delegates to [FamilyAccessPolicy] for Dart↔SQL capability lockstep.
abstract final class MemoryCarePolicy {
  /// Create/edit/order/approve/archive and manage media metadata.
  static bool canManageMemories(FamilyMembership actor) {
    return FamilyAccessPolicy.allows(actor, FamilyCapability.manageMemories);
  }

  /// Propose/add memories when granted (active family contributor).
  static bool canContributeMemories(FamilyMembership actor) {
    return FamilyAccessPolicy.allows(
      actor,
      FamilyCapability.contributeMemories,
    );
  }

  /// View approved memories (supported person and active family roles).
  static bool canViewApprovedMemories(FamilyMembership actor) {
    return FamilyAccessPolicy.allows(
      actor,
      FamilyCapability.viewApprovedMemories,
    );
  }

  /// Manage family-scoped media metadata paths/checksums.
  static bool canManageMediaMetadata(FamilyMembership actor) {
    return FamilyAccessPolicy.allows(
      actor,
      FamilyCapability.manageMediaMetadata,
    );
  }
}
