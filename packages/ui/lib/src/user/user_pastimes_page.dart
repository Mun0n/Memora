import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../demo/demo_data_scope.dart';
import '../l10n/memora_copy.dart';
import '../theme/memora_supported_person_typography.dart';
import '../theme/memora_theme.dart';
import 'pastimes/player/pastime_player_shell.dart';
import 'user_pastime_controller.dart';

/// Supported-person Pasatiempos: list → intro/detail → player → completion.
///
/// No draft/archived exposure, sync jargon, caregiver controls or scores.
class UserPastimesPage extends StatelessWidget {
  const UserPastimesPage({super.key, required this.controller});

  final UserPastimeController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return switch (controller.phase) {
          UserPastimePhase.list => _PastimeList(controller: controller),
          UserPastimePhase.guidedDetail => _GuidedDetail(
            pastime: controller.selectedPastime!,
            controller: controller,
          ),
          UserPastimePhase.intro => _PastimeIntro(controller: controller),
          UserPastimePhase.recoveryOffer => _RecoveryOffer(
            controller: controller,
          ),
          UserPastimePhase.playing => PastimePlayerShell(
            controller: controller,
          ),
          UserPastimePhase.completed => PastimeCompletedPanel(
            controller: controller,
          ),
        };
      },
    );
  }
}

class _PastimeList extends StatelessWidget {
  const _PastimeList({required this.controller});

  final UserPastimeController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: const Key('memora-user-pasatiempos'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          MemoraCopy.pasatiemposTitle,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: MemoraTheme.highContrastInk,
          ),
        ),
        if (controller.demoDataScope == DemoDataScope.isolatedLocal) ...[
          const SizedBox(height: 8),
          Text(
            MemoraCopy.pasatiemposIsolatedDemoNotice,
            key: const Key('memora-isolated-local-demo'),
            style: textTheme.bodyMedium?.copyWith(
              color: MemoraTheme.highContrastInk,
              fontSize: MemoraSupportedPersonTypography.secondary,
              height: MemoraSupportedPersonTypography.bodyHeight,
            ),
          ),
        ],
        if (controller.isRefreshingShared) ...[
          const SizedBox(height: 8),
          Text(
            MemoraCopy.pasatiemposSharedPending,
            key: const Key('memora-user-pasatiempos-shared-pending'),
            style: textTheme.bodyMedium?.copyWith(
              color: MemoraTheme.highContrastInk,
              fontSize: MemoraSupportedPersonTypography.secondary,
              height: MemoraSupportedPersonTypography.bodyHeight,
            ),
          ),
        ],
        if (controller.sharedPullFailed) ...[
          const SizedBox(height: 8),
          Text(
            MemoraCopy.pasatiemposSharedPullFailed,
            key: const Key('memora-user-pasatiempos-shared-pull-failed'),
            style: textTheme.bodyMedium?.copyWith(
              color: MemoraTheme.highContrastInk,
              fontSize: MemoraSupportedPersonTypography.secondary,
              height: MemoraSupportedPersonTypography.bodyHeight,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('memora-user-pasatiempos-pull-retry'),
            onPressed: controller.recover,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
            ),
            child: const Text(MemoraCopy.recoveryRetry),
          ),
        ],
        if (controller.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            controller.errorMessage!,
            key: const Key('memora-user-pasatiempos-error'),
            style: textTheme.bodyMedium?.copyWith(
              color: MemoraTheme.highContrastInk,
              fontSize: MemoraSupportedPersonTypography.secondary,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (controller.pastimes.isEmpty && !controller.sharedPullFailed)
          Text(
            MemoraCopy.pasatiemposBody,
            key: const Key('memora-user-pasatiempos-empty'),
            style: textTheme.bodyLarge?.copyWith(
              color: MemoraTheme.highContrastInk,
              fontSize: MemoraSupportedPersonTypography.body,
              height: MemoraSupportedPersonTypography.bodyHeight,
            ),
          )
        else if (controller.pastimes.isNotEmpty)
          ...controller.pastimes.map(
            (pastime) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PastimeCard(pastime: pastime, controller: controller),
            ),
          ),
      ],
    );
  }
}

