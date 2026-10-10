/// One ordered step inside a care/daily routine.
final class RoutineStep {
  RoutineStep({required this.order, required this.instruction}) {
    if (order < 0) {
      throw ArgumentError.value(order, 'order', 'must be >= 0');
    }
    if (instruction.trim().isEmpty) {
      throw ArgumentError.value(
        instruction,
        'instruction',
        'must be non-empty',
      );
    }
  }

  /// Zero-based position in the routine sequence.
  final int order;

  final String instruction;
}
