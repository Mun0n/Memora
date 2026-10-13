/// Local content flags used by voice recommendation. Built from existing
/// routine / pastime / approved-memory reads — no new sync entity.
final class VoiceContentSnapshot {
  const VoiceContentSnapshot({
    required this.hasCurrentOrPendingMiDia,
    required this.hasActivePastimes,
    required this.hasApprovedMemories,
  });

  /// True when Mi día has a current or pending step the person can act on.
  final bool hasCurrentOrPendingMiDia;

  /// True when at least one active cached pastime exists for viewing.
  final bool hasActivePastimes;

  /// True when at least one approved cached memory exists for viewing.
  final bool hasApprovedMemories;

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
  );

  VoiceContentSnapshot copyWith({
    bool? hasCurrentOrPendingMiDia,
    bool? hasActivePastimes,
    bool? hasApprovedMemories,
  }) {
    return VoiceContentSnapshot(
      hasCurrentOrPendingMiDia:
          hasCurrentOrPendingMiDia ?? this.hasCurrentOrPendingMiDia,
      hasActivePastimes: hasActivePastimes ?? this.hasActivePastimes,
      hasApprovedMemories: hasApprovedMemories ?? this.hasApprovedMemories,
    );
  }
}
