import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('IdentityFixtures', () {
    test('preserves Slice 1 Demo/Ejemplo persona labels', () {
      expect(SyntheticFixtures.amparoDemo.displayName, 'Amparo Demo');
      expect(SyntheticFixtures.elenaDemo.displayName, 'Elena Demo');
      expect(SyntheticFixtures.familiaEjemplo.displayName, 'Familia Ejemplo');
      expect(IdentityFixtures.amparoSupportedDisplayName, 'Amparo Demo');
      expect(IdentityFixtures.elenaPrimaryDisplayName, 'Elena Demo');
      expect(
        IdentityFixtures.familiaEjemploSpace.displayName,
        'Familia Ejemplo',
      );
    });

    test('uses only Demo/Ejemplo labels for new identity fixtures', () {
      final labels = <String>[
        IdentityFixtures.familiaEjemploSpace.displayName,
        IdentityFixtures.casaDemoBSpace.displayName,
        IdentityFixtures.elenaPrimaryDisplayName,
        IdentityFixtures.amparoSupportedDisplayName,
        IdentityFixtures.carlosCaregiverDisplayName,
        IdentityFixtures.luciaContributorDisplayName,
        IdentityFixtures.outsiderDisplayName,
      ];
      for (final label in labels) {
        final fictional = label.contains('Demo') || label.contains('Ejemplo');
        expect(fictional, isTrue, reason: label);
      }
    });

    test('keeps reserved UUIDs stable for SQL parity', () {
      expect(
        IdentityFixtures.familiaEjemploSpaceId.value,
        '01932f00-0002-7000-8000-0000000000a1',
      );
      expect(
        IdentityFixtures.casaDemoBSpaceId.value,
        '01932f00-0002-7000-8000-0000000000b2',
      );
      expect(
        IdentityFixtures.elenaPrimaryUserId.value,
        '01932f00-0002-7000-8000-000000000101',
      );
      expect(
        IdentityFixtures.outsiderDemoUserId.value,
        '01932f00-0002-7000-8000-000000000199',
      );
    });

    test('covers four roles across two fictional family spaces', () {
      expect(
        IdentityFixtures.elenaPrimaryMembership.role,
        FamilyRole.primaryCaregiver,
      );
      expect(
        IdentityFixtures.carlosCaregiverMembership.role,
        FamilyRole.caregiver,
      );
      expect(
        IdentityFixtures.luciaContributorMembership.role,
        FamilyRole.familyContributor,
      );
      expect(
        IdentityFixtures.amparoSupportedMembership.role,
        FamilyRole.supportedPerson,
      );
      expect(
        IdentityFixtures.casaDemoBPrimaryMembership.familySpaceId,
        IdentityFixtures.casaDemoBSpaceId,
      );
      expect(
        IdentityFixtures.elenaPrimaryMembership.familySpaceId,
        isNot(IdentityFixtures.casaDemoBSpaceId),
      );
    });
  });
}
