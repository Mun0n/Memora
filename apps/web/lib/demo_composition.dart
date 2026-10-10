import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:ui/ui.dart';

/// Wires fictional in-memory adapters for the caregiver/family web shell.
final class FamilyWebDemoComposition {
  FamilyWebDemoComposition({
    InMemoryOfflineStore? store,
    FamilyMembership? actor,
    bool networkAvailable = false,
  }) : store = store ?? InMemoryOfflineStore() {
    final membership = actor ?? IdentityFixtures.elenaPrimaryMembership;
    routines = InMemoryRoutineRepository(this.store);
    reminders = InMemoryReminderRepository(this.store);
    memories = InMemoryMemoryRepository(this.store);
    weights = InMemoryWeightObservationRepository(this.store);
    bloodPressures = InMemoryBloodPressureObservationRepository(this.store);
    controller = FamilyRoutineController(
      actor: membership,
      routines: routines,
      reminders: reminders,
      networkAvailable: networkAvailable,
    );
    memoryController = FamilyMemoryController(
      actor: membership,
      memories: memories,
      networkAvailable: networkAvailable,
    );
    observationController = FamilyObservationController(
      actor: membership,
      weights: weights,
      bloodPressures: bloodPressures,
      networkAvailable: networkAvailable,
      clock: DateTime(2026, 10, 10, 12, 0),
    );
  }

  final InMemoryOfflineStore store;
  late final InMemoryRoutineRepository routines;
  late final InMemoryReminderRepository reminders;
  late final InMemoryMemoryRepository memories;
  late final InMemoryWeightObservationRepository weights;
  late final InMemoryBloodPressureObservationRepository bloodPressures;
  late final FamilyRoutineController controller;
  late final FamilyMemoryController memoryController;
  late final FamilyObservationController observationController;

  /// Seeds Demo/Ejemplo routines, memories and observations.
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
    await memories.save(
      memory: OfflineFixtures.gardenMemory,
      idempotencyKey: OfflineFixtures.gardenMemorySaveKey,
    );
    await memories.save(
      memory: OfflineFixtures.proposedPatioMemory,
      idempotencyKey: IdempotencyKey(
        'demo-memory-save-01932f00-0005-7000-8000-000000000501',
      ),
    );
    await weights.append(
      observation: OfflineFixtures.amparoWeight,
      idempotencyKey: OfflineFixtures.weightAppendKey,
    );
    await bloodPressures.append(
      observation: OfflineFixtures.amparoBloodPressure,
      idempotencyKey: OfflineFixtures.bloodPressureAppendKey,
    );
  }

  MemoraFamilyWebApp buildApp({
    bool autoload = false,
    FeatureSection initialSection = FeatureSection.routines,
  }) {
    return MemoraFamilyWebApp(
      controller: controller,
      memoryController: memoryController,
      observationController: observationController,
      persona: SyntheticFixtures.familiaEjemplo,
      autoload: autoload,
      initialSection: initialSection,
    );
  }

  Future<void> load() async {
    await controller.load();
    await memoryController.load();
    await observationController.load();
  }
}
