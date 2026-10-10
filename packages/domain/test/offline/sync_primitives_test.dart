import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('SyncState', () {
    test('exposes exactly the five normative offline states', () {
      expect(SyncState.values.map((s) => s.name).toList(), <String>[
        'local',
        'pending',
        'synced',
        'conflicted',
        'failed',
      ]);
    });
  });

  group('AggregateVersion', () {
    test('rejects negative values and advances monotonically', () {
      expect(() => AggregateVersion(-1), throwsArgumentError);
      expect(AggregateVersion.initial.value, 0);
      expect(AggregateVersion.initial.next().value, 1);
      expect(AggregateVersion(2).isBefore(AggregateVersion(3)), isTrue);
    });
  });

  group('Tombstone', () {
    test('requires aggregate id and retains deletion metadata', () {
      expect(
        () => Tombstone(
          aggregateId: ' ',
          version: AggregateVersion.initial,
          deletedAt: DateTime.utc(2026, 10, 10),
        ),
        throwsArgumentError,
      );

      final tombstone = Tombstone(
        aggregateId: OfflineFixtures.morningRoutineId.value,
        version: AggregateVersion(1),
        deletedAt: DateTime.utc(2026, 10, 10, 12),
        deletedBy: IdentityFixtures.elenaPrimaryUserId,
      );
      expect(tombstone.deletedBy, IdentityFixtures.elenaPrimaryUserId);
      expect(tombstone.version.value, 1);
    });
  });

  group('OutboxOperation', () {
    test('accepts pending, failed and synced only', () {
      final base = OutboxOperation(
        idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
        aggregateType: OutboxAggregateType.routine,
        aggregateId: OfflineFixtures.morningRoutineId.value,
        baseVersion: AggregateVersion.initial,
        enqueuedAt: OfflineFixtures.demoRecordedAt,
        state: SyncState.pending,
      );
      expect(base.state, SyncState.pending);

      for (final illegal in <SyncState>[
        SyncState.local,
        SyncState.conflicted,
      ]) {
        expect(
          () => OutboxOperation(
            idempotencyKey: OfflineFixtures.morningRoutineSaveKey,
            aggregateType: OutboxAggregateType.routine,
            aggregateId: OfflineFixtures.morningRoutineId.value,
            baseVersion: AggregateVersion.initial,
            enqueuedAt: OfflineFixtures.demoRecordedAt,
            state: illegal,
          ),
          throwsArgumentError,
        );
      }
    });
  });
}
