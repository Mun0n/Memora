import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:user/demo_composition.dart';

void main() {
  const phoneSize = Size(390, 844);

  Future<UserDemoComposition> pumpPasatiempos(
    WidgetTester tester, {
    Pastime? extra,
    PreferredOrientationsPort? orientations,
    Size size = phoneSize,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final composition = UserDemoComposition(
      networkAvailable: false,
      sessionRecovery: InMemoryPastimeSessionRecoveryStore(),
      pastimeSeedFactory: () => 14,
      pastimeOrientations:
          orientations ?? const NoopPreferredOrientationsPort(),
    );
    await composition.seedDemoFixtures();
    if (extra != null) {
      await composition.pastimes.save(
        pastime: extra,
        idempotencyKey: IdempotencyKey('test-extra-pastime'),
      );
    }
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(initialDestination: UserHomeDestination.pasatiempos),
    );
    await tester.pumpAndSettle();
    return composition;
  }

  Future<void> openAndStart(WidgetTester tester, PastimeId id) async {
    await tester.tap(find.byKey(Key('memora-user-pastime-${id.value}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('memora-user-pastime-start')));
    await tester.pumpAndSettle();
  }

  testWidgets('playable card opens intro then player with Terminar', (
    tester,
  ) async {
    final composition = await pumpPasatiempos(tester);
    final id = OfflineFixtures.sudokuDemoPastimeId;

    expect(find.text('Sudoku Demo'), findsOneWidget);
    await tester.tap(find.byKey(Key('memora-user-pastime-${id.value}')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(Key('memora-user-pastime-intro-${id.value}')),
      findsOneWidget,
    );
    expect(find.text(MemoraCopy.pasatiemposStart), findsOneWidget);
    expect(find.text(MemoraCopy.pasatiemposBackToList), findsOneWidget);

    await tester.tap(find.byKey(const Key('memora-user-pastime-start')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('memora-user-pastime-player')), findsOneWidget);
    expect(find.byKey(const Key('memora-user-sudoku-board')), findsOneWidget);
    expect(find.byKey(const Key('memora-user-pastime-finish')), findsOneWidget);
    expect(find.textContaining('puntos'), findsNothing);
    expect(find.textContaining('racha'), findsNothing);
    expect(find.textContaining('fallo'), findsNothing);

    await tester.tap(find.byKey(const Key('memora-user-pastime-finish')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('memora-user-pastime-exit-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('memora-user-pastime-exit-leave')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-pasatiempos')), findsOneWidget);
    expect(await composition.sessionRecovery.loadCurrent(), isNull);
  });

  testWidgets('recovery offers Continuar without auto-entering play', (
    tester,
  ) async {
    final pastime = OfflineFixtures.sudokuDemoPastime;
    final composition = await pumpPasatiempos(tester);
    final engine = SudokuEngine();
    final state = engine.start(
      experience: pastime.experience as SudokuPastimeExperience,
      seed: 42,
    );
    await composition.sessionRecovery.save(
      PastimeSessionRecoverySnapshot(
        pastimeId: pastime.id,
        experienceType: pastime.experience.typeWireName,
        experienceSchemaVersion: pastime.experience.schemaVersion,
        seed: 42,
        boardState: state.toRecoveryMap(),
        updatedAt: DateTime.utc(2026, 10, 14, 12),
      ),
    );

    await tester.tap(
      find.byKey(Key('memora-user-pastime-${pastime.id.value}')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('memora-user-pastime-recovery')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('memora-user-pastime-continue')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('memora-user-pastime-player')), findsNothing);

    await tester.tap(find.byKey(const Key('memora-user-pastime-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-pastime-player')), findsOneWidget);
  });

  testWidgets('guided keeps readable detail without player shell', (
    tester,
  ) async {
    final guided = Pastime(
      id: PastimeId('01932f00-0008-7000-8000-0000000000a1'),
      familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
      title: 'Actividad guiada Demo UI',
      instruction: 'Escuchar la radio Ejemplo un rato en el sillón.',
      displayOrder: 9,
      lifecycleStatus: PastimeLifecycleStatus.active,
      version: AggregateVersion.initial,
      syncState: SyncState.local,
      experience: const GuidedPastimeExperience(),
    );
    await pumpPasatiempos(tester, extra: guided);

    await tester.scrollUntilVisible(
      find.byKey(Key('memora-user-pastime-${guided.id.value}')),
      80,
    );
    await tester.tap(find.byKey(Key('memora-user-pastime-${guided.id.value}')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(Key('memora-user-pastime-detail-${guided.id.value}')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('memora-user-pastime-start')), findsNothing);
    expect(find.byKey(const Key('memora-user-pastime-player')), findsNothing);
  });

  testWidgets(
    'quarantined/invalid experience stays off list and calm recovery',
    (tester) async {
      final quarantinedId = PastimeId('01932f00-0008-7000-8000-000000000099');
      final composition = await pumpPasatiempos(tester);
      composition.store.putPastime(
        Pastime(
          id: quarantinedId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Config Remota Demo',
          instruction: 'No debería abrirse.',
          displayOrder: 9,
          lifecycleStatus: PastimeLifecycleStatus.active,
          version: AggregateVersion.initial,
          syncState: SyncState.synced,
          experience: const QuarantinedPastimeExperience(
            plainLanguageReason: 'Configuración no válida.',
          ),
        ),
      );
      await composition.load();
      await tester.pumpAndSettle();

      expect(find.text('Config Remota Demo'), findsNothing);
      expect(find.textContaining('schemaVersion'), findsNothing);
      expect(find.textContaining('quarantined'), findsNothing);
      expect(find.textContaining('json'), findsNothing);
      expect(find.byKey(const Key('memora-user-pastime-player')), findsNothing);

      composition.pastimeController.pastimes = <Pastime>[
        Pastime(
          id: quarantinedId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          title: 'Config Remota Demo',
          instruction: 'No debería abrirse.',
          displayOrder: 9,
          lifecycleStatus: PastimeLifecycleStatus.active,
          version: AggregateVersion.initial,
          syncState: SyncState.synced,
          experience: const QuarantinedPastimeExperience(
            plainLanguageReason: 'Configuración no válida.',
          ),
        ),
      ];
      await composition.pastimeController.openDetail(quarantinedId);
      await tester.pumpAndSettle();

      expect(find.text(MemoraCopy.pasatiemposUnavailable), findsOneWidget);
      expect(find.byKey(const Key('memora-user-pastime-player')), findsNothing);
      expect(find.byKey(const Key('memora-user-pastime-start')), findsNothing);
      expect(find.textContaining('schemaVersion'), findsNothing);
      expect(find.textContaining('stack'), findsNothing);
      expect(find.textContaining('Configuración no válida.'), findsNothing);
    },
  );

  testWidgets('revealed sudoku keeps solved board until explicit continue', (
    tester,
  ) async {
    final composition = await pumpPasatiempos(tester);
    await openAndStart(tester, OfflineFixtures.sudokuDemoPastimeId);

    // Cancel confirmation leaves the board unchanged.
    composition.pastimeController.sudokuRevealSolution(confirmed: false);
    await tester.pumpAndSettle();
    expect(
      composition.pastimeController.sudokuState?.solutionRevealed,
      isFalse,
    );

    composition.pastimeController.sudokuRevealSolution(confirmed: true);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('memora-user-pastime-player')), findsOneWidget);
    expect(find.byKey(const Key('memora-user-sudoku-board')), findsOneWidget);
    expect(
      find.byKey(const Key('memora-user-sudoku-solution-status')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('memora-user-sudoku-solution-status')),
      findsOneWidget,
    );
    expect(find.text(MemoraCopy.pasatiemposSolutionShown), findsOneWidget);
    expect(
      find.byKey(const Key('memora-user-pastime-completed')),
      findsNothing,
    );
    expect(composition.pastimeController.phase, UserPastimePhase.playing);
    expect(composition.pastimeController.sudokuState?.solutionRevealed, isTrue);
    expect(
      composition.pastimeController.sudokuState?.values,
      composition.pastimeController.sudokuState?.solution,
    );
    expect(await composition.sessionRecovery.loadCurrent(), isNull);

    composition.pastimeController.notifyListeners();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('memora-user-sudoku-solution-status')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('memora-user-sudoku-solution-continue')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('memora-user-pastime-completed')),
      findsOneWidget,
    );
    expect(find.text(MemoraCopy.pasatiemposCompletedTitle), findsOneWidget);
    expect(find.byKey(const Key('memora-user-pastime-player')), findsNothing);
    expect(find.textContaining('puntos'), findsNothing);

    await tester.tap(
      find.byKey(const Key('memora-user-pastime-back-after-complete')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-pasatiempos')), findsOneWidget);
  });

  testWidgets('ordinary sudoku completion still uses the completion panel', (
    tester,
  ) async {
    final composition = await pumpPasatiempos(tester);
    await openAndStart(tester, OfflineFixtures.sudokuDemoPastimeId);

    final state = composition.pastimeController.sudokuState!;
    for (var i = 0; i < state.cellCount; i++) {
      if (state.isClue(i)) {
        continue;
      }
      composition.pastimeController.sudokuSelectCell(i);
      composition.pastimeController.sudokuEnterNumber(state.solution[i]);
    }
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('memora-user-pastime-completed')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('memora-user-pastime-player')), findsNothing);
    expect(
      composition.pastimeController.sudokuState?.solutionRevealed,
      isFalse,
    );
  });

  testWidgets('play again requires an explicit tap after completion', (
    tester,
  ) async {
    final composition = await pumpPasatiempos(tester);
    await openAndStart(tester, OfflineFixtures.sudokuDemoPastimeId);
    composition.pastimeController.sudokuRevealSolution(confirmed: true);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('memora-user-sudoku-solution-continue')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('memora-user-pastime-player')), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-pastime-player')), findsNothing);
    expect(
      find.byKey(const Key('memora-user-pastime-completed')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('memora-user-pastime-play-again')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-pastime-player')), findsOneWidget);
  });

  testWidgets('word search drag previews then submits on release', (
    tester,
  ) async {
    final composition = await pumpPasatiempos(tester);

    await openAndStart(tester, OfflineFixtures.wordSearchDemoPastimeId);

    final state = composition.pastimeController.wordSearchState!;
    expect(state.completed, isFalse);
    final placement = state.placements.firstWhere((p) => p.cells.length >= 3);
    final start = placement.cells.first;
    final end = placement.cells.last;
    final startFinder = find.byKey(
      Key('memora-user-wordsearch-cell-${start.row}-${start.col}'),
    );
    final endFinder = find.byKey(
      Key('memora-user-wordsearch-cell-${end.row}-${end.col}'),
    );

    // Press-drag-release across cell centres (primary touch path).
    final startCenter = tester.getCenter(startFinder);
    final endCenter = tester.getCenter(endFinder);
    final gesture = await tester.startGesture(startCenter);
    await tester.pump();
    expect(
      find.byKey(const Key('memora-user-wordsearch-cancel')),
      findsOneWidget,
      reason: 'pointer down on a cell must start a drag selection',
    );
    for (var i = 1; i <= 8; i++) {
      await gesture.moveTo(Offset.lerp(startCenter, endCenter, i / 8)!);
      await tester.pump();
    }
    expect(
      find.byKey(const Key('memora-user-wordsearch-drag-preview')),
      findsOneWidget,
    );
    expect(
      composition.pastimeController.wordSearchState!.foundWords.contains(
        placement.word,
      ),
      isFalse,
      reason: 'submit only on release',
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      composition.pastimeController.wordSearchState!.foundWords.contains(
        placement.word,
      ),
      isTrue,
    );

    // Accessibility tap-endpoint fallback for another word.
    final next = state.placements.firstWhere(
      (p) => !composition.pastimeController.wordSearchState!.foundWords
          .contains(p.word),
    );
    composition.pastimeController.wordSearchTapCell(next.cells.first);
    composition.pastimeController.wordSearchTapCell(next.cells.last);
    await tester.pumpAndSettle();
    expect(
      composition.pastimeController.wordSearchState!.foundWords.contains(
        next.word,
      ),
      isTrue,
    );
  });

  testWidgets('spider locks landscape on play and restores on exit', (
    tester,
  ) async {
    final orientations = RecordingPreferredOrientationsPort();
    await pumpPasatiempos(
      tester,
      orientations: orientations,
      size: const Size(844, 390),
    );
    final id = OfflineFixtures.spiderSolitaireDemoPastimeId;

    await tester.scrollUntilVisible(
      find.byKey(Key('memora-user-pastime-${id.value}')),
      80,
    );
    await openAndStart(tester, id);

    expect(orientations.calls, contains('lockLandscape'));
    expect(find.byKey(const Key('memora-user-spider-board')), findsOneWidget);
    expect(find.byType(PlayingCardFace), findsWidgets);

    await tester.tap(find.byKey(const Key('memora-user-pastime-finish')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('memora-user-pastime-exit-leave')));
    await tester.pumpAndSettle();

    expect(orientations.calls, contains('restoreAppDefaults'));
    expect(find.byKey(const Key('memora-user-pasatiempos')), findsOneWidget);
  });
}
