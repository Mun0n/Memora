import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:user/demo_composition.dart';

void main() {
  const phoneSize = Size(390, 844);
  const tabletSize = Size(800, 1280);

  Future<UserDemoComposition> pumpUser(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
    bool seed = true,
    InMemoryOfflineStore? store,
    UserHomeDestination initialDestination = UserHomeDestination.home,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final composition = UserDemoComposition(
      store: store,
      networkAvailable: false,
    );
    if (seed) {
      await composition.seedDemoFixtures();
    }
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(initialDestination: initialDestination),
    );
    await tester.pumpAndSettle();
    return composition;
  }

  Future<void> expectLargeTargets(WidgetTester tester) async {
    final card = find.byKey(
      Key('memora-user-pastime-${OfflineFixtures.radioPastimeId.value}'),
    );
    expect(card, findsOneWidget);
    final size = tester.getSize(card);
    expect(size.height, greaterThanOrEqualTo(48));
  }

  for (final entry in <(String, Size, double)>[
    ('phone 1.0', phoneSize, 1.0),
    ('phone 1.5', phoneSize, 1.5),
    ('tablet 1.0', tabletSize, 1.0),
    ('tablet 1.5', tabletSize, 1.5),
  ]) {
    testWidgets('${entry.$1}: active cards, detail, nav, no overflow', (
      tester,
    ) async {
      await pumpUser(
        tester,
        size: entry.$2,
        textScale: entry.$3,
        initialDestination: UserHomeDestination.pasatiempos,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('memora-user-pasatiempos')), findsOneWidget);
      expect(find.text('Radio Demo'), findsOneWidget);
      expect(find.textContaining('Puzzle Ejemplo'), findsNothing);
      expect(find.textContaining('Fotos Ejemplo'), findsNothing);
      expect(find.textContaining('sincroniz'), findsNothing);
      expect(find.textContaining('Borrador'), findsNothing);
      expect(find.textContaining('complet'), findsNothing);
      expect(find.text(MemoraCopy.activatePastime), findsNothing);
      await expectLargeTargets(tester);

      await tester.tap(
        find.byKey(
          Key('memora-user-pastime-${OfflineFixtures.radioPastimeId.value}'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          Key(
            'memora-user-pastime-detail-'
            '${OfflineFixtures.radioPastimeId.value}',
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Escuchar la radio Ejemplo'), findsOneWidget);
      expect(find.textContaining('hecho'), findsNothing);
      expect(find.textContaining('completado'), findsNothing);

      await tester.tap(find.byKey(const Key('memora-user-pasatiempos-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('memora-user-pasatiempos')), findsOneWidget);

      await tester.tap(find.byKey(const Key('memora-user-return-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
      expect(find.text(MemoraCopy.homeTileMiDia), findsOneWidget);
      expect(find.text(MemoraCopy.homeTilePasatiempos), findsOneWidget);
      expect(find.text(MemoraCopy.homeTileQuieroHablar), findsOneWidget);
      expect(find.text(MemoraCopy.homeTileRecuerdos), findsOneWidget);
    });
  }

  testWidgets('empty state keeps honest copy and return home', (tester) async {
    await pumpUser(tester, size: phoneSize, seed: false);

    await tester.tap(
      find.byKey(const Key('memora-user-home-tile-pasatiempos')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('memora-user-pasatiempos-empty')),
      findsOneWidget,
    );
    expect(find.textContaining('aparecerán las actividades'), findsOneWidget);
    await tester.tap(find.byKey(const Key('memora-user-return-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
  });

  testWidgets('Quiero hablar shows active Demo topic cards', (tester) async {
    await pumpUser(tester, size: phoneSize);

    await tester.tap(
      find.byKey(const Key('memora-user-home-tile-quiero-hablar')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-quiero-hablar')), findsOneWidget);
    expect(find.text('El jardín Demo'), findsOneWidget);
    expect(find.textContaining('Cocina Ejemplo'), findsNothing);
    expect(find.textContaining('emergencia'), findsNothing);
  });

  testWidgets('default demo identifies isolated local pastimes', (
    tester,
  ) async {
    await pumpUser(
      tester,
      size: phoneSize,
      initialDestination: UserHomeDestination.pasatiempos,
    );

    expect(find.byKey(const Key('memora-isolated-local-demo')), findsOneWidget);
    expect(find.text(MemoraCopy.pasatiemposIsolatedDemoNotice), findsOneWidget);
    expect(find.textContaining('sincroniz'), findsNothing);
  });

  Future<InMemorySyncAuthority> pushThreeActivePastimes({
    required String keyPrefix,
  }) async {
    final authority = InMemorySyncAuthority();
    final caregiver = FakeSupabaseRemote.withAuthority(authority);
    final caregiverStore = InMemoryOfflineStore();
    final caregiverPastimes = InMemoryPastimeRepository(caregiverStore);
    final configure = ConfigurePastime(caregiverPastimes);
    final elena = IdentityFixtures.elenaPrimaryMembership;
    final space = IdentityFixtures.familiaEjemploSpaceId;
    final ids = <PastimeId>[
      OfflineFixtures.radioPastimeId,
      OfflineFixtures.draftPuzzlePastimeId,
      OfflineFixtures.archivedPhotosPastimeId,
    ];
    for (var i = 0; i < ids.length; i++) {
      await configure.create(
        actor: elena,
        id: ids[i],
        familySpaceId: space,
        title: 'Activo Demo $i',
        instruction: 'Indicación Ejemplo $i para la persona apoyada.',
        lifecycleStatus: PastimeLifecycleStatus.active,
        displayOrder: i,
        idempotencyKey: IdempotencyKey('$keyPrefix-create-$i'),
      );
    }
    final caregiverBridge = OfflineSyncBridge(caregiverStore);
    final caregiverEngine = SyncEngine(
      outbox: caregiverStore.outbox,
      transport: caregiver,
      conflicts: InMemoryConflictStore(),
      payloadLoader: caregiverBridge,
      applyHandler: caregiverBridge,
      conflictIdFactory: () => '01932f00-0008-7000-8000-000000000d01',
    );
    final push = await caregiverEngine.pushPending();
    expect(push.failed, 0);
    return authority;
  }

  testWidgets('quiet pull on startup refreshes active pastimes', (
    tester,
  ) async {
    tester.view.physicalSize = phoneSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authority = await pushThreeActivePastimes(keyPrefix: 'ui-cross');

    final composition = UserDemoComposition(
      remote: FakeSupabaseRemote.withAuthority(authority),
      sharedLocalDemoTransport: true,
    );
    await tester.pumpWidget(
      composition.buildApp(
        autoload: true,
        initialDestination: UserHomeDestination.pasatiempos,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Activo Demo 0'), findsOneWidget);
    expect(find.text('Activo Demo 1'), findsOneWidget);
    expect(find.text('Activo Demo 2'), findsOneWidget);
    expect(find.byKey(const Key('memora-isolated-local-demo')), findsNothing);
  });

  testWidgets(
    'real main.dart startup contract pulls remote active set without autoload',
    (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authority = await pushThreeActivePastimes(keyPrefix: 'ui-main');

      // Mirrors apps/user/lib/main.dart: load() then buildApp() (autoload false).
      final composition = UserDemoComposition(
        remote: FakeSupabaseRemote.withAuthority(authority),
        sharedLocalDemoTransport: true,
      );
      expect(composition.usesSharedLocalDemoTransport, isTrue);
      expect(composition.pastimeController.networkAvailable, isTrue);
      await composition.load();
      await tester.pumpWidget(
        composition.buildApp(
          initialDestination: UserHomeDestination.pasatiempos,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Activo Demo 0'), findsOneWidget);
      expect(find.text('Activo Demo 1'), findsOneWidget);
      expect(find.text('Activo Demo 2'), findsOneWidget);
    },
  );

  testWidgets(
    're-entering Pasatiempos quiet-pulls caregiver activate/reorder set',
    (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authority = InMemorySyncAuthority();
      LocalDemoFictionalBaseline.ensurePastimes(authority);
      final composition = UserDemoComposition(
        remote: FakeSupabaseRemote.withAuthority(authority),
        sharedLocalDemoTransport: true,
      );
      await composition.seedDemoFixtures();
      await composition.load();
      await tester.pumpWidget(composition.buildApp());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('memora-user-home-tile-pasatiempos')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Radio Demo'), findsOneWidget);

      await tester.tap(find.byKey(const Key('memora-user-return-home')));
      await tester.pumpAndSettle();

      // Caregiver activates/reorders on the shared authority after user started.
      final caregiver = FakeSupabaseRemote.withAuthority(authority);
      final caregiverStore = InMemoryOfflineStore();
      final caregiverPastimes = InMemoryPastimeRepository(caregiverStore);
      final configure = ConfigurePastime(caregiverPastimes);
      final elena = IdentityFixtures.elenaPrimaryMembership;
      final space = IdentityFixtures.familiaEjemploSpaceId;
      final caregiverBridge = OfflineSyncBridge(caregiverStore);
      final caregiverEngine = SyncEngine(
        outbox: caregiverStore.outbox,
        transport: caregiver,
        conflicts: InMemoryConflictStore(),
        payloadLoader: caregiverBridge,
        applyHandler: caregiverBridge,
        conflictIdFactory: () => '01932f00-0008-7000-8000-000000000d02',
      );
      await caregiverEngine.pull(familySpaceId: space);
      await configure.activate(
        actor: elena,
        id: OfflineFixtures.draftPuzzlePastimeId,
        idempotencyKey: IdempotencyKey('ui-reenter-activate-puzzle'),
      );
      await configure.activate(
        actor: elena,
        id: OfflineFixtures.archivedPhotosPastimeId,
        idempotencyKey: IdempotencyKey('ui-reenter-activate-photos'),
      );
      await configure.reorder(
        actor: elena,
        familySpaceId: space,
        orderedIds: [
          OfflineFixtures.draftPuzzlePastimeId,
          OfflineFixtures.archivedPhotosPastimeId,
          OfflineFixtures.radioPastimeId,
        ],
        idempotencyKey: IdempotencyKey('ui-reenter-reorder'),
      );
      final push = await caregiverEngine.pushPending();
      expect(push.failed, 0);

      await tester.tap(
        find.byKey(const Key('memora-user-home-tile-pasatiempos')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Puzzle Ejemplo'), findsOneWidget);
      expect(find.textContaining('Fotos Ejemplo'), findsOneWidget);
      expect(find.text('Radio Demo'), findsOneWidget);
      final y0 = tester.getTopLeft(find.text('Puzzle Ejemplo')).dy;
      final y1 = tester.getTopLeft(find.textContaining('Fotos Ejemplo')).dy;
      final y2 = tester.getTopLeft(find.text('Radio Demo')).dy;
      expect(y0, lessThan(y1));
      expect(y1, lessThan(y2));
    },
  );

  testWidgets('failed quiet pull keeps cached pastimes and home escape', (
    tester,
  ) async {
    tester.view.physicalSize = phoneSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final composition = UserDemoComposition(
      transport: _FailingDemoTransport(),
      sharedLocalDemoTransport: true,
    );
    await composition.seedDemoFixtures();
    // Shared mode skips private pastime seed; plant a local cache for offline proof.
    await composition.pastimes.save(
      pastime: OfflineFixtures.radioPastime,
      idempotencyKey: OfflineFixtures.radioPastimeSaveKey,
    );
    await composition.pastimeController.load();
    await tester.pumpWidget(
      composition.buildApp(
        autoload: true,
        initialDestination: UserHomeDestination.pasatiempos,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Radio Demo'), findsOneWidget);
    expect(
      find.byKey(const Key('memora-user-pasatiempos-shared-pull-failed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('memora-user-pasatiempos-pull-retry')),
      findsOneWidget,
    );
    expect(find.textContaining('aparecerán las actividades'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('memora-user-return-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
    expect(find.text(MemoraCopy.homeTilePasatiempos), findsOneWidget);
  });

  testWidgets(
    'failed quiet pull on Pasatiempos entry retains cache and home escape',
    (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final composition = UserDemoComposition(
        transport: _FailingDemoTransport(),
        sharedLocalDemoTransport: true,
      );
      await composition.seedDemoFixtures();
      await composition.pastimes.save(
        pastime: OfflineFixtures.radioPastime,
        idempotencyKey: OfflineFixtures.radioPastimeSaveKey,
      );
      await composition.load();
      await tester.pumpWidget(composition.buildApp());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('memora-user-home-tile-pasatiempos')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Radio Demo'), findsOneWidget);
      expect(
        find.byKey(const Key('memora-user-pasatiempos-shared-pull-failed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('memora-user-pasatiempos-pull-retry')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('memora-user-return-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
      expect(find.text(MemoraCopy.homeTilePasatiempos), findsOneWidget);
    },
  );

  testWidgets(
    'unreachable shared transport shows retry; successful retry refreshes order',
    (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authority = InMemorySyncAuthority();
      LocalDemoFictionalBaseline.ensurePastimes(authority);
      final transport = _ToggleableDemoTransport(
        FakeSupabaseRemote.withAuthority(authority),
      );
      transport.failing = true;

      final composition = UserDemoComposition(
        transport: transport,
        sharedLocalDemoTransport: true,
      );
      await composition.seedDemoFixtures();
      await composition.pastimes.save(
        pastime: OfflineFixtures.radioPastime,
        idempotencyKey: OfflineFixtures.radioPastimeSaveKey,
      );
      await composition.load();
      await tester.pumpWidget(composition.buildApp());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('memora-user-home-tile-pasatiempos')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Radio Demo'), findsOneWidget);
      expect(
        find.byKey(const Key('memora-user-pasatiempos-shared-pull-failed')),
        findsOneWidget,
      );
      expect(find.text('Puzzle Ejemplo'), findsNothing);

      // Caregiver activates/reorders while user transport is still down.
      final caregiver = FakeSupabaseRemote.withAuthority(authority);
      final caregiverStore = InMemoryOfflineStore();
      final caregiverPastimes = InMemoryPastimeRepository(caregiverStore);
      final configure = ConfigurePastime(caregiverPastimes);
      final elena = IdentityFixtures.elenaPrimaryMembership;
      final space = IdentityFixtures.familiaEjemploSpaceId;
      final caregiverBridge = OfflineSyncBridge(caregiverStore);
      final caregiverEngine = SyncEngine(
        outbox: caregiverStore.outbox,
        transport: caregiver,
        conflicts: InMemoryConflictStore(),
        payloadLoader: caregiverBridge,
        applyHandler: caregiverBridge,
        conflictIdFactory: () => '01932f00-0008-7000-8000-000000000d03',
      );
      await caregiverEngine.pull(familySpaceId: space);
      await configure.activate(
        actor: elena,
        id: OfflineFixtures.draftPuzzlePastimeId,
        idempotencyKey: IdempotencyKey('ui-retry-activate-puzzle'),
      );
      await configure.activate(
        actor: elena,
        id: OfflineFixtures.archivedPhotosPastimeId,
        idempotencyKey: IdempotencyKey('ui-retry-activate-photos'),
      );
      await configure.reorder(
        actor: elena,
        familySpaceId: space,
        orderedIds: [
          OfflineFixtures.draftPuzzlePastimeId,
          OfflineFixtures.archivedPhotosPastimeId,
          OfflineFixtures.radioPastimeId,
        ],
        idempotencyKey: IdempotencyKey('ui-retry-reorder'),
      );
      final push = await caregiverEngine.pushPending();
      expect(push.failed, 0);

      transport.failing = false;
      await tester.tap(
        find.byKey(const Key('memora-user-pasatiempos-pull-retry')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('memora-user-pasatiempos-shared-pull-failed')),
        findsNothing,
      );
      expect(find.text('Puzzle Ejemplo'), findsOneWidget);
      expect(find.textContaining('Fotos Ejemplo'), findsOneWidget);
      expect(find.text('Radio Demo'), findsOneWidget);
      final y0 = tester.getTopLeft(find.text('Puzzle Ejemplo')).dy;
      final y1 = tester.getTopLeft(find.textContaining('Fotos Ejemplo')).dy;
      final y2 = tester.getTopLeft(find.text('Radio Demo')).dy;
      expect(y0, lessThan(y1));
      expect(y1, lessThan(y2));
    },
  );

  testWidgets(
    'failed shared pull with empty cache does not claim family list is empty',
    (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final composition = UserDemoComposition(
        transport: _FailingDemoTransport(),
        sharedLocalDemoTransport: true,
      );
      await composition.seedDemoFixtures();
      await composition.load();
      await tester.pumpWidget(
        composition.buildApp(
          initialDestination: UserHomeDestination.pasatiempos,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('memora-user-pasatiempos-shared-pull-failed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('memora-user-pasatiempos-pull-retry')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('memora-user-pasatiempos-empty')),
        findsNothing,
      );
      expect(find.textContaining('aparecerán las actividades'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('memora-user-return-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('memora-user-home')), findsOneWidget);
    },
  );

  testWidgets('shared mode reconciles authority without private pastime seed', (
    tester,
  ) async {
    tester.view.physicalSize = phoneSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authority = InMemorySyncAuthority();
    LocalDemoFictionalBaseline.ensurePastimes(authority);
    final composition = UserDemoComposition(
      remote: FakeSupabaseRemote.withAuthority(authority),
      sharedLocalDemoTransport: true,
    );
    await composition.seedDemoFixtures();
    expect(
      await composition.pastimes.listForFamily(
        IdentityFixtures.familiaEjemploSpaceId,
      ),
      isEmpty,
    );
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(initialDestination: UserHomeDestination.pasatiempos),
    );
    await tester.pumpAndSettle();

    expect(find.text('Radio Demo'), findsOneWidget);
    expect(find.textContaining('Puzzle Ejemplo'), findsNothing);
    expect(find.byKey(const Key('memora-isolated-local-demo')), findsNothing);
  });
}

final class _FailingDemoTransport implements SyncTransportPort {
  @override
  Future<PushResult> push(SyncEnvelope envelope) async {
    return PushResult.failed('demo_network_unavailable');
  }

  @override
  Future<List<RemoteRecord>> pull({
    required FamilySpaceId familySpaceId,
    int? afterCursor,
  }) async {
    throw StateError('demo_network_unavailable');
  }
}

/// Shared-demo transport that can fail then recover for retry chrome proofs.
final class _ToggleableDemoTransport implements SyncTransportPort {
  _ToggleableDemoTransport(this._delegate);

  final SyncTransportPort _delegate;
  bool failing = false;

  @override
  Future<PushResult> push(SyncEnvelope envelope) async {
    if (failing) {
      return PushResult.failed('demo_network_unavailable');
    }
    return _delegate.push(envelope);
  }

  @override
  Future<List<RemoteRecord>> pull({
    required FamilySpaceId familySpaceId,
    int? afterCursor,
  }) async {
    if (failing) {
      throw StateError('demo_network_unavailable');
    }
    return _delegate.pull(
      familySpaceId: familySpaceId,
      afterCursor: afterCursor,
    );
  }
}
