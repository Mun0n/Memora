/// Supported family-space membership roles for Slice 2.
enum FamilyRole {
  supportedPerson('supportedPerson'),
  primaryCaregiver('primaryCaregiver'),
  caregiver('caregiver'),
  familyContributor('familyContributor');

  const FamilyRole(this.wireName);

  /// Canonical wire/SQL name; callers must not invent alternate spellings.
  final String wireName;

  static FamilyRole parse(String raw) {
    for (final role in FamilyRole.values) {
      if (role.wireName == raw) {
        return role;
      }
    }
    throw FormatException('Unknown FamilyRole: $raw');
  }
}
