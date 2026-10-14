import 'dart:io';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:family_web/demo_composition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:ui/ui.dart';

void main() {
  const narrowSize = Size(390, 844);

  Future<FamilyWebDemoComposition> pumpPastimes(
    WidgetTester tester, {
    FamilyMembership? actor,
    bool seed = true,
  }) async {
    tester.view.physicalSize = narrowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final composition = FamilyWebDemoComposition(
      actor: actor ?? IdentityFixtures.elenaPrimaryMembership,
      networkAvailable: false,
    );
    if (seed) {
      await composition.seedDemoFixtures();
    }
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(initialSection: FeatureSection.pastimes),
    );
    await tester.pumpAndSettle();
    return composition;
  }

  testWidgets('caregiver creates and edits a Demo pastime', (tester) async {
    await pumpPastimes(tester, seed: false);

    expect(find.byKey(const Key('memora-nav-pastimes')), findsOneWidget);
    expect(
      find.byKey(const Key('memora-family-pastime-editor')),
      findsOneWidget,
    );

    final title = find.byKey(const Key('memora-family-pastime-title'));
    final instruction = find.byKey(
      const Key('memora-family-pastime-instruction'),
    );
    final save = find.byKey(const Key('memora-family-save-pastime'));

    await tester.ensureVisible(title);
    await tester.enterText(title, 'Lectura Demo');
    await tester.ensureVisible(instruction);
    await tester.enterText(instruction, 'Leer un cuento Ejemplo en voz baja.');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.textContaining('Lectura Demo'), findsWidgets);
    expect(find.textContaining('Borrador'), findsWidgets);

    final edit = find.text(MemoraCopy.editPastime).first;
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();

    await tester.ensureVisible(title);
    await tester.enterText(title, 'Lectura editada Demo');
    await tester.ensureVisible(instruction);
    await tester.enterText(instruction, 'Leer un poema Ejemplo con calma.');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.textContaining('Lectura editada Demo'), findsWidgets);
    expect(find.textContaining('poema Ejemplo'), findsWidgets);
  });

  testWidgets('caregiver reorders, activates and archives seeded pastimes', (
    tester,
  ) async {
    final composition = await pumpPastimes(tester);

    expect(find.textContaining('Radio Demo'), findsWidgets);
    expect(find.textContaining('Puzzle Ejemplo'), findsWidgets);
    expect(find.textContaining('Fotos Ejemplo'), findsWidgets);

    final radioDown = find.byKey(
      Key('memora-family-pastime-down-${OfflineFixtures.radioPastimeId.value}'),
    );
    await tester.ensureVisible(radioDown);
    await tester.tap(radioDown);
    await tester.pumpAndSettle();

    final listed = await composition.pastimes.listForFamily(
      IdentityFixtures.familiaEjemploSpaceId,
    );
    final live = listed.where((p) => !p.isDeleted).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    expect(live.first.id, OfflineFixtures.draftPuzzlePastimeId);

    final activatePuzzle = find.byKey(
      Key(
        'memora-family-activate-pastime-'
        '${OfflineFixtures.draftPuzzlePastimeId.value}',
      ),
    );
    await tester.ensureVisible(activatePuzzle);
    await tester.tap(activatePuzzle);
    await tester.pumpAndSettle();

    final archiveRadio = find.byKey(
      Key(
        'memora-family-archive-pastime-'
        '${OfflineFixtures.radioPastimeId.value}',
      ),
    );
    await tester.ensureVisible(archiveRadio);
    await tester.tap(archiveRadio);
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        Key(
          'memora-family-activate-pastime-'
          '${OfflineFixtures.radioPastimeId.value}',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('invalid input preserves draft fields', (tester) async {
    await pumpPastimes(tester, seed: false);

    final title = find.byKey(const Key('memora-family-pastime-title'));
    final save = find.byKey(const Key('memora-family-save-pastime'));
    await tester.ensureVisible(title);
    await tester.enterText(title, 'Título Demo válido');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('memora-family-pastime-error')),
      findsOneWidget,
    );
    expect(find.text(MemoraCopy.pastimesValidationError), findsOneWidget);
    expect(find.text('Título Demo válido'), findsOneWidget);
  });

  testWidgets('contributor cannot configure pastimes', (tester) async {
    await pumpPastimes(
      tester,
      actor: IdentityFixtures.luciaContributorMembership,
      seed: true,
    );

    expect(find.byKey(const Key('memora-family-pastime-editor')), findsNothing);
    expect(find.byKey(const Key('memora-family-begin-pastime')), findsNothing);
    expect(find.text(MemoraCopy.editPastime), findsNothing);
    expect(find.text(MemoraCopy.activatePastime), findsNothing);
    expect(find.byKey(const Key('memora-family-save-pastime')), findsNothing);
  });

  testWidgets('default product chrome hides isolated transport notices', (
    tester,
  ) async {
    await pumpPastimes(tester);

    expect(find.byKey(const Key('memora-isolated-local-demo')), findsNothing);
    expect(find.text(MemoraCopy.isolatedLocalDemoNotice), findsNothing);
    expect(find.byKey(const Key('memora-shared-local-demo')), findsNothing);
    expect(find.byKey(const Key('memora-sync-status')), findsNothing);
    expect(find.text(MemoraCopy.demoBanner), findsNothing);
  });

  testWidgets('shared demo auto-pushes pastime activate without Sync chrome', (
    tester,
  ) async {
    tester.view.physicalSize = narrowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authority = InMemorySyncAuthority();
    LocalDemoFictionalBaseline.ensurePastimes(authority);
    final remote = FakeSupabaseRemote.withAuthority(authority);
    final composition = FamilyWebDemoComposition(
      remote: remote,
      sharedLocalDemoTransport: true,
      networkAvailable: true,
    );
    await composition.seedDemoFixtures();
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(initialSection: FeatureSection.pastimes),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('memora-shared-local-demo')), findsNothing);
    expect(find.text(MemoraCopy.sharedLocalDemoNotice), findsNothing);
    expect(find.textContaining('Radio Demo'), findsWidgets);
    expect(find.textContaining('Puzzle Ejemplo'), findsWidgets);

    final activatePuzzle = find.byKey(
      Key(
        'memora-family-activate-pastime-'
        '${OfflineFixtures.draftPuzzlePastimeId.value}',
      ),
    );
    await tester.ensureVisible(activatePuzzle);
    await tester.tap(activatePuzzle);
    await tester.pumpAndSettle();

    final records = await remote.pull(
      familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    );
    expect(
      records.any(
        (record) =>
            record.aggregateId == OfflineFixtures.draftPuzzlePastimeId.value &&
            record.payload['lifecycle'] == 'active',
      ),
      isTrue,
    );
    // Normal pastime configure must not require the Sync section controls.
    expect(find.byKey(const Key('memora-sync-push')), findsNothing);
  });

  testWidgets(
    'shared mode skips private pastime seed and reconciles from authority',
    (tester) async {
      tester.view.physicalSize = narrowSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authority = InMemorySyncAuthority();
      LocalDemoFictionalBaseline.ensurePastimes(authority);
      final remote = FakeSupabaseRemote.withAuthority(authority);
      final composition = FamilyWebDemoComposition(
        remote: remote,
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
        composition.buildApp(initialSection: FeatureSection.pastimes),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Radio Demo'), findsWidgets);
      expect(find.textContaining('Puzzle Ejemplo'), findsWidgets);
      expect(find.byKey(const Key('memora-isolated-local-demo')), findsNothing);
    },
  );

  testWidgets('entering Pasatiempos quiet-pulls shared authority updates', (
    tester,
  ) async {
    tester.view.physicalSize = narrowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authority = InMemorySyncAuthority();
    LocalDemoFictionalBaseline.ensurePastimes(authority);
    final remote = FakeSupabaseRemote.withAuthority(authority);
    final composition = FamilyWebDemoComposition(
      remote: remote,
      sharedLocalDemoTransport: true,
    );
    await composition.seedDemoFixtures();
    await composition.load();
    await tester.pumpWidget(
      composition.buildApp(initialSection: FeatureSection.routines),
    );
    await tester.pumpAndSettle();

    // Peer mutates shared authority while this web client shows Routines.
    final peerStore = InMemoryOfflineStore();
    final peerPastimes = InMemoryPastimeRepository(peerStore);
    final peerBridge = OfflineSyncBridge(peerStore);
    final peerTransport = FakeSupabaseRemote.withAuthority(authority);
    final peerEngine = SyncEngine(
      outbox: peerStore.outbox,
      transport: peerTransport,
      conflicts: InMemoryConflictStore(),
      payloadLoader: peerBridge,
      applyHandler: peerBridge,
      conflictIdFactory: () => '01932f00-0008-7000-8000-000000000e01',
    );
    await peerEngine.pull(
      familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
    );
    await ConfigurePastime(peerPastimes).activate(
      actor: IdentityFixtures.elenaPrimaryMembership,
      id: OfflineFixtures.draftPuzzlePastimeId,
      idempotencyKey: IdempotencyKey('web-section-activate-puzzle'),
    );
    final push = await peerEngine.pushPending();
    expect(push.failed, 0);

    await tester.tap(find.byKey(const Key('memora-nav-pastimes')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        Key(
          'memora-family-pastime-'
          '${OfflineFixtures.draftPuzzlePastimeId.value}',
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('(Activo)'), findsWidgets);
  });

  testWidgets(
    'HTTP shared activate succeeds; push failure shows delivery retry',
    (tester) async {
      tester.view.physicalSize = narrowSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Real loopback HTTP via composition roots (not FakeSupabaseRemote).
      // Snapshot-file durability stays in data-layer proofs — flutter_test +
      // snapshot rename can hang; in-memory authority is enough for UI HTTP.
      final harness = await tester.runAsync(() async {
        final server = await LocalDemoSyncServer.bind(
          host: '127.0.0.1',
          port: 0,
          ensureFictionalBaselineWhenEmpty: true,
        );
        final httpClient = _TimeoutHttpClient(
          timeout: const Duration(milliseconds: 400),
        );
        final transport = LocalDemoSyncTransport(
          baseUrl: server.baseUrl,
          httpClient: httpClient,
        );
        final composition = FamilyWebDemoComposition(
          transport: transport,
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

        await composition.pastimeController.activate(
          OfflineFixtures.draftPuzzlePastimeId,
        );
        final afterActivate = await transport.pull(
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        );
        expect(
          afterActivate.any(
            (record) =>
                record.aggregateId ==
                    OfflineFixtures.draftPuzzlePastimeId.value &&
                record.payload['lifecycle'] == 'active',
          ),
          isTrue,
        );
        expect(composition.pastimeController.sharedDeliveryFailed, isFalse);

        await server.close();

        await composition.pastimeController.archive(
          OfflineFixtures.radioPastimeId,
        );
        expect(composition.pastimeController.sharedDeliveryFailed, isTrue);
        expect(
          composition.pastimeController.errorMessage,
          MemoraCopy.sharedLocalDemoDeliveryFailed,
        );

        transport.close();
        httpClient.close();
        return composition;
      });
      final composition = harness!;

      await tester.pumpWidget(
        composition.buildApp(
          autoload: false,
          initialSection: FeatureSection.pastimes,
        ),
      );
      await tester.pump();

      expect(find.textContaining('Puzzle Ejemplo'), findsWidgets);
      expect(
        find.byKey(const Key('memora-family-pastime-shared-delivery-failed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('memora-family-pastime-delivery-retry')),
        findsOneWidget,
      );
      expect(find.text(MemoraCopy.sharedLocalDemoDeliveryFailed), findsWidgets);
      expect(
        find.byKey(
          Key(
            'memora-family-activate-pastime-'
            '${OfflineFixtures.radioPastimeId.value}',
          ),
        ),
        findsOneWidget,
      );
    },
  );
}

/// Real loopback HTTP under flutter_test (binding stubs default HttpClient→400).
final class _TimeoutHttpClient extends http.BaseClient {
  _TimeoutHttpClient({required this.timeout}) : _inner = _createRealIoClient();

  final Duration timeout;
  final http.Client _inner;

  static http.Client _createRealIoClient() {
    final previous = HttpOverrides.current;
    HttpOverrides.global = null;
    try {
      return IOClient(HttpClient());
    } finally {
      HttpOverrides.global = previous;
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request).timeout(timeout);
  }

  @override
  void close() => _inner.close();
}
