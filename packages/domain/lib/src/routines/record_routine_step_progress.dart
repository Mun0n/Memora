import '../identity/family_membership.dart';
import '../offline/offline_identifiers.dart';
import '../repositories/routine_progress_repository.dart';
import '../repositories/routine_repository.dart';
import '../sync/aggregate_version.dart';
import '../sync/idempotency_key.dart';
import '../sync/sync_state.dart';
import 'routine_care_policy.dart';
import 'routine_day_progress.dart';
import 'step_completion_status.dart';
import 'unauthorized_care_action_exception.dart';

/// Supported-person local step complete/correct use case.
final class RecordRoutineStepProgress {
  RecordRoutineStepProgress({
    required RoutineRepository routines,
    required RoutineProgressRepository progress,
  }) : _routines = routines,
       _progress = progress;

  final RoutineRepository _routines;
  final RoutineProgressRepository _progress;

  /// Sets [stepOrder] to completed (or corrected back to pending).
  ///
  /// Creates a pending day-progress aggregate when none exists for [localDate].
  Future<RoutineDayProgress> setStepStatus({
    required FamilyMembership actor,
    required RoutineId routineId,
    required DateTime localDate,
    required int stepOrder,
    required StepCompletionStatus status,
    required IdempotencyKey idempotencyKey,
    RoutineProgressId? newProgressId,
  }) async {
    final routine = await _routines.findById(routineId);
    if (routine == null) {
      throw StateError('routine not found: ${routineId.value}');
    }
    if (actor.familySpaceId != routine.familySpaceId) {
      throw UnauthorizedCareActionException(
        'membership is outside family space ${routine.familySpaceId.value}',
      );
    }
    if (!RoutineCarePolicy.canRecordStepProgress(actor)) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot record step progress',
      );
    }
    if (!routine.isPresentableToday) {
      throw StateError(
        'routine is not active for progress: ${routineId.value}',
      );
    }
    if (stepOrder < 0 || stepOrder >= routine.steps.length) {
      throw ArgumentError.value(
        stepOrder,
        'stepOrder',
        'must be within routine steps',
      );
    }

    final existing = await _progress.findByRoutineAndDate(
      routineId: routineId,
      localDate: localDate,
    );

    final RoutineDayProgress next;
    if (existing == null) {
      if (newProgressId == null) {
        throw ArgumentError.notNull('newProgressId');
      }
      final created = RoutineDayProgress.pendingForRoutine(
        id: newProgressId,
        routineId: routineId,
        familySpaceId: routine.familySpaceId,
        localDate: localDate,
        stepCount: routine.steps.length,
      );
      next = created.withStepStatus(
        stepOrder: stepOrder,
        status: status,
        version: AggregateVersion.initial,
        syncState: SyncState.pending,
      );
    } else {
      if (existing.isDeleted) {
        throw StateError(
          'cannot update deleted progress: ${existing.id.value}',
        );
      }
      next = existing.withStepStatus(
        stepOrder: stepOrder,
        status: status,
        version: existing.version.next(),
        syncState: SyncState.pending,
      );
    }

    return _progress.save(progress: next, idempotencyKey: idempotencyKey);
  }
}
