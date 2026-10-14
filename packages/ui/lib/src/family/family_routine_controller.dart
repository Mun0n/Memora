import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../demo/demo_ids.dart';
import '../l10n/memora_copy.dart';
import '../sync/presentation_sync.dart';

/// Caregiver/family configure controller over the shared repository contract.
final class FamilyRoutineController extends ChangeNotifier {
  FamilyRoutineController({
    required this.actor,
    required RoutineRepository routines,
    required ReminderRepository reminders,
    this.networkAvailable = false,
    DemoIds? ids,
    ConfigureRoutine? configureRoutine,
    ConfigureReminder? configureReminder,
  }) : _routines = routines,
       _reminders = reminders,
       _ids = ids ?? DemoIds(),
       _configureRoutine = configureRoutine ?? ConfigureRoutine(routines),
       _configureReminder = configureReminder ?? ConfigureReminder(reminders);

  final FamilyMembership actor;
  final RoutineRepository _routines;
  final ReminderRepository _reminders;
  final ConfigureRoutine _configureRoutine;
  final ConfigureReminder _configureReminder;
  final DemoIds _ids;

  bool networkAvailable;

  PresentationSurfaceState surfaceState = PresentationSurfaceState.loading;
  List<Routine> routines = const <Routine>[];
  List<Reminder> reminders = const <Reminder>[];
  String? errorMessage;

  /// Draft fields for create/edit form.
  RoutineId? editingRoutineId;
  String draftTitle = '';
  List<String> draftSteps = <String>[''];

  ReminderId? editingReminderId;
  String draftReminderTitle = '';
  int quietStartHour = 22;
  int quietEndHour = 7;

