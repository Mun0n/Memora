import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// Minimal in-memory stubs so domain use-case tests stay package-local.
final class _StubRoutines implements RoutineRepository {
  final Map<String, Routine> _items = <String, Routine>{};

  @override
  Future<Routine> save({
    required Routine routine,
    required IdempotencyKey idempotencyKey,
  }) async {
    final pending = routine.copyWith(syncState: SyncState.pending);
    _items[pending.id.value] = pending;
    return pending;
  }

  @override
  Future<Routine?> findById(RoutineId id) async => _items[id.value];

  @override
  Future<List<Routine>> listForFamily(FamilySpaceId familySpaceId) async {
    return _items.values
        .where((r) => r.familySpaceId == familySpaceId)
        .toList(growable: false);
  }

  @override
  Future<List<Routine>> listActiveForFamily(FamilySpaceId familySpaceId) async {
    return _items.values
        .where((r) => r.familySpaceId == familySpaceId && r.isPresentableToday)
        .toList(growable: false);
  }

  @override
  Future<Routine> softDelete({
    required RoutineId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) {
    throw UnimplementedError();
  }
}

final class _StubProgress implements RoutineProgressRepository {
  final Map<String, RoutineDayProgress> _items = <String, RoutineDayProgress>{};

  @override
  Future<RoutineDayProgress> save({
    required RoutineDayProgress progress,
    required IdempotencyKey idempotencyKey,
  }) async {
    final pending = progress.copyWith(syncState: SyncState.pending);
    _items[pending.id.value] = pending;
    return pending;
  }

  @override
  Future<RoutineDayProgress?> findById(RoutineProgressId id) async =>
      _items[id.value];

  @override
  Future<RoutineDayProgress?> findByRoutineAndDate({
    required RoutineId routineId,
    required DateTime localDate,
  }) async {
    final day = DateTime(localDate.year, localDate.month, localDate.day);
    for (final progress in _items.values) {
      if (progress.routineId == routineId &&
          progress.localDate == day &&
          !progress.isDeleted) {
        return progress;
      }
    }
    return null;
  }

  @override
  Future<List<RoutineDayProgress>> listForFamily(
    FamilySpaceId familySpaceId,
  ) async {
    return _items.values
        .where((p) => p.familySpaceId == familySpaceId)
        .toList(growable: false);
  }

  @override
  Future<RoutineDayProgress> softDelete({
    required RoutineProgressId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('ConfigureRoutine', () {
    late _StubRoutines store;
    late ConfigureRoutine configure;

    setUp(() {
      store = _StubRoutines();
      configure = ConfigureRoutine(store);
    });

    test(
      'primary caregiver creates, edits, orders, archives and activates',
      () async {
        final elena = IdentityFixtures.elenaPrimaryMembership;
        final created = await configure.create(
          actor: elena,
          id: OfflineFixtures.morningRoutineId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Rutina de mañana Demo',
          steps: OfflineFixtures.morningRoutine.steps,
          idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
        );
        expect(created.lifecycleStatus, RoutineLifecycleStatus.active);
        expect(created.isPresentableToday, isTrue);

        final reordered = await configure.reorderSteps(
          actor: elena,
          id: OfflineFixtures.morningRoutineId,
          steps: <RoutineStep>[
            RoutineStep(order: 0, instruction: 'Preparar el desayuno Ejemplo'),
            RoutineStep(order: 1, instruction: 'Beber un vaso de agua'),
          ],
          idempotencyKey: IdempotencyKey('demo-routine-reorder'),
        );
        expect(reordered.steps.first.instruction, contains('desayuno'));
        expect(reordered.version.value, 1);

        final archived = await configure.archive(
          actor: elena,
          id: OfflineFixtures.morningRoutineId,
          idempotencyKey: IdempotencyKey('demo-routine-archive'),
        );
        expect(archived.lifecycleStatus, RoutineLifecycleStatus.archived);
        expect(archived.isPresentableToday, isFalse);
        expect(
          await store.listActiveForFamily(
            IdentityFixtures.familiaEjemploSpaceId,
          ),
          isEmpty,
        );

        final activated = await configure.activate(
          actor: elena,
          id: OfflineFixtures.morningRoutineId,
          idempotencyKey: IdempotencyKey('demo-routine-activate'),
        );
        expect(activated.lifecycleStatus, RoutineLifecycleStatus.active);
        expect(activated.isPresentableToday, isTrue);
      },
    );

    test(
      'active caregiver may configure; contributor and supported denied',
      () async {
        final carlos = IdentityFixtures.carlosCaregiverMembership;
        await configure.create(
          actor: carlos,
          id: OfflineFixtures.morningRoutineId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Rutina Carlos Demo',
          steps: OfflineFixtures.morningRoutine.steps,
          idempotencyKey: IdempotencyKey('demo-caregiver-create'),
        );

        await expectLater(
          configure.edit(
            actor: IdentityFixtures.luciaContributorMembership,
            id: OfflineFixtures.morningRoutineId,
            title: 'Hack Demo',
            idempotencyKey: IdempotencyKey('demo-contributor-denied'),
          ),
          throwsA(isA<UnauthorizedCareActionException>()),
        );
        await expectLater(
          configure.archive(
            actor: IdentityFixtures.amparoSupportedMembership,
            id: OfflineFixtures.morningRoutineId,
            idempotencyKey: IdempotencyKey('demo-supported-denied'),
          ),
          throwsA(isA<UnauthorizedCareActionException>()),
        );
      },
    );
  });

  group('RecordRoutineStepProgress', () {
    late _StubRoutines routines;
    late _StubProgress progress;
    late RecordRoutineStepProgress record;

    setUp(() async {
      routines = _StubRoutines();
      progress = _StubProgress();
      record = RecordRoutineStepProgress(
        routines: routines,
        progress: progress,
      );
      await routines.save(
        routine: OfflineFixtures.morningRoutine,
        idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
      );
    });

    test('supported person completes and corrects a step', () async {
      final amparo = IdentityFixtures.amparoSupportedMembership;
      final completed = await record.setStepStatus(
        actor: amparo,
        routineId: OfflineFixtures.morningRoutineId,
        localDate: OfflineFixtures.demoLocalDate,
        stepOrder: 0,
        status: StepCompletionStatus.completed,
        idempotencyKey: OfflineFixtures.morningProgressSaveKey,
        newProgressId: OfflineFixtures.morningProgressId,
      );
      expect(completed.stepAt(0).status, StepCompletionStatus.completed);
      expect(completed.stepAt(1).status, StepCompletionStatus.pending);

      final corrected = await record.setStepStatus(
        actor: amparo,
        routineId: OfflineFixtures.morningRoutineId,
        localDate: OfflineFixtures.demoLocalDate,
        stepOrder: 0,
        status: StepCompletionStatus.pending,
        idempotencyKey: IdempotencyKey('demo-progress-correct'),
      );
      expect(corrected.stepAt(0).status, StepCompletionStatus.pending);
      expect(corrected.version.value, greaterThan(completed.version.value));
    });

    test('caregiver cannot record step progress', () async {
      await expectLater(
        record.setStepStatus(
          actor: IdentityFixtures.elenaPrimaryMembership,
          routineId: OfflineFixtures.morningRoutineId,
          localDate: OfflineFixtures.demoLocalDate,
          stepOrder: 0,
          status: StepCompletionStatus.completed,
          idempotencyKey: IdempotencyKey('demo-caregiver-progress-denied'),
          newProgressId: OfflineFixtures.morningProgressId,
        ),
        throwsA(isA<UnauthorizedCareActionException>()),
      );
    });
  });
}
