/// Immutable identity identifiers for family spaces, memberships and users.
library;

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

void _assertUuid(String raw, String label) {
  if (!_uuidPattern.hasMatch(raw)) {
    throw FormatException('Invalid $label UUID: $raw');
  }
}

/// Opaque family-space identifier (UUID string).
final class FamilySpaceId {
  factory FamilySpaceId(String raw) {
    _assertUuid(raw, 'FamilySpaceId');
    return FamilySpaceId._(raw.toLowerCase());
  }

  const FamilySpaceId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is FamilySpaceId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'FamilySpaceId($value)';
}

/// Opaque membership-row identifier (UUID string).
final class FamilyMembershipId {
  factory FamilyMembershipId(String raw) {
    _assertUuid(raw, 'FamilyMembershipId');
    return FamilyMembershipId._(raw.toLowerCase());
  }

  const FamilyMembershipId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is FamilyMembershipId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'FamilyMembershipId($value)';
}

/// Authenticated-identity identifier referencing auth.users(id) on the server.
final class UserId {
  factory UserId(String raw) {
    _assertUuid(raw, 'UserId');
    return UserId._(raw.toLowerCase());
  }

  const UserId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is UserId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'UserId($value)';
}
