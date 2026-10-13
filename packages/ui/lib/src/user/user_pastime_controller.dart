import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../demo/demo_data_scope.dart';
import '../l10n/memora_copy.dart';
import '../sync/presentation_sync.dart' show PresentationSurfaceState;

/// Supported-person active pastime viewing (offline-cached, caregiver order).
///
/// Never exposes drafts, archived cards, sync jargon or completion claims.
final class UserPastimeController extends ChangeNotifier {
  UserPastimeController({
    required this.actor,
    required PastimeRepository pastimes,
    this.networkAvailable = false,
    this.demoDataScope = DemoDataScope.isolatedLocal,
    ConfigurePastime? configurePastime,
  }) : _configure = configurePastime ?? ConfigurePastime(pastimes);

  final FamilyMembership actor;
  final ConfigurePastime _configure;

  bool networkAvailable;
  DemoDataScope demoDataScope;

  /// Quiet pull hook for shared local demo (wired by composition).
  Future<bool> Function()? quietRemotePull;

  PresentationSurfaceState surfaceState = PresentationSurfaceState.loading;
  List<Pastime> pastimes = const <Pastime>[];
  String? errorMessage;

  /// Selected card for calm detail; null shows the list / empty state.
  PastimeId? selectedPastimeId;

  /// Shared-demo pull failed; cache retained; retry offered.
  bool sharedPullFailed = false;

  /// Shared-demo pull/refresh in flight (plain-language pending, no jargon).
  bool isRefreshingShared = false;

  bool get isSharedDemo => demoDataScope == DemoDataScope.sharedLocalDemo;

  Pastime? get selectedPastime {
    final id = selectedPastimeId;
    if (id == null) {
      return null;
    }
    for (final pastime in pastimes) {
      if (pastime.id == id) {
        return pastime;
      }
    }
    return null;
  }

  String get syncLabel {
    if (isRefreshingShared) {
      return MemoraCopy.pasatiemposSharedPending;
    }
    if (sharedPullFailed) {
      return MemoraCopy.pasatiemposSharedPullFailed;
    }
    if (surfaceState == PresentationSurfaceState.loading) {
      return MemoraCopy.pasatiemposLoading;
    }
    if (surfaceState == PresentationSurfaceState.empty) {
      return networkAvailable
          ? MemoraCopy.pasatiemposBody
          : '${MemoraCopy.pasatiemposBody} ${MemoraCopy.pasatiemposOffline}';
    }
    if (surfaceState == PresentationSurfaceState.failed) {
      return MemoraCopy.pasatiemposBody;
    }
    if (!networkAvailable || surfaceState == PresentationSurfaceState.offline) {
      return MemoraCopy.pasatiemposOffline;
    }
    return MemoraCopy.pasatiemposTitle;
  }

  Future<void> load() async {
    surfaceState = PresentationSurfaceState.loading;
    if (!isSharedDemo) {
      errorMessage = null;
      sharedPullFailed = false;
    }
    selectedPastimeId = null;
    notifyListeners();
    try {
      pastimes = await _configure.listActiveForViewing(
        actor: actor,
        familySpaceId: actor.familySpaceId,
      );
      surfaceState = pastimes.isEmpty
          ? PresentationSurfaceState.empty
          : (!networkAvailable
                ? PresentationSurfaceState.offline
                : PresentationSurfaceState.ready);
      if (!isSharedDemo) {
        errorMessage = null;
      }
    } catch (error) {
      errorMessage = error.toString();
      surfaceState = PresentationSurfaceState.failed;
    }
    notifyListeners();
  }

  /// Reloads active cards after a quiet pull; keeps selection when still valid.
  ///
  /// On failure, retains the previously cached list (never traps home).
  Future<void> refreshActive() async {
    try {
      final listed = await _configure.listActiveForViewing(
        actor: actor,
        familySpaceId: actor.familySpaceId,
      );
      pastimes = listed;
      if (selectedPastimeId != null &&
          !pastimes.any((p) => p.id == selectedPastimeId)) {
        selectedPastimeId = null;
      }
      surfaceState = pastimes.isEmpty
          ? PresentationSurfaceState.empty
          : (!networkAvailable
                ? PresentationSurfaceState.offline
                : PresentationSurfaceState.ready);
      if (!sharedPullFailed) {
        errorMessage = null;
      }
    } catch (_) {
      // Keep cached pastimes; do not surface technical errors here.
    }
    notifyListeners();
  }

  /// Quiet pull + local reload for shared-demo destination entry / retry.
  Future<void> refreshFromSharedRemote() async {
    if (!isSharedDemo) {
      await refreshActive();
      return;
    }
    isRefreshingShared = true;
    notifyListeners();
    var pullOk = true;
    final pull = quietRemotePull;
    if (pull != null) {
      try {
        pullOk = await pull();
      } catch (_) {
        pullOk = false;
      }
    }
    await refreshActive();
    isRefreshingShared = false;
    sharedPullFailed = !pullOk;
    errorMessage = sharedPullFailed
        ? MemoraCopy.pasatiemposSharedPullFailed
        : null;
    notifyListeners();
  }

  Future<void> recover() async {
    await refreshFromSharedRemote();
  }

  void openDetail(PastimeId id) {
    selectedPastimeId = id;
    notifyListeners();
  }

  void returnToList() {
    selectedPastimeId = null;
    notifyListeners();
  }
}
