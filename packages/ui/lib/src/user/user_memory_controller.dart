import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../l10n/memora_copy.dart';
import '../sync/presentation_sync.dart';

/// Supported-person approved-memory viewing (offline-cached caption/date/media).
final class UserMemoryController extends ChangeNotifier {
  UserMemoryController({
    required this.actor,
    required MemoryRepository memories,
    this.networkAvailable = false,
    ManageMemory? manageMemory,
  }) : _manage = manageMemory ?? ManageMemory(memories);

  final FamilyMembership actor;
  final ManageMemory _manage;

  bool networkAvailable;

  PresentationSurfaceState surfaceState = PresentationSurfaceState.loading;
  List<MemoryEntry> memories = const <MemoryEntry>[];
  String? errorMessage;

  /// When set, shows failed-media placeholder without trapping navigation.
  MemoryId? focusedFailedMediaId;

  String get syncLabel {
    if (surfaceState == PresentationSurfaceState.loading) {
      return MemoraCopy.memoriesLoading;
    }
    if (surfaceState == PresentationSurfaceState.empty) {
      return networkAvailable
          ? MemoraCopy.memoriesEmpty
          : '${MemoraCopy.memoriesEmpty} ${MemoraCopy.memoriesOffline}';
    }
    if (surfaceState == PresentationSurfaceState.failed) {
      return MemoraCopy.syncFailed;
    }
    if (!networkAvailable || surfaceState == PresentationSurfaceState.offline) {
      return MemoraCopy.memoriesOffline;
    }
    return SyncStatusLabels.forSyncState(_worstSync());
  }

  String? get recoveryActionLabel {
    return switch (surfaceState) {
      PresentationSurfaceState.failed => MemoraCopy.recoveryRetry,
      PresentationSurfaceState.conflicted => MemoraCopy.recoveryReviewConflict,
      PresentationSurfaceState.offline => MemoraCopy.recoveryContinueOffline,
      PresentationSurfaceState.empty => null,
      PresentationSurfaceState.loading => null,
      PresentationSurfaceState.ready =>
        !networkAvailable ? MemoraCopy.recoveryContinueOffline : null,
    };
  }

  Future<void> load() async {
    surfaceState = PresentationSurfaceState.loading;
    errorMessage = null;
    focusedFailedMediaId = null;
    notifyListeners();
    try {
      memories = await _manage.listApprovedForViewing(
        actor: actor,
        familySpaceId: actor.familySpaceId,
      );
      surfaceState = _deriveSurface(memories);
    } catch (error) {
      errorMessage = error.toString();
      surfaceState = PresentationSurfaceState.failed;
    }
    notifyListeners();
  }

  Future<void> recover() async {
    if (surfaceState == PresentationSurfaceState.offline ||
        (!networkAvailable && surfaceState == PresentationSurfaceState.ready)) {
      surfaceState = memories.isEmpty
          ? PresentationSurfaceState.empty
          : PresentationSurfaceState.ready;
      notifyListeners();
      return;
    }
    await load();
  }

  void acknowledgeFailedMedia(MemoryId id) {
    focusedFailedMediaId = id;
    notifyListeners();
  }

  void continueAfterFailedMedia() {
    focusedFailedMediaId = null;
    notifyListeners();
  }

  PresentationSurfaceState _deriveSurface(List<MemoryEntry> listed) {
    if (listed.isEmpty) {
      return PresentationSurfaceState.empty;
    }
    final worst = SyncStatusLabels.worstOf(listed.map((m) => m.syncState));
    if (worst == SyncState.conflicted) {
      return PresentationSurfaceState.conflicted;
    }
    if (worst == SyncState.failed) {
      return PresentationSurfaceState.failed;
    }
    if (!networkAvailable) {
      return PresentationSurfaceState.offline;
    }
    return PresentationSurfaceState.ready;
  }

  SyncState _worstSync() {
    if (memories.isEmpty) {
      return SyncState.local;
    }
    return SyncStatusLabels.worstOf(memories.map((m) => m.syncState));
  }
}