class _PastimeCard extends StatelessWidget {
  const _PastimeCard({required this.pastime, required this.controller});

  final Pastime pastime;
  final UserPastimeController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${pastime.title}. ${MemoraCopy.pasatiemposOpenHint}',
      child: Material(
        color: Colors.white,
        child: InkWell(
          key: Key('memora-user-pastime-${pastime.id.value}'),
          onTap: () => controller.openDetail(pastime.id),
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
                      pastime.title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: MemoraSupportedPersonTypography.title,
                        color: MemoraTheme.highContrastInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      MemoraCopy.pasatiemposOpenHint,
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: MemoraSupportedPersonTypography.secondary,
                        fontWeight: FontWeight.w600,
                        height: MemoraSupportedPersonTypography.bodyHeight,
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

class _GuidedDetail extends StatelessWidget {
  const _GuidedDetail({required this.pastime, required this.controller});

  final Pastime pastime;
  final UserPastimeController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: Key('memora-user-pastime-detail-${pastime.id.value}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const Key('memora-user-pasatiempos-back'),
            onPressed: controller.returnToList,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
            ),
            child: const Text(MemoraCopy.pasatiemposBackToList),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          pastime.title,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: MemoraTheme.highContrastInk,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          pastime.instruction,
          style: textTheme.bodyLarge?.copyWith(
            color: MemoraTheme.highContrastInk,
            fontSize: MemoraSupportedPersonTypography.body,
            height: MemoraSupportedPersonTypography.bodyHeight,
          ),
        ),
      ],
    );
  }
}

class _PastimeIntro extends StatelessWidget {
  const _PastimeIntro({required this.controller});

  final UserPastimeController controller;

  @override
  Widget build(BuildContext context) {
    final pastime = controller.selectedPastime;
    if (pastime == null) {
      return const SizedBox.shrink();
    }
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: Key('memora-user-pastime-intro-${pastime.id.value}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const Key('memora-user-pasatiempos-back'),
            onPressed: controller.returnToList,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
            ),
            child: const Text(MemoraCopy.pasatiemposBackToList),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          pastime.title,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: MemoraTheme.highContrastInk,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          pastime.instruction,
          style: textTheme.bodyLarge?.copyWith(
            color: MemoraTheme.highContrastInk,
            fontSize: MemoraSupportedPersonTypography.body,
            height: MemoraSupportedPersonTypography.bodyHeight,
          ),
        ),
        if (controller.boardGuidance != null) ...[
          const SizedBox(height: 12),
          Text(
            controller.boardGuidance!,
            style: textTheme.bodyLarge?.copyWith(
              fontSize: MemoraSupportedPersonTypography.secondary,
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('memora-user-pastime-start'),
          onPressed: controller.startFresh,
          style: FilledButton.styleFrom(
            minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
          ),
          child: const Text(MemoraCopy.pasatiemposStart),
        ),
      ],
    );
  }
}

class _RecoveryOffer extends StatelessWidget {
  const _RecoveryOffer({required this.controller});

  final UserPastimeController controller;

  @override
  Widget build(BuildContext context) {
    final pastime = controller.selectedPastime;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: const Key('memora-user-pastime-recovery'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const Key('memora-user-pasatiempos-back'),
            onPressed: controller.returnToList,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
            ),
            child: const Text(MemoraCopy.pasatiemposBackToList),
          ),
        ),
        const SizedBox(height: 20),
        if (pastime != null) ...[
          Text(
            pastime.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: MemoraTheme.highContrastInk,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          MemoraCopy.pasatiemposRecoveryBody,
          style: textTheme.bodyLarge?.copyWith(
            fontSize: MemoraSupportedPersonTypography.body,
            height: MemoraSupportedPersonTypography.bodyHeight,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('memora-user-pastime-continue'),
          onPressed: controller.continueRecovery,
          style: FilledButton.styleFrom(
            minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
          ),
          child: const Text(MemoraCopy.pasatiemposContinue),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('memora-user-pastime-start-over'),
          onPressed: controller.discardRecoveryAndStart,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(120, MemoraTheme.preferredTouchExtent),
          ),
          child: const Text(MemoraCopy.pasatiemposStartOver),
        ),
      ],
    );
  }
}
