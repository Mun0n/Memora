import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import '../demo/demo_data_scope.dart';
import '../l10n/memora_copy.dart';
import '../sync/presentation_sync.dart' show PresentationSurfaceState;

/// Supported-person active conversation topics (offline-cached, caregiver order).
///
/// Never exposes drafts, archived topics, sync jargon or speech persistence.
final class UserConversationTopicController extends ChangeNotifier {
  UserConversationTopicController({
    required this.actor,
    required ConversationTopicRepository topics,
    this.networkAvailable = false,
    this.demoDataScope = DemoDataScope.isolatedLocal,
    ConfigureConversationTopic? configureTopic,
    List<MemoryEntry> Function()? approvedMemoryLookup,
  }) : _configure = configureTopic ?? ConfigureConversationTopic(topics),
       _approvedMemoryLookup = approvedMemoryLookup;

  final FamilyMembership actor;
  final ConfigureConversationTopic _configure;
  final List<MemoryEntry> Function()? _approvedMemoryLookup;

  bool networkAvailable;
  DemoDataScope demoDataScope;

  Future<bool> Function()? quietRemotePull;

  PresentationSurfaceState surfaceState = PresentationSurfaceState.loading;
  List<ConversationTopic> topics = const <ConversationTopic>[];
  String? errorMessage;

  /// Selected topic awaiting explicit start (or in session via session controller).
  ConversationTopicId? selectedTopicId;

  bool sharedPullFailed = false;
  bool isRefreshingShared = false;

  bool get isSharedDemo => demoDataScope == DemoDataScope.sharedLocalDemo;

  bool get hasActiveTopics => topics.isNotEmpty;

  ConversationTopic? get selectedTopic {
    final id = selectedTopicId;
    if (id == null) {
      return null;
    }
    for (final topic in topics) {
      if (topic.id == id) {
        return topic;
      }
    }
    return null;
  }

  MemoryEntry? memoryFor(ConversationTopic topic) {
    final memoryId = topic.memoryId;
    if (memoryId == null) {
      return null;
    }
    final lookup = _approvedMemoryLookup;
    if (lookup == null) {
      return null;
    }
    for (final memory in lookup()) {
      if (memory.id == memoryId && memory.isApprovedForViewing) {
        return memory;
      }
    }
    return null;
  }

  String get syncLabel {
    if (isRefreshingShared) {
      return MemoraCopy.quieroHablarSharedPending;
    }
    if (sharedPullFailed) {
      return MemoraCopy.quieroHablarSharedPullFailed;
    }
    if (surfaceState == PresentationSurfaceState.loading) {
      return MemoraCopy.quieroHablarInvitation;
    }
    if (surfaceState == PresentationSurfaceState.empty) {
      return networkAvailable
          ? MemoraCopy.quieroHablarEmptyBody
          : '${MemoraCopy.quieroHablarEmptyBody} ${MemoraCopy.quieroHablarOffline}';
    }
    if (!networkAvailable || surfaceState == PresentationSurfaceState.offline) {
      return MemoraCopy.quieroHablarOffline;
    }
    return MemoraCopy.quieroHablarTitle;
  }

  Future<void> load() async {
    surfaceState = PresentationSurfaceState.loading;
    if (!isSharedDemo) {
      errorMessage = null;
      sharedPullFailed = false;
    }
    selectedTopicId = null;
    notifyListeners();
    try {
      topics = await _configure.listActiveForViewing(
        actor: actor,
        familySpaceId: actor.familySpaceId,
      );
      surfaceState = topics.isEmpty
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
      topics = listed;
      if (selectedTopicId != null &&
          !topics.any((t) => t.id == selectedTopicId)) {
        selectedTopicId = null;
      }
      surfaceState = topics.isEmpty
          ? PresentationSurfaceState.empty
          : (!networkAvailable
                ? PresentationSurfaceState.offline
                : PresentationSurfaceState.ready);
      if (!sharedPullFailed) {
        errorMessage = null;
      }
    } catch (_) {
      // Keep cached topics; do not surface technical errors here.
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
        ? MemoraCopy.quieroHablarSharedPullFailed
        : null;
    notifyListeners();
  }

  Future<void> recover() async {
    await refreshFromSharedRemote();
  }

  void selectTopic(ConversationTopicId id) {
    selectedTopicId = id;
    notifyListeners();
  }

  /// First active topic in stable caregiver-defined order (not random).
  void pickForMe() {
    if (topics.isEmpty) {
      return;
    }
    selectedTopicId = topics.first.id;
    notifyListeners();
  }

  void clearSelection() {
    selectedTopicId = null;
    notifyListeners();
  }
}
