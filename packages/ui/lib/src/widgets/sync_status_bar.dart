import 'package:flutter/material.dart';

import '../theme/memora_theme.dart';

/// Live-region sync / recovery chrome with large touch target.
class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar({
    super.key,
    required this.label,
    this.actionLabel,
    this.onAction,
  });

  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      container: true,
      label: label,
      child: Container(
        key: const Key('memora-sync-status'),
        constraints: const BoxConstraints(
          minHeight: MemoraTheme.minTouchExtent,
        ),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: MemoraTheme.borderInk, width: 2),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: textTheme.bodyLarge?.copyWith(
                color: MemoraTheme.highContrastInk,
                fontSize: 18,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('memora-sync-recovery-action'),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
