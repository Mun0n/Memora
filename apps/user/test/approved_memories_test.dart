import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:user/demo_composition.dart';

void main() {
  const phoneSize = Size(390, 844);
  const tabletSize = Size(800, 1280);

  Future<UserDemoComposition> pumpUser(
    WidgetTester tester, {
    required Size size,
    FeatureSection initialSection = FeatureSection.routines,
    bool networkAvailable = false,
    InMemoryOfflineStore? store,
    bool seed = true,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final composition = UserDemoComposition(
      store: store,
      networkAvailable: networkAvailable,
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

  testWidgets('phone: approved memory visible; proposed hidden', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpUser(
        tester,
        size: phoneSize,
        initialSection: FeatureSection.memories,
      );

      expect(find.textContaining('Jardín Ejemplo'), findsOneWidget);
      expect(find.textContaining('Octubre 2026 Demo'), findsOneWidget);
      expect(find.textContaining('Patio Ejemplo'), findsNothing);
      expect(find.textContaining('Sin red'), findsWidgets);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('tablet: same approved memory contract', (tester) async {
    await pumpUser(
      tester,
      size: tabletSize,
      initialSection: FeatureSection.memories,
    );
    expect(find.bySemanticsLabel('Expanded shell layout'), findsOneWidget);
    expect(
      find.byKey(
        Key('memora-user-memory-${OfflineFixtures.gardenMemoryId.value}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('failed media never breaks navigation', (tester) async {
    final store = InMemoryOfflineStore();
    store.putMemory(
      OfflineFixtures.gardenMemory.copyWith(
        media: OfflineFixtures.gardenMediaFailed,
      ),
    );
    await pumpUser(
      tester,
      size: phoneSize,
      store: store,
      seed: false,
      initialSection: FeatureSection.memories,
    );

    expect(
      find.byKey(
        Key('memora-user-media-failed-${OfflineFixtures.gardenMemoryId.value}'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Jardín Ejemplo'), findsOneWidget);
    expect(find.textContaining('Octubre 2026 Demo'), findsOneWidget);

    // Caption/date usable; Help nav still works (failed media never traps).
    final help = find.byKey(const Key('memora-nav-help'));
    await tester.ensureVisible(help);
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-help-disclaimer')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final memoriesNav = find.byKey(const Key('memora-nav-memories'));
    await tester.ensureVisible(memoriesNav);
    await tester.tap(memoriesNav);
    await tester.pumpAndSettle();
    expect(find.textContaining('Jardín Ejemplo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline cached memories remain usable', (tester) async {
    await pumpUser(
      tester,
      size: phoneSize,
      networkAvailable: false,
      initialSection: FeatureSection.memories,
    );
    expect(find.textContaining('Jardín Ejemplo'), findsOneWidget);
    expect(find.textContaining('siguen disponibles'), findsWidgets);
  });

  testWidgets('Help/About disclaimer on phone', (tester) async {
    await pumpUser(tester, size: phoneSize);
    await tester.tap(find.byKey(const Key('memora-nav-help')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-help-disclaimer')), findsOneWidget);
    expect(find.textContaining('emergencias'), findsWidgets);
  });

  testWidgets('phone text scale 1.3 keeps memory caption readable', (
    tester,
  ) async {
    await pumpUser(
      tester,
      size: phoneSize,
      initialSection: FeatureSection.memories,
      textScale: 1.3,
    );
    expect(find.textContaining('Jardín Ejemplo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
