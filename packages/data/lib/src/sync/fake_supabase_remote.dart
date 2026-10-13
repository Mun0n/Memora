import 'package:domain/domain.dart';

import 'in_memory_sync_authority.dart';

/// In-process Supabase-compatible remote for pull/push proofs.
///
/// No network, no hosted project, no credentials. Idempotency keys and
/// row versions mirror the SQL contract. Prefer
/// [LocalDemoSyncTransport] + [LocalDemoSyncServer] when separately running
/// clients must share one fictional authority.
final class FakeSupabaseRemote implements SyncTransportPort {
  FakeSupabaseRemote({this.failNextPush = false})
    : _authority = InMemorySyncAuthority();

  /// Shared-authority constructor for advanced proofs. Prefer a fresh
  /// [FakeSupabaseRemote] in unit tests.
  FakeSupabaseRemote.withAuthority(
    InMemorySyncAuthority authority, {
    this.failNextPush = false,
  }) : _authority = authority;

  /// When true, the next push returns failed then clears the flag.
  bool failNextPush;

  final InMemorySyncAuthority _authority;

  int get cursor => _authority.cursor;

  /// Seed a remote row (e.g. concurrent edit baseline).
  void seed({
    required OutboxAggregateType aggregateType,
    required String aggregateId,
    required String familySpaceId,
    required AggregateVersion version,
    required Map<String, Object?> payload,
    bool tombstoned = false,
  }) {
    _authority.seed(
      aggregateType: aggregateType,
      aggregateId: aggregateId,
      familySpaceId: familySpaceId,
      version: version,
      payload: payload,
      tombstoned: tombstoned,
    );
  }

  /// Test/inspection helper — whether [aggregateId] carries a tombstone.
  bool isTombstoned(String aggregateId) => _authority.isTombstoned(aggregateId);

  @override
  Future<PushResult> push(SyncEnvelope envelope) async {
    if (failNextPush) {
      failNextPush = false;
      return PushResult.failed('transient_demo_failure');
    }
    return _authority.push(envelope);
  }

  @override
  Future<List<RemoteRecord>> pull({
    required FamilySpaceId familySpaceId,
    int? afterCursor,
  }) async {
    return _authority.pull(
      familySpaceId: familySpaceId,
      afterCursor: afterCursor,
    );
  }
}
