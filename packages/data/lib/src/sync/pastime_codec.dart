import 'package:domain/domain.dart';

/// Encode/decode pastime sync payloads including versioned experience.
///
/// Missing `experience` decodes as guided. Unknown/invalid experience becomes
/// [QuarantinedPastimeExperience] (fail closed; never another playable type).
abstract final class PastimeCodec {
  static Map<String, Object?> encodePayload(Pastime pastime) {
    return <String, Object?>{
      'title': pastime.title,
      'instruction': pastime.instruction,
      'displayOrder': pastime.displayOrder,
      'lifecycle': pastime.lifecycleStatus.wireName,
      'experience': pastime.experience.toWireMap(),
      'tombstoned': pastime.isDeleted,
      'version': pastime.version.value,
    };
  }

  static Pastime decodePastime({
    required String aggregateId,
    required String familySpaceId,
    required Map<String, Object?> payload,
    required AggregateVersion version,
    required bool tombstoned,
    required SyncState syncState,
  }) {
    return Pastime(
      id: PastimeId(aggregateId),
      familySpaceId: FamilySpaceId(familySpaceId),
      title: payload['title']! as String,
      instruction: payload['instruction']! as String,
      displayOrder: payload['displayOrder'] as int? ?? 0,
      lifecycleStatus: PastimeLifecycleStatus.parse(
        payload['lifecycle'] as String? ?? 'draft',
      ),
      version: version,
      syncState: syncState,
      experience: PastimeExperience.fromWireMap(payload['experience']),
      tombstone: tombstoned
          ? Tombstone(
              aggregateId: aggregateId,
              version: version,
              deletedAt: DateTime.now().toUtc(),
            )
          : null,
    );
  }

  /// Soft decode for conflict payloads — never throws on bad experience.
  static Pastime? tryDecodePastime({
    required String aggregateId,
    required String familySpaceId,
    required Map<String, Object?> payload,
    required AggregateVersion version,
    required bool tombstoned,
    required SyncState syncState,
  }) {
    try {
      return decodePastime(
        aggregateId: aggregateId,
        familySpaceId: familySpaceId,
        payload: payload,
        version: version,
        tombstoned: tombstoned,
        syncState: syncState,
      );
    } on Object {
      return null;
    }
  }
}
