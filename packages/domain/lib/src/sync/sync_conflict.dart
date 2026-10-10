import '../identity/identifiers.dart';
import 'aggregate_version.dart';
import 'outbox_operation.dart';

/// Recoverable concurrent-edit conflict retained for caregiver resolution.
final class SyncConflict {
  SyncConflict({
    required this.id,
    required this.familySpaceId,
    required this.aggregateType,
    required this.aggregateId,
    required this.localVersion,
    required this.remoteVersion,
    required Map<String, Object?> localPayload,
    required Map<String, Object?> remotePayload,
    required this.detectedAt,
    this.resolvedAt,
    this.resolution = SyncConflictResolution.unresolved,
  }) : localPayload = Map<String, Object?>.unmodifiable(localPayload),
       remotePayload = Map<String, Object?>.unmodifiable(remotePayload);

  final String id;
  final FamilySpaceId familySpaceId;
  final OutboxAggregateType aggregateType;
  final String aggregateId;
  final AggregateVersion localVersion;
  final AggregateVersion remoteVersion;
  final Map<String, Object?> localPayload;
  final Map<String, Object?> remotePayload;
  final DateTime detectedAt;
  final DateTime? resolvedAt;
  final SyncConflictResolution resolution;

  bool get isUnresolved => resolution == SyncConflictResolution.unresolved;

  SyncConflict copyWith({
    SyncConflictResolution? resolution,
    DateTime? resolvedAt,
  }) {
    return SyncConflict(
      id: id,
      familySpaceId: familySpaceId,
      aggregateType: aggregateType,
      aggregateId: aggregateId,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      localPayload: localPayload,
      remotePayload: remotePayload,
      detectedAt: detectedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
    );
  }
}

enum SyncConflictResolution { unresolved, keepLocal, keepRemote, keepBoth }
