import 'conversation_command.dart';
import 'conversation_session_phase.dart';
import 'conversation_topic.dart';

/// Narrow port so UI stays independent from speech mechanics.
///
/// Implementations must be deterministic: family-authored topic text + fixed
/// reviewed copy only. No LLM, remote semantic service or scoring.
abstract interface class ConversationEnginePort {
  ConversationSessionSnapshot get snapshot;

  /// Explicit person start — begins at introduction. Mic stays closed.
  ConversationSessionSnapshot start(ConversationTopic topic);

  /// Advance from introduction into the first prompt (still not listening).
  ConversationSessionSnapshot confirmIntroduction();

  /// Open the listening phase for the current prompt.
  ConversationSessionSnapshot beginListening();

  /// Apply ephemeral recognized text (or null for silence / failure).
  ///
  /// [textInMemory] must not be stored by callers after this returns.
  ConversationSessionSnapshot onSpeechResult({
    required String? textInMemory,
    ConversationSpeechOutcome outcome = ConversationSpeechOutcome.recognized,
  });

  /// Visible control actions (also available without speech).
  ConversationSessionSnapshot applyControl(ConversationControlAction action);

  /// App pause, navigation away or cancellation — releases session immediately.
  ConversationSessionSnapshot cancel();

  /// Clears all in-memory session state.
  ConversationSessionSnapshot clear();
}

/// How speech capture ended for one turn.
enum ConversationSpeechOutcome {
  recognized,
  silence,
  recognitionFailure,
  permissionDenied,
  unavailable,
}

/// Visible manual controls mirrored in the UI.
enum ConversationControlAction { finishedSpeaking, repeat, changeTopic, finish }

/// Ephemeral in-memory session view. Never persisted, synced or audited.
final class ConversationSessionSnapshot {
  const ConversationSessionSnapshot({
    required this.phase,
    required this.promptIndex,
    required this.microphoneOpen,
    required this.displayedText,
    required this.topic,
    this.lastCommand,
    this.safetyStopped = false,
  });

  final ConversationSessionPhase phase;
  final int promptIndex;
  final bool microphoneOpen;
  final String displayedText;
  final ConversationTopic? topic;
  final ConversationCommand? lastCommand;
  final bool safetyStopped;

  static const ConversationSessionSnapshot empty = ConversationSessionSnapshot(
    phase: ConversationSessionPhase.idle,
    promptIndex: 0,
    microphoneOpen: false,
    displayedText: '',
    topic: null,
  );

  bool get hasActiveSession =>
      topic != null &&
      phase != ConversationSessionPhase.idle &&
      phase != ConversationSessionPhase.cancelled;

  ConversationSessionSnapshot copyWith({
    ConversationSessionPhase? phase,
    int? promptIndex,
    bool? microphoneOpen,
    String? displayedText,
    ConversationTopic? topic,
    bool clearTopic = false,
    ConversationCommand? lastCommand,
    bool clearLastCommand = false,
    bool? safetyStopped,
  }) {
    return ConversationSessionSnapshot(
      phase: phase ?? this.phase,
      promptIndex: promptIndex ?? this.promptIndex,
      microphoneOpen: microphoneOpen ?? this.microphoneOpen,
      displayedText: displayedText ?? this.displayedText,
      topic: clearTopic ? null : (topic ?? this.topic),
      lastCommand: clearLastCommand ? null : (lastCommand ?? this.lastCommand),
      safetyStopped: safetyStopped ?? this.safetyStopped,
    );
  }
}
