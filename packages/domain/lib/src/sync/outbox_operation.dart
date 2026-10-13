import 'aggregate_version.dart';
import 'idempotency_key.dart';
import 'sync_state.dart';

/// Aggregate kinds that may appear in the offline outbox.
enum OutboxAggregateType {
  routine,
  routineProgress,
  reminder,
  memory,
  weightObservation,
  bloodPressureObservation,
  pastime,
  conversationTopic,
}

/// One pending (or historically attempted) local mutation for sync.
final class OutboxOperation {
  OutboxOperation({
    required this.idempotencyKey,
    required this.aggregateType,
    required this.aggregateId,
    required this.baseVersion,
    required this.enqueuedAt,
    required this.state,
    this.attemptCount = 0,
  }) {
    if (aggregateId.trim().isEmpty) {
      throw ArgumentError.value(
        aggregateId,
        'aggregateId',
        'must be non-empty',
      );
    }
    if (attemptCount < 0) {
      throw ArgumentError.value(attemptCount, 'attemptCount', 'must be >= 0');
    }
    if (state != SyncState.pending &&
        state != SyncState.failed &&
        state != SyncState.synced) {
      throw ArgumentError.value(
        state,
        'state',
        'outbox entries use pending, failed or synced',
      );
    }
  }

  final IdempotencyKey idempotencyKey;
  final OutboxAggregateType aggregateType;
  final String aggregateId;
  final AggregateVersion baseVersion;
  final DateTime enqueuedAt;
  final SyncState state;
  final int attemptCount;

  OutboxOperation copyWith({SyncState? state, int? attemptCount}) {
    return OutboxOperation(
      idempotencyKey: idempotencyKey,
      aggregateType: aggregateType,
      aggregateId: aggregateId,
      baseVersion: baseVersion,
      enqueuedAt: enqueuedAt,
      state: state ?? this.state,
      attemptCount: attemptCount ?? this.attemptCount,
    );
  }
}
