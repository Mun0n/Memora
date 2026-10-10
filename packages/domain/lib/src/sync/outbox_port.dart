import 'idempotency_key.dart';
import 'outbox_operation.dart';

/// Outbox port: enqueue, inspect and transition sync delivery state.
///
/// Implementations must treat [OutboxOperation.idempotencyKey] as the
/// uniqueness key: repeated enqueue with the same key returns the existing
/// entry and must not create a duplicate pending mutation.
abstract interface class OutboxPort {
  /// Enqueues [operation] or returns the existing entry for its idempotency key.
  Future<OutboxOperation> enqueue(OutboxOperation operation);

  Future<OutboxOperation?> findByIdempotencyKey(IdempotencyKey key);

  /// Operations still awaiting successful remote apply (`pending` or `failed`).
  Future<List<OutboxOperation>> listRetryable();

  Future<List<OutboxOperation>> listPending();

  /// Marks a pending/failed entry as successfully synced.
  Future<OutboxOperation> markSynced(IdempotencyKey key);

  /// Marks a pending entry as failed (retryable).
  Future<OutboxOperation> markFailed(IdempotencyKey key);

  /// Moves a failed entry back to pending and increments [OutboxOperation.attemptCount].
  Future<OutboxOperation> retry(IdempotencyKey key);
}
