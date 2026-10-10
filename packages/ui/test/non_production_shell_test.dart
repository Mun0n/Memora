import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  testWidgets('user shell exposes experience semantics and synthetic persona', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: NonProductionShell(
            target: ExperienceTarget.user,
            persona: SyntheticFixtures.amparoDemo,
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Memora User shell, non-production demonstration',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('User'), findsWidgets);
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

  testWidgets(
    'family web shell sync status meets minimum touch target height',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NonProductionShell(
            target: ExperienceTarget.familyWeb,
            persona: SyntheticFixtures.familiaEjemplo,
          ),
        ),
      );

      final statusFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.minHeight ==
                NonProductionShell.minTouchExtent &&
            widget.decoration is BoxDecoration,
      );
      expect(statusFinder, findsOneWidget);
      final size = tester.getSize(statusFinder);
      expect(
        size.height,
        greaterThanOrEqualTo(NonProductionShell.minTouchExtent),
      );
    },
  );

  testWidgets('viewport class switches at expanded breakpoint', (tester) async {
    expect(
      ShellViewportClass.fromWidth(ShellViewportClass.expandedBreakpoint - 1),
      ShellViewportClass.compact,
    );
    expect(
      ShellViewportClass.fromWidth(ShellViewportClass.expandedBreakpoint),
      ShellViewportClass.expanded,
    );
  });
}
