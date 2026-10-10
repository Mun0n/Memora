/// Care-structure lifecycle for a routine aggregate.
///
/// Archived routines are excluded from today's presentation queries.
/// Soft-delete (tombstone) remains a separate retention path.
enum RoutineLifecycleStatus {
  active('active'),
  archived('archived');

  const RoutineLifecycleStatus(this.wireName);

  final String wireName;

  static RoutineLifecycleStatus parse(String raw) {
    for (final status in RoutineLifecycleStatus.values) {
      if (status.wireName == raw) {
        return status;
      }
    }
    throw FormatException('Unknown RoutineLifecycleStatus: $raw');
  }
}
