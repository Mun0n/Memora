import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../l10n/memora_copy.dart';
import '../../../theme/memora_supported_person_typography.dart';
import '../../../theme/memora_theme.dart';
import '../../user_pastime_controller.dart';
import '../games/spider_board.dart';
import '../games/sudoku_board.dart';
import '../games/word_search_board.dart';

/// Common native pastime player: title, instruction, board, session actions.
///
/// Header copy may scroll; session actions stay reachable; the board uses the
/// remaining viewport (local scroll outside the active board is allowed).
class PastimePlayerShell extends StatelessWidget {
  const PastimePlayerShell({super.key, required this.controller});

  final UserPastimeController controller;

  @override
  Widget build(BuildContext context) {
    final pastime = controller.selectedPastime;
    if (pastime == null) {
      return const SizedBox.shrink();
    }
    final textTheme = Theme.of(context).textTheme;
    final isSpider =
        controller.selectedPastime?.experience
            is SpiderSolitairePastimeExperience;
    // Spider needs the landscape tableau; keep chrome compact.
    final headerFraction = isSpider ? 0.16 : 0.28;
    return Column(
      key: const Key('memora-user-pastime-player'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          flex: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * headerFraction,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    pastime.title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: MemoraTheme.highContrastInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pastime.instruction,
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: MemoraSupportedPersonTypography.secondary,
                      height: MemoraSupportedPersonTypography.bodyHeight,
                      color: MemoraTheme.highContrastInk,
                    ),
                  ),
                  if (controller.boardGuidance != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      controller.boardGuidance!,
                      key: const Key('memora-user-pastime-board-guidance'),
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: MemoraSupportedPersonTypography.secondary,
                        height: MemoraSupportedPersonTypography.bodyHeight,
                        color: MemoraTheme.highContrastInk,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _BoardForExperience(controller: controller)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const Key('memora-user-pastime-finish'),
              onPressed: () => _confirmFinish(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
              ),
              child: const Text(MemoraCopy.pasatiemposFinish),
            ),
            OutlinedButton(
              key: const Key('memora-user-pastime-restart'),
              onPressed: () => _confirmRestart(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
              ),
              child: const Text(MemoraCopy.pasatiemposRestart),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmFinish(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('memora-user-pastime-exit-dialog'),
        content: const Text(MemoraCopy.pasatiemposExitConfirm),
        actions: [
          TextButton(
            key: const Key('memora-user-pastime-exit-stay'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(MemoraCopy.pasatiemposExitConfirmStay),
          ),
          FilledButton(
            key: const Key('memora-user-pastime-exit-leave'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(MemoraCopy.pasatiemposExitConfirmYes),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.finishSession(confirmed: true);
    }
  }

  Future<void> _confirmRestart(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('memora-user-pastime-restart-dialog'),
        content: const Text(MemoraCopy.pasatiemposRestartConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(MemoraCopy.pasatiemposConfirmNo),
          ),
          FilledButton(
            key: const Key('memora-user-pastime-restart-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(MemoraCopy.pasatiemposConfirmYes),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.restartSession(confirmed: true);
    }
  }
}

/// Neutral completion surface — no praise, score or auto-replay.
class PastimeCompletedPanel extends StatelessWidget {
  const PastimeCompletedPanel({super.key, required this.controller});

  final UserPastimeController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Column(
        key: const Key('memora-user-pastime-completed'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            MemoraCopy.pasatiemposCompletedTitle,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: MemoraTheme.highContrastInk,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('memora-user-pastime-play-again'),
            onPressed: controller.playAgain,
            style: FilledButton.styleFrom(
              minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
            ),
            child: const Text(MemoraCopy.pasatiemposPlayAgain),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('memora-user-pastime-back-after-complete'),
            onPressed: controller.returnToList,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
            ),
            child: const Text(MemoraCopy.pasatiemposBackToList),
          ),
        ],
      ),
    );
  }
}

class _BoardForExperience extends StatelessWidget {
  const _BoardForExperience({required this.controller});

  final UserPastimeController controller;

  @override
  Widget build(BuildContext context) {
    final experience = controller.selectedPastime?.experience;
    return switch (experience) {
      SudokuPastimeExperience() when controller.sudokuState != null =>
        SudokuBoard(controller: controller),
      WordSearchPastimeExperience() when controller.wordSearchState != null =>
        WordSearchBoard(controller: controller),
      SpiderSolitairePastimeExperience() when controller.spiderState != null =>
        SpiderBoard(controller: controller),
      _ => Text(
        MemoraCopy.pasatiemposUnavailable,
        key: const Key('memora-user-pastime-unavailable'),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    };
  }
}
