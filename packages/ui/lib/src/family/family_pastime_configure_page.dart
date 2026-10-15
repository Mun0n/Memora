import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import '../widgets/draft_text_field.dart';
import 'family_pastime_controller.dart';
import 'family_pastime_preview.dart';

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
              MemoraCopy.pastimesSectionBody,
              style: textTheme.bodyLarge?.copyWith(fontSize: 17),
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
    final typeLabel = _typeLabel(pastime.experience);
    final isActive = pastime.lifecycleStatus == PastimeLifecycleStatus.active;
    final quarantined = pastime.experience is QuarantinedPastimeExperience;
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
            const SizedBox(height: 4),
            Text(
              typeLabel,
              key: Key('memora-family-pastime-type-${pastime.id.value}'),
              style: textTheme.bodyMedium?.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              pastime.instruction,
              style: textTheme.bodyLarge?.copyWith(fontSize: 17),
            ),
            if (quarantined) ...[
              const SizedBox(height: 8),
              Text(
                (pastime.experience as QuarantinedPastimeExperience)
                    .plainLanguageReason,
                key: Key(
                  'memora-family-pastime-quarantine-${pastime.id.value}',
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 15,
                ),
              ),
            ],
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

  static String _typeLabel(PastimeExperience experience) {
    return switch (experience) {
      GuidedPastimeExperience() => MemoraCopy.pastimeTypeGuided,
      SudokuPastimeExperience() => MemoraCopy.pastimeTypeSudoku,
      WordSearchPastimeExperience() => MemoraCopy.pastimeTypeWordSearch,
      SpiderSolitairePastimeExperience() => MemoraCopy.pastimeTypeSpider,
      QuarantinedPastimeExperience() => MemoraCopy.pastimeQuarantinedLabel,
    };
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
    final type = controller.draftExperienceType;
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
            if (controller.pendingTypeChange != null) ...[
              const SizedBox(height: 12),
              _TypeChangeConfirm(controller: controller),
            ],
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
            const SizedBox(height: 16),
            Text(
              MemoraCopy.pastimeTypeLabel,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _TypeOption(
              keyName: 'guided',
              label: MemoraCopy.pastimeTypeGuided,
              description: MemoraCopy.pastimeTypeGuidedDesc,
              selected: type == GuidedPastimeExperience.wireType,
              onTap: () => controller.requestExperienceType(
                GuidedPastimeExperience.wireType,
              ),
            ),
            _TypeOption(
              keyName: 'sudoku',
              label: MemoraCopy.pastimeTypeSudoku,
              description: MemoraCopy.pastimeTypeSudokuDesc,
              selected: type == SudokuPastimeExperience.wireType,
              onTap: () => controller.requestExperienceType(
                SudokuPastimeExperience.wireType,
              ),
            ),
            _TypeOption(
              keyName: 'wordSearch',
              label: MemoraCopy.pastimeTypeWordSearch,
              description: MemoraCopy.pastimeTypeWordSearchDesc,
              selected: type == WordSearchPastimeExperience.wireType,
              onTap: () => controller.requestExperienceType(
                WordSearchPastimeExperience.wireType,
              ),
            ),
            _TypeOption(
              keyName: 'spiderSolitaire',
              label: MemoraCopy.pastimeTypeSpider,
              description: MemoraCopy.pastimeTypeSpiderDesc,
              selected: type == SpiderSolitairePastimeExperience.wireType,
              onTap: () => controller.requestExperienceType(
                SpiderSolitairePastimeExperience.wireType,
              ),
            ),
            if (type == SudokuPastimeExperience.wireType) ...[
              const SizedBox(height: 12),
              Text(
                MemoraCopy.pastimeSudokuSizeLabel,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final size in SudokuBoardSize.values)
                    ChoiceChip(
                      key: Key('memora-family-sudoku-size-${size.wireName}'),
                      label: Text(_sudokuSizeLabel(size)),
                      selected: controller.draftSudokuSize == size,
                      onSelected: (_) => controller.setDraftSudokuSize(size),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${MemoraCopy.pastimeSudokuLevelLabel}: '
                '${MemoraCopy.pastimeSudokuLevelStarter}',
                key: const Key('memora-family-sudoku-level'),
                style: textTheme.bodyMedium,
              ),
            ],
            if (type == WordSearchPastimeExperience.wireType) ...[
              const SizedBox(height: 12),
              Text(
                MemoraCopy.pastimeWordSearchSizeLabel,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final size in WordSearchBoardSize.values)
                    ChoiceChip(
                      key: Key(
                        'memora-family-wordsearch-size-${size.wireName}',
                      ),
                      label: Text(_wordSearchSizeLabel(size)),
                      selected: controller.draftWordSearchSize == size,
                      onSelected: (_) =>
                          controller.setDraftWordSearchSize(size),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                MemoraCopy.pastimeWordSearchThemeLabel,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final set in WordSearchWordSets.all)
                    ChoiceChip(
                      key: Key('memora-family-wordsearch-theme-${set.id}'),
                      label: Text(set.themeLabelEs),
                      selected: controller.draftWordSetId == set.id,
                      onSelected: (_) => controller.setDraftWordSetId(set.id),
                    ),
                ],
              ),
            ],
            if (type == SpiderSolitairePastimeExperience.wireType) ...[
              const SizedBox(height: 12),
              Text(
                MemoraCopy.pastimeSpiderSuitsLabel,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final suits in SpiderSuitCount.values)
                    ChoiceChip(
                      key: Key('memora-family-spider-suits-${suits.value}'),
                      label: Text(_spiderSuitsLabel(suits)),
                      selected: controller.draftSpiderSuits == suits,
                      onSelected: (_) => controller.setDraftSpiderSuits(suits),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FamilyPastimePreview(experience: controller.draftExperience),
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

  static String _sudokuSizeLabel(SudokuBoardSize size) => switch (size) {
    SudokuBoardSize.fourByFour => MemoraCopy.pastimeSudokuSize4,
    SudokuBoardSize.sixBySix => MemoraCopy.pastimeSudokuSize6,
    SudokuBoardSize.nineByNine => MemoraCopy.pastimeSudokuSize9,
  };

  static String _wordSearchSizeLabel(WordSearchBoardSize size) =>
      switch (size) {
        WordSearchBoardSize.eightByEight => MemoraCopy.pastimeWordSearchSize8,
        WordSearchBoardSize.tenByTen => MemoraCopy.pastimeWordSearchSize10,
      };

  static String _spiderSuitsLabel(SpiderSuitCount suits) => switch (suits) {
    SpiderSuitCount.one => MemoraCopy.pastimeSpiderSuits1,
    SpiderSuitCount.two => MemoraCopy.pastimeSpiderSuits2,
    SpiderSuitCount.four => MemoraCopy.pastimeSpiderSuits4,
  };
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.keyName,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String keyName;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFFE8F0EC) : Colors.white,
        child: InkWell(
          key: Key('memora-family-pastime-type-$keyName'),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: selected
                    ? MemoraTheme.accentBand
                    : MemoraTheme.borderInk,
                width: selected ? 2.5 : 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    semanticLabel: selected
                        ? 'Seleccionado'
                        : 'No seleccionado',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(description),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChangeConfirm extends StatelessWidget {
  const _TypeChangeConfirm({required this.controller});

  final FamilyPastimeController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('memora-family-pastime-type-change-dialog'),
      decoration: BoxDecoration(
        border: Border.all(color: MemoraTheme.borderInk, width: 2),
        color: const Color(0xFFFFF8E7),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(MemoraCopy.pastimeTypeChangeConfirm),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const Key('memora-family-pastime-type-change-cancel'),
                  onPressed: controller.cancelPendingTypeChange,
                  child: const Text(MemoraCopy.pasatiemposConfirmNo),
                ),
                FilledButton(
                  key: const Key('memora-family-pastime-type-change-confirm'),
                  onPressed: controller.confirmPendingTypeChange,
                  child: const Text(MemoraCopy.pasatiemposConfirmYes),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
