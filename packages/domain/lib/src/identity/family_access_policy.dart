import 'family_capability.dart';
import 'family_membership.dart';
import 'family_role.dart';
import 'membership_status.dart';

/// Central role→capability policy. Callers ask for a capability; they do not
/// scatter role-name checks.
///
/// Matrix (active memberships only; invited/revoked grant nothing). Product
/// wires mirror Slice 3–5 role policies and the architecture permission table
/// (contributor/caregiver “if granted” = capability present when active).
abstract final class FamilyAccessPolicy {
  static const Map<FamilyRole, Set<FamilyCapability>> _activeCapabilities =
      <FamilyRole, Set<FamilyCapability>>{
        FamilyRole.supportedPerson: {
          FamilyCapability.viewFamilySpace,
          FamilyCapability.viewRoutines,
          FamilyCapability.recordRoutineProgress,
          FamilyCapability.viewReminders,
          FamilyCapability.viewApprovedMemories,
          FamilyCapability.viewPastimes,
          FamilyCapability.viewConversationTopics,
        },
        FamilyRole.primaryCaregiver: {
          FamilyCapability.viewFamilySpace,
          FamilyCapability.updateFamilySpace,
          FamilyCapability.viewMemberships,
          FamilyCapability.manageMemberships,
          FamilyCapability.viewRoutines,
          FamilyCapability.editRoutines,
          FamilyCapability.viewReminders,
          FamilyCapability.configureReminders,
          FamilyCapability.viewApprovedMemories,
          FamilyCapability.manageMemories,
          FamilyCapability.manageMediaMetadata,
          FamilyCapability.viewObservations,
          FamilyCapability.recordObservations,
          FamilyCapability.resolveSyncConflicts,
          FamilyCapability.viewPastimes,
          FamilyCapability.editPastimes,
          FamilyCapability.viewConversationTopics,
          FamilyCapability.editConversationTopics,
        },
        FamilyRole.caregiver: {
          FamilyCapability.viewFamilySpace,
          FamilyCapability.viewMemberships,
          FamilyCapability.viewRoutines,
          FamilyCapability.editRoutines,
          FamilyCapability.viewReminders,
          FamilyCapability.configureReminders,
          FamilyCapability.viewApprovedMemories,
          FamilyCapability.manageMemories,
          FamilyCapability.manageMediaMetadata,
          FamilyCapability.viewObservations,
          FamilyCapability.recordObservations,
          FamilyCapability.resolveSyncConflicts,
          FamilyCapability.viewPastimes,
          FamilyCapability.editPastimes,
          FamilyCapability.viewConversationTopics,
          FamilyCapability.editConversationTopics,
        },
        FamilyRole.familyContributor: {
          FamilyCapability.viewFamilySpace,
          FamilyCapability.viewRoutines,
          FamilyCapability.viewApprovedMemories,
          FamilyCapability.contributeMemories,
        },
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
      return true;
    }
    return actor.isActive &&
        target.isActive &&
        actor.userId == target.userId &&
        actor.id == target.id;
  }
}
