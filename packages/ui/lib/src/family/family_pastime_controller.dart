import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../demo/demo_data_scope.dart';
import '../demo/demo_ids.dart';
import '../l10n/memora_copy.dart';
import '../sync/presentation_sync.dart';

/// Caregiver/family pastime configure controller over [ConfigurePastime].
///
/// UI visibility uses [PastimeCarePolicy]; domain remains authoritative.
final class FamilyPastimeController extends ChangeNotifier {
  FamilyPastimeController({
    required this.actor,
    required PastimeRepository pastimes,
    this.networkAvailable = false,
    this.demoDataScope = DemoDataScope.isolatedLocal,
    this.afterLocalWrite,
    DemoIds? ids,
    ConfigurePastime? configurePastime,
  }) : _pastimes = pastimes,
       _ids = ids ?? DemoIds(),
       _configure = configurePastime ?? ConfigurePastime(pastimes);

  final FamilyMembership actor;
  final PastimeRepository _pastimes;
  final ConfigurePastime _configure;
  final DemoIds _ids;

  bool networkAvailable;
  DemoDataScope demoDataScope;

  /// Optional quiet push after a successful local pastime write (shared demo).
  ///
  /// Returns `true` when the shared delivery succeeded.
  Future<bool> Function()? afterLocalWrite;

  /// Optional quiet pull before presenting shared-demo pastimes.
  Future<bool> Function()? quietRemotePull;

  PresentationSurfaceState surfaceState = PresentationSurfaceState.loading;
  List<Pastime> pastimes = const <Pastime>[];
  String? errorMessage;

  /// True while a shared quiet pull is in flight (cached rows stay visible).
  bool isRefreshingShared = false;

  /// Shared push did not reach the other client; local rows remain usable.
  bool sharedDeliveryFailed = false;

  /// Shared pull could not refresh; cached rows remain usable.
  bool sharedPullFailed = false;

  PastimeId? editingPastimeId;
  String draftTitle = '';
  String draftInstruction = '';
  int editorRevision = 0;

  bool get canEdit => PastimeCarePolicy.canEditPastimes(actor);

  bool get isSharedDemo => demoDataScope == DemoDataScope.sharedLocalDemo;

  String get syncLabel {
    if (isRefreshingShared) {
      return MemoraCopy.sharedLocalDemoPending;
    }
    if (sharedDeliveryFailed) {
      return MemoraCopy.sharedLocalDemoDeliveryFailed;
    }
    if (sharedPullFailed) {
      return MemoraCopy.sharedLocalDemoPullFailed;
    }
    if (surfaceState == PresentationSurfaceState.loading) {
      return MemoraCopy.pasatiemposLoading;
    }
    if (surfaceState == PresentationSurfaceState.empty) {
      return networkAvailable
          ? MemoraCopy.pastimesEmptyConfigure
          : '${MemoraCopy.pastimesEmptyConfigure} ${MemoraCopy.pasatiemposOffline}';
    }
    if (surfaceState == PresentationSurfaceState.failed) {
      return MemoraCopy.syncFailed;
    }
    if (surfaceState == PresentationSurfaceState.conflicted) {
      return MemoraCopy.syncConflicted;
    }
    if (!networkAvailable || surfaceState == PresentationSurfaceState.offline) {
      return MemoraCopy.pasatiemposOffline;
    }
    return SyncStatusLabels.forSyncState(_worstSync());
  }

  String? get recoveryActionLabel {
    if (sharedDeliveryFailed || sharedPullFailed) {
      return MemoraCopy.recoveryRetry;
    }
    return switch (surfaceState) {
      PresentationSurfaceState.failed => MemoraCopy.recoveryRetry,
      PresentationSurfaceState.conflicted => MemoraCopy.recoveryReviewConflict,
      PresentationSurfaceState.offline => MemoraCopy.recoveryContinueOffline,
      PresentationSurfaceState.empty =>
        canEdit ? MemoraCopy.createPastime : null,
      PresentationSurfaceState.loading => null,
      PresentationSurfaceState.ready =>
        !networkAvailable ? MemoraCopy.recoveryContinueOffline : null,
    };
  }

