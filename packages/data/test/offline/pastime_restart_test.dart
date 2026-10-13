import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'pastime create/edit/archive survive snapshot restart with idempotent outbox',
    () async {
      final live = InMemoryOfflineStore();
      final pastimes = InMemoryPastimeRepository(live);
      final configure = ConfigurePastime(pastimes);
      final elena = IdentityFixtures.elenaPrimaryMembership;

      await configure.create(
        actor: elena,
        id: OfflineFixtures.radioPastimeId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        title: OfflineFixtures.radioPastime.title,
        instruction: OfflineFixtures.radioPastime.instruction,
        lifecycleStatus: PastimeLifecycleStatus.active,
        idempotencyKey: OfflineFixtures.radioPastimeSaveKey,
      );
      await configure.create(
        actor: elena,
        id: OfflineFixtures.draftPuzzlePastimeId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        title: OfflineFixtures.draftPuzzlePastime.title,
        instruction: OfflineFixtures.draftPuzzlePastime.instruction,
        idempotencyKey: IdempotencyKey('demo-pastime-draft-save'),
      );
      await configure.edit(
        actor: elena,
        id: OfflineFixtures.radioPastimeId,
        title: 'Radio Familiar Demo',
        idempotencyKey: IdempotencyKey('demo-pastime-edit-save'),
      );
      await configure.archive(
        actor: elena,
        id: OfflineFixtures.draftPuzzlePastimeId,
        idempotencyKey: IdempotencyKey('demo-pastime-archive-save'),
      );

      final pendingBefore = await live.outbox.listPending();
      expect(pendingBefore, isNotEmpty);
      expect(
        pendingBefore.every(
          (op) => op.aggregateType == OutboxAggregateType.pastime,
        ),
        isTrue,
      );
      final keys = pendingBefore.map((op) => op.idempotencyKey.value).toSet();
      expect(keys.length, pendingBefore.length);

      final snapshot = live.capture();
      final restored = InMemoryOfflineStore.fromSnapshot(snapshot);
      final restoredRepo = InMemoryPastimeRepository(restored);
      final restoredConfigure = ConfigurePastime(restoredRepo);

      final radio = await restoredRepo.findById(OfflineFixtures.radioPastimeId);
      expect(radio, isNotNull);
      expect(radio!.title, 'Radio Familiar Demo');
      expect(radio.lifecycleStatus, PastimeLifecycleStatus.active);
      expect(radio.syncState, SyncState.pending);

      final draft = await restoredRepo.findById(
        OfflineFixtures.draftPuzzlePastimeId,
      );
      expect(draft!.lifecycleStatus, PastimeLifecycleStatus.archived);

      final active = await restoredConfigure.listActiveForViewing(
        actor: IdentityFixtures.amparoSupportedMembership,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
      );
      expect(active.map((p) => p.id), [OfflineFixtures.radioPastimeId]);

      final pendingAfter = await restored.outbox.listPending();
      expect(pendingAfter.length, pendingBefore.length);
      expect(pendingAfter.map((op) => op.idempotencyKey.value).toSet(), keys);

      // Fake remote converge: push pending envelopes then mark synced.
      final bridge = OfflineSyncBridge(restored);
      final remote = FakeSupabaseRemote();
      var conflictSeq = 0;
      final engine = SyncEngine(
        outbox: restored.outbox,
        transport: remote,
        conflicts: InMemoryConflictStore(),
        payloadLoader: bridge,
        applyHandler: bridge,
        conflictIdFactory: () {
          conflictSeq += 1;
          final suffix = conflictSeq.toString().padLeft(2, '0');
          return '01932f00-0008-7000-8000-0000000009$suffix';
        },
      );
      final summary = await engine.pushPending();
      expect(summary.failed, 0);
      expect(summary.conflicted, 0);
      expect(summary.applied + summary.duplicates, greaterThan(0));

      final synced = await restoredRepo.findById(
        OfflineFixtures.radioPastimeId,
      );
      expect(synced!.syncState, SyncState.synced);
    },
  );

  test(
    'soft delete writes tombstone without dropping pastime fields',
    () async {
      final store = InMemoryOfflineStore();
      final pastimes = InMemoryPastimeRepository(store);
      await pastimes.save(
        pastime: OfflineFixtures.radioPastime,
        idempotencyKey: OfflineFixtures.radioPastimeSaveKey,
      );

      final deleted = await pastimes.softDelete(
        id: OfflineFixtures.radioPastimeId,
        baseVersion: AggregateVersion.initial,
        deletedAt: OfflineFixtures.demoRecordedAt,
        idempotencyKey: IdempotencyKey('demo-pastime-delete'),
        deletedBy: IdentityFixtures.elenaPrimaryUserId,
      );
      expect(deleted.isDeleted, isTrue);
      expect(deleted.title, OfflineFixtures.radioPastime.title);
      expect(deleted.tombstone!.deletedBy, IdentityFixtures.elenaPrimaryUserId);
      expect(deleted.isActiveForViewing, isFalse);
    },
  );
}
