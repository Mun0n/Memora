import 'package:domain/domain.dart';

/// JSON maps for the local demo sync HTTP contract (fictional data only).
abstract final class LocalDemoSyncCodec {
  static Map<String, Object?> encodeEnvelope(SyncEnvelope envelope) {
    return <String, Object?>{
      'familySpaceId': envelope.familySpaceId,
      'payload': envelope.payload,
      'operation': encodeOperation(envelope.operation),
    };
  }

  static SyncEnvelope decodeEnvelope(Map<String, Object?> json) {
    final operationRaw = json['operation'];
    if (operationRaw is! Map) {
      throw FormatException('push body missing operation object');
    }
    final payloadRaw = json['payload'];
    if (payloadRaw is! Map) {
      throw FormatException('push body missing payload object');
    }
    final familySpaceId = json['familySpaceId'];
    if (familySpaceId is! String || familySpaceId.trim().isEmpty) {
      throw FormatException('push body missing familySpaceId');
    }
    return SyncEnvelope(
      operation: decodeOperation(_stringKeyed(operationRaw)),
      familySpaceId: familySpaceId,
      payload: _stringKeyed(payloadRaw),
    );
  }

  static Map<String, Object?> encodeOperation(OutboxOperation operation) {
    return <String, Object?>{
      'idempotencyKey': operation.idempotencyKey.value,
      'aggregateType': operation.aggregateType.name,
      'aggregateId': operation.aggregateId,
      'baseVersion': operation.baseVersion.value,
      'enqueuedAt': operation.enqueuedAt.toUtc().toIso8601String(),
      'state': operation.state.name,
      'attemptCount': operation.attemptCount,
    };
  }

  static OutboxOperation decodeOperation(Map<String, Object?> json) {
    return OutboxOperation(
      idempotencyKey: IdempotencyKey(_requireString(json, 'idempotencyKey')),
      aggregateType: OutboxAggregateType.values.byName(
        _requireString(json, 'aggregateType'),
      ),
      aggregateId: _requireString(json, 'aggregateId'),
      baseVersion: AggregateVersion(_requireInt(json, 'baseVersion')),
      enqueuedAt: DateTime.parse(_requireString(json, 'enqueuedAt')).toUtc(),
      state: SyncState.values.byName(_requireString(json, 'state')),
      attemptCount: _optionalInt(json, 'attemptCount') ?? 0,
    );
  }

  static Map<String, Object?> encodePushResult(PushResult result) {
    return <String, Object?>{
      'outcome': result.outcome.name,
      'remoteVersion': result.remoteVersion?.value,
      'conflictRemotePayload': result.conflictRemotePayload,
      'failureReason': result.failureReason,
    };
  }

  static PushResult decodePushResult(Map<String, Object?> json) {
    final outcome = PushOutcome.values.byName(_requireString(json, 'outcome'));
    final remoteVersionRaw = json['remoteVersion'];
    final remoteVersion = remoteVersionRaw is int
        ? AggregateVersion(remoteVersionRaw)
        : null;
    final conflictRaw = json['conflictRemotePayload'];
    final conflict = conflictRaw is Map ? _stringKeyed(conflictRaw) : null;
    final failureReason = json['failureReason'] as String?;
    return PushResult(
      outcome: outcome,
      remoteVersion: remoteVersion,
      conflictRemotePayload: conflict,
      failureReason: failureReason,
    );
  }

  static Map<String, Object?> encodeRemoteRecord(RemoteRecord record) {
    return <String, Object?>{
      'aggregateType': record.aggregateType.name,
      'aggregateId': record.aggregateId,
      'familySpaceId': record.familySpaceId,
      'version': record.version.value,
      'payload': record.payload,
      'cursor': record.cursor,
      'tombstoned': record.tombstoned,
    };
  }

  static RemoteRecord decodeRemoteRecord(Map<String, Object?> json) {
    final payloadRaw = json['payload'];
    if (payloadRaw is! Map) {
      throw FormatException('remote record missing payload');
    }
    return RemoteRecord(
      aggregateType: OutboxAggregateType.values.byName(
        _requireString(json, 'aggregateType'),
      ),
      aggregateId: _requireString(json, 'aggregateId'),
      familySpaceId: _requireString(json, 'familySpaceId'),
      version: AggregateVersion(_requireInt(json, 'version')),
      payload: _stringKeyed(payloadRaw),
      cursor: _requireInt(json, 'cursor'),
      tombstoned: json['tombstoned'] == true,
    );
  }

  static Map<String, Object?> encodePullResponse(List<RemoteRecord> records) {
    return <String, Object?>{
      'records': records.map(encodeRemoteRecord).toList(growable: false),
    };
  }

  static List<RemoteRecord> decodePullResponse(Map<String, Object?> json) {
    final raw = json['records'];
    if (raw is! List) {
      throw FormatException('pull response missing records list');
    }
    return raw
        .map((item) {
          if (item is! Map) {
            throw FormatException('pull record must be an object');
          }
          return decodeRemoteRecord(_stringKeyed(item));
        })
        .toList(growable: false);
  }

  static Map<String, Object?> _stringKeyed(Map<dynamic, dynamic> raw) {
    return <String, Object?>{
      for (final entry in raw.entries) entry.key.toString(): entry.value,
    };
  }

  static String _requireString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('missing string field: $key');
    }
    return value;
  }

  static int _requireInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    throw FormatException('missing int field: $key');
  }

  static int? _optionalInt(Map<String, Object?> json, String key) {
    final value = json[key];
    return value is int ? value : null;
  }
}
