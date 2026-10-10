import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import 'user_memory_controller.dart';

/// Calm approved-memory presentation for phone/tablet.
///
/// Failed/missing media shows a placeholder; navigation always continues.
class UserApprovedMemoriesPage extends StatelessWidget {
  const UserApprovedMemoriesPage({super.key, required this.controller});

  final UserMemoryController controller;

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
              MemoraCopy.memoriesApprovedTitle,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: MemoraTheme.highContrastInk,
              ),
            ),
            const SizedBox(height: 12),
            if (controller.memories.isEmpty)
              Text(
                MemoraCopy.memoriesEmpty,
                key: const Key('memora-user-memories-empty'),
                style: textTheme.bodyLarge?.copyWith(fontSize: 18),
              )
            else
              ...controller.memories.map(
                (memory) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ApprovedMemoryCard(
                    memory: memory,
                    controller: controller,
                  ),
                ),
              ),
            if (controller.focusedFailedMediaId != null) ...[
              const SizedBox(height: 8),
              Text(
                MemoraCopy.mediaFailedPlaceholder,
                key: const Key('memora-user-media-failed-banner'),
                style: textTheme.bodyLarge?.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('memora-user-continue-after-media'),
                onPressed: controller.continueAfterFailedMedia,
                child: const Text(MemoraCopy.continueAfterFailedMedia),
              ),
            ],
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                controller.errorMessage!,
                key: const Key('memora-user-memory-error'),
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

class _ApprovedMemoryCard extends StatelessWidget {
  const _ApprovedMemoryCard({required this.memory, required this.controller});

  final MemoryEntry memory;
  final UserMemoryController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final failed = memory.hasFailedMedia;
    return DecoratedBox(
      key: Key('memora-user-memory-${memory.id.value}'),
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
              memory.caption,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              memory.dateContext,
              style: textTheme.bodyLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            if (failed)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    MemoraCopy.mediaFailedPlaceholder,
                    key: Key('memora-user-media-failed-${memory.id.value}'),
                    style: textTheme.bodyLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: Key('memora-user-ack-failed-media-${memory.id.value}'),
                    onPressed: () =>
                        controller.acknowledgeFailedMedia(memory.id),
                    child: const Text(MemoraCopy.continueAfterFailedMedia),
                  ),
                ],
              )
            else if (memory.media != null)
              Text(
                '${MemoraCopy.memoryMediaPathLabel}: '
                '${memory.media!.familyScopedPath}',
                key: Key('memora-user-media-ok-${memory.id.value}'),
                style: textTheme.bodyMedium?.copyWith(fontSize: 15),
              )
            else
              Text(
                'Sin medio adjunto.',
                style: textTheme.bodyMedium?.copyWith(fontSize: 15),
              ),
          ],
        ),
      ),
    );
  }
}
