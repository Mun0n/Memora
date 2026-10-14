import 'family_access_policy.dart';
import 'family_capability.dart';
import 'family_membership.dart';

/// Role gates for the supported-person preferred-name profile.
///
/// Edit is primary-caregiver only (mirrors [FamilyCapability.updateFamilySpace]).
/// Delegates to [FamilyAccessPolicy] for Dart↔SQL capability lockstep.
abstract final class SupportedPersonProfileCarePolicy {
  /// Create/correct the preferred name (primary caregiver only).
  static bool canEditSupportedPersonProfile(FamilyMembership actor) {
    return FamilyAccessPolicy.allows(
      actor,
      FamilyCapability.editSupportedPersonProfile,
    );
  }

  /// Read the cached preferred name (supported person + caregivers).
  static bool canViewSupportedPersonProfile(FamilyMembership actor) {
    return FamilyAccessPolicy.allows(
      actor,
      FamilyCapability.viewSupportedPersonProfile,
    );
  }
}
