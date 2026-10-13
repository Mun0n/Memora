/// Lifecycle for a family conversation-topic aggregate.
///
/// Active topics are eligible for supported-person presentation.
/// Draft and archived items are excluded from that view.
/// Soft-delete (tombstone) remains a separate retention path.
enum ConversationTopicLifecycleStatus {
  /// Caregiver draft — not shown to the supported person.
  draft('draft'),

  /// Active for supported-person presentation (max six per family).
  active('active'),

  /// Removed from active presentation; retained for caregivers.
  archived('archived');

  const ConversationTopicLifecycleStatus(this.wireName);

  final String wireName;

  static ConversationTopicLifecycleStatus parse(String raw) {
    for (final status in ConversationTopicLifecycleStatus.values) {
      if (status.wireName == raw) {
        return status;
      }
    }
    throw FormatException('Unknown ConversationTopicLifecycleStatus: $raw');
  }
}
