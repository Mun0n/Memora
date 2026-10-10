import '../identity/identifiers.dart';
import 'remote_record.dart';
import 'push_result.dart';
import 'sync_envelope.dart';

/// Explicit pull/push port. Implementations may be in-process fakes; never
/// embed production endpoints or service-role credentials.
abstract interface class SyncTransportPort {
  /// Push one outbox envelope. Must be idempotent on the operation key.
  Future<PushResult> push(SyncEnvelope envelope);

  /// Pull remote changes after [afterCursor] (exclusive). Null cursor = full.
  Future<List<RemoteRecord>> pull({
    required FamilySpaceId familySpaceId,
    int? afterCursor,
  });
}
