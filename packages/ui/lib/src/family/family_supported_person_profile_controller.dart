import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../demo/demo_data_scope.dart';
import '../demo/demo_ids.dart';
import '../l10n/memora_copy.dart';
import '../sync/presentation_sync.dart';

/// Primary-caregiver preferred-name editor over [ConfigureSupportedPersonProfile].
///
/// UI visibility uses [SupportedPersonProfileCarePolicy]; domain remains
/// authoritative. Preferred names are never placed in [errorMessage].
final class FamilySupportedPersonProfileController extends ChangeNotifier {
  FamilySupportedPersonProfileController({
    required this.actor,
    required SupportedPersonProfileRepository profiles,
    this.networkAvailable = false,
    this.demoDataScope = DemoDataScope.isolatedLocal,
    this.afterLocalWrite,
    DemoIds? ids,
    ConfigureSupportedPersonProfile? configure,
  }) : _ids = ids ?? DemoIds(),
       _configure = configure ?? ConfigureSupportedPersonProfile(profiles);

  final FamilyMembership actor;
  final ConfigureSupportedPersonProfile _configure;
  final DemoIds _ids;

  bool networkAvailable;
  DemoDataScope demoDataScope;

  /// Optional quiet push after a successful local preferred-name write.
  Future<bool> Function()? afterLocalWrite;

  /// Optional quiet pull before presenting shared-demo profile.
  Future<bool> Function()? quietRemotePull;

  PresentationSurfaceState surfaceState = PresentationSurfaceState.loading;
  SupportedPersonProfile? profile;
  String? errorMessage;
  String? successMessage;
  String draftPreferredName = '';
  int editorRevision = 0;

  bool sharedDeliveryFailed = false;
  bool sharedPullFailed = false;
  bool isRefreshingShared = false;

  bool get canEdit =>
      SupportedPersonProfileCarePolicy.canEditSupportedPersonProfile(actor);

  bool get canView =>
      SupportedPersonProfileCarePolicy.canViewSupportedPersonProfile(actor);

  bool get isSharedDemo => demoDataScope == DemoDataScope.sharedLocalDemo;

  /// True when the primary caregiver still needs to set a preferred name.
  bool get needsPreferredNameSetup {
    if (!canEdit) {
      return false;
    }
    final current = profile;
    return current == null || current.isDeleted;
  }

  /// Safe display of the saved name for chrome (never logs the value).
  String get savedPreferredNameLabel {
    final current = profile;
    if (current == null || current.isDeleted) {
      return '';
    }
    return current.preferredName;
  }

  /// Bottom chrome should only appear when the caregiver must act.
  bool get needsActionableSyncNotice {
    if (sharedDeliveryFailed || sharedPullFailed) {
      return true;
    }
    return surfaceState == PresentationSurfaceState.failed ||
        surfaceState == PresentationSurfaceState.conflicted;
  }

  String get syncLabel {
    if (sharedDeliveryFailed) {
      return MemoraCopy.sharedLocalDemoDeliveryFailed;
    }
    if (sharedPullFailed) {
      return MemoraCopy.sharedLocalDemoPullFailed;
    }
    if (surfaceState == PresentationSurfaceState.failed) {
      return MemoraCopy.syncFailed;
    }
    if (surfaceState == PresentationSurfaceState.conflicted) {
      return MemoraCopy.syncConflicted;
    }
    if (isRefreshingShared) {
      return MemoraCopy.sharedLocalDemoPending;
    }
    if (surfaceState == PresentationSurfaceState.loading) {
      return MemoraCopy.supportedPersonProfileLoading;
    }
    if (!networkAvailable || surfaceState == PresentationSurfaceState.offline) {
      return MemoraCopy.stateOffline;
    }
    if (profile == null) {
      return MemoraCopy.supportedPersonProfileEmpty;
    }
    return SyncStatusLabels.forSyncState(profile!.syncState);
  }

  String? get recoveryActionLabel {
    if (sharedDeliveryFailed || sharedPullFailed) {
      return MemoraCopy.recoveryRetry;
    }
    return switch (surfaceState) {
      PresentationSurfaceState.failed => MemoraCopy.recoveryRetry,
      PresentationSurfaceState.conflicted => MemoraCopy.recoveryReviewConflict,
      _ => null,
    };
  }

