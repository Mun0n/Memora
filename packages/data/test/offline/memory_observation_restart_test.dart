import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'restart restores memories, media upload state and observation corrections',
    () async {
      final live = InMemoryOfflineStore();
      final memories = InMemoryMemoryRepository(live);
      final weights = InMemoryWeightObservationRepository(live);
      final bloodPressures = InMemoryBloodPressureObservationRepository(live);

      await memories.save(
        memory: OfflineFixtures.gardenMemory.copyWith(
          media: OfflineFixtures.gardenMediaFailed,
        ),
        idempotencyKey: OfflineFixtures.gardenMemorySaveKey,
      );
      await memories.save(
        memory: OfflineFixtures.proposedPatioMemory,
        idempotencyKey: IdempotencyKey('demo-memory-proposed-save'),
      );

      await weights.append(
        observation: OfflineFixtures.amparoWeight,
        idempotencyKey: OfflineFixtures.weightAppendKey,
      );
      await weights.append(
        observation: WeightObservation(
          id: OfflineFixtures.weightCorrectionId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          kilograms: 63.0,
          recordedAt: OfflineFixtures.demoRecordedAt.add(
            const Duration(hours: 3),
          ),
          authorId: IdentityFixtures.carlosCaregiverUserId,
          correctsObservationId: OfflineFixtures.weightObservationId,
          version: AggregateVersion.initial,
          syncState: SyncState.local,
        ),
        idempotencyKey: IdempotencyKey('demo-weight-correction-save'),
      );
      await bloodPressures.append(
        observation: OfflineFixtures.amparoBloodPressure,
        idempotencyKey: OfflineFixtures.bloodPressureAppendKey,
      );

      final snapshot = live.capture();
      final restored = InMemoryOfflineStore.fromSnapshot(snapshot);
      final restoredMemories = InMemoryMemoryRepository(restored);
      final restoredWeights = InMemoryWeightObservationRepository(restored);

      final garden = await restoredMemories.findById(
        OfflineFixtures.gardenMemoryId,
      );
      expect(garden, isNotNull);
      expect(garden!.caption, 'Jardín Ejemplo');
      expect(garden.media!.uploadState, SyncState.failed);
      expect(garden.media!.checksum, OfflineFixtures.gardenMediaChecksum);

      final approved = await restoredMemories.listApprovedForFamily(
        IdentityFixtures.familiaEjemploSpaceId,
      );
      expect(approved.map((m) => m.id), [OfflineFixtures.gardenMemoryId]);

      final history = await restoredWeights.listChronological(
        IdentityFixtures.familiaEjemploSpaceId,
      );
      expect(history, hasLength(2));
      expect(history.first.kilograms, 62.5);
      expect(
        history.last.correctsObservationId,
        OfflineFixtures.weightObservationId,
      );
      expect(history.last.authorId, IdentityFixtures.carlosCaregiverUserId);

      // Idempotent re-append must not overwrite the original kilograms.
      final again = await restoredWeights.append(
        observation: OfflineFixtures.amparoWeight.copyWith(
          syncState: SyncState.local,
        ),
        idempotencyKey: IdempotencyKey('demo-weight-reappend'),
      );
      expect(again.kilograms, 62.5);
      expect(
        (await restoredWeights.findById(
          OfflineFixtures.weightObservationId,
        ))!.kilograms,
        62.5,
      );
    },
  );

  test(
    'observation soft delete writes tombstone without dropping values',
    () async {
      final store = InMemoryOfflineStore();
      final weights = InMemoryWeightObservationRepository(store);
      await weights.append(
        observation: OfflineFixtures.amparoWeight,
        idempotencyKey: OfflineFixtures.weightAppendKey,
      );

      final deleted = await weights.softDelete(
        id: OfflineFixtures.weightObservationId,
        baseVersion: AggregateVersion.initial,
        deletedAt: OfflineFixtures.demoRecordedAt,
        idempotencyKey: IdempotencyKey('demo-weight-delete'),
        deletedBy: IdentityFixtures.elenaPrimaryUserId,
      );
      expect(deleted.isDeleted, isTrue);
      expect(deleted.kilograms, 62.5);
      expect(deleted.tombstone!.deletedBy, IdentityFixtures.elenaPrimaryUserId);
    },
  );
}
