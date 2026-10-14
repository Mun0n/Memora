import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../demo/demo_data_scope.dart';
import '../demo/demo_ids.dart';
import '../l10n/memora_copy.dart';
import '../sync/presentation_sync.dart';

/// Caregiver/family conversation-topic configure over [ConfigureConversationTopic].
///
/// UI visibility uses [ConversationTopicCarePolicy]; domain remains authoritative.
final class FamilyConversationTopicController extends ChangeNotifier {
  FamilyConversationTopicController({
    required this.actor,
    required ConversationTopicRepository topics,
    this.networkAvailable = false,
    this.demoDataScope = DemoDataScope.isolatedLocal,
    this.afterLocalWrite,
    DemoIds? ids,
    ConfigureConversationTopic? configureTopic,
  }) : _topics = topics,
       _ids = ids ?? DemoIds(),
       _configure = configureTopic ?? ConfigureConversationTopic(topics);

  final FamilyMembership actor;
  final ConversationTopicRepository _topics;
  final ConfigureConversationTopic _configure;
  final DemoIds _ids;

  bool networkAvailable;
  DemoDataScope demoDataScope;

  /// Optional quiet push after a successful local topic write (shared demo).
  Future<bool> Function()? afterLocalWrite;

  /// Optional quiet pull before presenting shared-demo topics.
  Future<bool> Function()? quietRemotePull;

  PresentationSurfaceState surfaceState = PresentationSurfaceState.loading;
  List<ConversationTopic> topics = const <ConversationTopic>[];
  List<MemoryEntry> approvedMemories = const <MemoryEntry>[];
  String? errorMessage;

  bool isRefreshingShared = false;
  bool sharedDeliveryFailed = false;
  bool sharedPullFailed = false;

  ConversationTopicId? editingTopicId;
  String draftTitle = '';
  String draftIntroduction = '';
  List<String> draftPrompts = <String>[''];

  /// Parallel to [draftPrompts]: optional cue text (empty = none).
  List<String> draftHelpCues = <String>[''];

  /// Parallel to [draftPrompts]: optional approved help-memory reference.
  List<MemoryId?> draftHelpMemoryIds = <MemoryId?>[null];

  String draftClosing = '';
  MemoryId? draftMemoryId;
  int editorRevision = 0;

  /// Prompt index awaiting explicit remove confirmation (help stays attached).
  int? pendingRemovePromptIndex;

  /// Zero-based prompt order of the last help validation failure, if any.
  int? helpErrorPromptOrder;

