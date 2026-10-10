/// Explicit offline/sync visibility states for local-first aggregates.
///
/// Plain-language UI mapping is presentation concern; this enum is normative.
enum SyncState {
  /// Written only in the local store; not yet queued for sync.
  local,

  /// Local mutation queued in the outbox awaiting delivery.
  pending,

  /// Acknowledged by the remote authority for this version.
  synced,

  /// Concurrent edit detected; both versions retained for resolution.
  conflicted,

  /// Delivery or apply failed; retryable without inventing a new mutation.
  failed,
}
