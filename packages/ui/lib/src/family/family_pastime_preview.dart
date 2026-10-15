import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import '../user/pastimes/games/playing_card_face.dart';

/// Non-interactive deterministic preview for caregiver template selection.
///
/// Never mutates live supported-person session state.
class FamilyPastimePreview extends StatelessWidget {
  const FamilyPastimePreview({super.key, required this.experience});

  final PastimeExperience? experience;

  static const int _previewSeed = 14;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final exp = experience;
    if (exp == null || !exp.isCompleteAndSupported) {
      return Text(
        MemoraCopy.pastimesExperienceValidationError,
        key: const Key('memora-family-pastime-preview-invalid'),
        style: textTheme.bodyMedium,
      );
    }
    return Column(
      key: const Key('memora-family-pastime-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          MemoraCopy.pastimePreviewLabel,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          MemoraCopy.pastimePreviewHint,
          style: textTheme.bodySmall?.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        AbsorbPointer(
          child: ExcludeSemantics(
            excluding: false,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: MemoraTheme.borderInk, width: 1),
                color: const Color(0xFFF0F0EA),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: switch (exp) {
                  GuidedPastimeExperience() => Text(
                    MemoraCopy.pastimeTypeGuidedDesc,
                    style: textTheme.bodyMedium,
                  ),
                  SudokuPastimeExperience() => _SudokuPreview(experience: exp),
                  WordSearchPastimeExperience() => _WordSearchPreview(
                    experience: exp,
                  ),
                  SpiderSolitairePastimeExperience() => _SpiderPreview(
                    experience: exp,
                  ),
                  QuarantinedPastimeExperience() => Text(
                    exp.plainLanguageReason,
                    style: textTheme.bodyMedium,
                  ),
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SudokuPreview extends StatelessWidget {
  const _SudokuPreview({required this.experience});

  final SudokuPastimeExperience experience;

  @override
  Widget build(BuildContext context) {
    final engine = SudokuEngine();
    final state = engine.start(
      experience: experience,
      seed: FamilyPastimePreview._previewSeed,
    );
    final n = state.dimension;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sudoku ${experience.boardSize.wireName}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: MemoraTheme.borderInk, width: 1),
          children: [
            for (var r = 0; r < n; r++)
              TableRow(
                children: [
                  for (var c = 0; c < n; c++)
                    SizedBox(
                      height: 28,
                      child: Center(
                        child: Text(
                          state.values[r * n + c] == 0
                              ? '·'
                              : '${state.values[r * n + c]}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: state.isClue(r * n + c)
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _WordSearchPreview extends StatelessWidget {
  const _WordSearchPreview({required this.experience});

  final WordSearchPastimeExperience experience;

  @override
  Widget build(BuildContext context) {
    final engine = WordSearchEngine();
    final state = engine.start(
      experience: experience,
      seed: FamilyPastimePreview._previewSeed,
    );
    final set = WordSearchWordSets.byId(experience.wordSetId);
    final n = state.dimension;
    final show = n > 8 ? 6 : n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${set.themeLabelEs} (${experience.boardSize.wireName})',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          state.words.join(' · '),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: MemoraTheme.borderInk, width: 1),
          children: [
            for (var r = 0; r < show; r++)
              TableRow(
                children: [
                  for (var c = 0; c < show; c++)
                    SizedBox(
                      height: 22,
                      child: Center(
                        child: Text(
                          state.grid[r][c],
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
        if (show < n)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('…', style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}

class _SpiderPreview extends StatelessWidget {
  const _SpiderPreview({required this.experience});

  final SpiderSolitairePastimeExperience experience;

  @override
  Widget build(BuildContext context) {
    final engine = SpiderEngine();
    final state = engine.start(
      experience: experience,
      seed: FamilyPastimePreview._previewSeed,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spider · ${experience.suitCount.value} palo'
          '${experience.suitCount.value == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        if (state.tableau.any((c) => c.any((card) => card.faceUp)))
          Align(
            alignment: Alignment.centerLeft,
            child: PlayingCardFace(
              card: state.tableau
                  .expand((c) => c)
                  .firstWhere((card) => card.faceUp),
              width: 56,
              height: 76,
              compact: true,
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var col = 0; col < SpiderEngine.columnCount; col++)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: MemoraTheme.borderInk),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'C${col + 1}:${state.tableau[col].length}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
