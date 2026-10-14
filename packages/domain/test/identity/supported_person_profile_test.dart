import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('SupportedPersonProfile preferred-name validation', () {
    test('accepts trimmed 1–40 Unicode scalars', () {
      final profile = SupportedPersonProfile(
        id: OfflineFixtures.amparoPreferredNameProfileId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        preferredName: '  Amparo Demo  ',
        version: AggregateVersion.initial,
        syncState: SyncState.local,
      );
      expect(profile.preferredName, 'Amparo Demo');
      expect(SupportedPersonProfile.isValidPreferredName('A'), isTrue);
      expect(SupportedPersonProfile.isValidPreferredName('á' * 40), isTrue);
    });

    test('rejects empty, whitespace-only, overlong and control chars', () {
      expect(
        () => SupportedPersonProfile.normalizePreferredName(''),
        throwsArgumentError,
      );
      expect(
        () => SupportedPersonProfile.normalizePreferredName('   '),
        throwsArgumentError,
      );
      expect(
        () => SupportedPersonProfile.normalizePreferredName('x' * 41),
        throwsArgumentError,
      );
      expect(
        () => SupportedPersonProfile.normalizePreferredName('Amparo\u0000Demo'),
        throwsArgumentError,
      );
      expect(
        () => SupportedPersonProfile.normalizePreferredName('Amparo\nDemo'),
        throwsArgumentError,
      );
    });

    test('homeGreeting falls back to Hola when missing or deleted', () {
      expect(SupportedPersonProfile.homeGreeting(null), 'Hola');
      expect(
        SupportedPersonProfile.homeGreeting(
          OfflineFixtures.amparoPreferredNameProfile,
        ),
        'Hola, Amparo Demo',
      );
      final deleted = OfflineFixtures.amparoPreferredNameProfile.copyWith(
        tombstone: Tombstone(
          aggregateId: OfflineFixtures.amparoPreferredNameProfileId.value,
          version: AggregateVersion(2),
          deletedAt: DateTime.utc(2026, 10, 14),
        ),
      );
      expect(SupportedPersonProfile.homeGreeting(deleted), 'Hola');
    });
  });

  group('ConfigureSupportedPersonProfile authorization', () {
    late _FakeProfileRepository repo;
    late ConfigureSupportedPersonProfile configure;

    setUp(() {
      repo = _FakeProfileRepository();
      configure = ConfigureSupportedPersonProfile(repo);
    });

    test('primary creates and corrects preferred name', () async {
      final created = await configure.setPreferredName(
        actor: IdentityFixtures.elenaPrimaryMembership,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        preferredName: 'Amparo Demo',
        id: OfflineFixtures.amparoPreferredNameProfileId,
        idempotencyKey: OfflineFixtures.amparoPreferredNameSaveKey,
      );
      expect(created.preferredName, 'Amparo Demo');
      expect(created.syncState, SyncState.pending);

      final corrected = await configure.setPreferredName(
        actor: IdentityFixtures.elenaPrimaryMembership,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        preferredName: 'Amparo Ejemplo',
        idempotencyKey: IdempotencyKey('demo-profile-correct-1'),
      );
      expect(corrected.preferredName, 'Amparo Ejemplo');
      expect(corrected.version.value, greaterThan(created.version.value));
    });

    test('invalid input preserves current stored value', () async {
      await configure.setPreferredName(
        actor: IdentityFixtures.elenaPrimaryMembership,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        preferredName: 'Amparo Demo',
        id: OfflineFixtures.amparoPreferredNameProfileId,
        idempotencyKey: OfflineFixtures.amparoPreferredNameSaveKey,
      );
      expect(
        () => configure.setPreferredName(
          actor: IdentityFixtures.elenaPrimaryMembership,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          preferredName: '   ',
          idempotencyKey: IdempotencyKey('demo-profile-invalid'),
        ),
        throwsArgumentError,
      );
      final stored = await repo.findForFamily(
        IdentityFixtures.familiaEjemploSpaceId,
      );
      expect(stored!.preferredName, 'Amparo Demo');
    });

    test('caregiver, contributor and supported cannot mutate', () async {
      for (final actor in [
        IdentityFixtures.carlosCaregiverMembership,
        IdentityFixtures.luciaContributorMembership,
        IdentityFixtures.amparoSupportedMembership,
      ]) {
        expect(
          () => configure.setPreferredName(
            actor: actor,
            familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
            preferredName: 'Hack Demo',
            id: OfflineFixtures.amparoPreferredNameProfileId,
            idempotencyKey: IdempotencyKey('deny-${actor.id.value}'),
          ),
          throwsA(isA<UnauthorizedCareActionException>()),
        );
      }
      expect(repo.saved, isEmpty);
    });

    test('cross-family actor is denied', () async {
      expect(
        () => configure.setPreferredName(
          actor: IdentityFixtures.casaDemoBPrimaryMembership,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          preferredName: 'Hack Cross',
          id: OfflineFixtures.amparoPreferredNameProfileId,
          idempotencyKey: IdempotencyKey('deny-cross'),
        ),
        throwsA(isA<UnauthorizedCareActionException>()),
      );
    });

    test('supported person may view; contributor may not', () async {
      repo.seed(OfflineFixtures.amparoPreferredNameProfile);
      final viewed = await configure.findForFamily(
        actor: IdentityFixtures.amparoSupportedMembership,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
      );
      expect(viewed!.preferredName, 'Amparo Demo');
      expect(
        () => configure.findForFamily(
          actor: IdentityFixtures.luciaContributorMembership,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        ),
        throwsA(isA<UnauthorizedCareActionException>()),
      );
    });
  });

  group('SupportedPersonProfileCarePolicy', () {
    test('edit is primary-only; view includes caregivers and supported', () {
      expect(
        SupportedPersonProfileCarePolicy.canEditSupportedPersonProfile(
          IdentityFixtures.elenaPrimaryMembership,
        ),
        isTrue,
      );
      expect(
        SupportedPersonProfileCarePolicy.canEditSupportedPersonProfile(
          IdentityFixtures.carlosCaregiverMembership,
        ),
        isFalse,
      );
      expect(
        SupportedPersonProfileCarePolicy.canViewSupportedPersonProfile(
          IdentityFixtures.amparoSupportedMembership,
        ),
        isTrue,
      );
      expect(
        SupportedPersonProfileCarePolicy.canViewSupportedPersonProfile(
          IdentityFixtures.luciaContributorMembership,
        ),
        isFalse,
      );
    });
  });

  group('privacy surfaces for preferred name', () {
    test('export/deletion includes supportedPersonProfile', () {
      expect(
        FamilyContentScope.exportAndDeletion,
        contains(FamilyContentType.supportedPersonProfile),
      );
    });

    test('LogRedactor blanks preferredName keys and inline labels', () {
      final redacted = LogRedactor.redact(
        'preferredName=Amparo Secreto Demo | title=ok',
      );
      expect(redacted, isNot(contains('Amparo Secreto')));
      expect(redacted, contains('[REDACTED'));

      final ctx = LogRedactor.redactContext({
        'preferredName': 'Amparo Secreto Demo',
        'event': 'sync.push',
      });
      expect(ctx['preferredName'], '[REDACTED]');
      expect(ctx['event'], 'sync.push');
    });
  });
}

final class _FakeProfileRepository implements SupportedPersonProfileRepository {
  final Map<String, SupportedPersonProfile> _byId =
      <String, SupportedPersonProfile>{};
  final List<SupportedPersonProfile> saved = <SupportedPersonProfile>[];

  void seed(SupportedPersonProfile profile) {
    _byId[profile.id.value] = profile;
  }

  @override
  Future<SupportedPersonProfile> save({
    required SupportedPersonProfile profile,
    required IdempotencyKey idempotencyKey,
  }) async {
    final pending = profile.copyWith(syncState: SyncState.pending);
    _byId[pending.id.value] = pending;
    saved.add(pending);
    return pending;
  }

  @override
  Future<SupportedPersonProfile?> findById(SupportedPersonProfileId id) async =>
      _byId[id.value];

  @override
  Future<SupportedPersonProfile?> findForFamily(
    FamilySpaceId familySpaceId,
  ) async {
    for (final profile in _byId.values) {
      if (profile.familySpaceId == familySpaceId && !profile.isDeleted) {
        return profile;
      }
    }
    return null;
  }

  @override
  Future<SupportedPersonProfile> softDelete({
    required SupportedPersonProfileId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) {
    throw UnimplementedError();
  }
}
