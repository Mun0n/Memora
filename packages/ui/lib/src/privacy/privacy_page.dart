import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import 'privacy_presentation_controller.dart';

/// Export / deletion / session-management contract surface (demo only).
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key, required this.controller});

  final PrivacyPresentationController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final active = controller.sessions.where((s) => s.isActive).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              MemoraCopy.privacySectionBody,
              key: const Key('memora-privacy-body'),
              style: textTheme.bodyLarge?.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('memora-privacy-export'),
              onPressed: controller.busy ? null : controller.requestExport,
              child: Text(MemoraCopy.privacyExportAction),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('memora-privacy-deletion'),
              onPressed: controller.busy ? null : controller.requestDeletion,
              child: Text(MemoraCopy.privacyDeletionAction),
            ),
            if (controller.statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                controller.statusMessage!,
                key: const Key('memora-privacy-status'),
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                controller.errorMessage!,
                key: const Key('memora-privacy-error'),
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              MemoraCopy.privacySessionsTitle,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: MemoraTheme.highContrastInk,
              ),
            ),
            const SizedBox(height: 8),
            if (active.isEmpty)
              Text(
                MemoraCopy.privacySessionsEmpty,
                key: const Key('memora-privacy-sessions-empty'),
                style: textTheme.bodyLarge?.copyWith(fontSize: 17),
              )
            else
              for (final session in active) ...[
                Text(
                  session.label,
                  key: Key('memora-privacy-session-${session.id}'),
                  style: textTheme.bodyLarge?.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: Key('memora-privacy-revoke-${session.id}'),
                  onPressed: controller.busy
                      ? null
                      : () => controller.revokeSession(session.id),
                  child: Text(MemoraCopy.privacyRevokeSession),
                ),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}
