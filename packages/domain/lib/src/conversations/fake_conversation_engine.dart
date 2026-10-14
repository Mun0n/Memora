import '../memories/memory_entry.dart';
import 'conversation_engine_port.dart';
import 'conversation_topic.dart';
import 'deterministic_conversation_engine.dart';

/// Test/demo fake that delegates to [DeterministicConversationEngine].
///
/// Exposes call counters for UI/QA proofs. Never opens a microphone.
final class FakeConversationEngine implements ConversationEnginePort {
  FakeConversationEngine({DeterministicConversationEngine? delegate})
    : _delegate = delegate ?? DeterministicConversationEngine();

  final DeterministicConversationEngine _delegate;

  int startCount = 0;
  int beginListeningCount = 0;
  int speechResultCount = 0;
  int controlCount = 0;
  int helpRequestCount = 0;
  int cancelCount = 0;
  int clearCount = 0;

  @override
  ConversationSessionSnapshot get snapshot => _delegate.snapshot;

  @override
  ConversationSessionSnapshot start(ConversationTopic topic) {
    startCount++;
    return _delegate.start(topic);
  }

  @override
  ConversationSessionSnapshot confirmIntroduction() {
    return _delegate.confirmIntroduction();
  }

  @override
  ConversationSessionSnapshot beginListening() {
    beginListeningCount++;
    return _delegate.beginListening();
  }

  @override
  ConversationSessionSnapshot onSpeechResult({
    required String? textInMemory,
    ConversationSpeechOutcome outcome = ConversationSpeechOutcome.recognized,
  }) {
    speechResultCount++;
    return _delegate.onSpeechResult(
      textInMemory: textInMemory,
      outcome: outcome,
    );
  }

  @override
  ConversationSessionSnapshot applyControl(ConversationControlAction action) {
    controlCount++;
    return _delegate.applyControl(action);
  }

  ConversationSessionSnapshot requestHelp({MemoryEntry? resolvedHelpMemory}) {
    helpRequestCount++;
    return _delegate.requestHelp(resolvedHelpMemory: resolvedHelpMemory);
  }

  ConversationSessionSnapshot completeHelpPresentation() {
    return _delegate.completeHelpPresentation();
  }

  @override
  ConversationSessionSnapshot cancel() {
    cancelCount++;
    return _delegate.cancel();
  }

  @override
  ConversationSessionSnapshot clear() {
    clearCount++;
    return _delegate.clear();
  }

  ConversationSessionSnapshot advanceAfterAcknowledgement() {
    return _delegate.advanceAfterAcknowledgement();
  }
}
