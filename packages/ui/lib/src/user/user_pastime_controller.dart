import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../demo/demo_data_scope.dart';
import '../l10n/memora_copy.dart';
import '../sync/presentation_sync.dart' show PresentationSurfaceState;
import 'pastimes/platform/preferred_orientations_port.dart';

/// Supported-person pastime surface phase.
enum UserPastimePhase {
  list,
  guidedDetail,
  intro,
  recoveryOffer,
  playing,
  completed,
}

/// Supported-person active pastime viewing + native playable sessions.
///
/// Never exposes drafts, archived cards, sync jargon, scores or completion
/// claims beyond the neutral finished copy. Session recovery is device-local.
final class UserPastimeController extends ChangeNotifier {
  UserPastimeController({
    required this.actor,
    required PastimeRepository pastimes,
    this.networkAvailable = false,
    this.demoDataScope = DemoDataScope.isolatedLocal,
    PastimeSessionRecoveryPort? sessionRecovery,
    int Function()? seedFactory,
    DateTime Function()? clock,
    ConfigurePastime? configurePastime,
    PreferredOrientationsPort? orientations,
  }) : _configure = configurePastime ?? ConfigurePastime(pastimes),
       _sessionRecovery = sessionRecovery,
       _orientations = orientations ?? const NoopPreferredOrientationsPort(),
       _seedFactory =
           seedFactory ??
           (() => DateTime.now().toUtc().millisecondsSinceEpoch & 0x7fffffff),
       _clock = clock ?? DateTime.now;

  final FamilyMembership actor;
  final ConfigurePastime _configure;
  final PastimeSessionRecoveryPort? _sessionRecovery;
  final PreferredOrientationsPort _orientations;
  final int Function() _seedFactory;
  final DateTime Function() _clock;

  /// Injectable orientation boundary (Spider landscape lock).
  PreferredOrientationsPort get orientations => _orientations;

  bool networkAvailable;
  DemoDataScope demoDataScope;

  Future<bool> Function()? quietRemotePull;

  PresentationSurfaceState surfaceState = PresentationSurfaceState.loading;
  List<Pastime> pastimes = const <Pastime>[];
  String? errorMessage;

  PastimeId? selectedPastimeId;
  UserPastimePhase phase = UserPastimePhase.list;

  bool sharedPullFailed = false;
  bool isRefreshingShared = false;

  /// Plain guidance from the active board (conflicts, illegal moves, etc.).
  String? boardGuidance;

  /// Active playable session state (exactly one engine at a time).
  SudokuEngine? _sudokuEngine;
  SudokuGameState? sudokuState;
  WordSearchEngine? _wordSearchEngine;
  WordSearchGameState? wordSearchState;
  SpiderEngine? _spiderEngine;
  SpiderGameState? spiderState;
  int? sessionSeed;
  bool notesMode = false;

  PastimeSessionRecoverySnapshot? pendingRecovery;

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

