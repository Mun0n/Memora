import 'family_capability.dart';
import 'family_membership.dart';
import 'family_role.dart';
import 'membership_status.dart';

/// Central role→capability policy. Callers ask for a capability; they do not
/// scatter role-name checks.
///
/// Matrix (active memberships only; invited/revoked grant nothing):
///
/// | Role               | viewFamilySpace | updateFamilySpace | viewMemberships | manageMemberships |
/// | ------------------ | --------------- | ----------------- | --------------- | ----------------- |
/// | supportedPerson    | Yes             | No                | No              | No                |
/// | primaryCaregiver   | Yes             | Yes               | Yes             | Yes               |
/// | caregiver          | Yes             | No                | Yes             | No                |
/// | familyContributor  | Yes             | No                | No              | No                |
abstract final class FamilyAccessPolicy {
  static const Map<FamilyRole, Set<FamilyCapability>> _activeCapabilities =
      <FamilyRole, Set<FamilyCapability>>{
        FamilyRole.supportedPerson: {FamilyCapability.viewFamilySpace},
        FamilyRole.primaryCaregiver: {
          FamilyCapability.viewFamilySpace,
          FamilyCapability.updateFamilySpace,
          FamilyCapability.viewMemberships,
          FamilyCapability.manageMemberships,
        },
        FamilyRole.caregiver: {
          FamilyCapability.viewFamilySpace,
          FamilyCapability.viewMemberships,
        },
        FamilyRole.familyContributor: {FamilyCapability.viewFamilySpace},
      };

  /// Capabilities granted by [role] when the membership is active.
  static Set<FamilyCapability> capabilitiesFor(FamilyRole role) =>
      Set<FamilyCapability>.unmodifiable(_activeCapabilities[role]!);

  /// Whether [membership] grants [capability]. Inactive statuses always deny.
  static bool allows(FamilyMembership membership, FamilyCapability capability) {
    if (membership.status != MembershipStatus.active) {
      return false;
    }
    return _activeCapabilities[membership.role]!.contains(capability);
  }

  /// Own-row read rule: an active member may read their own membership without
  /// [FamilyCapability.viewMemberships]. Invited/revoked grant no row access.
  static bool canViewMembershipRow({
    required FamilyMembership actor,
    required FamilyMembership target,
  }) {
    if (actor.familySpaceId != target.familySpaceId) {
      return false;
    }
    if (allows(actor, FamilyCapability.viewMemberships)) {
      // viewMemberships still requires the actor to be active (via [allows]).
      return true;
    }
    return actor.isActive &&
        target.isActive &&
        actor.userId == target.userId &&
        actor.id == target.id;
  }
}
