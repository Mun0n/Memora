import '../identity/identifiers.dart';
import '../memories/memory_entry.dart';
import 'conversation_prompt_help.dart';

/// One ordered invitation-to-speak within a [ConversationTopic].
///
/// Family-authored text only. Contiguous zero-based [order] is enforced by the
/// topic aggregate. Optional [help] is zero-or-one and stays attached across
/// prompt reorder; removing the prompt drops only that help card.
final class ConversationPrompt {
  static const int maxTextLength = 240;

  ConversationPrompt({required this.order, required this.text, this.help}) {
    if (order < 0) {
      throw ArgumentError.value(order, 'order', 'must be >= 0');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > maxTextLength) {
      throw ArgumentError.value(
        text,
        'text',
        'must be 1–$maxTextLength characters after trim',
      );
    }
  }

  final int order;
  final String text;

  /// Optional family help card (cue and/or approved memory reference).
  final ConversationPromptHelp? help;

  bool get hasAuthoredHelp => help != null;

  /// Whether `Dame una idea` should be offered for this prompt.
  bool hasUsableHelp({
    required FamilySpaceId familySpaceId,
    MemoryEntry? resolvedMemory,
  }) {
    final card = help;
    if (card == null) {
      return false;
    }
    return card.isUsable(
      familySpaceId: familySpaceId,
      resolvedMemory: resolvedMemory,
    );
  }

  ConversationPrompt copyWith({
    int? order,
    String? text,
    ConversationPromptHelp? help,
    bool clearHelp = false,
  }) {
    return ConversationPrompt(
      order: order ?? this.order,
      text: text ?? this.text,
      help: clearHelp ? null : (help ?? this.help),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ConversationPrompt &&
      other.order == order &&
      other.text == text &&
      other.help == help;

  @override
  int get hashCode => Object.hash(order, text, help);
}
