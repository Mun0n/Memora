import '../identity/identifiers.dart';
import '../sync/sync_state.dart';

/// Media metadata for a memory. No binary bytes — path + checksum + upload state.
///
/// Paths are family-scoped. Failed uploads are retryable via [uploadState].
final class MemoryMediaMetadata {
  MemoryMediaMetadata({
    required this.familySpaceId,
    required this.familyScopedPath,
    required this.checksum,
    required this.uploadState,
  }) {
    if (familyScopedPath.trim().isEmpty) {
      throw ArgumentError.value(
        familyScopedPath,
        'familyScopedPath',
        'must be non-empty',
      );
    }
    if (checksum.trim().isEmpty) {
      throw ArgumentError.value(checksum, 'checksum', 'must be non-empty');
    }
    final prefix = '${familySpaceId.value}/';
    if (!familyScopedPath.startsWith(prefix)) {
      throw ArgumentError.value(
        familyScopedPath,
        'familyScopedPath',
        'must start with family space prefix "$prefix"',
      );
    }
    if (!_allowedUploadStates.contains(uploadState)) {
      throw ArgumentError.value(
        uploadState,
        'uploadState',
        'must be local, pending, failed or synced',
      );
    }
  }

  static const Set<SyncState> _allowedUploadStates = <SyncState>{
    SyncState.local,
    SyncState.pending,
    SyncState.failed,
    SyncState.synced,
  };

  final FamilySpaceId familySpaceId;

  /// Object key scoped as `{familySpaceId}/…`. Fictional fixtures only in tests.
  final String familyScopedPath;

  /// Content checksum label (e.g. `sha256:demo-…`). Not a hosted digest lookup.
  final String checksum;

  /// Retryable upload/sync visibility for the media object.
  final SyncState uploadState;

  bool get isFailed => uploadState == SyncState.failed;

  bool get isRetryable =>
      uploadState == SyncState.failed || uploadState == SyncState.pending;

  MemoryMediaMetadata copyWith({SyncState? uploadState}) {
    return MemoryMediaMetadata(
      familySpaceId: familySpaceId,
      familyScopedPath: familyScopedPath,
      checksum: checksum,
      uploadState: uploadState ?? this.uploadState,
    );
  }
}
