import 'package:domain/domain.dart';
import 'package:test/test.dart';

final class _StubPastimes implements PastimeRepository {
  final Map<String, Pastime> _items = <String, Pastime>{};

  @override
  Future<Pastime> save({
    required Pastime pastime,
    required IdempotencyKey idempotencyKey,
  }) async {
    final pending = pastime.copyWith(syncState: SyncState.pending);
    _items[pending.id.value] = pending;
    return pending;
  }

  @override
  Future<Pastime?> findById(PastimeId id) async => _items[id.value];

  @override
  Future<List<Pastime>> listForFamily(FamilySpaceId familySpaceId) async {
    final listed = _items.values
        .where((p) => p.familySpaceId == familySpaceId)
        .toList();
    listed.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return listed;
  }

  @override
  Future<List<Pastime>> listActiveForFamily(FamilySpaceId familySpaceId) async {
    final listed = _items.values
        .where((p) => p.familySpaceId == familySpaceId && p.isActiveForViewing)
        .toList();
    listed.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return listed;
  }

  @override
  Future<Pastime> softDelete({
    required PastimeId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) {
    throw UnimplementedError();
  }
}

PastimeId _id(int n) => PastimeId(
  '01932f00-0008-7000-8000-0000000008${n.toString().padLeft(2, '0')}',
);

void main() {
  group('Pastime entity validation', () {
    test('rejects empty or overlong title and instruction', () {
      expect(
        () => Pastime(
          id: OfflineFixtures.radioPastimeId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: '   ',
          instruction: 'Ok Demo',
          displayOrder: 0,
          lifecycleStatus: PastimeLifecycleStatus.draft,
          version: AggregateVersion.initial,
          syncState: SyncState.local,
        ),
        throwsArgumentError,
      );
      expect(
        () => Pastime(
          id: OfflineFixtures.radioPastimeId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'x' * 61,
          instruction: 'Ok Demo',
          displayOrder: 0,
          lifecycleStatus: PastimeLifecycleStatus.draft,
          version: AggregateVersion.initial,
          syncState: SyncState.local,
        ),
        throwsArgumentError,
      );
      expect(
        () => Pastime(
          id: OfflineFixtures.radioPastimeId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Ok Demo',
          instruction: 'y' * 241,
          displayOrder: 0,
          lifecycleStatus: PastimeLifecycleStatus.draft,
          version: AggregateVersion.initial,
          syncState: SyncState.local,
        ),
        throwsArgumentError,
      );
    });

    test('draft and archived are not presentable', () {
      expect(OfflineFixtures.radioPastime.isActiveForViewing, isTrue);
      expect(OfflineFixtures.draftPuzzlePastime.isActiveForViewing, isFalse);
      expect(OfflineFixtures.archivedPhotosPastime.isActiveForViewing, isFalse);
    });
  });

  group('PastimeCarePolicy', () {
    test('caregivers edit; supported views; contributor neither', () {
      expect(
        PastimeCarePolicy.canEditPastimes(
          IdentityFixtures.elenaPrimaryMembership,
        ),
        isTrue,
      );
      expect(
        PastimeCarePolicy.canEditPastimes(
          IdentityFixtures.carlosCaregiverMembership,
        ),
        isTrue,
      );
      expect(
        PastimeCarePolicy.canEditPastimes(
          IdentityFixtures.luciaContributorMembership,
        ),
        isFalse,
      );
      expect(
        PastimeCarePolicy.canEditPastimes(
          IdentityFixtures.amparoSupportedMembership,
        ),
        isFalse,
      );
      expect(
        PastimeCarePolicy.canViewPastimes(
          IdentityFixtures.amparoSupportedMembership,
        ),
        isTrue,
      );
      expect(
        PastimeCarePolicy.canViewPastimes(
          IdentityFixtures.luciaContributorMembership,
        ),
        isFalse,
      );
      expect(
        PastimeCarePolicy.canEditPastimes(
          IdentityFixtures.invitedCaregiverMembership,
        ),
        isFalse,
      );
    });
  });

  group('ConfigurePastime', () {
    late _StubPastimes store;
    late ConfigurePastime configure;

    setUp(() {
      store = _StubPastimes();
      configure = ConfigurePastime(store);
    });

    test(
      'create edit reorder activate archive; active list hides draft/archived',
      () async {
        final elena = IdentityFixtures.elenaPrimaryMembership;
        final created = await configure.create(
          actor: elena,
          id: OfflineFixtures.radioPastimeId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Radio Demo',
          instruction: 'Escuchar la radio Ejemplo un rato en el sillón.',
          idempotencyKey: OfflineFixtures.radioPastimeSaveKey,
        );
        expect(created.lifecycleStatus, PastimeLifecycleStatus.draft);
        expect(created.displayOrder, 0);

        final edited = await configure.edit(
          actor: elena,
          id: OfflineFixtures.radioPastimeId,
          title: 'Radio Familiar Demo',
          idempotencyKey: IdempotencyKey('demo-pastime-edit'),
        );
        expect(edited.title, 'Radio Familiar Demo');

        await configure.create(
          actor: elena,
          id: OfflineFixtures.draftPuzzlePastimeId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Puzzle Ejemplo',
          instruction: 'Hacer un puzzle sencillo en la mesa Demo.',
          idempotencyKey: IdempotencyKey('demo-pastime-create-2'),
        );

        final reordered = await configure.reorder(
          actor: elena,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          orderedIds: [
            OfflineFixtures.draftPuzzlePastimeId,
            OfflineFixtures.radioPastimeId,
          ],
          idempotencyKey: IdempotencyKey('demo-pastime-reorder'),
        );
        expect(reordered.map((p) => p.id), [
          OfflineFixtures.draftPuzzlePastimeId,
          OfflineFixtures.radioPastimeId,
        ]);
        expect(reordered.map((p) => p.displayOrder), [0, 1]);

        final activated = await configure.activate(
          actor: elena,
          id: OfflineFixtures.radioPastimeId,
          idempotencyKey: IdempotencyKey('demo-pastime-activate'),
        );
        expect(activated.lifecycleStatus, PastimeLifecycleStatus.active);

        await configure.activate(
          actor: elena,
          id: OfflineFixtures.draftPuzzlePastimeId,
          idempotencyKey: IdempotencyKey('demo-pastime-activate-2'),
        );
        await configure.archive(
          actor: elena,
          id: OfflineFixtures.draftPuzzlePastimeId,
          idempotencyKey: IdempotencyKey('demo-pastime-archive'),
        );

        final viewing = await configure.listActiveForViewing(
          actor: IdentityFixtures.amparoSupportedMembership,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        );
        expect(viewing.map((p) => p.id), [OfflineFixtures.radioPastimeId]);
        expect(viewing.single.title, 'Radio Familiar Demo');
      },
    );

    test('rejects seventh active pastime', () async {
      final elena = IdentityFixtures.elenaPrimaryMembership;
      for (var i = 1; i <= 6; i++) {
        await configure.create(
          actor: elena,
          id: _id(i),
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Activo Demo $i',
          instruction: 'Instrucción Demo $i para prueba de límite.',
          lifecycleStatus: PastimeLifecycleStatus.active,
          idempotencyKey: IdempotencyKey('demo-pastime-active-$i'),
        );
      }
      await expectLater(
        configure.create(
          actor: elena,
          id: _id(7),
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Activo Demo 7',
          instruction: 'Instrucción Demo 7 para prueba de límite.',
          lifecycleStatus: PastimeLifecycleStatus.active,
          idempotencyKey: IdempotencyKey('demo-pastime-active-7'),
        ),
        throwsStateError,
      );

      final draft = await configure.create(
        actor: elena,
        id: _id(8),
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        title: 'Borrador Demo',
        instruction: 'Borrador Demo cuando ya hay seis activos.',
        idempotencyKey: IdempotencyKey('demo-pastime-draft-extra'),
      );
      expect(draft.lifecycleStatus, PastimeLifecycleStatus.draft);

      await expectLater(
        configure.activate(
          actor: elena,
          id: _id(8),
          idempotencyKey: IdempotencyKey('demo-pastime-activate-extra'),
        ),
        throwsStateError,
      );
    });

    test(
      'contributor and supported cannot configure; invalid edit throws',
      () async {
        await configure.create(
          actor: IdentityFixtures.elenaPrimaryMembership,
          id: OfflineFixtures.radioPastimeId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Radio Demo',
          instruction: 'Escuchar la radio Ejemplo un rato en el sillón.',
          idempotencyKey: OfflineFixtures.radioPastimeSaveKey,
        );

        await expectLater(
          configure.edit(
            actor: IdentityFixtures.luciaContributorMembership,
            id: OfflineFixtures.radioPastimeId,
            title: 'Hack Demo',
            idempotencyKey: IdempotencyKey('demo-contributor-edit-denied'),
          ),
          throwsA(isA<UnauthorizedCareActionException>()),
        );
        await expectLater(
          configure.activate(
            actor: IdentityFixtures.amparoSupportedMembership,
            id: OfflineFixtures.radioPastimeId,
            idempotencyKey: IdempotencyKey('demo-supported-activate-denied'),
          ),
          throwsA(isA<UnauthorizedCareActionException>()),
        );
        await expectLater(
          configure.edit(
            actor: IdentityFixtures.elenaPrimaryMembership,
            id: OfflineFixtures.radioPastimeId,
            title: '',
            idempotencyKey: IdempotencyKey('demo-pastime-invalid-title'),
          ),
          throwsArgumentError,
        );
        final still = await store.findById(OfflineFixtures.radioPastimeId);
        expect(still!.title, 'Radio Demo');
      },
    );

    test('cross-family actor is denied', () async {
      await expectLater(
        configure.create(
          actor: IdentityFixtures.casaDemoBPrimaryMembership,
          id: OfflineFixtures.radioPastimeId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Radio Demo',
          instruction: 'Escuchar la radio Ejemplo un rato en el sillón.',
          idempotencyKey: IdempotencyKey('demo-cross-family-denied'),
        ),
        throwsA(isA<UnauthorizedCareActionException>()),
      );
    });
  });
}
