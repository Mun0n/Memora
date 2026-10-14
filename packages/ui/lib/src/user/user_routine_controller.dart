import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../demo/demo_ids.dart';
import '../demo/spanish_date_format.dart';
import '../l10n/memora_copy.dart';
import '../sync/presentation_sync.dart';

/// One focused step action for the supported-person home.
final class PrimaryStepAction {
  const PrimaryStepAction({
    required this.routine,
    required this.step,
    required this.status,
  });

  final Routine routine;
  final RoutineStep step;
  final StepCompletionStatus status;

  bool get isCompleted => status == StepCompletionStatus.completed;
}

/// Local-first controller for the supported-person routine home.
final class UserRoutineController extends ChangeNotifier {
  UserRoutineController({
    required this.actor,
    required RoutineRepository routines,
    required RoutineProgressRepository progress,
    required this.localDate,
    DateTime? clock,
    this.networkAvailable = false,
    DemoIds? ids,
    RecordRoutineStepProgress? recordProgress,
  }) : _routines = routines,
       _progress = progress,
       _clock = clock,
       _ids = ids ?? DemoIds(),
       _record =
           recordProgress ??
           RecordRoutineStepProgress(routines: routines, progress: progress);

  final FamilyMembership actor;
  final RoutineRepository _routines;
  final RoutineProgressRepository _progress;
  final RecordRoutineStepProgress _record;
  final DateTime localDate;
  final DateTime? _clock;
  final DemoIds _ids;

  /// When false, chrome reports offline (normal; never blocks use).
  bool networkAvailable;

  PresentationSurfaceState surfaceState = PresentationSurfaceState.loading;
  List<Routine> routines = const <Routine>[];
  Map<String, RoutineDayProgress> progressByRoutineId =
      const <String, RoutineDayProgress>{};
  String? errorMessage;

  DateTime get now => _clock ?? DateTime.now();

  /// True when orientation uses the device-local clock (no injected fake).
  bool get usesLiveClock => _clock == null;

  String get orientationLabel => SpanishDateFormat.formatDateTime(now);

  /// Re-reads [now] for the orientation line without reloading repositories.
  void refreshOrientation() => notifyListeners();

  /// True when Mi día has a current or pending step (voice generic priority).
  bool get hasCurrentOrPendingMiDiaStep {
    for (final routine in routines) {
      final day = progressByRoutineId[routine.id.value];
      for (final step in routine.steps) {
        final status =
            day?.stepAt(step.order).status ?? StepCompletionStatus.pending;
        if (status == StepCompletionStatus.pending) {
          return true;
        }
      }
    }
    return false;
  }

  PrimaryStepAction? get primaryAction {
    for (final routine in routines) {
      final day = progressByRoutineId[routine.id.value];
      for (final step in routine.steps) {
        final status =
            day?.stepAt(step.order).status ?? StepCompletionStatus.pending;
        if (status == StepCompletionStatus.pending) {
          return PrimaryStepAction(
            routine: routine,
            step: step,
            status: status,
          );
        }
      }
    }
    // If all pending are done, offer correction on the last completed step.
    for (final routine in routines.reversed) {
      final day = progressByRoutineId[routine.id.value];
      if (day == null) {
        continue;
      }
      for (final step in routine.steps.reversed) {
        if (day.stepAt(step.order).status == StepCompletionStatus.completed) {
          return PrimaryStepAction(
            routine: routine,
            step: step,
            status: StepCompletionStatus.completed,
          );
        }
      }
    }
    return null;
  }