  bool get isPlayableSelected {
    final exp = selectedPastime?.experience;
    return exp is SudokuPastimeExperience ||
        exp is WordSearchPastimeExperience ||
        exp is SpiderSolitairePastimeExperience;
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
    _clearSession(clearSelection: true);
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

  Future<void> refreshActive() async {
    try {
      final listed = await _configure.listActiveForViewing(
        actor: actor,
        familySpaceId: actor.familySpaceId,
      );
      pastimes = listed;
      if (selectedPastimeId != null &&
          !pastimes.any((p) => p.id == selectedPastimeId)) {
        // Open session may finish; cannot reopen from list.
        if (phase == UserPastimePhase.playing ||
            phase == UserPastimePhase.completed) {
          // Keep finishing current local session without list re-entry later.
        } else {
          _clearSession(clearSelection: true);
        }
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
      // Keep cached pastimes.
    }
    notifyListeners();
  }

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

  Future<void> openDetail(PastimeId id) async {
    selectedPastimeId = id;
    boardGuidance = null;
    pendingRecovery = null;
    final pastime = selectedPastime;
    if (pastime == null) {
      phase = UserPastimePhase.list;
      selectedPastimeId = null;
      notifyListeners();
      return;
    }
    final experience = pastime.experience;
    if (!experience.isCompleteAndSupported ||
        experience is QuarantinedPastimeExperience) {
      errorMessage = MemoraCopy.pasatiemposUnavailable;
      phase = UserPastimePhase.list;
      selectedPastimeId = null;
      notifyListeners();
      return;
    }
    if (experience is GuidedPastimeExperience) {
      phase = UserPastimePhase.guidedDetail;
      notifyListeners();
      return;
    }
    final snapshot = await _loadMatchingRecovery(pastime);
    if (snapshot != null) {
      pendingRecovery = snapshot;
      phase = UserPastimePhase.recoveryOffer;
    } else {
      phase = UserPastimePhase.intro;
    }
    notifyListeners();
  }

  void returnToList() {
    _clearSession(clearSelection: true);
    notifyListeners();
  }

  Future<void> startFresh() async {
    final pastime = selectedPastime;
    if (pastime == null || !isPlayableSelected) {
      return;
    }
    await _sessionRecovery?.clear();
    pendingRecovery = null;
    final seed = _seedFactory();
    _beginPlay(pastime, seed: seed, recover: null);
  }

  Future<void> continueRecovery() async {
    final pastime = selectedPastime;
    final snapshot = pendingRecovery;
    if (pastime == null || snapshot == null) {
      phase = UserPastimePhase.intro;
      notifyListeners();
      return;
    }
    try {
      _beginPlay(pastime, seed: snapshot.seed, recover: snapshot);
    } on Object {
      await _sessionRecovery?.clear();
      pendingRecovery = null;
      boardGuidance = MemoraCopy.pasatiemposRecoveryDiscarded;
      phase = UserPastimePhase.intro;
      notifyListeners();
    }
  }

  Future<void> discardRecoveryAndStart() async {
    await _sessionRecovery?.clear();
    pendingRecovery = null;
    await startFresh();
  }

  void _beginPlay(
    Pastime pastime, {
    required int seed,
    required PastimeSessionRecoverySnapshot? recover,
  }) {
    boardGuidance = null;
    notesMode = false;
    sessionSeed = seed;
    _sudokuEngine = null;
    sudokuState = null;
    _wordSearchEngine = null;
    wordSearchState = null;
    _spiderEngine = null;
    spiderState = null;

    final experience = pastime.experience;
    switch (experience) {
      case SudokuPastimeExperience():
        final engine = SudokuEngine();
        _sudokuEngine = engine;
        if (recover != null) {
          sudokuState = SudokuGameState.fromRecoveryMap(recover.boardState);
        } else {
          sudokuState = engine.start(experience: experience, seed: seed);
        }
      case WordSearchPastimeExperience():
        final engine = WordSearchEngine();
        _wordSearchEngine = engine;
        if (recover != null) {
          wordSearchState = WordSearchGameState.fromRecoveryMap(
            recover.boardState,
          );
        } else {
          wordSearchState = engine.start(experience: experience, seed: seed);
        }
      case SpiderSolitairePastimeExperience():
        final engine = SpiderEngine();
        _spiderEngine = engine;
        if (recover != null) {
          spiderState = SpiderGameState.fromRecoveryMap(recover.boardState);
        } else {
          spiderState = engine.start(experience: experience, seed: seed);
        }
      case GuidedPastimeExperience() || QuarantinedPastimeExperience():
        phase = UserPastimePhase.guidedDetail;
        notifyListeners();
        return;
    }
    phase = UserPastimePhase.playing;
    notifyListeners();
    _persistRecovery();
  }

  Future<void> finishSession({required bool confirmed}) async {
    if (!confirmed) {
      return;
    }
    await _sessionRecovery?.clear();
    _clearSession(clearSelection: true);
    notifyListeners();
  }

  Future<void> restartSession({required bool confirmed}) async {
    if (!confirmed) {
      return;
    }
    final pastime = selectedPastime;
    final seed = sessionSeed;
    if (pastime == null || seed == null) {
      return;
    }
    boardGuidance = null;
    notesMode = false;
    switch (pastime.experience) {
      case SudokuPastimeExperience():
        final engine = _sudokuEngine ?? SudokuEngine();
        _sudokuEngine = engine;
        sudokuState = engine.restart(sudokuState!);
      case WordSearchPastimeExperience():
        final engine = _wordSearchEngine ?? WordSearchEngine();
        _wordSearchEngine = engine;
        wordSearchState = engine.restart(wordSearchState!);
      case SpiderSolitairePastimeExperience():
        final engine = _spiderEngine ?? SpiderEngine();
        _spiderEngine = engine;
        spiderState = engine.restart(spiderState!);
      case GuidedPastimeExperience() || QuarantinedPastimeExperience():
        return;
    }
    phase = UserPastimePhase.playing;
    notifyListeners();
    await _persistRecovery();
  }

  Future<void> playAgain() async {
    await startFresh();
  }

  // —— Sudoku actions ——

  void sudokuSelectCell(int index) {
    final engine = _sudokuEngine;
    final state = sudokuState;
    if (engine == null ||
        state == null ||
        state.completed ||
        state.solutionRevealed) {
      return;
    }
    sudokuState = engine.selectCell(state, index);
    boardGuidance = null;
    notifyListeners();
    _persistRecovery();
  }

  void sudokuEnterNumber(int number) {
    final engine = _sudokuEngine;
    final state = sudokuState;
    if (engine == null ||
        state == null ||
        state.completed ||
        state.solutionRevealed) {
      return;
    }
    if (notesMode) {
      sudokuState = engine.toggleNote(state, number);
      boardGuidance = null;
    } else {
      final result = engine.enterNumber(state, number);
      sudokuState = result.state;
      boardGuidance = result.conflictMessage;
      if (result.state.completed) {
        phase = UserPastimePhase.completed;
        _sessionRecovery?.clear();
      }
    }
    notifyListeners();
    if (phase == UserPastimePhase.playing) {
      _persistRecovery();
    }
  }

  void sudokuClearCell() {
    final engine = _sudokuEngine;
    final state = sudokuState;
    if (engine == null ||
        state == null ||
        state.completed ||
        state.solutionRevealed) {
      return;
    }
    sudokuState = engine.clearCell(state);
    boardGuidance = null;
    notifyListeners();
    _persistRecovery();
  }

  void sudokuUndo() {
    final engine = _sudokuEngine;
    final state = sudokuState;
    if (engine == null || state == null) {
      return;
    }
    final undone = engine.undo(state);
    if (undone != null) {
      sudokuState = undone;
      boardGuidance = null;
      notifyListeners();
      _persistRecovery();
    }
  }

  void toggleNotesMode() {
    notesMode = !notesMode;
    notifyListeners();
  }

  void sudokuRevealSolution({required bool confirmed}) {
    if (!confirmed) {
      return;
    }
    final engine = _sudokuEngine;
    final state = sudokuState;
    if (engine == null || state == null || state.solutionRevealed) {
      return;
    }
    // Keep the solved board visible in the player shell until an explicit
    // continue/leave/restart — do not jump straight to the completion panel.
    sudokuState = engine.revealSolution(state);
    phase = UserPastimePhase.playing;
    boardGuidance = null;
    _sessionRecovery?.clear();
    notifyListeners();
  }

  /// Leaves the revealed-solution board for the neutral completion surface.
  void acknowledgeSudokuSolution() {
    final state = sudokuState;
    if (state == null || !state.solutionRevealed) {
      return;
    }
    phase = UserPastimePhase.completed;
    boardGuidance = null;
    notifyListeners();
  }

  // —— Word search actions ——

  void wordSearchTapCell(WordSearchCell cell) {
    final engine = _wordSearchEngine;
    final state = wordSearchState;
    if (engine == null || state == null || state.completed) {
      return;
    }
    if (state.anchor == null || state.anchor == cell) {
      wordSearchState = engine.tapCell(state, cell);
      boardGuidance = null;
    } else {
      _applyWordSearchResult(
        engine.selectEndpoints(state, state.anchor!, cell),
      );
      return;
    }
    notifyListeners();
    if (phase == UserPastimePhase.playing) {
      _persistRecovery();
    }
  }

  /// Primary touch path: submit a drag (or accessibility) endpoint pair.
  void wordSearchSelectEndpoints(WordSearchCell start, WordSearchCell end) {
    final engine = _wordSearchEngine;
    final state = wordSearchState;
    if (engine == null || state == null || state.completed) {
      return;
    }
    _applyWordSearchResult(engine.selectEndpoints(state, start, end));
  }

  void _applyWordSearchResult(WordSearchSelectResult result) {
    wordSearchState = result.state;
    boardGuidance = result.neutralGuidance;
    if (result.state.completed) {
      phase = UserPastimePhase.completed;
      _sessionRecovery?.clear();
    }
    notifyListeners();
    if (phase == UserPastimePhase.playing) {
      _persistRecovery();
    }
  }

  void wordSearchClearSelection() {
    final engine = _wordSearchEngine;
    final state = wordSearchState;
    if (engine == null || state == null) {
      return;
    }
    wordSearchState = engine.clearSelection(state);
    boardGuidance = null;
    notifyListeners();
  }

  // —— Spider actions ——

  void spiderTapCard(int column, int index) {
    final engine = _spiderEngine;
    final state = spiderState;
    if (engine == null || state == null || state.completed) {
      return;
    }
    final result = engine.tapCard(state, column, index);
    spiderState = result.state;
    boardGuidance = result.neutralMessage;
    if (result.state.completed) {
      phase = UserPastimePhase.completed;
      _sessionRecovery?.clear();
    }
    notifyListeners();
    if (phase == UserPastimePhase.playing) {
      _persistRecovery();
    }
  }

  void spiderTapColumn(int column) {
    final engine = _spiderEngine;
    final state = spiderState;
    if (engine == null || state == null || state.completed) {
      return;
    }
    final result = engine.tapColumnDestination(state, column);
    spiderState = result.state;
    boardGuidance = result.neutralMessage;
    if (result.state.completed) {
      phase = UserPastimePhase.completed;
      _sessionRecovery?.clear();
    }
    notifyListeners();
    if (phase == UserPastimePhase.playing) {
      _persistRecovery();
    }
  }

  void spiderDealStock() {
    final engine = _spiderEngine;
    final state = spiderState;
    if (engine == null || state == null || state.completed) {
      return;
    }
    final result = engine.dealStock(state);
    spiderState = result.state;
    boardGuidance = result.neutralMessage;
    notifyListeners();
    _persistRecovery();
  }

  void spiderUndo() {
    final engine = _spiderEngine;
    final state = spiderState;
    if (engine == null || state == null) {
      return;
    }
    final undone = engine.undo(state);
    if (undone != null) {
      spiderState = undone;
      boardGuidance = null;
      notifyListeners();
      _persistRecovery();
    }
  }

  void spiderShowHint() {
    final engine = _spiderEngine;
    final state = spiderState;
    if (engine == null || state == null || state.completed) {
      return;
    }
    spiderState = engine.showHint(state);
    notifyListeners();
  }

  Future<PastimeSessionRecoverySnapshot?> _loadMatchingRecovery(
    Pastime pastime,
  ) async {
    final port = _sessionRecovery;
    if (port == null) {
      return null;
    }
    try {
      final snapshot = await port.loadCurrent();
      if (snapshot == null) {
        return null;
      }
      if (snapshot.isExpiredAt(_clock())) {
        await port.clear();
        return null;
      }
      if (snapshot.pastimeId != pastime.id) {
        return null;
      }
      if (!snapshot.matchesDefinition(
        experienceType: pastime.experience.typeWireName,
        experienceSchemaVersion: pastime.experience.schemaVersion,
      )) {
        await port.clearIfMatches(
          pastimeId: pastime.id,
          experienceType: pastime.experience.typeWireName,
          experienceSchemaVersion: pastime.experience.schemaVersion,
        );
        return null;
      }
      return snapshot;
    } on Object {
      await port.clear();
      return null;
    }
  }

  Future<void> _persistRecovery() async {
    final port = _sessionRecovery;
    final pastime = selectedPastime;
    final seed = sessionSeed;
    if (port == null ||
        pastime == null ||
        seed == null ||
        phase != UserPastimePhase.playing) {
      return;
    }
    final Map<String, Object?> boardState;
    if (sudokuState != null) {
      boardState = sudokuState!.toRecoveryMap();
    } else if (wordSearchState != null) {
      boardState = wordSearchState!.toRecoveryMap();
    } else if (spiderState != null) {
      boardState = spiderState!.toRecoveryMap();
    } else {
      return;
    }
    try {
      await port.save(
        PastimeSessionRecoverySnapshot(
          pastimeId: pastime.id,
          experienceType: pastime.experience.typeWireName,
          experienceSchemaVersion: pastime.experience.schemaVersion,
          seed: seed,
          boardState: boardState,
          updatedAt: _clock().toUtc(),
        ),
      );
    } on Object {
      // Recovery is best-effort; never crash play.
    }
  }

  void _clearSession({required bool clearSelection}) {
    phase = UserPastimePhase.list;
    if (clearSelection) {
      selectedPastimeId = null;
    }
    pendingRecovery = null;
    boardGuidance = null;
    notesMode = false;
    sessionSeed = null;
    _sudokuEngine = null;
    sudokuState = null;
    _wordSearchEngine = null;
    wordSearchState = null;
    _spiderEngine = null;
    spiderState = null;
  }
}
