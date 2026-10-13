import 'package:domain/domain.dart';

import 'in_memory_sync_authority.dart';

/// Actionable failure when a durable local demo snapshot is unusable.
final class LocalDemoSyncSnapshotException implements Exception {
  LocalDemoSyncSnapshotException(this.message);

  final String message;

  @override
  String toString() => 'LocalDemoSyncSnapshotException: $message';
}

/// Single documented initializer for the shared local demo authority.
///
/// Publishes the deterministic Familia Ejemplo pastime baseline when the
/// authority has no pastime rows for that fictional family space. Independent
/// clients must not each seed competing private pastime fixtures in shared mode.
abstract final class LocalDemoFictionalBaseline {
  static const int schemaVersion = 1;

  static FamilySpaceId get familySpaceId =>
      IdentityFixtures.familiaEjemploSpaceId;

  /// Returns `true` when this call published the baseline.
  static bool ensurePastimes(InMemorySyncAuthority authority) {
    if (authority.hasPastimeRowsFor(familySpaceId.value)) {
      return false;
    }
    _seedPastime(
      authority,
      pastime: OfflineFixtures.radioPastime,
      version: AggregateVersion(1),
    );
    _seedPastime(
      authority,
      pastime: OfflineFixtures.draftPuzzlePastime,
      version: AggregateVersion(1),
    );
    _seedPastime(
      authority,
      pastime: OfflineFixtures.archivedPhotosPastime,
      version: AggregateVersion(1),
    );
    return true;
  }

  static void _seedPastime(
    InMemorySyncAuthority authority, {
    required Pastime pastime,
    required AggregateVersion version,
  }) {
    authority.seed(
      aggregateType: OutboxAggregateType.pastime,
      aggregateId: pastime.id.value,
      familySpaceId: pastime.familySpaceId.value,
      version: version,
      payload: <String, Object?>{
        'title': pastime.title,
        'instruction': pastime.instruction,
        'displayOrder': pastime.displayOrder,
        'lifecycle': pastime.lifecycleStatus.wireName,
        'tombstoned': pastime.isDeleted,
        'version': version.value,
      },
      tombstoned: pastime.isDeleted,
    );
  }
}
