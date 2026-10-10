import 'package:domain/domain.dart';

/// Deterministic in-memory outbox. No network or credentials.
final class InMemoryOutbox implements OutboxPort {
  InMemoryOutbox();

  InMemoryOutbox.fromEntries(Iterable<OutboxOperation> entries) {
    for (final entry in entries) {
      _byKey[entry.idempotencyKey.value] = entry;
    }
  }

  final Map<String, OutboxOperation> _byKey = <String, OutboxOperation>{};

  List<OutboxOperation> captureEntries() =>
      List<OutboxOperation>.unmodifiable(_byKey.values.toList(growable: false));

  @override
  Future<OutboxOperation> enqueue(OutboxOperation operation) async {
    final existing = _byKey[operation.idempotencyKey.value];
    if (existing != null) {
      return existing;
    }
    final pending = operation.state == SyncState.pending
        ? operation
        : operation.copyWith(state: SyncState.pending);
    _byKey[pending.idempotencyKey.value] = pending;
    return pending;
  }

  @override
  Future<OutboxOperation?> findByIdempotencyKey(IdempotencyKey key) async {
    return _byKey[key.value];
  }

  @override
  Future<List<OutboxOperation>> listPending() async {
    return _byKey.values
        .where((op) => op.state == SyncState.pending)
        .toList(growable: false);
  }

  @override
  Future<List<OutboxOperation>> listRetryable() async {
    return _byKey.values
        .where(
          (op) => op.state == SyncState.pending || op.state == SyncState.failed,
        )
        .toList(growable: false);
  }

  @override
  Future<OutboxOperation> markSynced(IdempotencyKey key) async {
    final current = _require(key);
    final updated = current.copyWith(state: SyncState.synced);
    _byKey[key.value] = updated;
    return updated;
  }

  @override
  Future<OutboxOperation> markFailed(IdempotencyKey key) async {
    final current = _require(key);
    if (current.state == SyncState.synced) {
      throw StateError('cannot fail a synced outbox entry');
    }
    final updated = current.copyWith(state: SyncState.failed);
    _byKey[key.value] = updated;
    return updated;
  }

  @override
  Future<OutboxOperation> retry(IdempotencyKey key) async {
    final current = _require(key);
    if (current.state != SyncState.failed) {
      throw StateError('only failed outbox entries can be retried');
    }
    final updated = current.copyWith(
      state: SyncState.pending,
      attemptCount: current.attemptCount + 1,
    );
    _byKey[key.value] = updated;
    return updated;
  }

  OutboxOperation _require(IdempotencyKey key) {
    final current = _byKey[key.value];
    if (current == null) {
      throw StateError('unknown outbox key: ${key.value}');
    }
    return current;
  }
}
