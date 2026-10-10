import 'package:domain/domain.dart';

import '../l10n/memora_copy.dart';

/// Accessible surface states for empty/loading/offline/failed/conflicted.
enum PresentationSurfaceState {
  loading,
  empty,
  ready,
  offline,
  failed,
  conflicted,
}

/// Plain-language Spanish labels for sync and recovery surfaces.
abstract final class SyncStatusLabels {
  static String forSyncState(SyncState state) {
    return switch (state) {
      SyncState.local => MemoraCopy.syncLocal,
      SyncState.pending => MemoraCopy.syncPending,
      SyncState.synced => MemoraCopy.syncSynced,
      SyncState.conflicted => MemoraCopy.syncConflicted,
      SyncState.failed => MemoraCopy.syncFailed,
    };
  }

  static String forSurface(PresentationSurfaceState state) {
    return switch (state) {
      PresentationSurfaceState.loading => MemoraCopy.stateLoading,
      PresentationSurfaceState.empty => MemoraCopy.stateEmpty,
      PresentationSurfaceState.ready => MemoraCopy.syncLocal,
      PresentationSurfaceState.offline => MemoraCopy.stateOffline,
      PresentationSurfaceState.failed => MemoraCopy.syncFailed,
      PresentationSurfaceState.conflicted => MemoraCopy.syncConflicted,
    };
  }

  /// Picks the strongest (worst) sync signal from aggregates for the chrome.
  static SyncState worstOf(Iterable<SyncState> states) {
    var worst = SyncState.synced;
    for (final state in states) {
      if (_rank(state) > _rank(worst)) {
        worst = state;
      }
    }
    return worst;
  }

  static int _rank(SyncState state) {
    return switch (state) {
      SyncState.synced => 0,
      SyncState.local => 1,
      SyncState.pending => 2,
      SyncState.failed => 3,
      SyncState.conflicted => 4,
    };
  }
}
