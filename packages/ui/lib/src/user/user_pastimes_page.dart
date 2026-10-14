import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../demo/demo_data_scope.dart';
import '../l10n/memora_copy.dart';
import '../theme/memora_supported_person_typography.dart';
import '../theme/memora_theme.dart';
import 'user_pastime_controller.dart';

/// Supported-person Pasatiempos: active cards → calm detail (title + instruction).
///
/// No draft/archived exposure, sync jargon, caregiver controls or completion claim.
class UserPastimesPage extends StatelessWidget {
  const UserPastimesPage({super.key, required this.controller});

  final UserPastimeController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selected = controller.selectedPastime;
        if (selected != null) {
          return _PastimeDetail(pastime: selected, controller: controller);
        }
        return _PastimeList(controller: controller);
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

class _PastimeDetail extends StatelessWidget {
  const _PastimeDetail({required this.pastime, required this.controller});

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
