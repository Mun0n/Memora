import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  testWidgets(
    'Family Web shell is labeled and uses synthetic Ejemplo persona',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          const MemoraShellApp(
            target: ExperienceTarget.familyWeb,
            persona: SyntheticFixtures.familiaEjemplo,
          ),
        );

        expect(
          find.bySemanticsLabel(
            'Memora Family Web shell, non-production demonstration',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Family Web'), findsWidgets);
        expect(find.textContaining('Familia Ejemplo'), findsOneWidget);
        expect(
          find.textContaining('DEMOSTRACIÓN — NO PRODUCCIÓN'),
          findsOneWidget,
        );
        expect(
          find.textContaining('SYNTHETIC / NON-PRODUCTION'),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    },
  );
}
