import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../demo/demo_data_scope.dart';
import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import 'user_conversation_session_controller.dart';
import 'user_conversation_topic_controller.dart';

/// Supported-person Quiero hablar: topic cards → explicit start → turn session.
class UserConversationTopicsPage extends StatelessWidget {
  const UserConversationTopicsPage({
    super.key,
    required this.topicController,
    required this.sessionController,
  });

  final UserConversationTopicController topicController;
  final UserConversationSessionController sessionController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([topicController, sessionController]),
      builder: (context, _) {
        final phase = sessionController.phase;
        final inSession =
            sessionController.hasActiveSession ||
            phase == ConversationSessionPhase.closing ||
            phase == ConversationSessionPhase.unavailable ||
            phase == ConversationSessionPhase.safetyStopped;
        if (inSession) {
          return _ConversationSessionView(
            topicController: topicController,
            sessionController: sessionController,
          );
        }
        final selected = topicController.selectedTopic;
        if (selected != null) {
          return _TopicReady(
            topic: selected,
            topicController: topicController,
            sessionController: sessionController,
          );
        }
        return _TopicList(controller: topicController);
      },
    );
  }
}

class _TopicList extends StatelessWidget {
  const _TopicList({required this.controller});

  final UserConversationTopicController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: const Key('memora-user-quiero-hablar'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          MemoraCopy.quieroHablarTitle,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: MemoraTheme.highContrastInk,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          controller.topics.isEmpty
              ? MemoraCopy.quieroHablarEmptyBody
              : MemoraCopy.quieroHablarInvitation,
          key: Key(
            controller.topics.isEmpty
                ? 'memora-user-quiero-hablar-empty'
                : 'memora-user-quiero-hablar-invitation',
          ),
          style: textTheme.bodyLarge?.copyWith(
            color: MemoraTheme.highContrastInk,
            fontSize: 20,
            height: 1.35,
          ),
        ),
        if (controller.demoDataScope == DemoDataScope.isolatedLocal) ...[
          const SizedBox(height: 8),
          Text(
            MemoraCopy.quieroHablarIsolatedDemoNotice,
            key: const Key('memora-isolated-local-demo'),
            style: textTheme.bodyMedium?.copyWith(
              color: MemoraTheme.highContrastInk,
              fontSize: 16,
            ),
          ),
        ],
        if (controller.isRefreshingShared) ...[
          const SizedBox(height: 8),
          Text(
            MemoraCopy.quieroHablarSharedPending,
            key: const Key('memora-user-quiero-hablar-shared-pending'),
            style: textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
        ],
        if (controller.sharedPullFailed) ...[
          const SizedBox(height: 8),
          Text(
            MemoraCopy.quieroHablarSharedPullFailed,
            key: const Key('memora-user-quiero-hablar-shared-pull-failed'),
            style: textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('memora-user-quiero-hablar-pull-retry'),
            onPressed: controller.recover,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
            ),
            child: const Text(MemoraCopy.recoveryRetry),
          ),
        ],
        if (controller.topics.isNotEmpty) ...[
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('memora-user-quiero-hablar-pick-for-me'),
            onPressed: controller.pickForMe,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(
                MemoraTheme.preferredTouchExtent,
              ),
            ),
            child: const Text(MemoraCopy.quieroHablarPickForMe),
          ),
          const SizedBox(height: 16),
          ...controller.topics.map(
            (topic) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _TopicCard(topic: topic, controller: controller),
            ),
          ),
        ],
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, required this.controller});

  final ConversationTopic topic;
  final UserConversationTopicController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final memory = controller.memoryFor(topic);
    return Semantics(
      button: true,
      label: '${topic.title}. ${MemoraCopy.quieroHablarOpenHint}',
      child: Material(
        color: Colors.white,
        child: InkWell(
          key: Key('memora-user-conversation-topic-${topic.id.value}'),
          onTap: () => controller.selectTopic(topic.id),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: MemoraTheme.preferredTouchExtent,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: MemoraTheme.borderInk, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: MemoraTheme.highContrastInk,
                      ),
                    ),
                    if (memory != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        memory.caption,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: MemoraTheme.highContrastInk,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      MemoraCopy.quieroHablarOpenHint,
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: MemoraTheme.accentBand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicReady extends StatelessWidget {
  const _TopicReady({
    required this.topic,
    required this.topicController,
    required this.sessionController,
  });

  final ConversationTopic topic;
  final UserConversationTopicController topicController;
  final UserConversationSessionController sessionController;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final memory = topicController.memoryFor(topic);
    return Column(
      key: Key('memora-user-conversation-ready-${topic.id.value}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const Key('memora-user-conversation-back-to-list'),
            onPressed: topicController.clearSelection,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
            ),
            child: const Text(MemoraCopy.quieroHablarChangeTopic),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          topic.title,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: MemoraTheme.highContrastInk,
          ),
        ),
        if (memory != null) ...[
          const SizedBox(height: 12),
          Text(
            memory.caption,
            style: textTheme.bodyLarge?.copyWith(fontSize: 18),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          topic.introduction,
          style: textTheme.bodyLarge?.copyWith(fontSize: 20, height: 1.35),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('memora-user-conversation-start'),
          onPressed: () => sessionController.start(topic),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(
              MemoraTheme.preferredTouchExtent,
            ),
          ),
          child: const Text(MemoraCopy.quieroHablarStart),
        ),
      ],
    );
  }
}

class _ConversationSessionView extends StatelessWidget {
  const _ConversationSessionView({
    required this.topicController,
    required this.sessionController,
  });

