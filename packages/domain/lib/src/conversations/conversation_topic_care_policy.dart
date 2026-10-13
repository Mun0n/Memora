import '../identity/family_access_policy.dart';
import '../identity/family_capability.dart';
import '../identity/family_membership.dart';

/// Role gates for family conversation topics (configure / view active).
///
/// Delegates to [FamilyAccessPolicy] for Dart↔SQL capability lockstep.
abstract final class ConversationTopicCarePolicy {
  /// Create/edit/reorder/activate/archive topics.
  static bool canEditTopics(FamilyMembership actor) {
    return FamilyAccessPolicy.allows(
      actor,
      FamilyCapability.editConversationTopics,
    );
  }

  /// View active topics (supported person and caregiver roles).
  static bool canViewTopics(FamilyMembership actor) {
    return FamilyAccessPolicy.allows(
      actor,
      FamilyCapability.viewConversationTopics,
    );
  }
}
