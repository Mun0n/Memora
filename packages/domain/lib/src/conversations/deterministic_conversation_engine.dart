import '../memories/memory_entry.dart';
import '../voice/voice_intent.dart';
import '../voice/voice_intent_matcher.dart';
import 'conversation_command.dart';
import 'conversation_copy.dart';
import 'conversation_engine_port.dart';
import 'conversation_session_phase.dart';
import 'conversation_topic.dart';

/// Deterministic turn-based conversation engine (family-authored + fixed copy).
///
/// Never scores, corrects, claims understanding or persists speech. Help always
/// comes from the current prompt's authored card — never from answers, silence
/// or semantic selection.
final class DeterministicConversationEngine implements ConversationEnginePort {
  ConversationSessionSnapshot _snapshot = ConversationSessionSnapshot.empty;

  @override
  ConversationSessionSnapshot get snapshot => _snapshot;

  @override
  ConversationSessionSnapshot start(ConversationTopic topic) {
    if (!topic.isActiveForViewing) {
      _snapshot = ConversationSessionSnapshot(
        phase: ConversationSessionPhase.unavailable,
        promptIndex: 0,
        microphoneOpen: false,
        displayedText: ConversationCopy.unavailable,
        topic: topic,
      );
      return _snapshot;
    }
    _snapshot = ConversationSessionSnapshot(
      phase: ConversationSessionPhase.topicIntroduction,
      promptIndex: 0,
      microphoneOpen: false,
      displayedText: topic.introduction,
      topic: topic,
    );
    return _snapshot;
  }

  @override
  ConversationSessionSnapshot confirmIntroduction() {
    final topic = _requireTopic();
    if (_snapshot.phase != ConversationSessionPhase.topicIntroduction) {
      return _snapshot;
    }
    return _showPromptReady(topic, index: 0);
  }

  @override
  ConversationSessionSnapshot beginListening() {
    final topic = _requireTopic();
    if (_snapshot.phase != ConversationSessionPhase.promptReady) {
      // Never open the mic while Memora is speaking / acknowledging / closing.
      return _snapshot.copyWith(microphoneOpen: false);
    }
    _snapshot = _snapshot.copyWith(
      phase: ConversationSessionPhase.listening,
      microphoneOpen: true,
      displayedText: topic.prompts[_snapshot.promptIndex].text,
    );
    return _snapshot;
  }

  @override
  ConversationSessionSnapshot onSpeechResult({
    required String? textInMemory,
    ConversationSpeechOutcome outcome = ConversationSpeechOutcome.recognized,
  }) {
    final topic = _requireTopic();
    _snapshot = _snapshot.copyWith(microphoneOpen: false);

    if (outcome == ConversationSpeechOutcome.permissionDenied ||
        outcome == ConversationSpeechOutcome.unavailable) {
      _snapshot = _snapshot.copyWith(
        phase: ConversationSessionPhase.unavailable,
        displayedText: ConversationCopy.unavailable,
        clearHelpReveal: true,
      );
      return _snapshot;
    }

    if (outcome == ConversationSpeechOutcome.recognitionFailure) {
      _snapshot = _snapshot.copyWith(
        phase: ConversationSessionPhase.acknowledgement,
        displayedText: ConversationCopy.recognitionFailureRecovery,
        clearLastCommand: true,
      );
      return _snapshot;
    }

    if (outcome == ConversationSpeechOutcome.silence ||
        textInMemory == null ||
        textInMemory.trim().isEmpty) {
      _snapshot = _snapshot.copyWith(
        phase: ConversationSessionPhase.acknowledgement,
        displayedText: ConversationCopy.silenceRecovery,
        clearLastCommand: true,
      );
      return _snapshot;
    }

    if (VoiceIntentMatcher.classify(textInMemory) ==
        VoiceIntentClass.safetySensitive) {
      _snapshot = _snapshot.copyWith(
        phase: ConversationSessionPhase.safetyStopped,
        displayedText: ConversationCopy.safetyLimitation,
        safetyStopped: true,
        microphoneOpen: false,
        clearHelpReveal: true,
      );
      return _snapshot;
    }

    final command = ConversationCommandMatcher.classify(textInMemory);
    if (command != null) {
      return _applyCommand(command, topic);
    }

    return _acknowledgeOrdinaryAnswer(topic);
  }

