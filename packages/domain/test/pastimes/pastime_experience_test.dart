import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PastimeExperience', () {
    test('missing wire map decodes as guided', () {
      expect(
        PastimeExperience.fromWireMap(null),
        isA<GuidedPastimeExperience>(),
      );
      expect(
        PastimeExperience.fromWireMap(null).isCompleteAndSupported,
        isTrue,
      );
    });

    test('exhaustive guided/sudoku/wordSearch/spider round-trip', () {
      final cases = <PastimeExperience>[
        const GuidedPastimeExperience(),
        SudokuPastimeExperience(
          boardSize: SudokuBoardSize.fourByFour,
          puzzlePackId: SudokuPuzzlePackCatalog.starter4,
        ),
        SudokuPastimeExperience(
          boardSize: SudokuBoardSize.sixBySix,
          puzzlePackId: SudokuPuzzlePackCatalog.starter6,
        ),
        SudokuPastimeExperience(
          boardSize: SudokuBoardSize.nineByNine,
          puzzlePackId: SudokuPuzzlePackCatalog.starter9,
        ),
        WordSearchPastimeExperience(
          boardSize: WordSearchBoardSize.eightByEight,
          wordSetId: WordSearchWordSetCatalog.jardinDemo,
        ),
        WordSearchPastimeExperience(
          boardSize: WordSearchBoardSize.tenByTen,
          wordSetId: WordSearchWordSetCatalog.cocinaDemo,
        ),
        SpiderSolitairePastimeExperience(suitCount: SpiderSuitCount.one),
        SpiderSolitairePastimeExperience(suitCount: SpiderSuitCount.two),
        SpiderSolitairePastimeExperience(suitCount: SpiderSuitCount.four),
      ];
      for (final experience in cases) {
        final decoded = PastimeExperience.fromWireMap(experience.toWireMap());
        expect(decoded.runtimeType, experience.runtimeType);
        expect(decoded.toWireMap(), experience.toWireMap());
        expect(decoded.isCompleteAndSupported, isTrue);
      }
    });

    test('unknown type/version/fields fail closed to quarantine', () {
      expect(
        PastimeExperience.fromWireMap(<String, Object?>{
          'type': 'arcadeShooter',
          'schemaVersion': 1,
        }),
        isA<QuarantinedPastimeExperience>(),
      );
      expect(
        PastimeExperience.fromWireMap(<String, Object?>{
          'type': 'sudoku',
          'schemaVersion': 99,
          'boardSize': '4x4',
          'puzzlePackId': SudokuPuzzlePackCatalog.starter4,
        }),
        isA<QuarantinedPastimeExperience>(),
      );
      expect(
        PastimeExperience.fromWireMap(<String, Object?>{
          'type': 'guided',
          'schemaVersion': 1,
          'extra': true,
        }),
        isA<QuarantinedPastimeExperience>(),
      );
      expect(
        PastimeExperience.fromWireMap(<String, Object?>{
          'type': 'sudoku',
          'schemaVersion': 1,
          'boardSize': '4x4',
          'puzzlePackId': 'evil_remote_pack',
        }),
        isA<QuarantinedPastimeExperience>(),
      );
      final quarantined = PastimeExperience.fromWireMap(<String, Object?>{
        'type': 'wordSearch',
        'schemaVersion': 1,
        'boardSize': '8x8',
        'wordSetId': 'not_allowlisted',
      });
      expect(quarantined.isCompleteAndSupported, isFalse);
      expect(
        (quarantined as QuarantinedPastimeExperience).plainLanguageReason,
        isNot(contains('{')),
      );
    });

    test('legacy pastime without experience stays guided and presentable', () {
      final pastime = Pastime(
        id: OfflineFixtures.radioPastimeId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        title: 'Radio Demo',
        instruction: 'Escuchar la radio Ejemplo un rato en el sillón.',
        displayOrder: 0,
        lifecycleStatus: PastimeLifecycleStatus.active,
        version: AggregateVersion.initial,
        syncState: SyncState.local,
      );
      expect(pastime.experience, isA<GuidedPastimeExperience>());
      expect(pastime.isActiveForViewing, isTrue);
    });

    test('quarantined active pastime is hidden from viewing list policy', () {
      final pastime = Pastime(
        id: OfflineFixtures.radioPastimeId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        title: 'Radio Demo',
        instruction: 'Escuchar la radio Ejemplo un rato en el sillón.',
        displayOrder: 0,
        lifecycleStatus: PastimeLifecycleStatus.active,
        version: AggregateVersion.initial,
        syncState: SyncState.synced,
        experience: const QuarantinedPastimeExperience(
          plainLanguageReason: 'Configuración no válida.',
        ),
      );
      expect(pastime.isLifecycleActive, isTrue);
      expect(pastime.isActiveForViewing, isFalse);
      expect(pastime.isQuarantinedFromPlay, isTrue);
    });
  });

  group('ConfigurePastime experience', () {
    test(
      'create/edit/activate validate experience; type change needs confirm',
      () async {
        final store = _StubPastimes();
        final configure = ConfigurePastime(store);
        final elena = IdentityFixtures.elenaPrimaryMembership;

        final created = await configure.create(
          actor: elena,
          id: OfflineFixtures.radioPastimeId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Radio Demo',
          instruction: 'Escuchar la radio Ejemplo un rato en el sillón.',
          idempotencyKey: OfflineFixtures.radioPastimeSaveKey,
          experience: const GuidedPastimeExperience(),
        );
        expect(created.experience, isA<GuidedPastimeExperience>());

        await expectLater(
          configure.edit(
            actor: elena,
            id: OfflineFixtures.radioPastimeId,
            experience: SudokuPastimeExperience(
              boardSize: SudokuBoardSize.fourByFour,
              puzzlePackId: SudokuPuzzlePackCatalog.starter4,
            ),
            idempotencyKey: IdempotencyKey('demo-type-change-denied'),
          ),
          throwsStateError,
        );

        final changed = await configure.edit(
          actor: elena,
          id: OfflineFixtures.radioPastimeId,
          experience: SudokuPastimeExperience(
            boardSize: SudokuBoardSize.fourByFour,
            puzzlePackId: SudokuPuzzlePackCatalog.starter4,
          ),
          confirmExperienceTypeChange: true,
          idempotencyKey: IdempotencyKey('demo-type-change-ok'),
        );
        expect(changed.experience, isA<SudokuPastimeExperience>());

        final activated = await configure.activate(
          actor: elena,
          id: OfflineFixtures.radioPastimeId,
          idempotencyKey: IdempotencyKey('demo-activate-sudoku'),
        );
        expect(activated.lifecycleStatus, PastimeLifecycleStatus.active);

        await expectLater(
          configure.create(
            actor: elena,
            id: OfflineFixtures.draftPuzzlePastimeId,
            familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
            title: 'Bad Demo',
            instruction: 'No se puede guardar cuarentena Demo.',
            experience: const QuarantinedPastimeExperience(
              plainLanguageReason: 'no',
            ),
            idempotencyKey: IdempotencyKey('demo-quarantine-denied'),
          ),
          throwsArgumentError,
        );
      },
    );
  });
}

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
