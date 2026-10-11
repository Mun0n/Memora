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
    double textScale = 1.0,
    bool networkAvailable = false,
    InMemoryOfflineStore? store,
    bool seed = true,
    UserHomeDestination initialDestination = UserHomeDestination.home,
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
      composition.buildApp(initialDestination: initialDestination),
    );
    await tester.pumpAndSettle();
    return composition;
  }

  Future<void> expectNoHomeOverflow(WidgetTester tester) async {
    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollbar), findsNothing);
    final scrollables = find.byType(Scrollable);
    expect(scrollables, findsNothing);
  }

  testWidgets('phone 1.0: four tiles, order, no scroll/overflow', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpUser(tester, size: phoneSize);

      expect(
        find.bySemanticsLabel(MemoraCopy.homeSemanticsLabel),
        findsOneWidget,
      );
      expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
      expect(find.text(MemoraCopy.homeTileMiDia), findsOneWidget);
      expect(find.text(MemoraCopy.homeTilePasatiempos), findsOneWidget);
      expect(find.text(MemoraCopy.homeTileQuieroHablar), findsOneWidget);
      expect(find.text(MemoraCopy.homeTileRecuerdos), findsOneWidget);

      final miDia = tester.getTopLeft(
        find.byKey(const Key('memora-user-home-tile-mi-dia')),
      );
      final pasatiempos = tester.getTopLeft(
        find.byKey(const Key('memora-user-home-tile-pasatiempos')),
      );
      final hablar = tester.getTopLeft(
        find.byKey(const Key('memora-user-home-tile-quiero-hablar')),
      );
      final recuerdos = tester.getTopLeft(
        find.byKey(const Key('memora-user-home-tile-recuerdos')),
      );
      expect(miDia.dy, lessThan(hablar.dy));
      expect(pasatiempos.dy, lessThan(recuerdos.dy));
      expect(miDia.dx, lessThan(pasatiempos.dx));
      expect(hablar.dx, lessThan(recuerdos.dx));

      await expectNoHomeOverflow(tester);

      // AC3 exclusions on home
      expect(find.text(MemoraCopy.navSync), findsNothing);
      expect(find.text(MemoraCopy.navPrivacy), findsNothing);
      expect(find.text(MemoraCopy.navHelp), findsNothing);
      expect(find.textContaining('conflicto'), findsNothing);
      expect(find.textContaining('MEMORA_SUPABASE'), findsNothing);
      expect(find.textContaining('Amparo Demo'), findsNothing);
      expect(find.text(MemoraCopy.demoBanner), findsNothing);
      expect(find.text(MemoraCopy.todaysRoutines), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('phone 1.5 / tablet 1.0 & 1.5: four tiles, no scroll', (
    tester,
  ) async {
    for (final size in [phoneSize, tabletSize]) {
      for (final scale in [1.0, 1.5]) {
        await pumpUser(tester, size: size, textScale: scale);
        expect(
          find.byKey(const Key('memora-user-home-tile-mi-dia')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('memora-user-home-tile-pasatiempos')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('memora-user-home-tile-quiero-hablar')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('memora-user-home-tile-recuerdos')),
          findsOneWidget,
        );
        await expectNoHomeOverflow(tester);
      }
    }
  });

  testWidgets('tiles exceed 48 dp and expose Spanish semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpUser(tester, size: phoneSize);
      for (final key in [
        const Key('memora-user-home-tile-mi-dia'),
        const Key('memora-user-home-tile-pasatiempos'),
        const Key('memora-user-home-tile-quiero-hablar'),
        const Key('memora-user-home-tile-recuerdos'),
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThan(48));
        expect(size.height, greaterThan(48));
      }
      expect(find.bySemanticsLabel(MemoraCopy.homeTileMiDia), findsOneWidget);
      expect(
        find.bySemanticsLabel(MemoraCopy.homeTilePasatiempos),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(MemoraCopy.homeTileQuieroHablar),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(MemoraCopy.homeTileRecuerdos),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Mi día: one step, complete/correct, return home, offline', (
    tester,
  ) async {
    final composition = await pumpUser(tester, size: phoneSize);
    await tester.tap(find.byKey(const Key('memora-user-home-tile-mi-dia')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('memora-user-mi-dia')), findsOneWidget);
    expect(find.byKey(const Key('memora-user-primary-step')), findsOneWidget);
    expect(find.byKey(const Key('memora-user-primary-action')), findsOneWidget);
    expect(find.text(MemoraCopy.todaysRoutines), findsNothing);
    expect(find.textContaining('Beber un vaso'), findsOneWidget);

    await tester.tap(find.byKey(const Key('memora-user-primary-action')));
    await tester.pumpAndSettle();
    // Two-step demo routine: completing step 0 advances to the next pending step.
    expect(find.byKey(const Key('memora-user-primary-action')), findsOneWidget);
    expect(composition.controller.primaryAction, isNotNull);

    final snapshot = composition.store.capture();
    final restored = UserDemoComposition(
      store: InMemoryOfflineStore.fromSnapshot(snapshot),
      networkAvailable: false,
    );
    await restored.load();
    await tester.pumpWidget(
      restored.buildApp(initialDestination: UserHomeDestination.miDia),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-primary-action')), findsOneWidget);

    // Complete remaining steps until correction is offered.
    while (find.text(MemoraCopy.primaryActionComplete).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('memora-user-primary-action')));
      await tester.pumpAndSettle();
    }
    expect(find.text(MemoraCopy.primaryActionCorrect), findsOneWidget);

    await tester.tap(find.byKey(const Key('memora-user-return-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
  });

  testWidgets('Pasatiempos / Quiero hablar placeholders are honest', (
    tester,
  ) async {
    await pumpUser(tester, size: phoneSize);

    await tester.tap(
      find.byKey(const Key('memora-user-home-tile-pasatiempos')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-pasatiempos')), findsOneWidget);
    expect(find.textContaining('aparecerán las actividades'), findsOneWidget);
    expect(find.textContaining('llamada'), findsNothing);
    expect(find.textContaining('emergencia'), findsNothing);
    await tester.tap(find.byKey(const Key('memora-user-return-home')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('memora-user-home-tile-quiero-hablar')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-quiero-hablar')), findsOneWidget);
    expect(find.textContaining('no se hace ninguna llamada'), findsOneWidget);
    expect(find.textContaining('emergencia'), findsNothing);
    expect(find.textContaining('éxito'), findsNothing);
    await tester.tap(find.byKey(const Key('memora-user-return-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
  });

  testWidgets('sync failure does not rearrange home or block Mi día', (
    tester,
  ) async {
    final failedStore = InMemoryOfflineStore();
    failedStore.putRoutine(OfflineFixtures.morningRoutine);
    failedStore.putProgress(
      OfflineFixtures.morningProgressPending.copyWith(
        syncState: SyncState.failed,
      ),
    );
    await pumpUser(
      tester,
      size: phoneSize,
      store: failedStore,
      seed: false,
      networkAvailable: true,
    );

    expect(
      find.byKey(const Key('memora-user-home-tile-mi-dia')),
      findsOneWidget,
    );
    expect(find.textContaining('No se pudo sincronizar'), findsNothing);
    expect(find.textContaining('conflicto'), findsNothing);

    await tester.tap(find.byKey(const Key('memora-user-home-tile-mi-dia')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-primary-action')), findsOneWidget);
  });
}
