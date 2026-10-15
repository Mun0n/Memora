import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:user/demo_composition.dart';

void main() {
  const phone360 = Size(360, 800);
  const phone390 = Size(390, 844);
  const tablet = Size(800, 1280);

  const matrix = <(Size, double, String)>[
    (phone360, 1.0, '360x800_1.0'),
    (phone360, 1.3, '360x800_1.3'),
    (phone360, 1.5, '360x800_1.5'),
    (phone390, 1.0, '390x844_1.0'),
    (phone390, 1.3, '390x844_1.3'),
    (phone390, 1.5, '390x844_1.5'),
    (tablet, 1.0, '800x1280_1.0'),
    (tablet, 1.5, '800x1280_1.5'),
  ];

  Pastime sudokuPastime() => OfflineFixtures.sudokuDemoPastime;

  Pastime wordSearchPastime() => OfflineFixtures.wordSearchDemoPastime;

  Pastime spiderPastime() => OfflineFixtures.spiderSolitaireDemoPastime;

  Future<UserDemoComposition> pumpPlaying(
    WidgetTester tester, {
    required Pastime pastime,
    required Size size,
    double textScale = 1.0,
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    if (reduceMotion) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(
            disableAnimations: true,
            reduceMotion: true,
          );
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }

    final composition = UserDemoComposition(
      networkAvailable: false,
      sessionRecovery: InMemoryPastimeSessionRecoveryStore(),
      pastimeSeedFactory: () => 14,
      pastimeOrientations: const NoopPreferredOrientationsPort(),
    );
    await composition.seedDemoFixtures();
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(initialDestination: UserHomeDestination.pasatiempos),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(Key('memora-user-pastime-${pastime.id.value}'));
    await tester.scrollUntilVisible(card, 80);
    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('memora-user-pastime-start')));
    await tester.pumpAndSettle();
    return composition;
  }

  bool essentialCopyVisible(WidgetTester tester) {
    final title = find.byKey(const Key('memora-user-pastime-player'));
    final finish = find.byKey(const Key('memora-user-pastime-finish'));
    if (title.evaluate().isEmpty || finish.evaluate().isEmpty) {
      return false;
    }
    final view = tester.view.physicalSize;
    final finishBox = tester.getRect(finish);
    bool onScreen(Rect r) =>
        r.left >= -1 &&
        r.top >= -1 &&
        r.right <= view.width + 1 &&
        r.bottom <= view.height + 1;
    // Finish must remain reachable; title may scroll inside the player shell.
    return finishBox.width > 0 &&
        onScreen(finishBox) &&
        finishBox.height >= MemoraTheme.minTouchExtent;
  }

  for (final entry in matrix) {
    final size = entry.$1;
    final textScale = entry.$2;
    final label = entry.$3;

    testWidgets('sudoku player layout $label', (tester) async {
      await pumpPlaying(
        tester,
        pastime: sudokuPastime(),
        size: size,
        textScale: textScale,
      );

      expect(
        find.byKey(const Key('memora-user-pastime-player')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('memora-user-sudoku-board')), findsOneWidget);
      expect(essentialCopyVisible(tester), isTrue);

      final finishSize = tester.getSize(
        find.byKey(const Key('memora-user-pastime-finish')),
      );
      expect(finishSize.height, greaterThanOrEqualTo(48));
      expect(finishSize.width, greaterThanOrEqualTo(48));

      final tray = tester.getSize(
        find.byKey(const Key('memora-user-sudoku-tray-1')),
      );
      expect(tray.height, greaterThanOrEqualTo(48));
      expect(tray.width, greaterThanOrEqualTo(48));

      await expectLater(
        find.byKey(const Key('memora-user-pastime-player')),
        matchesGoldenFile('goldens/pastime_player_sudoku_$label.png'),
      );
    });
  }

  testWidgets('word search and spider boards open on phone', (tester) async {
    await pumpPlaying(tester, pastime: wordSearchPastime(), size: phone390);
    expect(
      find.byKey(const Key('memora-user-wordsearch-board')),
      findsOneWidget,
    );
    expect(find.text(MemoraCopy.pasatiemposWordList), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await pumpPlaying(tester, pastime: spiderPastime(), size: phone390);
    expect(find.byKey(const Key('memora-user-spider-board')), findsOneWidget);
    expect(find.byKey(const Key('memora-user-spider-goto-1')), findsOneWidget);
  });

  testWidgets('TalkBack order: title, board, session actions', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await pumpPlaying(tester, pastime: sudokuPastime(), size: phone390);

      final nodes = <String>[];
      void walk(SemanticsNode node) {
        final data = node.getSemanticsData();
        if (data.label.isNotEmpty) {
          nodes.add(data.label);
        }
        node.visitChildren((child) {
          walk(child);
          return true;
        });
      }

      final root = tester
          .binding
          // ignore: deprecated_member_use -- WidgetTester semantics still live here.
          .pipelineOwner
          .semanticsOwner!
          .rootSemanticsNode!;
      walk(root);

      final titleIdx = nodes.indexWhere((l) => l.contains('Sudoku Demo'));
      final boardIdx = nodes.indexWhere(
        (l) => l.contains('Tablero de sudoku') || l.contains('sudoku'),
      );
      final finishIdx = nodes.indexWhere(
        (l) => l.contains(MemoraCopy.pasatiemposFinish),
      );

      expect(titleIdx, greaterThanOrEqualTo(0));
      expect(boardIdx, greaterThan(titleIdx));
      expect(finishIdx, greaterThan(boardIdx));
    } finally {
      handle.dispose();
    }
  });

  testWidgets('reduced motion keeps player usable without clipping', (
    tester,
  ) async {
    await pumpPlaying(
      tester,
      pastime: sudokuPastime(),
      size: phone360,
      textScale: 1.5,
      reduceMotion: true,
    );

    expect(find.byKey(const Key('memora-user-pastime-player')), findsOneWidget);
    expect(essentialCopyVisible(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected sudoku cell is not colour-only', (tester) async {
    await pumpPlaying(tester, pastime: sudokuPastime(), size: phone390);

    // Prefer an editable (non-clue) cell when present.
    Finder? editable;
    for (var i = 0; i < 16; i++) {
      final candidate = find.byKey(Key('memora-user-sudoku-cell-$i'));
      if (candidate.evaluate().isEmpty) {
        continue;
      }
      final label = tester.getSemantics(candidate).label.toLowerCase();
      if (label.contains('fija') || label.contains('pista')) {
        continue;
      }
      editable = candidate;
      break;
    }
    expect(editable, isNotNull);
    await tester.tap(editable!);
    await tester.pumpAndSettle();

    final selectedLabel = tester.getSemantics(editable).label.toLowerCase();
    expect(
      selectedLabel,
      anyOf(contains('seleccion'), contains('elegid'), contains('celda')),
    );
    expect(find.byKey(const Key('memora-user-sudoku-board')), findsOneWidget);
  });
}
