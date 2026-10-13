/// Local content flags used by voice recommendation. Built from existing
/// routine / pastime / approved-memory / conversation-topic reads — no new
/// sync entity beyond those aggregates.
final class VoiceContentSnapshot {
  const VoiceContentSnapshot({
    required this.hasCurrentOrPendingMiDia,
    required this.hasActivePastimes,
    required this.hasApprovedMemories,
    this.hasActiveConversationTopics = false,
  });

  /// True when Mi día has a current or pending step the person can act on.
  final bool hasCurrentOrPendingMiDia;

  /// True when at least one active cached pastime exists for viewing.
  final bool hasActivePastimes;

  /// True when at least one approved cached memory exists for viewing.
  final bool hasApprovedMemories;

  /// True when at least one active cached conversation topic exists.
  final bool hasActiveConversationTopics;

  /// Empty local content — generic selection yields nothing prepared.
  static const VoiceContentSnapshot empty = VoiceContentSnapshot(
    hasCurrentOrPendingMiDia: false,
    hasActivePastimes: false,
    hasApprovedMemories: false,
  );

  /// Demo-friendly snapshot with all content classes available.
  static const VoiceContentSnapshot allAvailable = VoiceContentSnapshot(
    hasCurrentOrPendingMiDia: true,
    hasActivePastimes: true,
    hasApprovedMemories: true,
    hasActiveConversationTopics: true,
  );

  VoiceContentSnapshot copyWith({
    bool? hasCurrentOrPendingMiDia,
    bool? hasActivePastimes,
    bool? hasApprovedMemories,
    bool? hasActiveConversationTopics,
  }) {
    return VoiceContentSnapshot(
      hasCurrentOrPendingMiDia:
          hasCurrentOrPendingMiDia ?? this.hasCurrentOrPendingMiDia,
      hasActivePastimes: hasActivePastimes ?? this.hasActivePastimes,
      hasApprovedMemories: hasApprovedMemories ?? this.hasApprovedMemories,
      hasActiveConversationTopics:
          hasActiveConversationTopics ?? this.hasActiveConversationTopics,
    );
  }
}
