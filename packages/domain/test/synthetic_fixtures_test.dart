import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('SyntheticFixtures', () {
    test('exposes the three authorized fictional personas', () {
      expect(SyntheticFixtures.all.map((p) => p.displayName).toList(), <String>[
        'Amparo Demo',
        'Elena Demo',
        'Familia Ejemplo',
      ]);
    });

    test('marks every persona as synthetic / non-production', () {
      for (final persona in SyntheticFixtures.all) {
        expect(persona.isSynthetic, isTrue);
        expect(persona.syntheticMarker, contains('SYNTHETIC'));
        expect(persona.roleLabel.toLowerCase(), contains('synthetic'));
      }
    });

    test('display names stay in Demo/Ejemplo fictional form', () {
      for (final persona in SyntheticFixtures.all) {
        final name = persona.displayName;
        final fictional = name.contains('Demo') || name.contains('Ejemplo');
        expect(fictional, isTrue, reason: name);
      }
    });
  });
}
