import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const catalog = SyntheticPersonaCatalog();

  test('lists domain synthetic personas without network calls', () {
    final personas = catalog.listPersonas();
    expect(personas, hasLength(3));
    expect(personas, orderedEquals(SyntheticFixtures.all));
    for (final persona in personas) {
      expect(persona.isSynthetic, isTrue);
    }
  });

  test('finds Familia Ejemplo by display name', () {
    final found = catalog.findByDisplayName('Familia Ejemplo');
    expect(found, isNotNull);
    expect(found!.displayName, 'Familia Ejemplo');
    expect(found.syntheticMarker, contains('NON-PRODUCTION'));
  });

  test('returns null for unknown names', () {
    expect(catalog.findByDisplayName('Not A Real Person'), isNull);
  });
}
