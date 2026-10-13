/// Lifecycle for a family pastime aggregate.
///
/// Active pastimes are eligible for supported-person presentation.
/// Draft and archived items are excluded from that view.
/// Soft-delete (tombstone) remains a separate retention path.
enum PastimeLifecycleStatus {
  /// Caregiver draft — not shown to the supported person.
  draft('draft'),

  /// Active for supported-person presentation (max six per family).
  active('active'),

  /// Removed from active presentation; retained for caregivers.
  archived('archived');

  const PastimeLifecycleStatus(this.wireName);

  final String wireName;

  static PastimeLifecycleStatus parse(String raw) {
    for (final status in PastimeLifecycleStatus.values) {
      if (status.wireName == raw) {
        return status;
      }
    }
    throw FormatException('Unknown PastimeLifecycleStatus: $raw');
  }
}