  Future<void> load() async {
    surfaceState = PresentationSurfaceState.loading;
    if (!isSharedDemo) {
      errorMessage = null;
      sharedDeliveryFailed = false;
      sharedPullFailed = false;
    }
    notifyListeners();
    if (!canView) {
      profile = null;
      draftPreferredName = '';
      editorRevision += 1;
      surfaceState = PresentationSurfaceState.empty;
      errorMessage = MemoraCopy.supportedPersonProfileUnauthorized;
      notifyListeners();
      return;
    }
    try {
      final found = await _configure.findForFamily(
        actor: actor,
        familySpaceId: actor.familySpaceId,
      );
      profile = found;
      draftPreferredName = found?.preferredName ?? '';
      editorRevision += 1;
      surfaceState = _deriveSurface(found);
      if (!isSharedDemo) {
        errorMessage = null;
      }
    } catch (error) {
      if (error is UnauthorizedCareActionException) {
        errorMessage = MemoraCopy.supportedPersonProfileUnauthorized;
      } else {
        // Never echo preferred-name values from exception text.
        errorMessage = MemoraCopy.syncFailed;
      }
      surfaceState = PresentationSurfaceState.failed;
    }
    notifyListeners();
  }

  Future<void> refreshFromSharedRemote() async {
    if (!isSharedDemo) {
      await load();
      return;
    }
    final pull = quietRemotePull;
    isRefreshingShared = true;
    notifyListeners();
    var pullOk = true;
    if (pull != null) {
      try {
        pullOk = await pull();
      } catch (_) {
        pullOk = false;
      }
    }
    sharedPullFailed = !pullOk;
    isRefreshingShared = false;
    await load();
  }

  void setDraftPreferredName(String value) {
    draftPreferredName = value;
    if (successMessage != null) {
      successMessage = null;
      notifyListeners();
    }
  }

  /// Creates or corrects the preferred name. Invalid input keeps the draft and
  /// leaves the saved profile unchanged.
  Future<void> savePreferredName() async {
    if (!canEdit) {
      errorMessage = MemoraCopy.supportedPersonProfileUnauthorized;
      successMessage = null;
      notifyListeners();
      return;
    }
    if (!SupportedPersonProfile.isValidPreferredName(draftPreferredName)) {
      errorMessage = MemoraCopy.supportedPersonProfileValidationError;
      successMessage = null;
      notifyListeners();
      return;
    }
    try {
      final saved = await _configure.setPreferredName(
        actor: actor,
        familySpaceId: actor.familySpaceId,
        preferredName: draftPreferredName,
        idempotencyKey: _ids.nextIdempotencyKey('preferred-name'),
        id: profile?.id ?? _ids.nextSupportedPersonProfileId(),
      );
      profile = saved;
      draftPreferredName = saved.preferredName;
      editorRevision += 1;
      errorMessage = null;
      successMessage = MemoraCopy.changesSaved;
      surfaceState = _deriveSurface(saved);
      notifyListeners();
      final push = afterLocalWrite;
      if (push != null && isSharedDemo) {
        try {
          sharedDeliveryFailed = !(await push());
        } catch (_) {
          sharedDeliveryFailed = true;
        }
        notifyListeners();
      }
    } on UnauthorizedCareActionException {
      errorMessage = MemoraCopy.supportedPersonProfileUnauthorized;
      successMessage = null;
      notifyListeners();
    } on ArgumentError {
      // Domain rejected before write — preserve draft + current saved value.
      errorMessage = MemoraCopy.supportedPersonProfileValidationError;
      successMessage = null;
      notifyListeners();
    } catch (_) {
      errorMessage = MemoraCopy.syncFailed;
      successMessage = null;
      notifyListeners();
    }
  }

  Future<void> recover() async {
    if (sharedDeliveryFailed || sharedPullFailed) {
      await refreshFromSharedRemote();
      return;
    }
    await load();
  }

  PresentationSurfaceState _deriveSurface(SupportedPersonProfile? value) {
    if (value == null) {
      return PresentationSurfaceState.empty;
    }
    if (value.syncState == SyncState.conflicted) {
      return PresentationSurfaceState.conflicted;
    }
    if (value.syncState == SyncState.failed) {
      return PresentationSurfaceState.failed;
    }
    if (!networkAvailable) {
      return PresentationSurfaceState.offline;
    }
    return PresentationSurfaceState.ready;
  }
}
