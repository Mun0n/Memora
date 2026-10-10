import 'package:domain/domain.dart';
import 'package:test/test.dart';

final class _StubMemories implements MemoryRepository {
  final Map<String, MemoryEntry> _items = <String, MemoryEntry>{};

  @override
  Future<MemoryEntry> save({
    required MemoryEntry memory,
    required IdempotencyKey idempotencyKey,
  }) async {
    final pending = memory.copyWith(syncState: SyncState.pending);
    _items[pending.id.value] = pending;
    return pending;
  }

  @override
  Future<MemoryEntry?> findById(MemoryId id) async => _items[id.value];

  @override
  Future<List<MemoryEntry>> listForFamily(FamilySpaceId familySpaceId) async {
    final listed = _items.values
        .where((m) => m.familySpaceId == familySpaceId)
        .toList();
    listed.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return listed;
  }

  @override
  Future<List<MemoryEntry>> listApprovedForFamily(
    FamilySpaceId familySpaceId,
  ) async {
    final listed = _items.values
        .where(
          (m) => m.familySpaceId == familySpaceId && m.isApprovedForViewing,
        )
        .toList();
    listed.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return listed;
  }

  @override
  Future<MemoryEntry> softDelete({
    required MemoryId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('MemoryCarePolicy', () {
    test('distinguishes manage, contribute and approved view', () {
      expect(
        MemoryCarePolicy.canManageMemories(
          IdentityFixtures.elenaPrimaryMembership,
        ),
        isTrue,
      );
      expect(
        MemoryCarePolicy.canManageMemories(
          IdentityFixtures.carlosCaregiverMembership,
        ),
        isTrue,
      );
      expect(
        MemoryCarePolicy.canManageMemories(
          IdentityFixtures.luciaContributorMembership,
        ),
        isFalse,
      );
      expect(
        MemoryCarePolicy.canContributeMemories(
          IdentityFixtures.luciaContributorMembership,
        ),
        isTrue,
      );
      expect(
        MemoryCarePolicy.canContributeMemories(
          IdentityFixtures.elenaPrimaryMembership,
        ),
        isFalse,
      );
      expect(
        MemoryCarePolicy.canViewApprovedMemories(
          IdentityFixtures.amparoSupportedMembership,
        ),
        isTrue,
      );
      expect(
        MemoryCarePolicy.canManageMemories(
          IdentityFixtures.invitedCaregiverMembership,
        ),
        isFalse,
      );
      expect(
        MemoryCarePolicy.canContributeMemories(
          IdentityFixtures.revokedContributorMembership,
        ),
        isFalse,
      );
    });
  });

  group('ManageMemory', () {
    late _StubMemories store;
    late ManageMemory manage;

    setUp(() {
      store = _StubMemories();
      manage = ManageMemory(store);
    });

    test(
      'manager creates, edits, orders, approves and archives; contributor proposes',
      () async {
        final elena = IdentityFixtures.elenaPrimaryMembership;
        final created = await manage.create(
          actor: elena,
          id: OfflineFixtures.gardenMemoryId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          caption: 'Jardín Ejemplo',
          dateContext: 'Octubre 2026 Demo',
          displayOrder: 0,
          media: OfflineFixtures.gardenMediaMetadata,
          idempotencyKey: OfflineFixtures.gardenMemorySaveKey,
        );
        expect(created.lifecycleStatus, MemoryLifecycleStatus.approved);
        expect(created.isApprovedForViewing, isTrue);
        expect(created.media!.checksum, OfflineFixtures.gardenMediaChecksum);

        final proposed = await manage.contribute(
          actor: IdentityFixtures.luciaContributorMembership,
          id: OfflineFixtures.proposedPatioMemoryId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          caption: 'Patio Ejemplo (propuesta)',
          dateContext: 'Septiembre 2026 Demo',
          displayOrder: 1,
          idempotencyKey: IdempotencyKey('demo-memory-contribute'),
        );
        expect(proposed.lifecycleStatus, MemoryLifecycleStatus.proposed);
        expect(proposed.isApprovedForViewing, isFalse);

        final approved = await manage.approve(
          actor: elena,
          id: OfflineFixtures.proposedPatioMemoryId,
          idempotencyKey: IdempotencyKey('demo-memory-approve'),
        );
        expect(approved.lifecycleStatus, MemoryLifecycleStatus.approved);

        final reordered = await manage.reorder(
          actor: elena,
          id: OfflineFixtures.proposedPatioMemoryId,
          displayOrder: 0,
          idempotencyKey: IdempotencyKey('demo-memory-reorder'),
        );
        expect(reordered.displayOrder, 0);

        final archived = await manage.archive(
          actor: elena,
          id: OfflineFixtures.gardenMemoryId,
          idempotencyKey: IdempotencyKey('demo-memory-archive'),
        );
        expect(archived.lifecycleStatus, MemoryLifecycleStatus.archived);
        expect(archived.isApprovedForViewing, isFalse);

        final viewing = await manage.listApprovedForViewing(
          actor: IdentityFixtures.amparoSupportedMembership,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        );
        expect(viewing.map((m) => m.id), [
          OfflineFixtures.proposedPatioMemoryId,
        ]);
      },
    );

    test('contributor cannot manage; supported cannot contribute', () async {
      await manage.create(
        actor: IdentityFixtures.elenaPrimaryMembership,
        id: OfflineFixtures.gardenMemoryId,
        familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        caption: 'Jardín Ejemplo',
        dateContext: 'Octubre 2026 Demo',
        displayOrder: 0,
        idempotencyKey: OfflineFixtures.gardenMemorySaveKey,
      );

      await expectLater(
        manage.edit(
          actor: IdentityFixtures.luciaContributorMembership,
          id: OfflineFixtures.gardenMemoryId,
          caption: 'Hack Demo',
          idempotencyKey: IdempotencyKey('demo-contributor-edit-denied'),
        ),
        throwsA(isA<UnauthorizedCareActionException>()),
      );
      await expectLater(
        manage.approve(
          actor: IdentityFixtures.luciaContributorMembership,
          id: OfflineFixtures.gardenMemoryId,
          idempotencyKey: IdempotencyKey('demo-contributor-approve-denied'),
        ),
        throwsA(isA<UnauthorizedCareActionException>()),
      );
      await expectLater(
        manage.contribute(
          actor: IdentityFixtures.amparoSupportedMembership,
          id: OfflineFixtures.proposedPatioMemoryId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          caption: 'Denied Demo',
          dateContext: '2026 Demo',
          displayOrder: 0,
          idempotencyKey: IdempotencyKey('demo-supported-contribute-denied'),
        ),
        throwsA(isA<UnauthorizedCareActionException>()),
      );
    });

    test('failed media retries to pending without dropping caption', () async {
      await store.save(
        memory: OfflineFixtures.gardenMemory.copyWith(
          media: OfflineFixtures.gardenMediaFailed,
        ),
        idempotencyKey: OfflineFixtures.gardenMemorySaveKey,
      );

      final retried = await manage.retryFailedMedia(
        actor: IdentityFixtures.elenaPrimaryMembership,
        id: OfflineFixtures.gardenMemoryId,
        idempotencyKey: IdempotencyKey('demo-media-retry'),
      );
      expect(retried.caption, 'Jardín Ejemplo');
      expect(retried.media!.uploadState, SyncState.pending);
      expect(retried.hasFailedMedia, isFalse);
    });

    test('media path must be family-scoped', () {
      expect(
        () => MemoryMediaMetadata(
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          familyScopedPath: 'other-space/memories/x.jpg',
          checksum: 'sha256:demo',
          uploadState: SyncState.local,
        ),
        throwsArgumentError,
      );
    });
  });
}