  bool get canEdit => ConversationTopicCarePolicy.canEditTopics(actor);

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
          ? MemoraCopy.conversationsEmptyConfigure
          : '${MemoraCopy.conversationsEmptyConfigure} '
                '${MemoraCopy.quieroHablarOffline}';
    }
    if (surfaceState == PresentationSurfaceState.failed) {
      return MemoraCopy.syncFailed;
    }
    if (surfaceState == PresentationSurfaceState.conflicted) {
      return MemoraCopy.syncConflicted;
    }
    if (!networkAvailable || surfaceState == PresentationSurfaceState.offline) {
      return MemoraCopy.quieroHablarOffline;
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
        canEdit ? MemoraCopy.createConversationTopic : null,
      PresentationSurfaceState.loading => null,
      PresentationSurfaceState.ready =>
        !networkAvailable ? MemoraCopy.recoveryContinueOffline : null,
    };
  }

  Future<void> load() async {
    final keepCached = topics.isNotEmpty;
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
      final listed = await _topics.listForFamily(actor.familySpaceId);
      topics = listed.where((t) => !t.isDeleted).toList(growable: false)
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      surfaceState = _deriveSurface(topics);
      if (!isSharedDemo) {
        errorMessage = null;
      }
    } catch (error) {
      errorMessage = error.toString();
      surfaceState = PresentationSurfaceState.failed;
    }
    notifyListeners();
  }

  void setApprovedMemories(List<MemoryEntry> memories) {
    approvedMemories = memories
        .where((m) => m.isApprovedForViewing)
        .toList(growable: false);
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
      surfaceState = topics.isEmpty
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
      errorMessage = MemoraCopy.conversationsUnauthorized;
      notifyListeners();
      return;
    }
    editingTopicId = null;
    draftTitle = '';
    draftIntroduction = '';
    draftPrompts = <String>[''];
    draftHelpCues = <String>[''];
    draftHelpMemoryIds = <MemoryId?>[null];
    draftClosing = '';
    draftMemoryId = null;
    pendingRemovePromptIndex = null;
    helpErrorPromptOrder = null;
    editorRevision += 1;
    errorMessage = null;
    notifyListeners();
  }

  void beginEdit(ConversationTopic topic) {
    if (!canEdit) {
      errorMessage = MemoraCopy.conversationsUnauthorized;
      notifyListeners();
      return;
    }
    editingTopicId = topic.id;
    draftTitle = topic.title;
    draftIntroduction = topic.introduction;
    draftPrompts = topic.prompts.map((p) => p.text).toList(growable: true);
    draftHelpCues = topic.prompts
        .map((p) => p.help?.cue ?? '')
        .toList(growable: true);
    draftHelpMemoryIds = topic.prompts
        .map((p) => p.help?.memoryId)
        .toList(growable: true);
    draftClosing = topic.closing;
    draftMemoryId = topic.memoryId;
    pendingRemovePromptIndex = null;
    helpErrorPromptOrder = null;
    editorRevision += 1;
    errorMessage = null;
    notifyListeners();
  }

  void setDraftTitle(String value) => draftTitle = value;

  void setDraftIntroduction(String value) => draftIntroduction = value;

  void setDraftClosing(String value) => draftClosing = value;

  void setDraftPrompt(int index, String value) {
    if (index < 0 || index >= draftPrompts.length) {
      return;
    }
    draftPrompts[index] = value;
  }

  void setDraftHelpCue(int index, String value) {
    if (index < 0 || index >= draftHelpCues.length) {
      return;
    }
    draftHelpCues[index] = value;
    if (helpErrorPromptOrder == index) {
      helpErrorPromptOrder = null;
    }
    notifyListeners();
  }

  void setDraftHelpMemoryId(int index, MemoryId? id) {
    if (index < 0 || index >= draftHelpMemoryIds.length) {
      return;
    }
    draftHelpMemoryIds[index] = id;
    if (helpErrorPromptOrder == index) {
      helpErrorPromptOrder = null;
    }
    notifyListeners();
  }

  void clearDraftHelp(int index) {
    if (index < 0 || index >= draftHelpCues.length) {
      return;
    }
    draftHelpCues[index] = '';
    draftHelpMemoryIds[index] = null;
    if (helpErrorPromptOrder == index) {
      helpErrorPromptOrder = null;
    }
    editorRevision += 1;
    notifyListeners();
  }

  bool draftHelpPresent(int index) {
    if (index < 0 || index >= draftHelpCues.length) {
      return false;
    }
    return draftHelpCues[index].trim().isNotEmpty ||
        draftHelpMemoryIds[index] != null;
  }

  MemoryEntry? approvedMemoryById(MemoryId? id) {
    if (id == null) {
      return null;
    }
    for (final memory in approvedMemories) {
      if (memory.id == id) {
        return memory;
      }
    }
    return null;
  }

  void setDraftMemoryId(MemoryId? id) {
    draftMemoryId = id;
    notifyListeners();
  }

  void addPromptField() {
    if (draftPrompts.length >= ConversationTopic.maxPrompts) {
      return;
    }
    draftPrompts = [...draftPrompts, ''];
    draftHelpCues = [...draftHelpCues, ''];
    draftHelpMemoryIds = [...draftHelpMemoryIds, null];
    pendingRemovePromptIndex = null;
    editorRevision += 1;
    notifyListeners();
  }

  /// Starts remove; if the invitation has help, waits for explicit confirmation.
  void requestRemovePromptField(int index) {
    if (draftPrompts.length <= ConversationTopic.minPrompts) {
      return;
    }
    if (index < 0 || index >= draftPrompts.length) {
      return;
    }
    if (draftHelpPresent(index)) {
      pendingRemovePromptIndex = index;
      notifyListeners();
      return;
    }
    removePromptField(index);
  }

  void cancelPendingRemovePrompt() {
    pendingRemovePromptIndex = null;
    notifyListeners();
  }

  void confirmPendingRemovePrompt() {
    final index = pendingRemovePromptIndex;
    pendingRemovePromptIndex = null;
    if (index == null) {
      return;
    }
    removePromptField(index);
  }

  void removePromptField(int index) {
    if (draftPrompts.length <= ConversationTopic.minPrompts) {
      return;
    }
    if (index < 0 || index >= draftPrompts.length) {
      return;
    }
    final nextPrompts = [...draftPrompts]..removeAt(index);
    final nextCues = [...draftHelpCues]..removeAt(index);
    final nextMemories = [...draftHelpMemoryIds]..removeAt(index);
    draftPrompts = nextPrompts;
    draftHelpCues = nextCues;
    draftHelpMemoryIds = nextMemories;
    pendingRemovePromptIndex = null;
    if (helpErrorPromptOrder != null) {
      if (helpErrorPromptOrder == index) {
        helpErrorPromptOrder = null;
      } else if (helpErrorPromptOrder! > index) {
        helpErrorPromptOrder = helpErrorPromptOrder! - 1;
      }
    }
    editorRevision += 1;
    notifyListeners();
  }

  Future<void> saveDraft() async {
    if (!canEdit) {
      errorMessage = MemoraCopy.conversationsUnauthorized;
      notifyListeners();
      return;
    }
    final title = draftTitle.trim();
    final introduction = draftIntroduction.trim();
    final closing = draftClosing.trim();
    final promptTexts = draftPrompts
        .map((p) => p.trim())
        .toList(growable: false);
    if (!_looksValid(
      title: title,
      introduction: introduction,
      closing: closing,
      promptTexts: promptTexts,
    )) {
      errorMessage = MemoraCopy.conversationsValidationError;
      helpErrorPromptOrder = null;
      notifyListeners();
      return;
    }
    final built = _buildPrompts(promptTexts);
    if (built == null) {
      errorMessage = MemoraCopy.conversationsHelpValidationError;
      notifyListeners();
      return;
    }
    final prompts = built;
    try {
      if (editingTopicId == null) {
        await _configure.create(
          actor: actor,
          id: _ids.nextConversationTopicId(),
          familySpaceId: actor.familySpaceId,
          title: title,
          introduction: introduction,
          prompts: prompts,
          closing: closing,
          memoryId: draftMemoryId,
          idempotencyKey: _ids.nextIdempotencyKey('topic-create'),
        );
      } else {
        await _configure.edit(
          actor: actor,
          id: editingTopicId!,
          title: title,
          introduction: introduction,
          prompts: prompts,
          closing: closing,
          memoryId: draftMemoryId,
          clearMemoryId: draftMemoryId == null,
          idempotencyKey: _ids.nextIdempotencyKey('topic-edit'),
        );
      }
      editingTopicId = null;
      draftTitle = '';
      draftIntroduction = '';
      draftPrompts = <String>[''];
      draftHelpCues = <String>[''];
      draftHelpMemoryIds = <MemoryId?>[null];
      draftClosing = '';
      draftMemoryId = null;
      pendingRemovePromptIndex = null;
      helpErrorPromptOrder = null;
      editorRevision += 1;
      errorMessage = null;
      await load();
      await _runAfterLocalWrite();
    } on InvalidConversationHelpMemoryException catch (error) {
      helpErrorPromptOrder = error.promptOrder;
      errorMessage = MemoraCopy.conversationsHelpMemoryError;
      notifyListeners();
    } on ArgumentError {
      errorMessage = MemoraCopy.conversationsValidationError;
      notifyListeners();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> activate(ConversationTopicId id) async {
    if (!canEdit) {
      errorMessage = MemoraCopy.conversationsUnauthorized;
      notifyListeners();
      return;
    }
    try {
      await _configure.activate(
        actor: actor,
        id: id,
        idempotencyKey: _ids.nextIdempotencyKey('topic-activate'),
      );
      helpErrorPromptOrder = null;
      errorMessage = null;
      await load();
      await _runAfterLocalWrite();
    } on InvalidConversationHelpMemoryException catch (error) {
      helpErrorPromptOrder = error.promptOrder;
      errorMessage = MemoraCopy.conversationsHelpMemoryError;
      notifyListeners();
    } on StateError catch (error) {
      final message = error.toString();
      errorMessage = message.contains('active conversation topics')
          ? MemoraCopy.conversationsActiveLimitError
          : message;
      notifyListeners();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> archive(ConversationTopicId id) async {
    if (!canEdit) {
      errorMessage = MemoraCopy.conversationsUnauthorized;
      notifyListeners();
      return;
    }
    try {
      await _configure.archive(
        actor: actor,
        id: id,
        idempotencyKey: _ids.nextIdempotencyKey('topic-archive'),
      );
      errorMessage = null;
      await load();
      await _runAfterLocalWrite();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> move(ConversationTopic topic, int delta) async {
    if (!canEdit) {
      errorMessage = MemoraCopy.conversationsUnauthorized;
      notifyListeners();
      return;
    }
    final index = topics.indexWhere((t) => t.id == topic.id);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= topics.length) {
      return;
    }
    final ordered = [...topics];
    final item = ordered.removeAt(index);
    ordered.insert(target, item);
    try {
      await _configure.reorder(
        actor: actor,
        familySpaceId: actor.familySpaceId,
        orderedIds: ordered.map((t) => t.id).toList(growable: false),
        idempotencyKey: _ids.nextIdempotencyKey('topic-reorder'),
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

  bool _looksValid({
    required String title,
    required String introduction,
    required String closing,
    required List<String> promptTexts,
  }) {
    if (title.isEmpty || title.length > ConversationTopic.maxTitleLength) {
      return false;
    }
    if (introduction.isEmpty ||
        introduction.length > ConversationTopic.maxIntroductionLength) {
      return false;
    }
    if (closing.isEmpty ||
        closing.length > ConversationTopic.maxClosingLength) {
      return false;
    }
    if (promptTexts.length < ConversationTopic.minPrompts ||
        promptTexts.length > ConversationTopic.maxPrompts) {
      return false;
    }
    for (final text in promptTexts) {
      if (text.isEmpty || text.length > ConversationPrompt.maxTextLength) {
        return false;
      }
    }
    return true;
  }

  /// Builds prompts with attached help. Returns null when a help card is invalid
  /// (draft fields are left unchanged; [helpErrorPromptOrder] identifies it).
  List<ConversationPrompt>? _buildPrompts(List<String> promptTexts) {
    helpErrorPromptOrder = null;
    final prompts = <ConversationPrompt>[];
    for (var i = 0; i < promptTexts.length; i++) {
      final cueRaw = i < draftHelpCues.length ? draftHelpCues[i].trim() : '';
      final memoryId = i < draftHelpMemoryIds.length
          ? draftHelpMemoryIds[i]
          : null;
      ConversationPromptHelp? help;
      if (cueRaw.isNotEmpty || memoryId != null) {
        if (cueRaw.length > ConversationPromptHelp.maxCueLength) {
          helpErrorPromptOrder = i;
          return null;
        }
        try {
          help = ConversationPromptHelp(
            cue: cueRaw.isEmpty ? null : cueRaw,
            memoryId: memoryId,
          );
        } on ArgumentError {
          helpErrorPromptOrder = i;
          return null;
        }
      }
      prompts.add(
        ConversationPrompt(order: i, text: promptTexts[i], help: help),
      );
    }
    return prompts;
  }

  PresentationSurfaceState _deriveSurface(List<ConversationTopic> listed) {
    if (listed.isEmpty) {
      return PresentationSurfaceState.empty;
    }
    final worst = SyncStatusLabels.worstOf(listed.map((t) => t.syncState));
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
    if (topics.isEmpty) {
      return SyncState.local;
    }
    return SyncStatusLabels.worstOf(topics.map((t) => t.syncState));
  }
}
