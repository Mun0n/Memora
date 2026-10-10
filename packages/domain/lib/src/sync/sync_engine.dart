import '../identity/family_membership.dart';
import '../identity/identifiers.dart';
import '../routines/routine_care_policy.dart';
import '../routines/unauthorized_care_action_exception.dart';
import 'aggregate_version.dart';
import 'conflict_store_port.dart';
import 'outbox_operation.dart';
import 'outbox_port.dart';
import 'push_result.dart';
import 'remote_record.dart';
import 'sync_conflict.dart';
import 'sync_envelope.dart';
import 'sync_state.dart';
import 'sync_transport_port.dart';

/// Explicit pull/push synchronization with idempotency, retry, version checks,
/// tombstones and recoverable conflicts.
final class SyncEngine {
  SyncEngine({
    required OutboxPort outbox,
    required SyncTransportPort transport,
    required ConflictStorePort conflicts,
    required SyncPayloadLoader payloadLoader,
    required SyncApplyHandler applyHandler,
    required String Function() conflictIdFactory,
  }) : _outbox = outbox,
       _transport = transport,
       _conflicts = conflicts,
       _payloadLoader = payloadLoader,
       _applyHandler = applyHandler,
       _conflictIdFactory = conflictIdFactory;

  final OutboxPort _outbox;
  final SyncTransportPort _transport;
  final ConflictStorePort _conflicts;
  final SyncPayloadLoader _payloadLoader;
  final SyncApplyHandler _applyHandler;
  final String Function() _conflictIdFactory;

  int? _pullCursor;

  int? get pullCursor => _pullCursor;

  /// Push all retryable outbox operations. Returns counts by outcome.
  Future<SyncPushSummary> pushPending() async {
    final retryable = await _outbox.listRetryable();
    var applied = 0;
    var duplicates = 0;
    var conflicted = 0;
    var failed = 0;

    for (final op in retryable) {
      if (op.state != SyncState.pending && op.state != SyncState.failed) {
        continue;
      }
      final pending = op.state == SyncState.failed
          ? await _outbox.retry(op.idempotencyKey)
          : op;

      final loaded = await _payloadLoader.load(pending);
      if (loaded == null) {
        await _outbox.markFailed(pending.idempotencyKey);
        failed++;
        continue;
      }

      final result = await _transport.push(loaded);
      switch (result.outcome) {
        case PushOutcome.applied:
          await _outbox.markSynced(pending.idempotencyKey);
          await _applyHandler.markLocalSynced(pending, result.remoteVersion!);
          applied++;
        case PushOutcome.duplicateIgnored:
          await _outbox.markSynced(pending.idempotencyKey);
          await _applyHandler.markLocalSynced(pending, result.remoteVersion!);
          duplicates++;
        case PushOutcome.conflict:
          await _outbox.markSynced(pending.idempotencyKey);
          await _applyHandler.markLocalConflicted(pending);
          final conflict = SyncConflict(
            id: _conflictIdFactory(),
            familySpaceId: FamilySpaceId(loaded.familySpaceId),
            aggregateType: pending.aggregateType,
            aggregateId: pending.aggregateId,
            localVersion: pending.baseVersion,
            remoteVersion: result.remoteVersion!,
            localPayload: loaded.payload,
            remotePayload: result.conflictRemotePayload ?? const {},
            detectedAt: DateTime.now().toUtc(),
          );
          await _conflicts.save(conflict);
          if (_isObservation(pending.aggregateType)) {
            await _applyHandler.applyRemote(
              RemoteRecord(
                aggregateType: pending.aggregateType,
                aggregateId: pending.aggregateId,
                familySpaceId: loaded.familySpaceId,
                version: result.remoteVersion!,
                payload: result.conflictRemotePayload ?? const {},
                cursor: 0,
              ),
              preserveBoth: true,
            );
          }
          conflicted++;
        case PushOutcome.failed:
          await _outbox.markFailed(pending.idempotencyKey);
          await _applyHandler.markLocalFailed(pending);
          failed++;
      }
    }

    return SyncPushSummary(
      applied: applied,
      duplicates: duplicates,
      conflicted: conflicted,
      failed: failed,
    );
  }

  /// Pull remote changes and apply with version checks / tombstone propagation.
  Future<SyncPullSummary> pull({required FamilySpaceId familySpaceId}) async {
    final records = await _transport.pull(
      familySpaceId: familySpaceId,
      afterCursor: _pullCursor,
    );
    var applied = 0;
    var skipped = 0;
    for (final record in records) {
      final outcome = await _applyHandler.applyRemote(record);
      if (outcome == SyncApplyOutcome.applied) {
        applied++;
      } else {
        skipped++;
      }
      if (record.cursor > (_pullCursor ?? -1)) {
        _pullCursor = record.cursor;
      }
    }
    return SyncPullSummary(applied: applied, skipped: skipped);
  }

  /// Caregiver resolves an unresolved conflict.
  Future<SyncConflict> resolveConflict({
    required FamilyMembership actor,
    required String conflictId,
    required SyncConflictResolution resolution,
  }) async {
    if (resolution == SyncConflictResolution.unresolved) {
      throw ArgumentError.value(resolution, 'resolution', 'must resolve');
    }
    if (!RoutineCarePolicy.canResolveSyncConflicts(actor)) {
      throw UnauthorizedCareActionException(
        'role ${actor.role.wireName} cannot resolve sync conflicts',
      );
    }
    final current = await _conflicts.findById(conflictId);
    if (current == null) {
      throw StateError('unknown conflict: $conflictId');
    }
    if (current.familySpaceId != actor.familySpaceId) {
      throw UnauthorizedCareActionException('conflict outside actor family');
    }
    final resolved = current.copyWith(
      resolution: resolution,
      resolvedAt: DateTime.now().toUtc(),
    );
    await _conflicts.save(resolved);
    await _applyHandler.applyConflictResolution(resolved);
    return resolved;
  }

  static bool _isObservation(OutboxAggregateType type) {
    return type == OutboxAggregateType.weightObservation ||
        type == OutboxAggregateType.bloodPressureObservation;
  }
}

final class SyncPushSummary {
  const SyncPushSummary({
    required this.applied,
    required this.duplicates,
    required this.conflicted,
    required this.failed,
  });

  final int applied;
  final int duplicates;
  final int conflicted;
  final int failed;
}

final class SyncPullSummary {
  const SyncPullSummary({required this.applied, required this.skipped});

  final int applied;
  final int skipped;
}

enum SyncApplyOutcome { applied, skipped }

/// Loads a push envelope for an outbox operation from local repositories.
abstract interface class SyncPayloadLoader {
  Future<SyncEnvelope?> load(OutboxOperation operation);
}

/// Applies remote/local sync state transitions onto local repositories.
abstract interface class SyncApplyHandler {
  Future<void> markLocalSynced(
    OutboxOperation operation,
    AggregateVersion remoteVersion,
  );

  Future<void> markLocalConflicted(OutboxOperation operation);

  Future<void> markLocalFailed(OutboxOperation operation);

  Future<SyncApplyOutcome> applyRemote(
    RemoteRecord record, {
    bool preserveBoth = false,
  });

  Future<void> applyConflictResolution(SyncConflict conflict);
}
