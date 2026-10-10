import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  const phoneSize = Size(390, 844);
  const tabletSize = Size(800, 1280);

  Future<void> pumpUserShell(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      const MemoraShellApp(
        target: ExperienceTarget.user,
        persona: SyntheticFixtures.amparoDemo,
      ),
    );
  }

  Finder syncStatusContainer() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.constraints?.minHeight == NonProductionShell.minTouchExtent &&
          widget.decoration is BoxDecoration,
    );
  }

  testWidgets('phone layout: semantics, Demo persona, compact key', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpUserShell(tester, size: phoneSize);

      expect(
        find.bySemanticsLabel(
          'Memora User shell, non-production demonstration',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Compact shell layout'), findsOneWidget);
      expect(
        find.byKey(const Key('memora-shell-layout-compact')),
        findsOneWidget,
      );
      expect(find.textContaining('User'), findsWidgets);
      expect(find.textContaining('Amparo Demo'), findsOneWidget);
      expect(
        find.textContaining('DEMOSTRACIÓN — NO PRODUCCIÓN'),
        findsOneWidget,
      );
      expect(find.textContaining('SYNTHETIC / NON-PRODUCTION'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('tablet layout: semantics, Demo persona, expanded key', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpUserShell(tester, size: tabletSize);

      expect(
        find.bySemanticsLabel(
          'Memora User shell, non-production demonstration',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Expanded shell layout'), findsOneWidget);
      expect(
        find.byKey(const Key('memora-shell-layout-expanded')),
        findsOneWidget,
      );
      expect(find.textContaining('Amparo Demo'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('phone text scale 1.3 keeps Demo copy readable', (tester) async {
    await pumpUserShell(tester, size: phoneSize, textScale: 1.3);

    expect(find.textContaining('Amparo Demo'), findsOneWidget);
    expect(find.textContaining('Estado de sincronización'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet text scale 1.3 keeps Demo copy readable', (tester) async {
    await pumpUserShell(tester, size: tabletSize, textScale: 1.3);

    expect(find.textContaining('Amparo Demo'), findsOneWidget);
    expect(find.textContaining('Estado de sincronización'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone sync status meets minimum touch target height', (
    tester,
  ) async {
    await pumpUserShell(tester, size: phoneSize);

    final statusFinder = syncStatusContainer();
    expect(statusFinder, findsOneWidget);
    expect(
      tester.getSize(statusFinder).height,
      greaterThanOrEqualTo(NonProductionShell.minTouchExtent),
    );
  });

  testWidgets('tablet sync status meets minimum touch target height', (
    tester,
  ) async {
    await pumpUserShell(tester, size: tabletSize);

    final statusFinder = syncStatusContainer();
    expect(statusFinder, findsOneWidget);
    expect(
      tester.getSize(statusFinder).height,
      greaterThanOrEqualTo(NonProductionShell.minTouchExtent),
    );
  });
}