  @override
  ConversationSessionSnapshot applyControl(ConversationControlAction action) {
    final topic = _requireTopic();
    _snapshot = _snapshot.copyWith(microphoneOpen: false);
    switch (action) {
      case ConversationControlAction.finishedSpeaking:
        if (_snapshot.phase == ConversationSessionPhase.listening ||
            _snapshot.phase == ConversationSessionPhase.promptReady) {
          return _acknowledgeOrdinaryAnswer(topic);
        }
        if (_snapshot.phase == ConversationSessionPhase.acknowledgement) {
          return _advanceAfterAcknowledgement(topic);
        }
        return _snapshot;
      case ConversationControlAction.repeat:
        return _applyCommand(ConversationCommand.repeat, topic);
      case ConversationControlAction.changeTopic:
        return _applyCommand(ConversationCommand.changeTopic, topic);
      case ConversationControlAction.finish:
        return _applyCommand(ConversationCommand.finish, topic);
      case ConversationControlAction.requestHelp:
        return requestHelp();
      case ConversationControlAction.completeHelpPresentation:
        return completeHelpPresentation();
    }
  }

  /// Explicit help request for the current prompt (touch or exact command).
  ///
  /// [resolvedHelpMemory] supplies approved-memory metadata when the card
  /// references one. Never selects a different memory or topic.
  ConversationSessionSnapshot requestHelp({MemoryEntry? resolvedHelpMemory}) {
    final topic = _requireTopic();
    _snapshot = _snapshot.copyWith(microphoneOpen: false);

    if (_snapshot.phase != ConversationSessionPhase.listening &&
        _snapshot.phase != ConversationSessionPhase.promptReady &&
        _snapshot.phase != ConversationSessionPhase.acknowledgement &&
        _snapshot.phase != ConversationSessionPhase.presentingHelp) {
      return _snapshot;
    }

    final prompt = topic.prompts[_snapshot.promptIndex];
    final help = prompt.help;
    if (help == null ||
        !help.isUsable(
          familySpaceId: topic.familySpaceId,
          resolvedMemory: resolvedHelpMemory,
        )) {
      _snapshot = _snapshot.copyWith(
        phase: ConversationSessionPhase.acknowledgement,
        displayedText: ConversationCopy.helpUnavailable,
        lastCommand: ConversationCommand.help,
        clearHelpReveal: true,
      );
      return _snapshot;
    }

    final memory = resolvedHelpMemory;
    final showMemory =
        help.memoryId != null &&
        memory != null &&
        memory.id == help.memoryId &&
        memory.familySpaceId == topic.familySpaceId &&
        memory.isApprovedForViewing;
    final spoken = help.spokenText(
      memoryCaption: showMemory ? memory.caption : null,
    );
    _snapshot = ConversationSessionSnapshot(
      phase: ConversationSessionPhase.presentingHelp,
      promptIndex: _snapshot.promptIndex,
      microphoneOpen: false,
      displayedText: spoken ?? ConversationCopy.helpUnavailable,
      topic: topic,
      lastCommand: ConversationCommand.help,
      helpRevealed: true,
      revealedHelpCue: spoken,
      revealedHelpMemoryId: showMemory ? help.memoryId : null,
    );
    return _snapshot;
  }

  /// After help speech completes — return to the same prompt (mic still closed).
  ConversationSessionSnapshot completeHelpPresentation() {
    final topic = _requireTopic();
    if (_snapshot.phase != ConversationSessionPhase.presentingHelp) {
      return _snapshot;
    }
    return _showPromptReady(
      topic,
      index: _snapshot.promptIndex,
      lastCommand: ConversationCommand.help,
      keepHelpReveal: true,
    );
  }

  @override
  ConversationSessionSnapshot cancel() {
    _snapshot = ConversationSessionSnapshot(
      phase: ConversationSessionPhase.cancelled,
      promptIndex: _snapshot.promptIndex,
      microphoneOpen: false,
      displayedText: '',
      topic: _snapshot.topic,
    );
    return _snapshot;
  }

