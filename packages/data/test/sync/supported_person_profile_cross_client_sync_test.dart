import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  late LocalDemoSyncServer server;
  late LocalDemoSyncTransport caregiverTransport;
  late LocalDemoSyncTransport userTransport;

  setUp(() async {
    server = await LocalDemoSyncServer.bind(host: '127.0.0.1', port: 0);
    caregiverTransport = LocalDemoSyncTransport(baseUrl: server.baseUrl);
    userTransport = LocalDemoSyncTransport(baseUrl: server.baseUrl);
  });

  tearDown(() async {
    caregiverTransport.close();
    userTransport.close();
    await server.close();
  });

  test(
    'primary preferred-name edit converges on independent user store',
    () async {
      final caregiver = _ClientHarness(transport: caregiverTransport);
      final user = _ClientHarness(transport: userTransport);
      final elena = IdentityFixtures.elenaPrimaryMembership;
      final amparo = IdentityFixtures.amparoSupportedMembership;
      final space = IdentityFixtures.familiaEjemploSpaceId;

      await caregiver.configure.setPreferredName(
        actor: elena,
        familySpaceId: space,
        preferredName: 'Amparo Demo',
        id: OfflineFixtures.amparoPreferredNameProfileId,
        idempotencyKey: OfflineFixtures.amparoPreferredNameSaveKey,
      );

      final push = await caregiver.engine.pushPending();
      expect(push.failed, 0);
      expect(push.conflicted, 0);
      expect(push.applied + push.duplicates, greaterThanOrEqualTo(1));

      final pull = await user.engine.pull(familySpaceId: space);
      expect(pull.applied, greaterThanOrEqualTo(1));

      final viewed = await user.configure.findForFamily(
        actor: amparo,
        familySpaceId: space,
      );
      expect(viewed!.preferredName, 'Amparo Demo');
      expect(SupportedPersonProfile.homeGreeting(viewed), 'Hola, Amparo Demo');

      await caregiver.configure.setPreferredName(
        actor: elena,
        familySpaceId: space,
        preferredName: 'Amparo Ejemplo',
        idempotencyKey: IdempotencyKey('demo-profile-cross-correct'),
      );
      await caregiver.engine.pushPending();
      await user.engine.pull(familySpaceId: space);

      final corrected = await user.configure.findForFamily(
        actor: amparo,
        familySpaceId: space,
      );
      expect(corrected!.preferredName, 'Amparo Ejemplo');
    },
  );

  test('baseline ensure publishes Amparo Demo when authority empty', () {
    final authority = InMemorySyncAuthority();
    expect(
      LocalDemoFictionalBaseline.ensureSupportedPersonProfile(authority),
      isTrue,
    );
    expect(
      authority.hasSupportedPersonProfileRowsFor(
        IdentityFixtures.familiaEjemploSpaceId.value,
      ),
      isTrue,
    );
    expect(
      LocalDemoFictionalBaseline.ensureSupportedPersonProfile(authority),
      isFalse,
    );
  });
}

final class _ClientHarness {
  _ClientHarness({required SyncTransportPort transport})
    : store = InMemoryOfflineStore() {
    profiles = InMemorySupportedPersonProfileRepository(store);
    configure = ConfigureSupportedPersonProfile(profiles);
    bridge = OfflineSyncBridge(store);
    conflicts = InMemoryConflictStore();
    var conflictSeq = 0;
    engine = SyncEngine(
      outbox: store.outbox,
      transport: transport,
      conflicts: conflicts,
      payloadLoader: bridge,
      applyHandler: bridge,
      conflictIdFactory: () {
        conflictSeq += 1;
        final suffix = conflictSeq.toString().padLeft(2, '0');
        return '01932f00-0012-7000-8000-000000000c$suffix';
      },
    );
  }

  final InMemoryOfflineStore store;
  late final InMemorySupportedPersonProfileRepository profiles;
  late final ConfigureSupportedPersonProfile configure;
  late final OfflineSyncBridge bridge;
  late final InMemoryConflictStore conflicts;
  late final SyncEngine engine;
}
