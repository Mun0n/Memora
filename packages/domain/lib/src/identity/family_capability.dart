/// Explicit capability catalogue for family-identity and product authorization.
///
/// Wire names must stay identical to PostgreSQL `memora_has_capability`.
enum FamilyCapability {
  viewFamilySpace('viewFamilySpace'),
  updateFamilySpace('updateFamilySpace'),
  viewMemberships('viewMemberships'),
  manageMemberships('manageMemberships'),
  viewRoutines('viewRoutines'),
  editRoutines('editRoutines'),
  recordRoutineProgress('recordRoutineProgress'),
  viewReminders('viewReminders'),
  configureReminders('configureReminders'),
  viewApprovedMemories('viewApprovedMemories'),
  manageMemories('manageMemories'),
  contributeMemories('contributeMemories'),
  manageMediaMetadata('manageMediaMetadata'),
  viewObservations('viewObservations'),
  recordObservations('recordObservations'),
  resolveSyncConflicts('resolveSyncConflicts');

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
