import 'aggregate_version.dart';
import 'outbox_operation.dart';

/// One pulled remote aggregate snapshot for local apply.
final class RemoteRecord {
  RemoteRecord({
    required this.aggregateType,
    required this.aggregateId,
    required this.familySpaceId,
    required this.version,
    required Map<String, Object?> payload,
    required this.cursor,
    this.tombstoned = false,
  }) : payload = Map<String, Object?>.unmodifiable(payload);

  final OutboxAggregateType aggregateType;
  final String aggregateId;
  final String familySpaceId;
  final AggregateVersion version;
  final Map<String, Object?> payload;
  final int cursor;
  final bool tombstoned;
}
