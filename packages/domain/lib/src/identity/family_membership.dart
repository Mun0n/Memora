import 'family_role.dart';
import 'identifiers.dart';
import 'membership_status.dart';

/// Immutable membership of an authenticated identity in a family space.
final class FamilyMembership {
  const FamilyMembership({
    required this.id,
    required this.familySpaceId,
    required this.userId,
    required this.role,
    required this.status,
  });

  final FamilyMembershipId id;
  final FamilySpaceId familySpaceId;
  final UserId userId;
  final FamilyRole role;
  final MembershipStatus status;

  bool get isActive => status == MembershipStatus.active;
}
