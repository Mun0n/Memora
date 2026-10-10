import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/sync_state.dart';
import '../sync/tombstone.dart';
import 'routine_step_progress.dart';
import 'step_completion_status.dart';

/// Local-first progress for one routine on one calendar day.
///
/// Completions and corrections write here first; network absence must not
/// block use. Soft-delete uses [tombstone] consistent with other aggregates.
final class RoutineDayProgress {
  RoutineDayProgress({
    required this.id,
    required this.routineId,
    required this.familySpaceId,
    required DateTime localDate,
    required List<RoutineStepProgress> steps,
    required this.version,
    required this.syncState,
    this.tombstone,
  }) : localDate = _dateOnly(localDate),
       steps = List<RoutineStepProgress>.unmodifiable(_validateSteps(steps));

  final RoutineProgressId id;
  final RoutineId routineId;
  final FamilySpaceId familySpaceId;

  /// Calendar day in household-local civil time (time-of-day ignored).
  final DateTime localDate;
  final List<RoutineStepProgress> steps;
  final AggregateVersion version;
  final SyncState syncState;
  final Tombstone? tombstone;

  bool get isDeleted => tombstone != null;

  RoutineStepProgress stepAt(int order) {
    for (final step in steps) {
      if (step.stepOrder == order) {
        return step;
      }
    }
    throw ArgumentError.value(order, 'order', 'step not present in progress');
  }

  /// Returns a copy with [stepOrder] set to [status] (complete or correct).
  RoutineDayProgress withStepStatus({
    required int stepOrder,
    required StepCompletionStatus status,
    AggregateVersion? version,
    SyncState? syncState,
  }) {
    final nextSteps = steps
        .map(
          (step) => step.stepOrder == stepOrder
              ? step.copyWith(status: status)
              : step,
        )
        .toList(growable: false);
    if (!nextSteps.any((s) => s.stepOrder == stepOrder)) {
      throw ArgumentError.value(
        stepOrder,
        'stepOrder',
        'step not present in progress',
      );
    }
    return copyWith(steps: nextSteps, version: version, syncState: syncState);
  }

  RoutineDayProgress copyWith({
    List<RoutineStepProgress>? steps,
    AggregateVersion? version,
    SyncState? syncState,
    Tombstone? tombstone,
    bool clearTombstone = false,
  }) {
    return RoutineDayProgress(
      id: id,
      routineId: routineId,
      familySpaceId: familySpaceId,
      localDate: localDate,
      steps: steps ?? this.steps,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      tombstone: clearTombstone ? null : (tombstone ?? this.tombstone),
    );
  }

  /// Builds pending progress aligned to [stepCount] contiguous orders.
  static RoutineDayProgress pendingForRoutine({
    required RoutineProgressId id,
    required RoutineId routineId,
    required FamilySpaceId familySpaceId,
    required DateTime localDate,
    required int stepCount,
    AggregateVersion version = AggregateVersion.initial,
    SyncState syncState = SyncState.local,
  }) {
    if (stepCount < 1) {
      throw ArgumentError.value(stepCount, 'stepCount', 'must be >= 1');
    }
    return RoutineDayProgress(
      id: id,
      routineId: routineId,
      familySpaceId: familySpaceId,
      localDate: localDate,
      steps: List<RoutineStepProgress>.generate(
        stepCount,
        (i) => RoutineStepProgress(
          stepOrder: i,
          status: StepCompletionStatus.pending,
        ),
        growable: false,
      ),
      version: version,
      syncState: syncState,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static List<RoutineStepProgress> _validateSteps(
    List<RoutineStepProgress> steps,
  ) {
    if (steps.isEmpty) {
      throw ArgumentError.value(
        steps,
        'steps',
        'must contain at least one step',
      );
    }
    final sorted = [...steps]
      ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
    for (var i = 0; i < sorted.length; i++) {
      if (sorted[i].stepOrder != i) {
        throw ArgumentError.value(
          steps.map((s) => s.stepOrder).toList(),
          'steps.stepOrder',
          'must be contiguous from 0',
        );
      }
    }
    return sorted;
  }
}
