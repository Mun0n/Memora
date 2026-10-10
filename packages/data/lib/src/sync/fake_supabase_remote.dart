import 'package:domain/domain.dart';

/// In-process Supabase-compatible remote for pull/push proofs.
///
/// No network, no hosted project, no credentials. Idempotency keys and
/// row versions mirror the SQL contract.
final class FakeSupabaseRemote implements SyncTransportPort {
  FakeSupabaseRemote({this.failNextPush = false});

  /// When true, the next push returns failed then clears the flag.
  bool failNextPush;

  final Map<String, _RemoteRow> _rows = <String, _RemoteRow>{};
  final Set<String> _appliedKeys = <String>{};
  var _cursor = 0;

  int get cursor => _cursor;

  /// Seed a remote row (e.g. concurrent edit baseline).
  void seed({
    required OutboxAggregateType aggregateType,
    required String aggregateId,
    required String familySpaceId,
    required AggregateVersion version,
    required Map<String, Object?> payload,
    bool tombstoned = false,
  }) {
    _cursor += 1;
    _rows[aggregateId] = _RemoteRow(
      aggregateType: aggregateType,
      aggregateId: aggregateId,
      familySpaceId: familySpaceId,
      version: version,
      payload: Map<String, Object?>.from(payload),
      cursor: _cursor,
      tombstoned: tombstoned,
    );
  }

  /// Test/inspection helper — whether [aggregateId] carries a tombstone.
  bool isTombstoned(String aggregateId) =>
      _rows[aggregateId]?.tombstoned ?? false;

  @override
  Future<PushResult> push(SyncEnvelope envelope) async {
    if (failNextPush) {
      failNextPush = false;
      return PushResult.failed('transient_demo_failure');
    }

    final key = envelope.operation.idempotencyKey.value;
    if (_appliedKeys.contains(key)) {
      final existing = _rows[envelope.operation.aggregateId];
      return PushResult.duplicate(
        existing?.version ?? envelope.operation.baseVersion,
      );
    }

    final aggregateId = envelope.operation.aggregateId;
    final existing = _rows[aggregateId];
    final type = envelope.operation.aggregateType;

    if (_isObservation(type)) {
      // Append-only: never overwrite a different payload for the same id.
      if (existing != null) {
        if (_payloadEquals(existing.payload, envelope.payload)) {
          _appliedKeys.add(key);
          return PushResult.duplicate(existing.version);
        }
        // Conflict: keep remote as-is; caller preserves both locally.
        return PushResult.conflict(
          remoteVersion: existing.version,
          remotePayload: existing.payload,
        );
      }
      return _applyNew(envelope);
    }

    // Routines / reminders / memories / progress: stale base ⇒ conflict.
    if (existing != null &&
        envelope.operation.baseVersion.value < existing.version.value) {
      return PushResult.conflict(
        remoteVersion: existing.version,
        remotePayload: existing.payload,
      );
    }

    return _applyNew(envelope);
  }

  PushResult _applyNew(SyncEnvelope envelope) {
    final nextVersion = AggregateVersion(
      envelope.operation.baseVersion.value + 1,
    );
    final tombstoned = envelope.payload['tombstoned'] == true;
    _cursor += 1;
    _rows[envelope.operation.aggregateId] = _RemoteRow(
      aggregateType: envelope.operation.aggregateType,
      aggregateId: envelope.operation.aggregateId,
      familySpaceId: envelope.familySpaceId,
      version: nextVersion,
      payload: Map<String, Object?>.from(envelope.payload),
      cursor: _cursor,
      tombstoned: tombstoned,
    );
    _appliedKeys.add(envelope.operation.idempotencyKey.value);
    return PushResult.applied(nextVersion);
  }

  @override
  Future<List<RemoteRecord>> pull({
    required FamilySpaceId familySpaceId,
    int? afterCursor,
  }) async {
    final floor = afterCursor ?? -1;
    final listed =
        _rows.values
            .where(
              (r) => r.familySpaceId == familySpaceId.value && r.cursor > floor,
            )
            .toList()
          ..sort((a, b) => a.cursor.compareTo(b.cursor));
    return listed
        .map(
          (r) => RemoteRecord(
            aggregateType: r.aggregateType,
            aggregateId: r.aggregateId,
            familySpaceId: r.familySpaceId,
            version: r.version,
            payload: r.payload,
            cursor: r.cursor,
            tombstoned: r.tombstoned,
          ),
        )
        .toList(growable: false);
  }

  static bool _isObservation(OutboxAggregateType type) {
    return type == OutboxAggregateType.weightObservation ||
        type == OutboxAggregateType.bloodPressureObservation;
  }

  static bool _payloadEquals(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}

final class _RemoteRow {
  _RemoteRow({
    required this.aggregateType,
    required this.aggregateId,
    required this.familySpaceId,
    required this.version,
    required this.payload,
    required this.cursor,
    required this.tombstoned,
  });

  final OutboxAggregateType aggregateType;
  final String aggregateId;
  final String familySpaceId;
  final AggregateVersion version;
  final Map<String, Object?> payload;
  final int cursor;
  final bool tombstoned;
}
