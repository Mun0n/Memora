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
    await tester.pumpWidget(composition.buildApp());
    await tester.pumpAndSettle();
    return composition;
  }

  testWidgets('phone: orientation, Demo persona, one primary action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpUser(tester, size: phoneSize);

      expect(
        find.bySemanticsLabel(
          'Memora User shell, non-production demonstration',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Compact shell layout'), findsOneWidget);
      expect(find.textContaining('Amparo Demo'), findsOneWidget);
      expect(
        find.textContaining('DEMOSTRACIÓN — NO PRODUCCIÓN'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('memora-user-orientation')), findsOneWidget);
      expect(find.textContaining('Rutina de mañana Demo'), findsWidgets);
      expect(
        find.byKey(const Key('memora-user-primary-action')),
        findsOneWidget,
      );
      expect(find.text(MemoraCopy.primaryActionComplete), findsOneWidget);
      expect(find.textContaining('Sin red'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('tablet: expanded layout consumes same routine contract', (
    tester,
  ) async {
    await pumpUser(tester, size: tabletSize);

    expect(find.bySemanticsLabel('Expanded shell layout'), findsOneWidget);
    expect(find.textContaining('Rutina de mañana Demo'), findsWidgets);
    expect(find.byKey(const Key('memora-user-primary-step')), findsOneWidget);
  });

  testWidgets('complete and correct survive restart snapshot', (tester) async {
    final composition = await pumpUser(tester, size: phoneSize);

    final action = find.byKey(const Key('memora-user-primary-action'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.textContaining('Hecho'), findsWidgets);

    final snapshot = composition.store.capture();
    final restored = InMemoryOfflineStore.fromSnapshot(snapshot);
    final restoredComposition = UserDemoComposition(
      store: restored,
      networkAvailable: false,
    );
    await restoredComposition.load();
    await tester.pumpWidget(restoredComposition.buildApp());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Beber un vaso de agua (Hecho)'),
      findsOneWidget,
    );

    final next = find.byKey(const Key('memora-user-primary-action'));
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-primary-action')), findsOneWidget);
  });

  testWidgets('phone text scale 1.3 keeps routine copy readable', (
    tester,
  ) async {
    await pumpUser(tester, size: phoneSize, textScale: 1.3);
    expect(find.textContaining('Rutina de mañana Demo'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary action meets large touch target', (tester) async {
    await pumpUser(tester, size: phoneSize);
    final action = find.byKey(const Key('memora-user-primary-action'));
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
  });

  testWidgets('empty and failed recovery states are accessible', (
    tester,
  ) async {
    await pumpUser(tester, size: phoneSize, seed: false);
    expect(find.byKey(const Key('memora-user-empty')), findsOneWidget);
    expect(find.textContaining('No hay rutinas activas'), findsWidgets);

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
    expect(find.textContaining('No se pudo sincronizar'), findsOneWidget);
    expect(
      find.byKey(const Key('memora-sync-recovery-action')),
      findsOneWidget,
    );
  });

  testWidgets('conflicted state exposes recovery action', (tester) async {
    final store = InMemoryOfflineStore();
    store.putRoutine(OfflineFixtures.morningRoutine);
    store.putProgress(
      OfflineFixtures.morningProgressPending.copyWith(
        syncState: SyncState.conflicted,
      ),
    );
    await pumpUser(
      tester,
      size: phoneSize,
      store: store,
      seed: false,
      networkAvailable: true,
    );
    expect(find.textContaining('conflicto'), findsWidgets);
    expect(find.text(MemoraCopy.recoveryReviewConflict), findsOneWidget);
  });
}
