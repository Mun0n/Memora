import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:family_web/demo_composition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  const narrowSize = Size(390, 844);
  const desktopSize = Size(1280, 800);

  Future<FamilyWebDemoComposition> pumpWeb(
    WidgetTester tester, {
    required Size size,
    FamilyMembership? actor,
    FeatureSection initialSection = FeatureSection.routines,
    bool seed = true,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final composition = FamilyWebDemoComposition(
      networkAvailable: false,
      actor: actor,
    );
    if (seed) {
      await composition.seedDemoFixtures();
    }
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(initialSection: initialSection),
    );
    await tester.pumpAndSettle();
    return composition;
  }

  testWidgets('manager: create/edit/approve/archive memories (narrow)', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpWeb(
        tester,
        size: narrowSize,
        initialSection: FeatureSection.memories,
      );

      expect(find.textContaining('Jardín Ejemplo'), findsOneWidget);
      expect(find.textContaining('Patio Ejemplo'), findsOneWidget);
      expect(find.text(MemoraCopy.approveMemory), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('memora-family-memory-caption')),
        'Recuerdo nuevo Demo',
      );
      await tester.enterText(
        find.byKey(const Key('memora-family-memory-date')),
        'Octubre 2026 Ejemplo',
      );
      final save = find.byKey(const Key('memora-family-save-memory'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.textContaining('Recuerdo nuevo Demo'), findsWidgets);

      final approve = find.byKey(
        Key(
          'memora-family-approve-${OfflineFixtures.proposedPatioMemoryId.value}',
        ),
      );
      await tester.ensureVisible(approve);
      await tester.tap(approve);
      await tester.pumpAndSettle();
      expect(approve, findsNothing);

      final archive = find.byKey(
        Key(
          'memora-family-archive-memory-${OfflineFixtures.gardenMemoryId.value}',
        ),
      );
      await tester.ensureVisible(archive);
      await tester.tap(archive);
      await tester.pumpAndSettle();
      expect(find.textContaining('Archivado'), findsWidgets);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('contributor proposes only; manage actions hidden', (
    tester,
  ) async {
    await pumpWeb(
      tester,
      size: desktopSize,
      actor: IdentityFixtures.luciaContributorMembership,
      initialSection: FeatureSection.memories,
      seed: false,
    );

    expect(find.byKey(const Key('memora-family-begin-memory')), findsOneWidget);
    expect(find.text(MemoraCopy.createMemory), findsNothing);
    expect(find.text(MemoraCopy.approveMemory), findsNothing);
    expect(find.text(MemoraCopy.archiveMemory), findsNothing);

    await tester.enterText(
      find.byKey(const Key('memora-family-memory-caption')),
      'Propuesta Lucía Demo',
    );
    await tester.enterText(
      find.byKey(const Key('memora-family-memory-date')),
      '2026 Demo',
    );
    final save = find.byKey(const Key('memora-family-save-memory'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.textContaining('Propuesta Lucía Demo'), findsWidgets);
    expect(find.textContaining('Propuesto'), findsWidgets);
  });

  testWidgets('supported person cannot manage or contribute memories', (
    tester,
  ) async {
    await pumpWeb(
      tester,
      size: narrowSize,
      actor: IdentityFixtures.amparoSupportedMembership,
      initialSection: FeatureSection.memories,
      seed: true,
    );

    expect(find.byKey(const Key('memora-family-begin-memory')), findsNothing);
    expect(find.byKey(const Key('memora-family-save-memory')), findsNothing);
    expect(find.text(MemoraCopy.approveMemory), findsNothing);
  });

  testWidgets('media failed shows retry affordance for manager', (
    tester,
  ) async {
    final store = InMemoryOfflineStore();
    store.putMemory(
      OfflineFixtures.gardenMemory.copyWith(
        media: OfflineFixtures.gardenMediaFailed,
      ),
    );
    final composition = FamilyWebDemoComposition(
      store: store,
      networkAvailable: false,
    );
    await composition.load();
    tester.view.physicalSize = desktopSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      composition.buildApp(initialSection: FeatureSection.memories),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(
      Key('memora-family-retry-media-${OfflineFixtures.gardenMemoryId.value}'),
    );
    expect(retry, findsOneWidget);
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(retry, findsNothing);
  });

  testWidgets('observation entry shows disclaimer; history + correction', (
    tester,
  ) async {
    final composition = await pumpWeb(
      tester,
      size: desktopSize,
      initialSection: FeatureSection.observations,
    );

    expect(
      find.byKey(const Key('memora-observation-disclaimer')),
      findsOneWidget,
    );
    expect(find.textContaining('no interpreta'), findsWidgets);
    expect(find.textContaining('62.5 kg'), findsOneWidget);
    expect(find.textContaining('120/80 mmHg'), findsOneWidget);

    // No clinical severity / advice copy (AC6) on observation surface.
    final disclaimer = tester
        .widget<Text>(find.byKey(const Key('memora-observation-disclaimer')))
        .data!
        .toLowerCase();
    expect(disclaimer, contains('no interpreta'));
    expect(disclaimer, isNot(contains('umbral')));
    expect(disclaimer, isNot(contains('alerta')));
    expect(disclaimer, isNot(contains('normal')));
    expect(find.textContaining('recomend'), findsNothing);
    expect(find.textContaining('diagnóst'), findsNothing);

    final weightField = find.byKey(const Key('memora-weight-kg'));
    final saveWeight = find.byKey(const Key('memora-save-weight'));
    await tester.ensureVisible(weightField);
    await tester.enterText(weightField, '63.0');
    await tester.ensureVisible(saveWeight);
    await tester.tap(saveWeight);
    await tester.pumpAndSettle();
    expect(find.textContaining('63.0 kg'), findsWidgets);

    final correct = find.byKey(
      Key('memora-weight-correct-${OfflineFixtures.weightObservationId.value}'),
    );
    expect(correct, findsOneWidget);
    await tester.ensureVisible(correct);
    await tester.tap(correct);
    await tester.pumpAndSettle();
    // Drive correction through the same controller the form binds to
    // (avoids flaky off-screen TextField hits after scroll).
    composition.observationController.setDraftWeightKg('62.8');
    await composition.observationController.saveWeight();
    await tester.pumpAndSettle();
    expect(find.textContaining('62.5 kg'), findsOneWidget);
    expect(find.textContaining('62.8 kg'), findsWidgets);
    expect(
      find.textContaining(MemoraCopy.observationCorrectionOf),
      findsWidgets,
    );
  });

  testWidgets('Help/About disclaimer reachable from nav', (tester) async {
    await pumpWeb(tester, size: narrowSize);
    await tester.tap(find.byKey(const Key('memora-nav-help')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-help-disclaimer')), findsOneWidget);
    expect(find.textContaining('no interpreta'), findsWidgets);
    expect(find.textContaining('emergencias'), findsWidgets);
  });

  testWidgets('narrow text scale 1.3 keeps observation disclaimer readable', (
    tester,
  ) async {
    await pumpWeb(
      tester,
      size: narrowSize,
      initialSection: FeatureSection.observations,
      textScale: 1.3,
    );
    expect(
      find.byKey(const Key('memora-observation-disclaimer')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('save memory button meets large touch target', (tester) async {
    await pumpWeb(
      tester,
      size: narrowSize,
      initialSection: FeatureSection.memories,
    );
    final save = find.byKey(const Key('memora-family-save-memory'));
    expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
  });
}
