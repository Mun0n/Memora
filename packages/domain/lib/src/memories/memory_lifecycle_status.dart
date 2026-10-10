/// Lifecycle for a family memory aggregate.
///
/// Approved memories are eligible for supported-person viewing.
/// Archived and proposed memories are excluded from that view.
/// Soft-delete (tombstone) remains a separate retention path.
enum MemoryLifecycleStatus {
  /// Contributor proposal or caregiver draft awaiting approval.
  proposed('proposed'),

  /// Approved for supported-person presentation.
  approved('approved'),

  /// Removed from active presentation; retained for caregivers.
  archived('archived');

  const MemoryLifecycleStatus(this.wireName);

  final String wireName;

  static MemoryLifecycleStatus parse(String raw) {
    for (final status in MemoryLifecycleStatus.values) {
      if (status.wireName == raw) {
        return status;
      }
    }
    throw FormatException('Unknown MemoryLifecycleStatus: $raw');
  }
}
