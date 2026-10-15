import 'package:domain/domain.dart';

/// Shared in-process sync authority used by [FakeSupabaseRemote] and the
/// local demo HTTP server. No network, credentials or hosted Supabase.
final class InMemorySyncAuthority {
  InMemorySyncAuthority();

  /// Restores rows, cursor and idempotency keys from a durable snapshot map.
  factory InMemorySyncAuthority.fromSnapshot(Map<String, Object?> snapshot) {
    final authority = InMemorySyncAuthority();
    authority._importSnapshot(snapshot);
    return authority;
  }

  final Map<String, _RemoteRow> _rows = <String, _RemoteRow>{};
  final Set<String> _appliedKeys = <String>{};
  var _cursor = 0;

  int get cursor => _cursor;

  int get rowCount => _rows.length;

  bool get isEmpty => _rows.isEmpty;

  /// Whether any pastime row exists for [familySpaceId].
  bool hasPastimeRowsFor(String familySpaceId) {
    final trimmed = familySpaceId.trim();
    return _rows.values.any(
      (row) =>
          row.familySpaceId == trimmed &&
          row.aggregateType == OutboxAggregateType.pastime,
    );
  }

  /// Whether any conversation-topic row exists for [familySpaceId].
  bool hasConversationTopicRowsFor(String familySpaceId) {
    final trimmed = familySpaceId.trim();
    return _rows.values.any(
      (row) =>
          row.familySpaceId == trimmed &&
          row.aggregateType == OutboxAggregateType.conversationTopic,
    );
  }

  /// Whether any supported-person profile row exists for [familySpaceId].
  bool hasSupportedPersonProfileRowsFor(String familySpaceId) {
    final trimmed = familySpaceId.trim();
    return _rows.values.any(
      (row) =>
          row.familySpaceId == trimmed &&
          row.aggregateType == OutboxAggregateType.supportedPersonProfile,
    );
  }

  /// Clears all rows and idempotency keys (documented local demo reset).
  void reset() {
    _rows.clear();
    _appliedKeys.clear();
    _cursor = 0;
  }

  /// Serializable capture for the durable local demo snapshot.
  Map<String, Object?> exportSnapshot() {
    final rows = _rows.values.toList(growable: false)
      ..sort((a, b) => a.cursor.compareTo(b.cursor));
    return <String, Object?>{
      'cursor': _cursor,
      'appliedKeys': _appliedKeys.toList(growable: false)..sort(),
      'rows': rows
          .map(
            (row) => <String, Object?>{
              'aggregateType': row.aggregateType.name,
              'aggregateId': row.aggregateId,
              'familySpaceId': row.familySpaceId,
              'version': row.version.value,
              'payload': Map<String, Object?>.from(row.payload),
              'cursor': row.cursor,
              'tombstoned': row.tombstoned,
            },
          )
          .toList(growable: false),
    };
  }

  void _importSnapshot(Map<String, Object?> snapshot) {
    final cursorRaw = snapshot['cursor'];
    if (cursorRaw is! int || cursorRaw < 0) {
      throw const FormatException('snapshot missing non-negative cursor');
    }
    final keysRaw = snapshot['appliedKeys'];
    if (keysRaw is! List) {
      throw const FormatException('snapshot missing appliedKeys list');
    }
    final rowsRaw = snapshot['rows'];
    if (rowsRaw is! List) {
      throw const FormatException('snapshot missing rows list');
    }

    _rows.clear();
    _appliedKeys.clear();
    _cursor = cursorRaw;
    for (final key in keysRaw) {
      if (key is! String || key.trim().isEmpty) {
        throw const FormatException('snapshot appliedKeys must be strings');
      }
      _appliedKeys.add(key);
    }
    for (final item in rowsRaw) {
      if (item is! Map) {
        throw const FormatException('snapshot row must be an object');
      }
      final row = <String, Object?>{
        for (final entry in item.entries) entry.key.toString(): entry.value,
      };
      final payloadRaw = row['payload'];
      if (payloadRaw is! Map) {
        throw const FormatException('snapshot row missing payload');
      }
      final aggregateId = row['aggregateId'];
      final familySpaceId = row['familySpaceId'];
      final versionRaw = row['version'];
      final cursor = row['cursor'];
      final typeRaw = row['aggregateType'];
      if (aggregateId is! String ||
          familySpaceId is! String ||
          versionRaw is! int ||
          cursor is! int ||
          typeRaw is! String) {
        throw const FormatException('snapshot row missing required fields');
      }
      _rows[aggregateId] = _RemoteRow(
        aggregateType: OutboxAggregateType.values.byName(typeRaw),
        aggregateId: aggregateId,
        familySpaceId: familySpaceId,
        version: AggregateVersion(versionRaw),
        payload: <String, Object?>{
          for (final entry in payloadRaw.entries)
            entry.key.toString(): entry.value,
        },
        cursor: cursor,
        tombstoned: row['tombstoned'] == true,
      );
    }
  }

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

  bool isTombstoned(String aggregateId) =>
      _rows[aggregateId]?.tombstoned ?? false;

  /// Inspection helper for baseline upgrades and tests.
  RemoteRecord? recordFor(String aggregateId) {
    final row = _rows[aggregateId];
    if (row == null) {
      return null;
    }
    return RemoteRecord(
      aggregateType: row.aggregateType,
      aggregateId: row.aggregateId,
      familySpaceId: row.familySpaceId,
      version: row.version,
      payload: Map<String, Object?>.from(row.payload),
      cursor: row.cursor,
      tombstoned: row.tombstoned,
    );
  }

  PushResult push(SyncEnvelope envelope) {
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
      if (existing != null) {
        if (_payloadEquals(existing.payload, envelope.payload)) {
          _appliedKeys.add(key);
          return PushResult.duplicate(existing.version);
        }
        return PushResult.conflict(
          remoteVersion: existing.version,
          remotePayload: existing.payload,
        );
      }
      return _applyNew(envelope);
    }

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

  List<RemoteRecord> pull({
    required FamilySpaceId familySpaceId,
    int? afterCursor,
  }) {
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
