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
    memories = InMemoryMemoryRepository(this.store);
    controller = UserRoutineController(
      actor: IdentityFixtures.amparoSupportedMembership,
      routines: routines,
      progress: progress,
      localDate: OfflineFixtures.demoLocalDate,
      clock: clock ?? DateTime(2026, 10, 10, 9, 30),
      networkAvailable: networkAvailable,
    );
    memoryController = UserMemoryController(
      actor: IdentityFixtures.amparoSupportedMembership,
      memories: memories,
      networkAvailable: networkAvailable,
    );
  }

  final InMemoryOfflineStore store;
  late final InMemoryRoutineRepository routines;
  late final InMemoryRoutineProgressRepository progress;
  late final InMemoryMemoryRepository memories;
  late final UserRoutineController controller;
  late final UserMemoryController memoryController;

  /// Seeds Demo/Ejemplo morning routine + approved garden memory.
  Future<void> seedDemoFixtures() async {
    await routines.save(
      routine: OfflineFixtures.morningRoutine,
      idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
    );
    await progress.save(
      progress: OfflineFixtures.morningProgressPending,
      idempotencyKey: OfflineFixtures.morningProgressSaveKey,
    );
    await memories.save(
      memory: OfflineFixtures.gardenMemory,
      idempotencyKey: OfflineFixtures.gardenMemorySaveKey,
    );
    // Proposed memory must not appear in approved viewing.
    await memories.save(
      memory: OfflineFixtures.proposedPatioMemory,
      idempotencyKey: IdempotencyKey(
        'demo-memory-save-01932f00-0005-7000-8000-000000000501',
      ),
    );
  }

  MemoraUserApp buildApp({
    bool autoload = false,
    FeatureSection initialSection = FeatureSection.routines,
  }) {
    return MemoraUserApp(
      controller: controller,
      memoryController: memoryController,
      persona: SyntheticFixtures.amparoDemo,
      autoload: autoload,
      initialSection: initialSection,
    );
  }

  Future<void> load() async {
    await controller.load();
    await memoryController.load();
  }
}
