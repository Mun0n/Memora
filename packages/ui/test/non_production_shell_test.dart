import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  testWidgets('shell exposes experience semantics and synthetic persona', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: NonProductionShell(
            target: ExperienceTarget.tablet,
            persona: SyntheticFixtures.amparoDemo,
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Memora Tablet shell, non-production demonstration',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Tablet'), findsWidgets);
      expect(find.textContaining('Amparo Demo'), findsOneWidget);
      expect(find.textContaining('SYNTHETIC / NON-PRODUCTION'), findsOneWidget);
      expect(
        find.textContaining('DEMOSTRACIÓN — NO PRODUCCIÓN'),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('sync status region meets minimum touch target height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NonProductionShell(
          target: ExperienceTarget.caregiver,
          persona: SyntheticFixtures.elenaDemo,
        ),
      ),
    );

    final statusFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.constraints?.minHeight == NonProductionShell.minTouchExtent &&
          widget.decoration is BoxDecoration,
    );
    expect(statusFinder, findsOneWidget);
    final size = tester.getSize(statusFinder);
    expect(
      size.height,
      greaterThanOrEqualTo(NonProductionShell.minTouchExtent),
    );
  });
}
