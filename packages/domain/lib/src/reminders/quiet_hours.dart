/// Quiet-hours window that suppresses convenience reminder prompts.
///
/// Minutes are from local midnight in `[0, 1440)`. Overnight windows are
/// allowed when [startMinuteOfDay] > [endMinuteOfDay] (e.g. 22:00–07:00).
///
/// This value object never implies emergency coverage, medical alerting or
/// guaranteed delivery — reminders remain convenience prompts only.
final class QuietHours {
  QuietHours({required this.startMinuteOfDay, required this.endMinuteOfDay}) {
    _assertMinute(startMinuteOfDay, 'startMinuteOfDay');
    _assertMinute(endMinuteOfDay, 'endMinuteOfDay');
    if (startMinuteOfDay == endMinuteOfDay) {
      throw ArgumentError(
        'quiet-hours window must be non-empty '
        '(startMinuteOfDay != endMinuteOfDay)',
      );
    }
  }

  /// Inclusive start of the quiet window, minutes from local midnight.
  final int startMinuteOfDay;

  /// Exclusive end of the quiet window, minutes from local midnight.
  final int endMinuteOfDay;

  /// Whether [localMinuteOfDay] falls inside this quiet window.
  bool containsMinuteOfDay(int localMinuteOfDay) {
    _assertMinute(localMinuteOfDay, 'localMinuteOfDay');
    if (startMinuteOfDay < endMinuteOfDay) {
      return localMinuteOfDay >= startMinuteOfDay &&
          localMinuteOfDay < endMinuteOfDay;
    }
    // Overnight: e.g. 22:00 → 07:00.
    return localMinuteOfDay >= startMinuteOfDay ||
        localMinuteOfDay < endMinuteOfDay;
  }

  /// Whether a local wall-clock [instant] is inside quiet hours.
  ///
  /// Uses the clock fields on [instant] as already-local civil time. Callers
  /// that hold UTC must convert before calling — domain stays TZ-DB free.
  bool containsLocalDateTime(DateTime instant) {
    final minute = instant.hour * 60 + instant.minute;
    return containsMinuteOfDay(minute);
  }

  static void _assertMinute(int value, String label) {
    if (value < 0 || value >= 24 * 60) {
      throw ArgumentError.value(value, label, 'must be in [0, 1440)');
    }
  }
}