  Future<void> load() async {
    final keepCached = pastimes.isNotEmpty;
    if (!keepCached) {
      surfaceState = PresentationSurfaceState.loading;
    }
    if (!isSharedDemo) {
      errorMessage = null;
      sharedDeliveryFailed = false;
      sharedPullFailed = false;
    }
    notifyListeners();
    try {
      final listed = await _pastimes.listForFamily(actor.familySpaceId);
      pastimes = listed.where((p) => !p.isDeleted).toList(growable: false)
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      surfaceState = _deriveSurface(pastimes);
      if (!isSharedDemo) {
        errorMessage = null;
      }
    } catch (error) {
      errorMessage = error.toString();
      surfaceState = PresentationSurfaceState.failed;
    }
    notifyListeners();
  }

  /// Quiet pull + local reload for shared-demo destination entry / retry.
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
    await load();
    isRefreshingShared = false;
    sharedPullFailed = !pullOk;
    if (sharedPullFailed) {
      errorMessage = MemoraCopy.sharedLocalDemoPullFailed;
    } else if (!sharedDeliveryFailed) {
      errorMessage = null;
    }
    notifyListeners();
  }

  Future<void> recover() async {
    if (sharedDeliveryFailed) {
      await _retrySharedDelivery();
      return;
    }
    if (sharedPullFailed || isSharedDemo) {
      await refreshFromSharedRemote();
      return;
    }
    if (surfaceState == PresentationSurfaceState.empty) {
      beginCreate();
      return;
    }
    if (surfaceState == PresentationSurfaceState.offline ||
        (!networkAvailable && surfaceState == PresentationSurfaceState.ready)) {
      surfaceState = pastimes.isEmpty
          ? PresentationSurfaceState.empty
          : PresentationSurfaceState.ready;
      notifyListeners();
      return;
    }
    await load();
  }

  Future<void> _retrySharedDelivery() async {
    final hook = afterLocalWrite;
    if (hook == null) {
      sharedDeliveryFailed = false;
      errorMessage = null;
      notifyListeners();
      return;
    }
    isRefreshingShared = true;
    notifyListeners();
    var ok = false;
    try {
      ok = await hook();
    } catch (_) {
      ok = false;
    }
    isRefreshingShared = false;
    sharedDeliveryFailed = !ok;
    errorMessage = ok ? null : MemoraCopy.sharedLocalDemoDeliveryFailed;
    notifyListeners();
  }

  void beginCreate() {
    if (!canEdit) {
      errorMessage = MemoraCopy.pastimesUnauthorized;
      notifyListeners();
      return;
    }
    editingPastimeId = null;
    draftTitle = '';
    draftInstruction = '';
    editorRevision += 1;
    errorMessage = null;
    notifyListeners();
  }

  void beginEdit(Pastime pastime) {
    if (!canEdit) {
      errorMessage = MemoraCopy.pastimesUnauthorized;
      notifyListeners();
      return;
    }
    editingPastimeId = pastime.id;
    draftTitle = pastime.title;
    draftInstruction = pastime.instruction;
    editorRevision += 1;
    errorMessage = null;
    notifyListeners();
  }

  void setDraftTitle(String value) => draftTitle = value;

  void setDraftInstruction(String value) => draftInstruction = value;

  Future<void> saveDraft() async {
    if (!canEdit) {
      errorMessage = MemoraCopy.pastimesUnauthorized;
      notifyListeners();
      return;
    }
    final title = draftTitle.trim();
    final instruction = draftInstruction.trim();
    if (title.isEmpty ||
        title.length > Pastime.maxTitleLength ||
        instruction.isEmpty ||
        instruction.length > Pastime.maxInstructionLength) {
      // Keep draft fields; do not bump editorRevision.
      errorMessage = MemoraCopy.pastimesValidationError;
      notifyListeners();
      return;
    }
    try {
      if (editingPastimeId == null) {
        await _configure.create(
          actor: actor,
          id: _ids.nextPastimeId(),
          familySpaceId: actor.familySpaceId,
          title: title,
          instruction: instruction,
          idempotencyKey: _ids.nextIdempotencyKey('pastime-create'),
        );
      } else {
        await _configure.edit(
          actor: actor,
          id: editingPastimeId!,
          title: title,
          instruction: instruction,
          idempotencyKey: _ids.nextIdempotencyKey('pastime-edit'),
        );
      }
      editingPastimeId = null;
      draftTitle = '';
      draftInstruction = '';
      editorRevision += 1;
      errorMessage = null;
      await load();
      await _runAfterLocalWrite();
    } on ArgumentError {
      errorMessage = MemoraCopy.pastimesValidationError;
      notifyListeners();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> activate(PastimeId id) async {
    if (!canEdit) {
      errorMessage = MemoraCopy.pastimesUnauthorized;
      notifyListeners();
      return;
    }
    try {
      await _configure.activate(
        actor: actor,
        id: id,
        idempotencyKey: _ids.nextIdempotencyKey('pastime-activate'),
      );
      errorMessage = null;
      await load();
      await _runAfterLocalWrite();
    } on StateError catch (error) {
      final message = error.toString();
      errorMessage = message.contains('active pastimes')
          ? MemoraCopy.pastimesActiveLimitError
          : message;
      notifyListeners();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> archive(PastimeId id) async {
    if (!canEdit) {
      errorMessage = MemoraCopy.pastimesUnauthorized;
      notifyListeners();
      return;
    }
    try {
      await _configure.archive(
        actor: actor,
        id: id,
        idempotencyKey: _ids.nextIdempotencyKey('pastime-archive'),
      );
      errorMessage = null;
      await load();
      await _runAfterLocalWrite();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> move(Pastime pastime, int delta) async {
    if (!canEdit) {
      errorMessage = MemoraCopy.pastimesUnauthorized;
      notifyListeners();
      return;
    }
    final index = pastimes.indexWhere((p) => p.id == pastime.id);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= pastimes.length) {
      return;
    }
    final ordered = [...pastimes];
    final item = ordered.removeAt(index);
    ordered.insert(target, item);
    try {
      await _configure.reorder(
        actor: actor,
        familySpaceId: actor.familySpaceId,
        orderedIds: ordered.map((p) => p.id).toList(growable: false),
        idempotencyKey: _ids.nextIdempotencyKey('pastime-reorder'),
      );
      errorMessage = null;
      await load();
      await _runAfterLocalWrite();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> _runAfterLocalWrite() async {
    final hook = afterLocalWrite;
    if (hook == null) {
      return;
    }
    var ok = false;
    try {
      ok = await hook();
    } catch (_) {
      ok = false;
    }
    if (!ok && isSharedDemo) {
      sharedDeliveryFailed = true;
      errorMessage = MemoraCopy.sharedLocalDemoDeliveryFailed;
      notifyListeners();
      return;
    }
    if (ok) {
      sharedDeliveryFailed = false;
      if (errorMessage == MemoraCopy.sharedLocalDemoDeliveryFailed) {
        errorMessage = null;
      }
      notifyListeners();
    }
  }

  PresentationSurfaceState _deriveSurface(List<Pastime> listed) {
    if (listed.isEmpty) {
      return PresentationSurfaceState.empty;
    }
    final worst = SyncStatusLabels.worstOf(listed.map((p) => p.syncState));
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
    if (pastimes.isEmpty) {
      return SyncState.local;
    }
    return SyncStatusLabels.worstOf(pastimes.map((p) => p.syncState));
  }
}
