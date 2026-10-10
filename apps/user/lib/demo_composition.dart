import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:ui/ui.dart';

/// Wires fictional in-memory adapters for the supported-person shell.
final class UserDemoComposition {
  UserDemoComposition({
    InMemoryOfflineStore? store,
    DateTime? clock,
    bool networkAvailable = false,
  }) : store = store ?? InMemoryOfflineStore() {
    routines = InMemoryRoutineRepository(this.store);
    progress = InMemoryRoutineProgressRepository(this.store);
    controller = UserRoutineController(
      actor: IdentityFixtures.amparoSupportedMembership,
      routines: routines,
      progress: progress,
      localDate: OfflineFixtures.demoLocalDate,
      clock: clock ?? DateTime(2026, 10, 10, 9, 30),
      networkAvailable: networkAvailable,
    );
  }

  final InMemoryOfflineStore store;
  late final InMemoryRoutineRepository routines;
  late final InMemoryRoutineProgressRepository progress;
  late final UserRoutineController controller;

  /// Seeds Demo/Ejemplo morning routine + pending day progress.
  Future<void> seedDemoFixtures() async {
    await routines.save(
      routine: OfflineFixtures.morningRoutine,
      idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
    );
    await progress.save(
      progress: OfflineFixtures.morningProgressPending,
      idempotencyKey: OfflineFixtures.morningProgressSaveKey,
    );
  }

  MemoraUserApp buildApp({bool autoload = false}) {
    return MemoraUserApp(
      controller: controller,
      persona: SyntheticFixtures.amparoDemo,
      autoload: autoload,
    );
  }

  Future<void> load() => controller.load();
}
