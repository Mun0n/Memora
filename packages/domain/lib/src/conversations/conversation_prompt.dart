/// One ordered invitation-to-speak within a [ConversationTopic].
///
/// Family-authored text only. Contiguous zero-based [order] is enforced by the
/// topic aggregate.
final class ConversationPrompt {
  static const int maxTextLength = 240;

  ConversationPrompt({required this.order, required this.text}) {
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

  ConversationPrompt copyWith({int? order, String? text}) {
    return ConversationPrompt(
      order: order ?? this.order,
      text: text ?? this.text,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ConversationPrompt && other.order == order && other.text == text;

  @override
  int get hashCode => Object.hash(order, text);
}
