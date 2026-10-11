import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:user/demo_composition.dart';

/// Supported-person path for Slice 7 four-tile home (MVP E2E revision).
void main() {
  const phoneSize = Size(390, 844);
  const tabletSize = Size(800, 1280);

  Future<UserDemoComposition> pumpUser(
    WidgetTester tester, {
    required Size size,
    UserHomeDestination initialDestination = UserHomeDestination.home,
    double textScale = 1.0,
    Key? treeKey,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final composition = UserDemoComposition(networkAvailable: false);
    await composition.seedDemoFixtures();
    await composition.load();
    await tester.pumpWidget(
      KeyedSubtree(
        key: treeKey ?? ValueKey(initialDestination.name),
        child: composition.buildApp(initialDestination: initialDestination),
      ),
    );
    await tester.pumpAndSettle();
    return composition;
  }

  testWidgets('phone: home → Mi día → Recuerdos offline; sync stays behind', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final composition = await pumpUser(tester, size: phoneSize);

      expect(composition.sessionBoundary, SessionBoundary.demo);
      expect(composition.sessionBoundary.requiresNetwork, isFalse);
      expect(find.text(MemoraCopy.userHomeGreeting), findsOneWidget);
      expect(
        find.textContaining('sábado, 10 de octubre de 2026'),
        findsOneWidget,
      );
      expect(find.text(MemoraCopy.demoBanner), findsNothing);
      expect(find.text(MemoraCopy.navSync), findsNothing);

      await tester.tap(find.byKey(const Key('memora-user-home-tile-mi-dia')));
      await tester.pumpAndSettle();
      expect(composition.controller.primaryAction, isNotNull);
      await tester.tap(find.byKey(const Key('memora-user-primary-action')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('memora-user-primary-action')),
        findsOneWidget,
      );
      expect(composition.controller.primaryAction, isNotNull);

      await tester.tap(find.byKey(const Key('memora-user-return-home')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('memora-user-home-tile-recuerdos')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Jardín Ejemplo'), findsOneWidget);
      expect(find.textContaining('Patio Ejemplo'), findsNothing);

      // Sync engine still available behind the shell (not on home chrome).
      await composition.syncController.push();
      expect(composition.syncController.lastPush, isNotNull);
      expect(composition.syncController.canResolveConflicts, isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('tablet + text scale 1.5: four tiles remain fixed', (
    tester,
  ) async {
    await pumpUser(tester, size: tabletSize, textScale: 1.5);
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
    expect(tester.takeException(), isNull);
  });
}
