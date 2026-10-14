import '../identity/identifiers.dart';
import '../offline/offline_identifiers.dart';
import '../sync/aggregate_version.dart';
import '../sync/sync_state.dart';
import '../sync/tombstone.dart';
import 'conversation_prompt.dart';
import 'conversation_prompt_help.dart';
import 'conversation_topic_lifecycle_status.dart';

/// Family-scoped guided conversation topic (intro, prompts, closing).
///
/// Local-first aggregate. No scoring, recall test or therapeutic claim is
/// modeled. Session speech is never part of this record. Prompt help cards
/// travel with their prompts inside this aggregate (conflict/sync unit).
final class ConversationTopic {
  static const int maxTitleLength = 60;
  static const int maxIntroductionLength = 240;
  static const int maxClosingLength = 160;
  static const int minPrompts = 1;
  static const int maxPrompts = 5;
  static const int maxActivePerFamily = 6;
  static const int maxPromptHelpCards = maxPrompts;

  ConversationTopic({
    required this.id,
    required this.familySpaceId,
    required this.title,
    required this.introduction,
    required this.prompts,
    required this.closing,
    required this.displayOrder,
    required this.lifecycleStatus,
    required this.version,
    required this.syncState,
    this.memoryId,
    this.tombstone,
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty || trimmedTitle.length > maxTitleLength) {
      throw ArgumentError.value(
        title,
        'title',
        'must be 1–$maxTitleLength characters after trim',
      );
    }
    final trimmedIntro = introduction.trim();
    if (trimmedIntro.isEmpty || trimmedIntro.length > maxIntroductionLength) {
      throw ArgumentError.value(
        introduction,
        'introduction',
        'must be 1–$maxIntroductionLength characters after trim',
      );
    }
    final trimmedClosing = closing.trim();
    if (trimmedClosing.isEmpty || trimmedClosing.length > maxClosingLength) {
      throw ArgumentError.value(
        closing,
        'closing',
        'must be 1–$maxClosingLength characters after trim',
      );
    }
    if (prompts.length < minPrompts || prompts.length > maxPrompts) {
      throw ArgumentError.value(
        prompts.length,
        'prompts',
        'must contain $minPrompts–$maxPrompts items',
      );
    }
    final sorted = List<ConversationPrompt>.from(prompts)
      ..sort((a, b) => a.order.compareTo(b.order));
    for (var i = 0; i < sorted.length; i++) {
      if (sorted[i].order != i) {
        throw ArgumentError.value(
          prompts.map((p) => p.order).toList(),
          'prompts',
          'orders must be contiguous zero-based',
        );
      }
    }
    if (displayOrder < 0) {
      throw ArgumentError.value(displayOrder, 'displayOrder', 'must be >= 0');
    }
    final helpCount = sorted.where((p) => p.help != null).length;
    if (helpCount > maxPromptHelpCards) {
      throw ArgumentError.value(
        helpCount,
        'prompts.help',
        'at most $maxPromptHelpCards help cards',
      );
    }
  }

  final ConversationTopicId id;
  final FamilySpaceId familySpaceId;
  final String title;
  final String introduction;
  final List<ConversationPrompt> prompts;
  final String closing;
  final int displayOrder;
  final ConversationTopicLifecycleStatus lifecycleStatus;
  final AggregateVersion version;
  final SyncState syncState;

  /// Optional reference to one already-approved family memory (topic cover).
  /// Independent from per-prompt [ConversationPromptHelp] cards.
  final MemoryId? memoryId;
  final Tombstone? tombstone;

  bool get isDeleted => tombstone != null;

  /// Eligible for supported-person presentation (active, non-tombstoned).
  bool get isActiveForViewing =>
      !isDeleted && lifecycleStatus == ConversationTopicLifecycleStatus.active;

  /// Prompt-level help cards currently attached (at most [maxPromptHelpCards]).
  List<ConversationPromptHelp> get promptHelpCards => prompts
      .map((p) => p.help)
      .whereType<ConversationPromptHelp>()
      .toList(growable: false);

  /// Prompt-level approved-memory references (≤ five).
  List<MemoryId> get promptHelpMemoryIds => promptHelpCards
      .map((h) => h.memoryId)
      .whereType<MemoryId>()
      .toList(growable: false);

  ConversationTopic copyWith({
    String? title,
    String? introduction,
    List<ConversationPrompt>? prompts,
    String? closing,
    int? displayOrder,
    ConversationTopicLifecycleStatus? lifecycleStatus,
    AggregateVersion? version,
    SyncState? syncState,
    MemoryId? memoryId,
    bool clearMemoryId = false,
    Tombstone? tombstone,
    bool clearTombstone = false,
  }) {
    return ConversationTopic(
      id: id,
      familySpaceId: familySpaceId,
      title: title ?? this.title,
      introduction: introduction ?? this.introduction,
      prompts: prompts ?? this.prompts,
      closing: closing ?? this.closing,
      displayOrder: displayOrder ?? this.displayOrder,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      version: version ?? this.version,
      syncState: syncState ?? this.syncState,
      memoryId: clearMemoryId ? null : (memoryId ?? this.memoryId),
      tombstone: clearTombstone ? null : (tombstone ?? this.tombstone),
    );
  }
}
