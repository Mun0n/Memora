import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../sync/presentation_sync.dart';
import '../theme/memora_theme.dart';
import '../widgets/draft_text_field.dart';
import 'family_memory_controller.dart';

/// Caregiver/family web: create/edit/order/approve/archive + media retry.
class FamilyMemoryPage extends StatelessWidget {
  const FamilyMemoryPage({super.key, required this.controller});

  final FamilyMemoryController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final textTheme = Theme.of(context).textTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.memories.isEmpty)
              Text(
                MemoraCopy.memoriesEmpty,
                key: const Key('memora-family-memories-empty'),
                style: textTheme.bodyLarge?.copyWith(fontSize: 18),
              )
            else
              ...controller.memories.map(
                (memory) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MemoryCard(memory: memory, controller: controller),
                ),
              ),
            const SizedBox(height: 8),
            if (controller.canManage || controller.canContribute)
              OutlinedButton(
                key: const Key('memora-family-begin-memory'),
                onPressed: controller.beginCreate,
                child: Text(
                  controller.canManage
                      ? MemoraCopy.createMemory
                      : MemoraCopy.contributeMemory,
                ),
              ),
            const SizedBox(height: 16),
            _MemoryEditor(controller: controller),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                controller.errorMessage!,
                key: const Key('memora-family-memory-error'),
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.memory, required this.controller});

  final MemoryEntry memory;
  final FamilyMemoryController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lifecycle = switch (memory.lifecycleStatus) {
      MemoryLifecycleStatus.proposed => MemoraCopy.memoryLifecycleProposed,
      MemoryLifecycleStatus.approved => MemoraCopy.memoryLifecycleApproved,
      MemoryLifecycleStatus.archived => MemoraCopy.memoryLifecycleArchived,
    };
    final media = memory.media;
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
              '${memory.caption} ($lifecycle)',
              key: Key('memora-family-memory-${memory.id.value}'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              memory.dateContext,
              style: textTheme.bodyLarge?.copyWith(fontSize: 16),
            ),
            if (media != null) ...[
              const SizedBox(height: 8),
              Text(
                '${MemoraCopy.mediaStatusLabel}: '
                '${SyncStatusLabels.forSyncState(media.uploadState)}',
                key: Key('memora-family-media-status-${memory.id.value}'),
                style: textTheme.bodyMedium?.copyWith(fontSize: 15),
              ),
              Text(
                '${MemoraCopy.memoryMediaPathLabel}: ${media.familyScopedPath}',
                style: textTheme.bodySmall?.copyWith(fontSize: 14),
              ),
              Text(
                '${MemoraCopy.memoryMediaChecksumLabel}: ${media.checksum}',
                style: textTheme.bodySmall?.copyWith(fontSize: 14),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (controller.canManage) ...[
                  OutlinedButton(
                    key: Key('memora-family-edit-memory-${memory.id.value}'),
                    onPressed: () => controller.beginEdit(memory),
                    child: const Text(MemoraCopy.editMemory),
                  ),
                  if (memory.lifecycleStatus == MemoryLifecycleStatus.proposed)
                    OutlinedButton(
                      key: Key('memora-family-approve-${memory.id.value}'),
                      onPressed: () => controller.approve(memory.id),
                      child: const Text(MemoraCopy.approveMemory),
                    ),
                  if (memory.lifecycleStatus != MemoryLifecycleStatus.archived)
                    OutlinedButton(
                      key: Key(
                        'memora-family-archive-memory-${memory.id.value}',
                      ),
                      onPressed: () => controller.archive(memory.id),
                      child: const Text(MemoraCopy.archiveMemory),
                    ),
                  OutlinedButton(
                    key: Key('memora-family-memory-up-${memory.id.value}'),
                    onPressed: () => controller.move(memory, -1),
                    child: const Text(MemoraCopy.moveMemoryUp),
                  ),
                  OutlinedButton(
                    key: Key('memora-family-memory-down-${memory.id.value}'),
                    onPressed: () => controller.move(memory, 1),
                    child: const Text(MemoraCopy.moveMemoryDown),
                  ),
                  if (memory.hasFailedMedia)
                    OutlinedButton(
                      key: Key('memora-family-retry-media-${memory.id.value}'),
                      onPressed: () => controller.retryMedia(memory.id),
                      child: const Text(MemoraCopy.mediaRetryUpload),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryEditor extends StatelessWidget {
  const _MemoryEditor({required this.controller});

  final FamilyMemoryController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.canManage && !controller.canContribute) {
      return const SizedBox.shrink();
    }
    final revision = controller.editorRevision;
    return Column(
      key: const Key('memora-family-memory-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DraftTextField(
          key: const Key('memora-family-memory-caption'),
          revision: revision,
          initialText: controller.draftCaption,
          onChanged: controller.setDraftCaption,
          labelText: MemoraCopy.memoryCaptionLabel,
        ),
        const SizedBox(height: 12),
        DraftTextField(
          key: const Key('memora-family-memory-date'),
          revision: revision,
          initialText: controller.draftDateContext,
          onChanged: controller.setDraftDateContext,
          labelText: MemoraCopy.memoryDateContextLabel,
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('memora-family-save-memory'),
          onPressed: controller.saveDraft,
          child: const Text(MemoraCopy.saveMemory),
        ),
      ],
    );
  }
}
