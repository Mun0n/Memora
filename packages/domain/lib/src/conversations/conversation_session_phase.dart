/// Explicit phases of a turn-based guided conversation session.
///
/// Session state is ephemeral in-memory only — never persisted or synced.
enum ConversationSessionPhase {
  /// Before the person explicitly starts.
  idle,

  /// Showing the family-authored contextual introduction.
  topicIntroduction,

  /// Authored invitation visible; microphone not yet open.
  promptReady,

  /// Person's turn — microphone may be active.
  listening,

  /// Neutral acknowledgement after speech / command; mic released.
  acknowledgement,

  /// Advancing toward the next authored prompt (brief transitional).
  nextPrompt,

  /// Final authored closing shown.
  closing,

  /// Person cancelled or left the flow.
  cancelled,

  /// Recognition/permission/voice unavailable; written controls remain.
  unavailable,

  /// Safety-sensitive language — fixed limitation; listening stopped.
  safetyStopped,
}
