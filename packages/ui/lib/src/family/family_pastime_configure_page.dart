import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../demo/demo_data_scope.dart';
import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import '../widgets/draft_text_field.dart';
import 'family_pastime_controller.dart';

/// Caregiver/family web: create/edit/order/activate/archive pastimes.
class FamilyPastimeConfigureContent extends StatelessWidget {
  const FamilyPastimeConfigureContent({super.key, required this.controller});

  final FamilyPastimeController controller;

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
              MemoraCopy.pastimesSectionTitle,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: MemoraTheme.highContrastInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              MemoraCopy.pastimesSectionBody,
              style: textTheme.bodyLarge?.copyWith(fontSize: 17),
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
                key: const Key('memora-family-pastime-shared-pending'),
                style: textTheme.bodyMedium?.copyWith(fontSize: 16),
              ),
            ],
            if (controller.sharedPullFailed) ...[
              const SizedBox(height: 8),
              Text(
                MemoraCopy.sharedLocalDemoPullFailed,
                key: const Key('memora-family-pastime-shared-pull-failed'),
                style: textTheme.bodyMedium?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('memora-family-pastime-pull-retry'),
                onPressed: controller.recover,
                child: const Text(MemoraCopy.recoveryRetry),
              ),
            ],
            if (controller.sharedDeliveryFailed) ...[
              const SizedBox(height: 8),
              Text(
                MemoraCopy.sharedLocalDemoDeliveryFailed,
                key: const Key('memora-family-pastime-shared-delivery-failed'),
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('memora-family-pastime-delivery-retry'),
                onPressed: controller.recover,
                child: const Text(MemoraCopy.recoveryRetry),
              ),
            ],
            const SizedBox(height: 16),
            if (controller.pastimes.isEmpty)
              Text(
                MemoraCopy.pastimesEmptyConfigure,
                key: const Key('memora-family-pastimes-empty'),
                style: textTheme.bodyLarge?.copyWith(fontSize: 18),
              )
            else
              ...controller.pastimes.map(
                (pastime) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PastimeCard(pastime: pastime, controller: controller),
                ),
              ),
            if (controller.canEdit) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('memora-family-begin-pastime'),
                onPressed: controller.beginCreate,
                child: const Text(MemoraCopy.createPastime),
              ),
              const SizedBox(height: 16),
              _PastimeEditor(controller: controller),
            ],
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                controller.errorMessage!,
                key: const Key('memora-family-pastime-error'),
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

class _PastimeCard extends StatelessWidget {
  const _PastimeCard({required this.pastime, required this.controller});

  final Pastime pastime;
  final FamilyPastimeController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lifecycle = switch (pastime.lifecycleStatus) {
      PastimeLifecycleStatus.draft => MemoraCopy.pastimeLifecycleDraft,
      PastimeLifecycleStatus.active => MemoraCopy.pastimeLifecycleActive,
      PastimeLifecycleStatus.archived => MemoraCopy.pastimeLifecycleArchived,
    };
    final isActive = pastime.lifecycleStatus == PastimeLifecycleStatus.active;
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
              '${pastime.title} ($lifecycle)',
              key: Key('memora-family-pastime-${pastime.id.value}'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              pastime.instruction,
              style: textTheme.bodyLarge?.copyWith(fontSize: 17),
            ),
            if (controller.canEdit) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: Key('memora-family-edit-pastime-${pastime.id.value}'),
                    onPressed: () => controller.beginEdit(pastime),
                    child: const Text(MemoraCopy.editPastime),
                  ),
                  if (isActive)
                    OutlinedButton(
                      key: Key(
                        'memora-family-archive-pastime-${pastime.id.value}',
                      ),
                      onPressed: () => controller.archive(pastime.id),
                      child: const Text(MemoraCopy.archivePastime),
                    )
                  else
                    FilledButton(
                      key: Key(
                        'memora-family-activate-pastime-${pastime.id.value}',
                      ),
                      onPressed: () => controller.activate(pastime.id),
                      child: const Text(MemoraCopy.activatePastime),
                    ),
                  OutlinedButton(
                    key: Key('memora-family-pastime-up-${pastime.id.value}'),
                    onPressed: () => controller.move(pastime, -1),
                    child: const Text(MemoraCopy.movePastimeUp),
                  ),
                  OutlinedButton(
                    key: Key('memora-family-pastime-down-${pastime.id.value}'),
                    onPressed: () => controller.move(pastime, 1),
                    child: const Text(MemoraCopy.movePastimeDown),
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

class _PastimeEditor extends StatelessWidget {
  const _PastimeEditor({required this.controller});

  final FamilyPastimeController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEdit = controller.editingPastimeId != null;
    final revision = controller.editorRevision;
    return DecoratedBox(
      key: const Key('memora-family-pastime-editor'),
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
              isEdit ? MemoraCopy.editPastime : MemoraCopy.createPastime,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            DraftTextField(
              key: const Key('memora-family-pastime-title'),
              revision: revision,
              initialText: controller.draftTitle,
              labelText: MemoraCopy.pastimeTitleLabel,
              onChanged: controller.setDraftTitle,
            ),
            const SizedBox(height: 12),
            DraftTextField(
              key: const Key('memora-family-pastime-instruction'),
              revision: revision,
              initialText: controller.draftInstruction,
              labelText: MemoraCopy.pastimeInstructionLabel,
              onChanged: controller.setDraftInstruction,
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('memora-family-save-pastime'),
              onPressed: () => controller.saveDraft(),
              child: const Text(MemoraCopy.savePastime),
            ),
          ],
        ),
      ),
    );
  }
}