  @override
  ConversationSessionSnapshot clear() {
    _snapshot = ConversationSessionSnapshot.empty;
    return _snapshot;
  }

  /// Call after an acknowledgement to move to the next prompt or closing.
  ConversationSessionSnapshot advanceAfterAcknowledgement() {
    final topic = _requireTopic();
    return _advanceAfterAcknowledgement(topic);
  }

  ConversationSessionSnapshot _applyCommand(
    ConversationCommand command,
    ConversationTopic topic,
  ) {
    switch (command) {
      case ConversationCommand.repeat:
        return _showPromptReady(
          topic,
          index: _snapshot.promptIndex,
          lastCommand: command,
          keepHelpReveal: false,
        );
      case ConversationCommand.changeTopic:
        _snapshot = ConversationSessionSnapshot(
          phase: ConversationSessionPhase.cancelled,
          promptIndex: 0,
          microphoneOpen: false,
          displayedText: '',
          topic: topic,
          lastCommand: command,
        );
        return _snapshot;
      case ConversationCommand.finish:
        _snapshot = ConversationSessionSnapshot(
          phase: ConversationSessionPhase.closing,
          promptIndex: _snapshot.promptIndex,
          microphoneOpen: false,
          displayedText: topic.closing,
          topic: topic,
          lastCommand: command,
        );
        return _snapshot;
      case ConversationCommand.noMeAcuerdo:
        _snapshot = _snapshot.copyWith(
          phase: ConversationSessionPhase.acknowledgement,
          displayedText: ConversationCopy.noMeAcuerdoRecovery,
          lastCommand: command,
          microphoneOpen: false,
        );
        return _snapshot;
      case ConversationCommand.help:
        return requestHelp();
    }
  }

  ConversationSessionSnapshot _acknowledgeOrdinaryAnswer(
    ConversationTopic topic,
  ) {
    _snapshot = ConversationSessionSnapshot(
      phase: ConversationSessionPhase.acknowledgement,
      promptIndex: _snapshot.promptIndex,
      microphoneOpen: false,
      displayedText: ConversationCopy.neutralAcknowledgement,
      topic: topic,
      helpRevealed: _snapshot.helpRevealed,
      revealedHelpCue: _snapshot.revealedHelpCue,
      revealedHelpMemoryId: _snapshot.revealedHelpMemoryId,
    );
    return _snapshot;
  }

  ConversationSessionSnapshot _advanceAfterAcknowledgement(
    ConversationTopic topic,
  ) {
    if (_snapshot.phase != ConversationSessionPhase.acknowledgement &&
        _snapshot.phase != ConversationSessionPhase.nextPrompt) {
      return _snapshot;
    }
    final nextIndex = _snapshot.promptIndex + 1;
    if (nextIndex >= topic.prompts.length) {
      _snapshot = ConversationSessionSnapshot(
        phase: ConversationSessionPhase.closing,
        promptIndex: _snapshot.promptIndex,
        microphoneOpen: false,
        displayedText: topic.closing,
        topic: topic,
      );
      return _snapshot;
    }
    _snapshot = _snapshot.copyWith(phase: ConversationSessionPhase.nextPrompt);
    return _showPromptReady(topic, index: nextIndex);
  }

  ConversationSessionSnapshot _showPromptReady(
    ConversationTopic topic, {
    required int index,
    ConversationCommand? lastCommand,
    bool keepHelpReveal = false,
  }) {
    final samePrompt = index == _snapshot.promptIndex && keepHelpReveal;
    _snapshot = ConversationSessionSnapshot(
      phase: ConversationSessionPhase.promptReady,
      promptIndex: index,
      microphoneOpen: false,
      displayedText: topic.prompts[index].text,
      topic: topic,
      lastCommand: lastCommand,
      helpRevealed: samePrompt ? _snapshot.helpRevealed : false,
      revealedHelpCue: samePrompt ? _snapshot.revealedHelpCue : null,
      revealedHelpMemoryId: samePrompt ? _snapshot.revealedHelpMemoryId : null,
    );
    return _snapshot;
  }

  ConversationTopic _requireTopic() {
    final topic = _snapshot.topic;
    if (topic == null) {
      throw StateError('conversation session has no topic');
    }
    return topic;
  }
}
