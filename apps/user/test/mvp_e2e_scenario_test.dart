import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:user/demo_composition.dart';

/// Supported-person path from `docs/current/MVP_E2E_SCENARIO.md` (AC3).
void main() {
  const phoneSize = Size(390, 844);
  const tabletSize = Size(800, 1280);

  Future<UserDemoComposition> pumpUser(
    WidgetTester tester, {
    required Size size,
    FeatureSection initialSection = FeatureSection.routines,
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
        key: treeKey ?? ValueKey(initialSection.name),
        child: composition.buildApp(initialSection: initialSection),
      ),
    );
    await tester.pumpAndSettle();
    return composition;
  }

  testWidgets('AC3: phone usable with no network and no remote config', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final composition = await pumpUser(tester, size: phoneSize);

      expect(composition.sessionBoundary, SessionBoundary.demo);
      expect(composition.sessionBoundary.requiresNetwork, isFalse);
      expect(
        find.textContaining('sábado, 10 de octubre de 2026'),
        findsOneWidget,
      );
      expect(find.text(MemoraCopy.demoBanner), findsOneWidget);
      expect(find.textContaining('Rutina de mañana Demo'), findsWidgets);

      // Primary step action via controller (phone scroll is tight with new nav).
      expect(composition.controller.primaryAction, isNotNull);
      await composition.controller.togglePrimaryAction();
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        KeyedSubtree(
          key: const ValueKey('user-memories'),
          child: composition.buildApp(initialSection: FeatureSection.memories),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Jardín Ejemplo'), findsOneWidget);
      expect(find.textContaining('Patio Ejemplo'), findsNothing);

      await tester.pumpWidget(
        KeyedSubtree(
          key: const ValueKey('user-sync'),
          child: composition.buildApp(initialSection: FeatureSection.sync),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(MemoraCopy.sessionDemoTitle), findsWidgets);
      await composition.syncController.push();
      await tester.pumpAndSettle();
      expect(composition.syncController.lastPush, isNotNull);
      expect(find.byKey(const Key('memora-sync-push-summary')), findsOneWidget);
      expect(composition.syncController.canResolveConflicts, isFalse);

      await tester.pumpWidget(
        KeyedSubtree(
          key: const ValueKey('user-privacy'),
          child: composition.buildApp(initialSection: FeatureSection.privacy),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('demo-tablet'), findsOneWidget);
      await composition.privacyController.revokeSession(
        UserDemoComposition.demoSessionId,
      );
      await tester.pumpAndSettle();
      expect(find.text(MemoraCopy.privacySessionRevoked), findsOneWidget);

      await tester.pumpWidget(
        KeyedSubtree(
          key: const ValueKey('user-help'),
          child: composition.buildApp(initialSection: FeatureSection.help),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('memora-help-disclaimer')), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('AC3/AC6: tablet + text scale — demo sync reachable', (
    tester,
  ) async {
    await pumpUser(
      tester,
      size: tabletSize,
      textScale: 1.3,
      initialSection: FeatureSection.sync,
    );
    expect(
      find.byKey(const Key('memora-shell-layout-expanded')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('memora-sync-push')), findsOneWidget);
    final push = tester.getSize(find.byKey(const Key('memora-sync-push')));
    expect(push.height, greaterThanOrEqualTo(48));
  });
}
