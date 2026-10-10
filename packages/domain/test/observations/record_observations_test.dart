import 'package:domain/domain.dart';
import 'package:test/test.dart';

final class _StubWeights implements WeightObservationRepository {
  final Map<String, WeightObservation> _items = <String, WeightObservation>{};

  @override
  Future<WeightObservation> append({
    required WeightObservation observation,
    required IdempotencyKey idempotencyKey,
  }) async {
    final existing = _items[observation.id.value];
    if (existing != null) {
      return existing;
    }
    final pending = observation.copyWith(syncState: SyncState.pending);
    _items[pending.id.value] = pending;
    return pending;
  }

  @override
  Future<WeightObservation?> findById(ObservationId id) async =>
      _items[id.value];

  @override
  Future<List<WeightObservation>> listForFamily(
    FamilySpaceId familySpaceId,
  ) async {
    return _items.values
        .where((o) => o.familySpaceId == familySpaceId)
        .toList(growable: false);
  }

  @override
  Future<List<WeightObservation>> listChronological(
    FamilySpaceId familySpaceId,
  ) async {
    final listed = await listForFamily(familySpaceId);
    final sorted = listed.toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return sorted;
  }

  @override
  Future<WeightObservation> softDelete({
    required ObservationId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) async {
    final current = _items[id.value];
    if (current == null) {
      throw StateError('missing');
    }
    final next = baseVersion.next();
    final deleted = current.copyWith(
      version: next,
      syncState: SyncState.pending,
      tombstone: Tombstone(
        aggregateId: id.value,
        version: next,
        deletedAt: deletedAt,
        deletedBy: deletedBy,
      ),
    );
    _items[id.value] = deleted;
    return deleted;
  }
}

final class _StubBloodPressures implements BloodPressureObservationRepository {
  final Map<String, BloodPressureObservation> _items =
      <String, BloodPressureObservation>{};

  @override
  Future<BloodPressureObservation> append({
    required BloodPressureObservation observation,
    required IdempotencyKey idempotencyKey,
  }) async {
    final existing = _items[observation.id.value];
    if (existing != null) {
      return existing;
    }
    final pending = observation.copyWith(syncState: SyncState.pending);
    _items[pending.id.value] = pending;
    return pending;
  }

  @override
  Future<BloodPressureObservation?> findById(ObservationId id) async =>
      _items[id.value];

  @override
  Future<List<BloodPressureObservation>> listForFamily(
    FamilySpaceId familySpaceId,
  ) async {
    return _items.values
        .where((o) => o.familySpaceId == familySpaceId)
        .toList(growable: false);
  }

  @override
  Future<List<BloodPressureObservation>> listChronological(
    FamilySpaceId familySpaceId,
  ) async {
    final listed = await listForFamily(familySpaceId);
    final sorted = listed.toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return sorted;
  }

