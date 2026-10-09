import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  testWidgets('Tablet shell is labeled and uses synthetic Demo persona', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        const MemoraShellApp(
          target: ExperienceTarget.tablet,
          persona: SyntheticFixtures.amparoDemo,
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
      expect(
        find.textContaining('DEMOSTRACIÓN — NO PRODUCCIÓN'),
        findsOneWidget,
      );
      expect(find.textContaining('SYNTHETIC / NON-PRODUCTION'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
