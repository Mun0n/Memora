import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../demo/demo_data_scope.dart';
import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import '../widgets/draft_text_field.dart';
import 'family_conversation_topic_controller.dart';

/// Caregiver/family web: create/edit/order/activate/archive conversation topics.
class FamilyConversationTopicConfigureContent extends StatelessWidget {
  const FamilyConversationTopicConfigureContent({
    super.key,
    required this.controller,
  });

  final FamilyConversationTopicController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final textTheme = Theme.of(context).textTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              MemoraCopy.conversationsSectionTitle,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: MemoraTheme.highContrastInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              MemoraCopy.conversationsSectionBody,
              style: textTheme.bodyLarge?.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              MemoraCopy.conversationsGuidance,
              key: const Key('memora-family-conversation-guidance'),
              style: textTheme.bodyMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              controller.demoDataScope == DemoDataScope.sharedLocalDemo
                  ? MemoraCopy.sharedLocalDemoNotice
                  : MemoraCopy.isolatedLocalDemoNotice,
              key: Key(
                controller.demoDataScope == DemoDataScope.sharedLocalDemo
                    ? 'memora-shared-local-demo'
                    : 'memora-isolated-local-demo',
              ),
              style: textTheme.bodyMedium?.copyWith(fontSize: 16),
            ),
            if (controller.isRefreshingShared) ...[
              const SizedBox(height: 8),
              Text(
                MemoraCopy.sharedLocalDemoPending,
                key: const Key('memora-family-conversation-shared-pending'),
                style: textTheme.bodyMedium?.copyWith(fontSize: 16),
              ),
            ],
            if (controller.sharedPullFailed) ...[
              const SizedBox(height: 8),
              Text(
                MemoraCopy.sharedLocalDemoPullFailed,
                key: const Key('memora-family-conversation-shared-pull-failed'),
                style: textTheme.bodyMedium?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('memora-family-conversation-pull-retry'),
                onPressed: controller.recover,
                child: const Text(MemoraCopy.recoveryRetry),
              ),
            ],
            if (controller.sharedDeliveryFailed) ...[
              const SizedBox(height: 8),
              Text(
                MemoraCopy.sharedLocalDemoDeliveryFailed,
                key: const Key(
                  'memora-family-conversation-shared-delivery-failed',
                ),
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('memora-family-conversation-delivery-retry'),
                onPressed: controller.recover,
                child: const Text(MemoraCopy.recoveryRetry),
              ),
            ],
            const SizedBox(height: 16),
            if (controller.topics.isEmpty)
              Text(
                MemoraCopy.conversationsEmptyConfigure,
                key: const Key('memora-family-conversations-empty'),
                style: textTheme.bodyLarge?.copyWith(fontSize: 18),
              )
            else
              ...controller.topics.map(
                (topic) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TopicCard(topic: topic, controller: controller),
                ),
              ),
            if (controller.canEdit) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('memora-family-begin-conversation'),
                onPressed: controller.beginCreate,
                child: const Text(MemoraCopy.createConversationTopic),
              ),
              const SizedBox(height: 16),
              _TopicEditor(controller: controller),
            ],
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  controller.helpErrorPromptOrder == null
                      ? controller.errorMessage!
                      : '${controller.errorMessage!} '
                            '(${MemoraCopy.conversationPromptLabel} '
                            '${controller.helpErrorPromptOrder! + 1})',
                  key: const Key('memora-family-conversation-error'),
                  style: textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PromptHelpEditor extends StatelessWidget {
  const _PromptHelpEditor({required this.controller, required this.index});

  final FamilyConversationTopicController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final revision = controller.editorRevision;
    final hasError = controller.helpErrorPromptOrder == index;
    final cue = index < controller.draftHelpCues.length
        ? controller.draftHelpCues[index]
        : '';
    final helpMemoryId = index < controller.draftHelpMemoryIds.length
        ? controller.draftHelpMemoryIds[index]
        : null;
    return Semantics(
      container: true,
      label:
          '${MemoraCopy.conversationHelpSectionLabel}, '
          '${MemoraCopy.conversationPromptLabel} ${index + 1}',
      child: DecoratedBox(
        key: Key('memora-family-conversation-help-$index'),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasError
                ? Theme.of(context).colorScheme.error
                : MemoraTheme.borderInk,
            width: 2,
          ),
          color: MemoraTheme.highContrastSurface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                MemoraCopy.conversationHelpSectionLabel,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                MemoraCopy.conversationHelpGuidance,
                key: Key('memora-family-conversation-help-guidance-$index'),
                style: textTheme.bodyMedium?.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 8),
              DraftTextField(
                key: Key('memora-family-conversation-help-cue-$index'),
                revision: revision,
                initialText: cue,
                labelText: MemoraCopy.conversationHelpCueLabel,
                maxLines: 3,
                onChanged: (value) => controller.setDraftHelpCue(index, value),
              ),
              const SizedBox(height: 8),
              Text(
                MemoraCopy.conversationHelpMemoryLabel,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                key: Key('memora-family-conversation-help-memory-$index'),
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: Key(
                      'memora-family-conversation-help-memory-none-$index',
                    ),
                    onPressed: () =>
                        controller.setDraftHelpMemoryId(index, null),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: helpMemoryId == null
                          ? MemoraTheme.accentBand
                          : Colors.white,
                      foregroundColor: helpMemoryId == null
                          ? MemoraTheme.accentOnBand
                          : MemoraTheme.highContrastInk,
                      minimumSize: const Size(
                        48,
                        MemoraTheme.preferredTouchExtent,
                      ),
                    ),
                    child: const Text(MemoraCopy.conversationHelpMemoryNone),
                  ),
                  ...controller.approvedMemories.map(
                    (memory) => OutlinedButton(
                      key: Key(
                        'memora-family-conversation-help-memory-'
                        '${memory.id.value}-$index',
                      ),
                      onPressed: () =>
                          controller.setDraftHelpMemoryId(index, memory.id),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: helpMemoryId == memory.id
                            ? MemoraTheme.accentBand
                            : Colors.white,
                        foregroundColor: helpMemoryId == memory.id
                            ? MemoraTheme.accentOnBand
                            : MemoraTheme.highContrastInk,
                        minimumSize: const Size(
                          48,
                          MemoraTheme.preferredTouchExtent,
                        ),
                      ),
                      child: Text(memory.caption),
                    ),
                  ),
                ],
              ),
              if (controller.draftHelpPresent(index)) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  key: Key('memora-family-conversation-help-clear-$index'),
                  onPressed: () => controller.clearDraftHelp(index),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(
                      48,
                      MemoraTheme.preferredTouchExtent,
                    ),
                  ),
                  child: const Text(MemoraCopy.conversationHelpClear),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, required this.controller});

  final ConversationTopic topic;
  final FamilyConversationTopicController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lifecycle = switch (topic.lifecycleStatus) {
      ConversationTopicLifecycleStatus.draft =>
        MemoraCopy.conversationLifecycleDraft,
      ConversationTopicLifecycleStatus.active =>
        MemoraCopy.conversationLifecycleActive,
      ConversationTopicLifecycleStatus.archived =>
        MemoraCopy.conversationLifecycleArchived,
    };
    final isActive =
        topic.lifecycleStatus == ConversationTopicLifecycleStatus.active;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: MemoraTheme.borderInk, width: 2),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${topic.title} ($lifecycle)',
              key: Key('memora-family-conversation-${topic.id.value}'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              topic.introduction,
              style: textTheme.bodyLarge?.copyWith(fontSize: 17),
            ),
            if (controller.canEdit) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: Key(
                      'memora-family-edit-conversation-${topic.id.value}',
                    ),
                    onPressed: () => controller.beginEdit(topic),
                    child: const Text(MemoraCopy.editConversationTopic),
                  ),
                  if (isActive)
                    OutlinedButton(
                      key: Key(
                        'memora-family-archive-conversation-${topic.id.value}',
                      ),
                      onPressed: () => controller.archive(topic.id),
                      child: const Text(MemoraCopy.archiveConversationTopic),
                    )
                  else
                    FilledButton(
                      key: Key(
                        'memora-family-activate-conversation-${topic.id.value}',
                      ),
                      onPressed: () => controller.activate(topic.id),
                      child: const Text(MemoraCopy.activateConversationTopic),
                    ),
                  OutlinedButton(
                    key: Key('memora-family-conversation-up-${topic.id.value}'),
                    onPressed: () => controller.move(topic, -1),
                    child: const Text(MemoraCopy.moveConversationTopicUp),
                  ),
                  OutlinedButton(
                    key: Key(
                      'memora-family-conversation-down-${topic.id.value}',
                    ),
                    onPressed: () => controller.move(topic, 1),
                    child: const Text(MemoraCopy.moveConversationTopicDown),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopicEditor extends StatelessWidget {
  const _TopicEditor({required this.controller});

  final FamilyConversationTopicController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEdit = controller.editingTopicId != null;
    final revision = controller.editorRevision;
    return DecoratedBox(
      key: const Key('memora-family-conversation-editor'),
      decoration: BoxDecoration(
        border: Border.all(color: MemoraTheme.borderInk, width: 2),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit
                  ? MemoraCopy.editConversationTopic
                  : MemoraCopy.createConversationTopic,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            DraftTextField(
              key: const Key('memora-family-conversation-title'),
              revision: revision,
              initialText: controller.draftTitle,
              labelText: MemoraCopy.conversationTopicTitleLabel,
              onChanged: controller.setDraftTitle,
            ),
            const SizedBox(height: 12),
            Text(
              MemoraCopy.conversationIntroductionLabel,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            DraftTextField(
              key: const Key('memora-family-conversation-introduction'),
              revision: revision,
              initialText: controller.draftIntroduction,
              labelText: MemoraCopy.conversationIntroductionLabel,
              maxLines: 3,
              onChanged: controller.setDraftIntroduction,
            ),
            const SizedBox(height: 12),
            Text(
              MemoraCopy.conversationPromptsLabel,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < controller.draftPrompts.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DraftTextField(
                      key: Key('memora-family-conversation-prompt-$i'),
                      revision: revision,
                      initialText: controller.draftPrompts[i],
                      labelText:
                          '${MemoraCopy.conversationPromptLabel} ${i + 1}',
                      maxLines: 3,
                      onChanged: (value) => controller.setDraftPrompt(i, value),
                    ),
                  ),
                  if (controller.draftPrompts.length >
                      ConversationTopic.minPrompts) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      key: Key('memora-family-conversation-remove-prompt-$i'),
                      onPressed: () => controller.requestRemovePromptField(i),
                      child: const Text(MemoraCopy.conversationRemovePrompt),
                    ),
                  ],
                ],
              ),
              if (controller.pendingRemovePromptIndex == i) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    MemoraCopy.conversationRemovePromptConfirm,
                    key: Key(
                      'memora-family-conversation-remove-prompt-confirm-$i',
                    ),
                    style: textTheme.bodyMedium?.copyWith(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      key: Key(
                        'memora-family-conversation-remove-prompt-yes-$i',
                      ),
                      onPressed: controller.confirmPendingRemovePrompt,
                      child: const Text(
                        MemoraCopy.conversationRemovePromptConfirmAction,
                      ),
                    ),
                    OutlinedButton(
                      key: Key(
                        'memora-family-conversation-remove-prompt-no-$i',
                      ),
                      onPressed: controller.cancelPendingRemovePrompt,
                      child: const Text(
                        MemoraCopy.conversationRemovePromptCancel,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              _PromptHelpEditor(controller: controller, index: i),
              const SizedBox(height: 12),
            ],
            if (controller.draftPrompts.length < ConversationTopic.maxPrompts)
              OutlinedButton(
                key: const Key('memora-family-conversation-add-prompt'),
                onPressed: controller.addPromptField,
                child: const Text(MemoraCopy.conversationAddPrompt),
              ),
            const SizedBox(height: 12),
            Text(
              MemoraCopy.conversationClosingLabel,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            DraftTextField(
              key: const Key('memora-family-conversation-closing'),
              revision: revision,
              initialText: controller.draftClosing,
              labelText: MemoraCopy.conversationClosingLabel,
              maxLines: 2,
              onChanged: controller.setDraftClosing,
            ),
            const SizedBox(height: 12),
            Text(
              MemoraCopy.conversationMemoryLinkLabel,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              key: const Key('memora-family-conversation-memory'),
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const Key('memora-family-conversation-memory-none'),
                  onPressed: () => controller.setDraftMemoryId(null),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: controller.draftMemoryId == null
                        ? MemoraTheme.accentBand
                        : Colors.white,
                    foregroundColor: controller.draftMemoryId == null
                        ? MemoraTheme.accentOnBand
                        : MemoraTheme.highContrastInk,
                  ),
                  child: const Text(MemoraCopy.conversationMemoryLinkNone),
                ),
                ...controller.approvedMemories.map(
                  (memory) => OutlinedButton(
                    key: Key(
                      'memora-family-conversation-memory-${memory.id.value}',
                    ),
                    onPressed: () => controller.setDraftMemoryId(memory.id),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: controller.draftMemoryId == memory.id
                          ? MemoraTheme.accentBand
                          : Colors.white,
                      foregroundColor: controller.draftMemoryId == memory.id
                          ? MemoraTheme.accentOnBand
                          : MemoraTheme.highContrastInk,
                    ),
                    child: Text(memory.caption),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SupportedPersonPreview(controller: controller),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('memora-family-save-conversation'),
              onPressed: () => controller.saveDraft(),
              child: const Text(MemoraCopy.saveConversationTopic),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportedPersonPreview extends StatelessWidget {
  const _SupportedPersonPreview({required this.controller});

  final FamilyConversationTopicController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = controller.draftTitle.trim().isEmpty
        ? '…'
        : controller.draftTitle.trim();
    final intro = controller.draftIntroduction.trim().isEmpty
        ? '…'
        : controller.draftIntroduction.trim();
    final closing = controller.draftClosing.trim().isEmpty
        ? '…'
        : controller.draftClosing.trim();
    return DecoratedBox(
      key: const Key('memora-family-conversation-preview'),
      decoration: BoxDecoration(
        border: Border.all(color: MemoraTheme.accentBand, width: 2),
        color: MemoraTheme.highContrastSurface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              MemoraCopy.conversationPreviewTitle,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(intro, style: textTheme.bodyLarge?.copyWith(fontSize: 17)),
            const SizedBox(height: 8),
            for (var i = 0; i < controller.draftPrompts.length; i++) ...[
              if (controller.draftPrompts[i].trim().isNotEmpty) ...[
                Text(
                  '• ${controller.draftPrompts[i].trim()}',
                  style: textTheme.bodyLarge?.copyWith(fontSize: 16),
                ),
                if (controller.draftHelpPresent(i)) ...[
                  const SizedBox(height: 4),
                  Text(
                    MemoraCopy.conversationPreviewHelpAffordance,
                    key: Key(
                      'memora-family-conversation-preview-help-action-$i',
                    ),
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (controller.draftHelpCues[i].trim().isNotEmpty)
                    Text(
                      controller.draftHelpCues[i].trim(),
                      key: Key(
                        'memora-family-conversation-preview-help-cue-$i',
                      ),
                      style: textTheme.bodyMedium?.copyWith(fontSize: 15),
                    ),
                  if (controller.draftHelpMemoryIds[i] != null)
                    Text(
                      controller
                              .approvedMemoryById(
                                controller.draftHelpMemoryIds[i],
                              )
                              ?.caption ??
                          MemoraCopy.conversationHelpMemoryLabel,
                      key: Key(
                        'memora-family-conversation-preview-help-memory-$i',
                      ),
                      style: textTheme.bodyMedium?.copyWith(fontSize: 15),
                    ),
                ],
                const SizedBox(height: 4),
              ],
            ],
            const SizedBox(height: 4),
            Text(closing, style: textTheme.bodyLarge?.copyWith(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
