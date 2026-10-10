import '../identity/identifiers.dart';

/// Append-only audit event for MVP review. No sensitive payloads.
final class AuditRecord {
  AuditRecord({
    required this.id,
    required this.familySpaceId,
    required this.actorUserId,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.occurredAt,
    required this.requestId,
  }) {
    if (action.trim().isEmpty) {
      throw ArgumentError.value(action, 'action', 'must be non-empty');
    }
    if (targetType.trim().isEmpty) {
      throw ArgumentError.value(targetType, 'targetType', 'must be non-empty');
    }
    if (targetId.trim().isEmpty) {
      throw ArgumentError.value(targetId, 'targetId', 'must be non-empty');
    }
    if (requestId.trim().isEmpty) {
      throw ArgumentError.value(requestId, 'requestId', 'must be non-empty');
    }
  }

  final String id;
  final FamilySpaceId familySpaceId;
  final UserId actorUserId;

  /// Stable action label, e.g. `export.requested`, `session.revoked`.
  final String action;

  /// Aggregate/target kind label (not content).
  final String targetType;
  final String targetId;
  final DateTime occurredAt;

  /// Correlation id for the request (idempotency or demo request id).
  final String requestId;
}
