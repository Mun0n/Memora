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

  test(
    'web-configured fictional Amparo reaches independent user store via shared authority',
    () async {
      final caregiver = _ClientHarness(transport: caregiverTransport);
      final user = _ClientHarness(transport: userTransport);
      final elena = IdentityFixtures.elenaPrimaryMembership;
      final amparo = IdentityFixtures.amparoSupportedMembership;
      final space = IdentityFixtures.familiaEjemploSpaceId;

      // Authority baseline starts as Amparo Demo; caregiver web corrects to Amparo.
      await LocalDemoSharedBootstrap.reconcileFromAuthority(
        engine: caregiver.engine,
        transport: caregiverTransport,
      );
      final baseline = await caregiver.configure.findForFamily(
        actor: elena,
        familySpaceId: space,
      );
      expect(baseline!.preferredName, 'Amparo Demo');

      await caregiver.configure.setPreferredName(
        actor: elena,
        familySpaceId: space,
        preferredName: 'Amparo',
        idempotencyKey: IdempotencyKey('demo-profile-web-amparo'),
      );
      final push = await caregiver.engine.pushPending();
      expect(push.failed, 0);
      expect(push.conflicted, 0);

      // User app path: bootstrap + pull through LocalDemoSharedBootstrap.
      final pull = await LocalDemoSharedBootstrap.reconcileFromAuthority(
        engine: user.engine,
        transport: userTransport,
      );
      expect(pull.applied, greaterThanOrEqualTo(1));

      final viewed = await user.configure.findForFamily(
        actor: amparo,
        familySpaceId: space,
      );
      expect(viewed!.preferredName, 'Amparo');
      expect(SupportedPersonProfile.homeGreeting(viewed), 'Hola, Amparo');
    },
  );

  test('unreachable shared authority keeps cached preferred name', () async {
    final caregiver = _ClientHarness(transport: caregiverTransport);
    final user = _ClientHarness(transport: userTransport);
    final elena = IdentityFixtures.elenaPrimaryMembership;
    final amparo = IdentityFixtures.amparoSupportedMembership;
    final space = IdentityFixtures.familiaEjemploSpaceId;

    await caregiver.configure.setPreferredName(
      actor: elena,
      familySpaceId: space,
      preferredName: 'Amparo',
      id: OfflineFixtures.amparoPreferredNameProfileId,
      idempotencyKey: IdempotencyKey('demo-profile-cache-amparo'),
    );
    await caregiver.engine.pushPending();
    await LocalDemoSharedBootstrap.reconcileFromAuthority(
      engine: user.engine,
      transport: userTransport,
    );
    final cached = await user.configure.findForFamily(
      actor: amparo,
      familySpaceId: space,
    );
    expect(cached!.preferredName, 'Amparo');

    // Dead loopback authority on a fresh port; keep the setUp server for tearDown.
    final ghost = await LocalDemoSyncServer.bind(host: '127.0.0.1', port: 0);
    final ghostUrl = ghost.baseUrl;
    await ghost.close();
    final deadTransport = LocalDemoSyncTransport(baseUrl: ghostUrl);
    addTearDown(deadTransport.close);
    final deadEngine = SyncEngine(
      outbox: user.store.outbox,
      transport: deadTransport,
      conflicts: user.conflicts,
      payloadLoader: user.bridge,
      applyHandler: user.bridge,
      conflictIdFactory: () => '01932f00-0012-7000-8000-000000000c99',
    );

    // Failed reconcile must not invent baseline Amparo Demo or clear cache.
    await expectLater(
      LocalDemoSharedBootstrap.reconcileFromAuthority(
        engine: deadEngine,
        transport: deadTransport,
      ),
      throwsA(anything),
    );

    final stillCached = await user.configure.findForFamily(
      actor: amparo,
      familySpaceId: space,
    );
    expect(stillCached!.preferredName, 'Amparo');
    expect(SupportedPersonProfile.homeGreeting(stillCached), 'Hola, Amparo');
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
