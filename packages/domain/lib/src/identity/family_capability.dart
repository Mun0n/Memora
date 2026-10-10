/// Explicit capability catalogue for Slice 2 family-identity authorization.
enum FamilyCapability {
  viewFamilySpace('viewFamilySpace'),
  updateFamilySpace('updateFamilySpace'),
  viewMemberships('viewMemberships'),
  manageMemberships('manageMemberships');

  const FamilyCapability(this.wireName);

  /// Canonical wire/SQL name shared with the PostgreSQL policy matrix.
  final String wireName;

  static FamilyCapability parse(String raw) {
    for (final capability in FamilyCapability.values) {
      if (capability.wireName == raw) {
        return capability;
      }
    }
    throw FormatException('Unknown FamilyCapability: $raw');
  }
}
