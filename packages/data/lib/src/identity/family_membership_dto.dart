import 'package:domain/domain.dart';

/// Transport-neutral membership DTO. Wire names match SQL role/status enums.
final class FamilyMembershipDto {
  const FamilyMembershipDto({
    required this.id,
    required this.familySpaceId,
    required this.userId,
    required this.role,
    required this.status,
  });

  final String id;
  final String familySpaceId;
  final String userId;
  final String role;
  final String status;

  factory FamilyMembershipDto.fromDomain(FamilyMembership membership) {
    return FamilyMembershipDto(
      id: membership.id.value,
      familySpaceId: membership.familySpaceId.value,
      userId: membership.userId.value,
      role: membership.role.wireName,
      status: membership.status.wireName,
    );
  }

  factory FamilyMembershipDto.fromJson(Map<String, Object?> json) {
    return FamilyMembershipDto(
      id: json['id']! as String,
      familySpaceId: json['family_space_id']! as String,
      userId: json['user_id']! as String,
      role: json['role']! as String,
      status: json['status']! as String,
    );
  }

  FamilyMembership toDomain() {
    return FamilyMembership(
      id: FamilyMembershipId(id),
      familySpaceId: FamilySpaceId(familySpaceId),
      userId: UserId(userId),
      role: FamilyRole.parse(role),
      status: MembershipStatus.parse(status),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'family_space_id': familySpaceId,
    'user_id': userId,
    'role': role,
    'status': status,
  };
}
