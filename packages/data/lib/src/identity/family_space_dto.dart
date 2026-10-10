import 'package:domain/domain.dart';

/// Transport-neutral family-space DTO. No network or Supabase client.
final class FamilySpaceDto {
  const FamilySpaceDto({
    required this.id,
    required this.displayName,
    required this.householdTimezone,
  });

  final String id;
  final String displayName;
  final String householdTimezone;

  factory FamilySpaceDto.fromDomain(FamilySpace space) {
    return FamilySpaceDto(
      id: space.id.value,
      displayName: space.displayName,
      householdTimezone: space.householdTimezone.value,
    );
  }

  factory FamilySpaceDto.fromJson(Map<String, Object?> json) {
    return FamilySpaceDto(
      id: json['id']! as String,
      displayName: json['display_name']! as String,
      householdTimezone: json['household_timezone']! as String,
    );
  }

  FamilySpace toDomain() {
    return FamilySpace(
      id: FamilySpaceId(id),
      displayName: displayName,
      householdTimezone: HouseholdTimezone(householdTimezone),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'display_name': displayName,
    'household_timezone': householdTimezone,
  };
}
