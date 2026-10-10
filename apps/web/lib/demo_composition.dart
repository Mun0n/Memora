import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:ui/ui.dart';

/// Wires fictional in-memory adapters for the caregiver/family web shell.
final class FamilyWebDemoComposition {
  FamilyWebDemoComposition({
    InMemoryOfflineStore? store,
    bool networkAvailable = false,
  }) : store = store ?? InMemoryOfflineStore() {
    routines = InMemoryRoutineRepository(this.store);
    reminders = InMemoryReminderRepository(this.store);
    controller = FamilyRoutineController(
      actor: IdentityFixtures.elenaPrimaryMembership,
      routines: routines,
      reminders: reminders,
      networkAvailable: networkAvailable,
    );
  }

  final InMemoryOfflineStore store;
  late final InMemoryRoutineRepository routines;
  late final InMemoryReminderRepository reminders;
  late final FamilyRoutineController controller;

  /// Seeds Demo/Ejemplo routines + quiet-hours reminder.
  Future<void> seedDemoFixtures() async {
    await routines.save(
      routine: OfflineFixtures.morningRoutine,
      idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
    );
    await routines.save(
      routine: OfflineFixtures.archivedEveningRoutine,
      idempotencyKey: IdempotencyKey(
        'demo-routine-save-01932f00-0004-7000-8000-000000000401',
      ),
    );
    await reminders.save(
      reminder: OfflineFixtures.walkReminder,
      idempotencyKey: OfflineFixtures.walkReminderSaveKey,
    );
  }

  MemoraFamilyWebApp buildApp({bool autoload = false}) {
    return MemoraFamilyWebApp(
      controller: controller,
      persona: SyntheticFixtures.familiaEjemplo,
      autoload: autoload,
    );
  }

  Future<void> load() => controller.load();
}
