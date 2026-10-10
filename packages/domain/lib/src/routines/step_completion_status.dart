/// Per-step progress for a routine on a calendar day.
///
/// Toggle is bidirectional: completed may be corrected back to pending.
enum StepCompletionStatus {
  pending('pending'),
  completed('completed');

  const StepCompletionStatus(this.wireName);

  final String wireName;

  static StepCompletionStatus parse(String raw) {
    for (final status in StepCompletionStatus.values) {
      if (status.wireName == raw) {
        return status;
      }
    }
    throw FormatException('Unknown StepCompletionStatus: $raw');
  }
}