  String get syncLabel {
    if (surfaceState == PresentationSurfaceState.loading) {
      return MemoraCopy.stateLoading;
    }
    if (surfaceState == PresentationSurfaceState.empty) {
      return networkAvailable
          ? MemoraCopy.stateEmpty
          : '${MemoraCopy.stateEmpty} ${MemoraCopy.stateOffline}';
    }
    if (surfaceState == PresentationSurfaceState.failed) {
      return MemoraCopy.syncFailed;
    }
    if (surfaceState == PresentationSurfaceState.conflicted) {
      return MemoraCopy.syncConflicted;
    }
    if (!networkAvailable || surfaceState == PresentationSurfaceState.offline) {
      return MemoraCopy.stateOffline;
    }
    return SyncStatusLabels.forSyncState(_worstAggregateSync());
  }

  String? get recoveryActionLabel {
    return switch (surfaceState) {
      PresentationSurfaceState.failed => MemoraCopy.recoveryRetry,
      PresentationSurfaceState.conflicted => MemoraCopy.recoveryReviewConflict,
      PresentationSurfaceState.offline => MemoraCopy.recoveryContinueOffline,
      PresentationSurfaceState.empty => null,
      PresentationSurfaceState.loading => null,
      PresentationSurfaceState.ready =>
        !networkAvailable ? MemoraCopy.recoveryContinueOffline : null,
    };
  }

  Future<void> load() async {
    surfaceState = PresentationSurfaceState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final active = await _routines.listActiveForFamily(actor.familySpaceId);
      final map = <String, RoutineDayProgress>{};
      for (final routine in active) {
        final day = await _progress.findByRoutineAndDate(
          routineId: routine.id,
          localDate: localDate,
        );
        if (day != null) {
          map[routine.id.value] = day;
        }
      }
      routines = active;
      progressByRoutineId = map;
      surfaceState = _deriveSurface(active, map.values);
    } catch (error) {
      errorMessage = error.toString();
      surfaceState = PresentationSurfaceState.failed;
    }
    notifyListeners();
  }

  Future<void> recover() async {
    if (surfaceState == PresentationSurfaceState.offline ||
        (!networkAvailable && surfaceState == PresentationSurfaceState.ready)) {
      // Offline is normal — acknowledge and stay on local data.
      surfaceState = routines.isEmpty
          ? PresentationSurfaceState.empty
          : PresentationSurfaceState.ready;
      notifyListeners();
      return;
    }
    await load();
  }

  Future<void> togglePrimaryAction() async {
    final action = primaryAction;
    if (action == null) {
      return;
    }
    final nextStatus = action.isCompleted
        ? StepCompletionStatus.pending
        : StepCompletionStatus.completed;
    await _record.setStepStatus(
      actor: actor,
      routineId: action.routine.id,
      localDate: localDate,
      stepOrder: action.step.order,
      status: nextStatus,
      idempotencyKey: _ids.nextIdempotencyKey('progress'),
      newProgressId: progressByRoutineId.containsKey(action.routine.id.value)
          ? null
          : _ids.nextProgressId(),
    );
    await load();
  }

  StepCompletionStatus statusFor(Routine routine, RoutineStep step) {
    final day = progressByRoutineId[routine.id.value];
    return day?.stepAt(step.order).status ?? StepCompletionStatus.pending;
  }

  PresentationSurfaceState _deriveSurface(
    List<Routine> active,
    Iterable<RoutineDayProgress> progress,
  ) {
    if (active.isEmpty) {
      return PresentationSurfaceState.empty;
    }
    final worst = SyncStatusLabels.worstOf(progress.map((p) => p.syncState));
    if (worst == SyncState.conflicted) {
      return PresentationSurfaceState.conflicted;
    }
    if (worst == SyncState.failed) {
      return PresentationSurfaceState.failed;
    }
    if (!networkAvailable) {
      return PresentationSurfaceState.offline;
    }
    return PresentationSurfaceState.ready;
  }

  SyncState _worstAggregateSync() {
    final states = <SyncState>[
      ...routines.map((r) => r.syncState),
      ...progressByRoutineId.values.map((p) => p.syncState),
    ];
    if (states.isEmpty) {
      return SyncState.local;
    }
    return SyncStatusLabels.worstOf(states);
  }
}
