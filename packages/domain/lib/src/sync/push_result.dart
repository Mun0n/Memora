import 'aggregate_version.dart';

/// Outcome of pushing one outbox operation to a remote authority.
enum PushOutcome {
  /// Remote applied the mutation at [remoteVersion].
  applied,

  /// Same idempotency key already applied; treat as success.
  duplicateIgnored,

  /// Concurrent edit; both versions retained for resolution.
  conflict,

  /// Transient or permanent apply failure; retryable via outbox.
  failed,
}

final class PushResult {
  const PushResult({
    required this.outcome,
    this.remoteVersion,
    this.conflictRemotePayload,
    this.failureReason,
  });

  final PushOutcome outcome;
  final AggregateVersion? remoteVersion;

  /// Remote side when [outcome] is [PushOutcome.conflict] (routines).
  final Map<String, Object?>? conflictRemotePayload;

  /// Machine-safe failure label — never a content/health/token payload.
  final String? failureReason;

  factory PushResult.applied(AggregateVersion version) =>
      PushResult(outcome: PushOutcome.applied, remoteVersion: version);

  factory PushResult.duplicate(AggregateVersion version) =>
      PushResult(outcome: PushOutcome.duplicateIgnored, remoteVersion: version);

  factory PushResult.conflict({
    required AggregateVersion remoteVersion,
    required Map<String, Object?> remotePayload,
  }) => PushResult(
    outcome: PushOutcome.conflict,
    remoteVersion: remoteVersion,
    conflictRemotePayload: Map<String, Object?>.unmodifiable(remotePayload),
  );

  factory PushResult.failed(String reason) =>
      PushResult(outcome: PushOutcome.failed, failureReason: reason);
}
