import 'package:domain/domain.dart';
import 'package:family_web/demo_composition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  const narrowSize = Size(390, 844);

  Future<FamilyWebDemoComposition> pumpEditor(WidgetTester tester) async {
    tester.view.physicalSize = narrowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final composition = FamilyWebDemoComposition(
      actor: IdentityFixtures.elenaPrimaryMembership,
      networkAvailable: false,
    );
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(initialSection: FeatureSection.pastimes),
    );
    await tester.pumpAndSettle();
    return composition;
  }

  Future<void> saveDraft(
    WidgetTester tester, {
    required String title,
    required String instruction,
  }) async {
    await tester.enterText(
      find.byKey(const Key('memora-family-pastime-title')),
      title,
    );
    await tester.enterText(
      find.byKey(const Key('memora-family-pastime-instruction')),
      instruction,
    );
    await tester.ensureVisible(
      find.byKey(const Key('memora-family-save-pastime')),
    );
    await tester.tap(find.byKey(const Key('memora-family-save-pastime')));
    await tester.pumpAndSettle();
  }

  Future<void> activateNewestDraft(
    WidgetTester tester,
    FamilyWebDemoComposition composition,
  ) async {
    final drafts = composition.pastimeController.pastimes
        .where((p) => p.lifecycleStatus == PastimeLifecycleStatus.draft)
        .toList();
    expect(drafts, isNotEmpty);
    final id = drafts.last.id;
    final activate = find.byKey(
      Key('memora-family-activate-pastime-${id.value}'),
    );
    await tester.ensureVisible(activate);
    await tester.tap(activate);
    await tester.pumpAndSettle();
  }

  testWidgets('caregiver selects Sudoku type and sees preview', (tester) async {
    await pumpEditor(tester);

    expect(find.text(MemoraCopy.pastimeTypeLabel), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('memora-family-pastime-type-sudoku')),
    );
    await tester.tap(
      find.byKey(const Key('memora-family-pastime-type-sudoku')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('memora-family-sudoku-size-4x4')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('memora-family-pastime-preview')),
      findsOneWidget,
    );

    await saveDraft(
      tester,
      title: 'Sudoku Familiar Demo',
      instruction: 'Juega el sudoku Demo con calma.',
    );

    expect(find.textContaining('Sudoku Familiar Demo'), findsWidgets);
    expect(find.text(MemoraCopy.pastimeTypeSudoku), findsWidgets);
  });

  testWidgets('type change confirmation can be cancelled', (tester) async {
    await pumpEditor(tester);

    await saveDraft(
      tester,
      title: 'Guiada Demo',
      instruction: 'Indicación Demo breve.',
    );

    expect(find.textContaining('Guiada Demo'), findsWidgets);

    final edit = find.text(MemoraCopy.editPastime).first;
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();

    final wordSearch = find.byKey(
      const Key('memora-family-pastime-type-wordSearch'),
    );
    await tester.ensureVisible(wordSearch);
    await tester.tap(wordSearch);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('memora-family-pastime-type-change-dialog')),
      findsOneWidget,
    );
    final cancel = find.byKey(
      const Key('memora-family-pastime-type-change-cancel'),
    );
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('memora-family-pastime-type-change-dialog')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('memora-family-wordsearch-size-8x8')),
      findsNothing,
    );
  });

  testWidgets('caregiver selects word search, previews, saves and activates', (
    tester,
  ) async {
    final composition = await pumpEditor(tester);

    await tester.ensureVisible(
      find.byKey(const Key('memora-family-pastime-type-wordSearch')),
    );
    await tester.tap(
      find.byKey(const Key('memora-family-pastime-type-wordSearch')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('memora-family-wordsearch-size-8x8')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        Key(
          'memora-family-wordsearch-theme-'
          '${WordSearchWordSetCatalog.jardinDemo}',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('memora-family-pastime-preview')),
      findsOneWidget,
    );

    await saveDraft(
      tester,
      title: 'Sopa Jardín Demo',
      instruction: 'Busca las palabras Demo del jardín.',
    );

    expect(find.textContaining('Sopa Jardín Demo'), findsWidgets);
    expect(find.text(MemoraCopy.pastimeTypeWordSearch), findsWidgets);

    await activateNewestDraft(tester, composition);
    expect(find.textContaining('(Activo)'), findsWidgets);
  });

  testWidgets('caregiver selects Spider, previews, saves and activates', (
    tester,
  ) async {
    final composition = await pumpEditor(tester);

    await tester.ensureVisible(
      find.byKey(const Key('memora-family-pastime-type-spiderSolitaire')),
    );
    await tester.tap(
      find.byKey(const Key('memora-family-pastime-type-spiderSolitaire')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('memora-family-spider-suits-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('memora-family-spider-suits-4')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('memora-family-pastime-preview')),
      findsOneWidget,
    );

    await saveDraft(
      tester,
      title: 'Spider Un Palo Demo',
      instruction: 'Ordena las cartas Demo con calma.',
    );

    expect(find.textContaining('Spider Un Palo Demo'), findsWidgets);
    expect(find.text(MemoraCopy.pastimeTypeSpider), findsWidgets);

    await activateNewestDraft(tester, composition);
    expect(find.textContaining('(Activo)'), findsWidgets);
  });
}