  final UserConversationTopicController topicController;
  final UserConversationSessionController sessionController;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final phase = sessionController.phase;
    final topic = sessionController.topic;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final listening = sessionController.microphoneOpen;
    final speaking = sessionController.memoraSpeaking;
    final announce = sessionController.displayedText;

    return Column(
      key: const Key('memora-user-conversation-session'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (topic != null)
          Text(
            topic.title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: MemoraTheme.highContrastInk,
            ),
          ),
        const SizedBox(height: 12),
        // Visible text always; avoid live-region re-speech while TTS speaks.
        ExcludeSemantics(
          excluding: speaking,
          child: Text(
            announce,
            key: const Key('memora-user-conversation-displayed'),
            style: textTheme.bodyLarge?.copyWith(
              fontSize: 22,
              height: 1.35,
              color: MemoraTheme.highContrastInk,
            ),
          ),
        ),
        if (sessionController.speechOutputUnavailable) ...[
          const SizedBox(height: 12),
          Text(
            MemoraCopy.quieroHablarSpeechOutputUnavailable,
            key: const Key('memora-user-conversation-tts-unavailable'),
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: MemoraTheme.highContrastInk,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _TurnStateBanner(
          speaking: speaking,
          listening: listening,
          reduceMotion: reduceMotion,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (phase == ConversationSessionPhase.topicIntroduction)
              FilledButton(
                key: const Key('memora-user-conversation-continue'),
                onPressed: sessionController.confirmIntroduction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(
                    140,
                    MemoraTheme.preferredTouchExtent,
                  ),
                ),
                child: const Text(MemoraCopy.quieroHablarContinue),
              ),
            if (sessionController.needsManualListen)
              FilledButton(
                key: const Key('memora-user-conversation-manual-speak'),
                onPressed: sessionController.beginManualListen,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(
                    140,
                    MemoraTheme.preferredTouchExtent,
                  ),
                ),
                child: const Text(MemoraCopy.quieroHablarManualSpeak),
              ),
            if (phase == ConversationSessionPhase.listening ||
                phase == ConversationSessionPhase.acknowledgement ||
                (phase == ConversationSessionPhase.promptReady &&
                    !sessionController.needsManualListen) ||
                phase == ConversationSessionPhase.unavailable)
              FilledButton(
                key: const Key('memora-user-conversation-finished'),
                onPressed: sessionController.finishedSpeaking,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(
                    140,
                    MemoraTheme.preferredTouchExtent,
                  ),
                ),
                child: const Text(MemoraCopy.quieroHablarFinishedSpeaking),
              ),
            OutlinedButton(
              key: const Key('memora-user-conversation-repeat'),
              onPressed:
                  phase == ConversationSessionPhase.closing ||
                      phase == ConversationSessionPhase.safetyStopped ||
                      speaking
                  ? null
                  : sessionController.repeat,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
              ),
              child: const Text(MemoraCopy.quieroHablarRepeat),
            ),
            OutlinedButton(
              key: const Key('memora-user-conversation-change-topic'),
              onPressed: () async {
                await sessionController.changeTopic();
                await sessionController.clear();
                topicController.clearSelection();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
              ),
              child: const Text(MemoraCopy.quieroHablarChangeTopic),
            ),
            OutlinedButton(
              key: const Key('memora-user-conversation-finish'),
              onPressed: sessionController.finish,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
              ),
              child: const Text(MemoraCopy.quieroHablarFinish),
            ),
          ],
        ),
        if (phase == ConversationSessionPhase.closing ||
            phase == ConversationSessionPhase.safetyStopped) ...[
          const SizedBox(height: 20),
          OutlinedButton(
            key: const Key('memora-user-conversation-back-topics'),
            onPressed: () async {
              await sessionController.clear();
              topicController.clearSelection();
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(
                MemoraTheme.preferredTouchExtent,
              ),
            ),
            child: const Text(MemoraCopy.quieroHablarBackToTopics),
          ),
        ],
      ],
    );
  }
}

class _TurnStateBanner extends StatelessWidget {
  const _TurnStateBanner({
    required this.speaking,
    required this.listening,
    required this.reduceMotion,
  });

  final bool speaking;
  final bool listening;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final String label;
    final String keyName;
    final bool activeBand;
    if (speaking) {
      label = MemoraCopy.quieroHablarMemoraSpeaking;
      keyName = 'memora-user-conversation-speaking';
      activeBand = true;
    } else if (listening) {
      label = MemoraCopy.quieroHablarListening;
      keyName = 'memora-user-conversation-listening';
      activeBand = true;
    } else {
      label = MemoraCopy.quieroHablarMicReleased;
      keyName = 'memora-user-conversation-mic-released';
      activeBand = false;
    }
    return Semantics(
      // Announce turn state only — not the prompt body (TTS owns that).
      liveRegion: true,
      label: label,
      child: DecoratedBox(
        key: Key(keyName),
        decoration: BoxDecoration(
          border: Border.all(color: MemoraTheme.borderInk, width: 2),
          color: activeBand ? MemoraTheme.accentBand : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (listening && !reduceMotion)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: MemoraTheme.accentOnBand,
                    ),
                  ),
                )
              else if (listening)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.mic,
                    color: MemoraTheme.accentOnBand,
                    size: 22,
                  ),
                )
              else if (speaking)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.volume_up,
                    color: MemoraTheme.accentOnBand,
                    size: 22,
                  ),
                ),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: activeBand
                        ? MemoraTheme.accentOnBand
                        : MemoraTheme.highContrastInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
