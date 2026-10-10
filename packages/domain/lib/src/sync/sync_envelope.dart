import 'outbox_operation.dart';

/// Transport envelope for one outbox mutation. Payload maps must stay free of
/// tokens and media URLs; health values may be present for apply but must never
/// be logged without [LogRedactor].
final class SyncEnvelope {
  SyncEnvelope({
    required this.operation,
    required this.familySpaceId,
    required Map<String, Object?> payload,
  }) : payload = Map<String, Object?>.unmodifiable(payload);

  final OutboxOperation operation;
  final String familySpaceId;
  final Map<String, Object?> payload;
}
