import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  testWidgets('Caregiver shell is labeled and uses synthetic Demo persona', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        const MemoraShellApp(
          target: ExperienceTarget.caregiver,
          persona: SyntheticFixtures.elenaDemo,
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Memora Caregiver shell, non-production demonstration',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Caregiver'), findsWidgets);
      expect(find.textContaining('Elena Demo'), findsOneWidget);
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
