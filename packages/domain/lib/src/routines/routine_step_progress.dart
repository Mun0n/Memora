import 'step_completion_status.dart';

/// Progress for one ordered step inside a [RoutineDayProgress] aggregate.
final class RoutineStepProgress {
  RoutineStepProgress({required this.stepOrder, required this.status}) {
    if (stepOrder < 0) {
      throw ArgumentError.value(stepOrder, 'stepOrder', 'must be >= 0');
    }
  }

  final int stepOrder;
  final StepCompletionStatus status;

  RoutineStepProgress copyWith({StepCompletionStatus? status}) {
    return RoutineStepProgress(
      stepOrder: stepOrder,
      status: status ?? this.status,
    );
  }
}
