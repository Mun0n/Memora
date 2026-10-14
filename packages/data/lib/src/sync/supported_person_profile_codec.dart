import 'package:domain/domain.dart';

/// Encode/decode supported-person preferred-name sync payloads.
///
/// Snapshots without a preferred-name record simply omit the aggregate; callers
/// treat a missing decode target as the safe greeting fallback (`Hola`).
abstract final class SupportedPersonProfileCodec {
  static Map<String, Object?> encodePayload(SupportedPersonProfile profile) {
    return <String, Object?>{
      'preferredName': profile.preferredName,
      'tombstoned': profile.isDeleted,
      'version': profile.version.value,
    };
  }

  /// Returns null when [payload] lacks a usable preferred name (backward-compat).
  static SupportedPersonProfile? tryDecodeProfile({
    required String aggregateId,
    required String familySpaceId,
    required Map<String, Object?> payload,
    required AggregateVersion version,
    required bool tombstoned,
    required SyncState syncState,
  }) {
    final rawName = payload['preferredName'];
    if (rawName is! String) {
      return null;
    }
    try {
      return SupportedPersonProfile(
        id: SupportedPersonProfileId(aggregateId),
        familySpaceId: FamilySpaceId(familySpaceId),
        preferredName: rawName,
        version: version,
        syncState: syncState,
        tombstone: tombstoned
            ? Tombstone(
                aggregateId: aggregateId,
                version: version,
                deletedAt: DateTime.now().toUtc(),
              )
            : null,
      );
    } on ArgumentError {
      return null;
    } on FormatException {
      return null;
    }
  }

  static SupportedPersonProfile decodeProfile({
    required String aggregateId,
    required String familySpaceId,
    required Map<String, Object?> payload,
    required AggregateVersion version,
    required bool tombstoned,
    required SyncState syncState,
  }) {
    final decoded = tryDecodeProfile(
      aggregateId: aggregateId,
      familySpaceId: familySpaceId,
      payload: payload,
      version: version,
      tombstoned: tombstoned,
      syncState: syncState,
    );
    if (decoded == null) {
      throw FormatException(
        'supported-person profile payload missing valid preferredName',
      );
    }
    return decoded;
  }
}