  @override
  Future<BloodPressureObservation> softDelete({
    required ObservationId id,
    required AggregateVersion baseVersion,
    required DateTime deletedAt,
    required IdempotencyKey idempotencyKey,
    UserId? deletedBy,
  }) async {
    final current = _items[id.value];
    if (current == null) {
      throw StateError('missing');
    }
    final next = baseVersion.next();
    final deleted = current.copyWith(
      version: next,
      syncState: SyncState.pending,
      tombstone: Tombstone(
        aggregateId: id.value,
        version: next,
        deletedAt: deletedAt,
        deletedBy: deletedBy,
      ),
    );
    _items[id.value] = deleted;
    return deleted;
  }
}

void main() {
  group('RecordObservations', () {
    late _StubWeights weights;
    late _StubBloodPressures bloodPressures;
    late RecordObservations record;

    setUp(() {
      weights = _StubWeights();
      bloodPressures = _StubBloodPressures();
      record = RecordObservations(
        weights: weights,
        bloodPressures: bloodPressures,
      );
    });

    test(
      'add, correct and tombstone preserve prior values and author history',
      () async {
        final elena = IdentityFixtures.elenaPrimaryMembership;
        final added = await record.addWeight(
          actor: elena,
          id: OfflineFixtures.weightObservationId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          kilograms: 62.5,
          recordedAt: OfflineFixtures.demoRecordedAt,
          idempotencyKey: OfflineFixtures.weightAppendKey,
        );
        expect(added.kilograms, 62.5);
        expect(added.authorId, IdentityFixtures.elenaPrimaryUserId);
        expect(WeightObservation.unitLabel, 'kg');

        final correction = await record.correctWeight(
          actor: IdentityFixtures.carlosCaregiverMembership,
          sourceId: OfflineFixtures.weightObservationId,
          correctionId: OfflineFixtures.weightCorrectionId,
          kilograms: 63.0,
          recordedAt: OfflineFixtures.demoRecordedAt.add(
            const Duration(hours: 2),
          ),
          idempotencyKey: IdempotencyKey('demo-weight-correct'),
        );
        expect(correction.kilograms, 63.0);
        expect(
          correction.correctsObservationId,
          OfflineFixtures.weightObservationId,
        );
        expect(correction.authorId, IdentityFixtures.carlosCaregiverUserId);

        // Original row unchanged — no silent merge / overwrite.
        final original = await weights.findById(
          OfflineFixtures.weightObservationId,
        );
        expect(original!.kilograms, 62.5);
        expect(original.authorId, IdentityFixtures.elenaPrimaryUserId);

        final history = await record.listWeightHistory(
          actor: elena,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
        );
        expect(history, hasLength(2));
        expect(history.first.kilograms, 62.5);
        expect(history.last.kilograms, 63.0);

        final tombstoned = await record.tombstoneWeight(
          actor: elena,
          id: OfflineFixtures.weightObservationId,
          baseVersion: AggregateVersion.initial,
          deletedAt: OfflineFixtures.demoRecordedAt.add(
            const Duration(days: 1),
          ),
          idempotencyKey: IdempotencyKey('demo-weight-tombstone'),
        );
        expect(tombstoned.isDeleted, isTrue);
        expect(tombstoned.kilograms, 62.5);

        final bp = await record.addBloodPressure(
          actor: elena,
          id: OfflineFixtures.bloodPressureObservationId,
          familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
          systolicMmHg: 120,
          diastolicMmHg: 80,
          recordedAt: OfflineFixtures.demoRecordedAt,
          idempotencyKey: OfflineFixtures.bloodPressureAppendKey,
        );
        expect(BloodPressureObservation.unitLabel, 'mmHg');
        expect(bp.systolicMmHg, 120);

        final bpCorrection = await record.correctBloodPressure(
          actor: elena,
          sourceId: OfflineFixtures.bloodPressureObservationId,
          correctionId: OfflineFixtures.bloodPressureCorrectionId,
          systolicMmHg: 118,
          diastolicMmHg: 78,
          recordedAt: OfflineFixtures.demoRecordedAt.add(
            const Duration(hours: 1),
          ),
          idempotencyKey: IdempotencyKey('demo-bp-correct'),
        );
        expect(bpCorrection.systolicMmHg, 118);
        final bpSource = await bloodPressures.findById(
          OfflineFixtures.bloodPressureObservationId,
        );
        expect(bpSource!.systolicMmHg, 120);
      },
    );

    test(
      'supported person and contributor cannot record observations',
      () async {
        await expectLater(
          record.addWeight(
            actor: IdentityFixtures.amparoSupportedMembership,
            id: OfflineFixtures.weightObservationId,
            familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
            kilograms: 62.5,
            recordedAt: OfflineFixtures.demoRecordedAt,
            idempotencyKey: IdempotencyKey('demo-supported-weight-denied'),
          ),
          throwsA(isA<UnauthorizedCareActionException>()),
        );
        await expectLater(
          record.addBloodPressure(
            actor: IdentityFixtures.luciaContributorMembership,
            id: OfflineFixtures.bloodPressureObservationId,
            familySpaceId: IdentityFixtures.familiaEjemploSpaceId,
            systolicMmHg: 120,
            diastolicMmHg: 80,
            recordedAt: OfflineFixtures.demoRecordedAt,
            idempotencyKey: IdempotencyKey('demo-contributor-bp-denied'),
          ),
          throwsA(isA<UnauthorizedCareActionException>()),
        );
      },
    );
  });
}