  /// Bottom chrome only when delivery/conflict requires caregiver action.
  bool get needsActionableSyncNotice =>
      surfaceState == PresentationSurfaceState.failed ||
      surfaceState == PresentationSurfaceState.conflicted;

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
      PresentationSurfaceState.empty => MemoraCopy.recoveryCreateRoutine,
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
      final listed = await _routines.listForFamily(actor.familySpaceId);
      final reminderList = await _reminders.listForFamily(actor.familySpaceId);
      routines = listed.where((r) => !r.isDeleted).toList(growable: false);
      reminders = reminderList
          .where((r) => !r.isDeleted)
          .toList(growable: false);
      surfaceState = _deriveSurface(routines);
    } catch (error) {
      errorMessage = error.toString();
      surfaceState = PresentationSurfaceState.failed;
    }
    notifyListeners();
  }

  Future<void> recover() async {
    if (surfaceState == PresentationSurfaceState.empty) {
      beginCreateRoutine();
      return;
    }
    if (surfaceState == PresentationSurfaceState.offline ||
        (!networkAvailable && surfaceState == PresentationSurfaceState.ready)) {
      surfaceState = routines.isEmpty
          ? PresentationSurfaceState.empty
          : PresentationSurfaceState.ready;
      notifyListeners();
      return;
    }
    await load();
  }

  void beginCreateRoutine() {
    editingRoutineId = null;
    draftTitle = '';
    draftSteps = <String>[''];
    notifyListeners();
  }

  void beginEditRoutine(Routine routine) {
    editingRoutineId = routine.id;
    draftTitle = routine.title;
    draftSteps = routine.steps.map((s) => s.instruction).toList();
    notifyListeners();
  }

  void setDraftTitle(String value) {
    draftTitle = value;
  }

  void setDraftStep(int index, String value) {
    draftSteps[index] = value;
  }

  void addDraftStep() {
    draftSteps = [...draftSteps, ''];
    notifyListeners();
  }

  void removeDraftStep(int index) {
    if (draftSteps.length <= 1) {
      return;
    }
    final next = [...draftSteps]..removeAt(index);
    draftSteps = next;
    notifyListeners();
  }

  void moveDraftStep(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= draftSteps.length) {
      return;
    }
    final next = [...draftSteps];
    final value = next.removeAt(index);
    next.insert(target, value);
    draftSteps = next;
    notifyListeners();
  }

  Future<void> saveDraftRoutine() async {
    final steps = <RoutineStep>[];
    for (var i = 0; i < draftSteps.length; i++) {
      final instruction = draftSteps[i].trim();
      if (instruction.isEmpty) {
        continue;
      }
      steps.add(RoutineStep(order: steps.length, instruction: instruction));
    }
    if (draftTitle.trim().isEmpty || steps.isEmpty) {
      errorMessage = 'Título y al menos un paso son obligatorios.';
      notifyListeners();
      return;
    }

    if (editingRoutineId == null) {
      await _configureRoutine.create(
        actor: actor,
        id: _ids.nextRoutineId(),
        familySpaceId: actor.familySpaceId,
        title: draftTitle.trim(),
        steps: steps,
        idempotencyKey: _ids.nextIdempotencyKey('routine-create'),
      );
    } else {
      await _configureRoutine.edit(
        actor: actor,
        id: editingRoutineId!,
        title: draftTitle.trim(),
        steps: steps,
        idempotencyKey: _ids.nextIdempotencyKey('routine-edit'),
      );
    }
    editingRoutineId = null;
    draftTitle = '';
    draftSteps = <String>[''];
    await load();
  }

  Future<void> activate(RoutineId id) async {
    await _configureRoutine.activate(
      actor: actor,
      id: id,
      idempotencyKey: _ids.nextIdempotencyKey('routine-activate'),
    );
    await load();
  }

  Future<void> archive(RoutineId id) async {
    await _configureRoutine.archive(
      actor: actor,
      id: id,
      idempotencyKey: _ids.nextIdempotencyKey('routine-archive'),
    );
    await load();
  }

  void beginCreateReminder() {
    editingReminderId = null;
    draftReminderTitle = '';
    quietStartHour = 22;
    quietEndHour = 7;
    notifyListeners();
  }

  void beginEditReminder(Reminder reminder) {
    editingReminderId = reminder.id;
    draftReminderTitle = reminder.title;
    quietStartHour = (reminder.quietHours?.startMinuteOfDay ?? 22 * 60) ~/ 60;
    quietEndHour = (reminder.quietHours?.endMinuteOfDay ?? 7 * 60) ~/ 60;
    notifyListeners();
  }

  void setDraftReminderTitle(String value) {
    draftReminderTitle = value;
  }

  void setQuietStartHour(int hour) {
    quietStartHour = hour.clamp(0, 23);
    notifyListeners();
  }

  void setQuietEndHour(int hour) {
    quietEndHour = hour.clamp(0, 23);
    notifyListeners();
  }

  Future<void> saveDraftReminder() async {
    if (draftReminderTitle.trim().isEmpty) {
      errorMessage = 'El título del recordatorio es obligatorio.';
      notifyListeners();
      return;
    }
    final quiet = QuietHours(
      startMinuteOfDay: quietStartHour * 60,
      endMinuteOfDay: quietEndHour * 60,
    );
    if (editingReminderId == null) {
      await _configureReminder.create(
        actor: actor,
        id: _ids.nextReminderId(),
        familySpaceId: actor.familySpaceId,
        title: draftReminderTitle.trim(),
        scheduledAt: DateTime.utc(2026, 10, 10, 17, 30),
        quietHours: quiet,
        idempotencyKey: _ids.nextIdempotencyKey('reminder-create'),
      );
    } else {
      await _configureReminder.edit(
        actor: actor,
        id: editingReminderId!,
        title: draftReminderTitle.trim(),
        quietHours: quiet,
        idempotencyKey: _ids.nextIdempotencyKey('reminder-edit'),
      );
    }
    editingReminderId = null;
    draftReminderTitle = '';
    await load();
  }

  PresentationSurfaceState _deriveSurface(List<Routine> listed) {
    if (listed.isEmpty) {
      return PresentationSurfaceState.empty;
    }
    final worst = SyncStatusLabels.worstOf(listed.map((r) => r.syncState));
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
      ...reminders.map((r) => r.syncState),
    ];
    if (states.isEmpty) {
      return SyncState.local;
    }
    return SyncStatusLabels.worstOf(states);
  }
}
