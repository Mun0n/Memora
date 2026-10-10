import '../identity/identifiers.dart';
import 'aggregate_version.dart';

/// Soft-delete marker with retention/audit metadata.
///
/// Deletions never hard-erase locally; tombstones travel through the outbox.
final class Tombstone {
  Tombstone({
    required this.aggregateId,
    required this.version,
    required this.deletedAt,
    this.deletedBy,
  }) {
    if (aggregateId.trim().isEmpty) {
      throw ArgumentError.value(
        aggregateId,
        'aggregateId',
        'must be non-empty',
      );
    }
  }

  /// Aggregate identifier as a stable UUID string.
  final String aggregateId;

  /// Version at which the deletion was recorded.
  final AggregateVersion version;

  final DateTime deletedAt;

  /// Optional actor; omitted for anonymous local demo writes.
  final UserId? deletedBy;
}
