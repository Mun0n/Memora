import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import 'sync_presentation_controller.dart';

/// Sync push/pull + conflict recovery surface (Spanish plain language).
class SyncStatusPage extends StatelessWidget {
  const SyncStatusPage({super.key, required this.controller});

  final SyncPresentationController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              MemoraCopy.syncSectionTitle,
              key: const Key('memora-sync-title'),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: MemoraTheme.highContrastInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              MemoraCopy.syncSectionBody,
              style: textTheme.bodyLarge?.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 12),
            Text(
              controller.sessionLabel,
              key: const Key('memora-session-label'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: MemoraTheme.highContrastInk,
              ),
            ),
            if (controller.sessionBoundary.mode ==
                SessionCompositionMode.namedCredentialsConfigured) ...[
              const SizedBox(height: 8),
              Text(
                MemoraCopy.sessionCredentialNamesHint,
                key: const Key('memora-session-credential-names'),
                style: textTheme.bodyMedium?.copyWith(fontSize: 16),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('memora-sync-push'),
              onPressed: controller.busy ? null : controller.push,
              child: Text(MemoraCopy.syncPushAction),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('memora-sync-pull'),
              onPressed: controller.busy ? null : controller.pull,
              child: Text(MemoraCopy.syncPullAction),
            ),
            if (controller.lastPush != null) ...[
              const SizedBox(height: 12),
              Text(
                SyncPresentationController.pushSummaryLabel(
                  controller.lastPush!,
                ),
                key: const Key('memora-sync-push-summary'),
                style: textTheme.bodyLarge?.copyWith(fontSize: 16),
              ),
            ],
            if (controller.lastPull != null) ...[
              const SizedBox(height: 8),
              Text(
                SyncPresentationController.pullSummaryLabel(
                  controller.lastPull!,
                ),
                key: const Key('memora-sync-pull-summary'),
                style: textTheme.bodyLarge?.copyWith(fontSize: 16),
              ),
            ],
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                controller.errorMessage!,
                key: const Key('memora-sync-error'),
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              MemoraCopy.syncConflictsTitle,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: MemoraTheme.highContrastInk,
              ),
            ),
            const SizedBox(height: 8),
            if (controller.unresolved.isEmpty)
              Text(
                MemoraCopy.syncConflictsEmpty,
                key: const Key('memora-sync-conflicts-empty'),
                style: textTheme.bodyLarge?.copyWith(fontSize: 17),
              )
            else
              for (final conflict in controller.unresolved)
                _ConflictCard(
                  conflict: conflict,
                  canResolve: controller.canResolveConflicts,
                  onResolve: (resolution) => controller.resolve(
                    conflictId: conflict.id,
                    resolution: resolution,
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.conflict,
    required this.canResolve,
    required this.onResolve,
  });

  final SyncConflict conflict;
  final bool canResolve;
  final ValueChanged<SyncConflictResolution> onResolve;

  bool get _isObservation =>
      conflict.aggregateType == OutboxAggregateType.weightObservation ||
      conflict.aggregateType == OutboxAggregateType.bloodPressureObservation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      key: Key('memora-sync-conflict-${conflict.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: MemoraTheme.borderInk, width: 2),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            SyncPresentationController.conflictSummary(conflict),
            style: textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_isObservation) ...[
            const SizedBox(height: 8),
            Text(
              MemoraCopy.syncCannotResolveObservations,
              style: textTheme.bodyMedium?.copyWith(fontSize: 16),
            ),
          ],
          if (!canResolve) ...[
            const SizedBox(height: 8),
            Text(
              MemoraCopy.syncResolveUnauthorized,
              style: textTheme.bodyMedium?.copyWith(fontSize: 16),
            ),
          ] else ...[
            const SizedBox(height: 12),
            if (!_isObservation) ...[
              FilledButton(
                key: Key('memora-sync-keep-local-${conflict.id}'),
                onPressed: () => onResolve(SyncConflictResolution.keepLocal),
                child: Text(MemoraCopy.syncResolveKeepLocal),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: Key('memora-sync-keep-remote-${conflict.id}'),
                onPressed: () => onResolve(SyncConflictResolution.keepRemote),
                child: Text(MemoraCopy.syncResolveKeepRemote),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton(
              key: Key('memora-sync-keep-both-${conflict.id}'),
              onPressed: () => onResolve(SyncConflictResolution.keepBoth),
              child: Text(MemoraCopy.syncResolveKeepBoth),
            ),
          ],
        ],
      ),
    );
  }
}
