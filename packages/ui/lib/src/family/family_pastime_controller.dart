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
  Future<bool> Function()? afterLocalWrite;

  /// Optional quiet pull before presenting shared-demo pastimes.
  Future<bool> Function()? quietRemotePull;

  PresentationSurfaceState surfaceState = PresentationSurfaceState.loading;
  List<Pastime> pastimes = const <Pastime>[];
  String? errorMessage;

  bool isRefreshingShared = false;
  bool sharedDeliveryFailed = false;
  bool sharedPullFailed = false;

  PastimeId? editingPastimeId;
  String draftTitle = '';
  String draftInstruction = '';
  String draftExperienceType = GuidedPastimeExperience.wireType;
  SudokuBoardSize draftSudokuSize = SudokuBoardSize.fourByFour;
  String draftSudokuPackId = SudokuPuzzlePackCatalog.starter4;
  WordSearchBoardSize draftWordSearchSize = WordSearchBoardSize.eightByEight;
  String draftWordSetId = WordSearchWordSetCatalog.jardinDemo;
  SpiderSuitCount draftSpiderSuits = SpiderSuitCount.one;

  /// Saved type when editing; used to require type-change confirmation.
  String? _savedExperienceType;
  int editorRevision = 0;

  /// When non-null, UI should show type-change confirmation before applying.
  String? pendingTypeChange;

  bool get canEdit => PastimeCarePolicy.canEditPastimes(actor);

  bool get isSharedDemo => demoDataScope == DemoDataScope.sharedLocalDemo;

  bool get needsActionableSyncNotice =>
      sharedDeliveryFailed ||
      sharedPullFailed ||
      surfaceState == PresentationSurfaceState.failed ||
      surfaceState == PresentationSurfaceState.conflicted;

  PastimeExperience? get draftExperience {
    try {
      return _buildExperience(draftExperienceType);
    } on Object {
      return null;
    }
  }

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
    _savedExperienceType = null;
    pendingTypeChange = null;
    draftTitle = '';
    draftInstruction = '';
    _resetExperienceDraft(GuidedPastimeExperience.wireType);
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
    pendingTypeChange = null;
    _applyExperienceToDraft(pastime.experience);
    _savedExperienceType = draftExperienceType;
    editorRevision += 1;
    errorMessage = null;
    if (pastime.experience is QuarantinedPastimeExperience) {
      errorMessage = (pastime.experience as QuarantinedPastimeExperience)
          .plainLanguageReason;
    }
    notifyListeners();
  }

  void setDraftTitle(String value) => draftTitle = value;

  void setDraftInstruction(String value) => draftInstruction = value;

  /// Requests a type change; may set [pendingTypeChange] for UI confirmation.
  void requestExperienceType(String wireType) {
    if (wireType == draftExperienceType) {
      return;
    }
    final saved = _savedExperienceType;
    if (saved != null && wireType != saved && pendingTypeChange == null) {
      pendingTypeChange = wireType;
      notifyListeners();
      return;
    }
    _applyTypeChange(wireType);
  }

  void confirmPendingTypeChange() {
    final pending = pendingTypeChange;
    if (pending == null) {
      return;
    }
    pendingTypeChange = null;
    _applyTypeChange(pending);
  }

  void cancelPendingTypeChange() {
    pendingTypeChange = null;
    notifyListeners();
  }

  void setDraftSudokuSize(SudokuBoardSize size) {
    draftSudokuSize = size;
    draftSudokuPackId = switch (size) {
      SudokuBoardSize.fourByFour => SudokuPuzzlePackCatalog.starter4,
      SudokuBoardSize.sixBySix => SudokuPuzzlePackCatalog.starter6,
      SudokuBoardSize.nineByNine => SudokuPuzzlePackCatalog.starter9,
    };
    notifyListeners();
  }

  void setDraftWordSearchSize(WordSearchBoardSize size) {
    draftWordSearchSize = size;
    notifyListeners();
  }

  void setDraftWordSetId(String id) {
    draftWordSetId = id;
    notifyListeners();
  }

  void setDraftSpiderSuits(SpiderSuitCount suits) {
    draftSpiderSuits = suits;
    notifyListeners();
  }

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
      errorMessage = MemoraCopy.pastimesValidationError;
      notifyListeners();
      return;
    }
    final PastimeExperience experience;
    try {
      experience = _buildExperience(draftExperienceType);
    } on Object {
      errorMessage = MemoraCopy.pastimesExperienceValidationError;
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
          experience: experience,
          idempotencyKey: _ids.nextIdempotencyKey('pastime-create'),
        );
      } else {
        final typeChanged =
            _savedExperienceType != null &&
            experience.typeWireName != _savedExperienceType;
        await _configure.edit(
          actor: actor,
          id: editingPastimeId!,
          title: title,
          instruction: instruction,
          experience: experience,
          confirmExperienceTypeChange: typeChanged,
          idempotencyKey: _ids.nextIdempotencyKey('pastime-edit'),
        );
      }
      editingPastimeId = null;
      _savedExperienceType = null;
      pendingTypeChange = null;
      draftTitle = '';
      draftInstruction = '';
      _resetExperienceDraft(GuidedPastimeExperience.wireType);
      editorRevision += 1;
      errorMessage = null;
      await load();
      await _runAfterLocalWrite();
    } on ArgumentError {
      errorMessage = MemoraCopy.pastimesExperienceValidationError;
      notifyListeners();
    } on StateError catch (error) {
      final message = error.toString();
      if (message.contains('confirmExperienceTypeChange')) {
        pendingTypeChange = draftExperienceType;
        errorMessage = MemoraCopy.pastimeTypeChangeConfirm;
      } else {
        errorMessage = MemoraCopy.pastimesValidationError;
      }
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
    } on ArgumentError {
      errorMessage = MemoraCopy.pastimesActivateExperienceError;
      notifyListeners();
    } on StateError catch (error) {
      final message = error.toString();
      if (message.contains('active pastimes')) {
        errorMessage = MemoraCopy.pastimesActiveLimitError;
      } else if (message.contains('incomplete') ||
          message.contains('unsupported') ||
          message.contains('quarantined') ||
          message.contains('experience')) {
        errorMessage = MemoraCopy.pastimesActivateExperienceError;
      } else {
        errorMessage = message;
      }
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

  void _applyTypeChange(String wireType) {
    _resetExperienceDraft(wireType);
    notifyListeners();
  }

  void _resetExperienceDraft(String wireType) {
    draftExperienceType = wireType;
    draftSudokuSize = SudokuBoardSize.fourByFour;
    draftSudokuPackId = SudokuPuzzlePackCatalog.starter4;
    draftWordSearchSize = WordSearchBoardSize.eightByEight;
    draftWordSetId = WordSearchWordSetCatalog.jardinDemo;
    draftSpiderSuits = SpiderSuitCount.one;
  }

  void _applyExperienceToDraft(PastimeExperience experience) {
    switch (experience) {
      case GuidedPastimeExperience():
        _resetExperienceDraft(GuidedPastimeExperience.wireType);
      case SudokuPastimeExperience(:final boardSize, :final puzzlePackId):
        draftExperienceType = SudokuPastimeExperience.wireType;
        draftSudokuSize = boardSize;
        draftSudokuPackId = puzzlePackId;
      case WordSearchPastimeExperience(:final boardSize, :final wordSetId):
        draftExperienceType = WordSearchPastimeExperience.wireType;
        draftWordSearchSize = boardSize;
        draftWordSetId = wordSetId;
      case SpiderSolitairePastimeExperience(:final suitCount):
        draftExperienceType = SpiderSolitairePastimeExperience.wireType;
        draftSpiderSuits = suitCount;
      case QuarantinedPastimeExperience():
        _resetExperienceDraft(GuidedPastimeExperience.wireType);
    }
  }

  PastimeExperience _buildExperience(String wireType) {
    return switch (wireType) {
      GuidedPastimeExperience.wireType => const GuidedPastimeExperience(),
      SudokuPastimeExperience.wireType => SudokuPastimeExperience(
        boardSize: draftSudokuSize,
        puzzlePackId: draftSudokuPackId,
      ),
      WordSearchPastimeExperience.wireType => WordSearchPastimeExperience(
        boardSize: draftWordSearchSize,
        wordSetId: draftWordSetId,
      ),
      SpiderSolitairePastimeExperience.wireType =>
        SpiderSolitairePastimeExperience(suitCount: draftSpiderSuits),
      _ => throw ArgumentError.value(wireType, 'wireType'),
    };
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
