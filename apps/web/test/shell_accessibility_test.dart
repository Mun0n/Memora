import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  const narrowSize = Size(390, 844);
  const desktopSize = Size(1280, 800);

  Future<void> pumpWebShell(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MemoraShellApp(
        target: ExperienceTarget.familyWeb,
        persona: SyntheticFixtures.familiaEjemplo,
      ),
    );
  }

  testWidgets('narrow layout: Family Web semantics and compact key', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpWebShell(tester, size: narrowSize);

      expect(
        find.bySemanticsLabel(
          'Memora Family Web shell, non-production demonstration',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Compact shell layout'), findsOneWidget);
      expect(
        find.byKey(const Key('memora-shell-layout-compact')),
        findsOneWidget,
      );
      expect(find.textContaining('Family Web'), findsWidgets);
      expect(find.textContaining('Familia Ejemplo'), findsOneWidget);
      expect(
        find.textContaining('DEMOSTRACIÓN — NO PRODUCCIÓN'),
        findsOneWidget,
      );
      expect(find.textContaining('SYNTHETIC / NON-PRODUCTION'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('desktop layout: Family Web semantics and expanded key', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpWebShell(tester, size: desktopSize);

      expect(
        find.bySemanticsLabel(
          'Memora Family Web shell, non-production demonstration',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Expanded shell layout'), findsOneWidget);
      expect(
        find.byKey(const Key('memora-shell-layout-expanded')),
        findsOneWidget,
      );
      expect(find.textContaining('Familia Ejemplo'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
