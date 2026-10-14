import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'preferred-name profile survives snapshot restart with pending outbox',
    () async {
      final live = InMemoryOfflineStore();
      final profiles = InMemorySupportedPersonProfileRepository(live);
      final configure = ConfigureSupportedPersonProfile(profiles);

      await configure.setPreferredName(
        actor: IdentityFixtures.elenaPrimaryMembership,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        preferredName: 'Amparo Demo',
        id: OfflineFixtures.amparoPreferredNameProfileId,
        idempotencyKey: OfflineFixtures.amparoPreferredNameSaveKey,
      );

      final snapshot = live.capture();
      expect(snapshot.supportedPersonProfiles, hasLength(1));
      expect(
        snapshot.outboxEntries.any(
          (op) =>
              op.aggregateType == OutboxAggregateType.supportedPersonProfile,
        ),
        isTrue,
      );

      final restored = InMemoryOfflineStore.fromSnapshot(snapshot);
      final restoredProfiles = InMemorySupportedPersonProfileRepository(
        restored,
      );
      final found = await restoredProfiles.findForFamily(
        IdentityFixtures.familiaEjemploSpaceId,
      );
      expect(found!.preferredName, 'Amparo Demo');
      expect(found.syncState, SyncState.pending);
      expect(SupportedPersonProfile.homeGreeting(found), 'Hola, Amparo Demo');
    },
  );

  test('snapshot without profile list loads empty (greeting fallback)', () {
    final snapshot = OfflineStoreSnapshot(
      routines: const [],
      routineProgress: const [],
      reminders: const [],
      memories: const [],
      pastimes: const [],
      conversationTopics: const [],
      weightObservations: const [],
      bloodPressureObservations: const [],
      outboxEntries: const [],
    );
    final store = InMemoryOfflineStore.fromSnapshot(snapshot);
    expect(
      store.supportedPersonProfileForFamily(
        IdentityFixtures.familiaEjemploSpaceId,
      ),
      isNull,
    );
    expect(SupportedPersonProfile.homeGreeting(null), 'Hola');
  });
}
