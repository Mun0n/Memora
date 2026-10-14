import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../experience_target.dart';
import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import 'demo_banner.dart';
import 'sync_status_bar.dart';

/// Chrome density for shared shells.
enum ShellChromeMode {
  /// Slice-1 demonstration markers (legacy / non-production placeholder).
  demonstration,

  /// Product-facing caregiver/family web chrome.
  product,
}

/// Responsive chrome shared by user and family-web feature surfaces.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({
    super.key,
    required this.target,
    required this.persona,
    required this.syncLabel,
    required this.body,
    this.syncActionLabel,
    this.onSyncAction,
    this.chromeMode = ShellChromeMode.demonstration,
    this.sectionTitle,
    this.showSyncStatus = true,
  });

  final ExperienceTarget target;
  final SyntheticPersona persona;
  final String syncLabel;
  final Widget body;
  final String? syncActionLabel;
  final VoidCallback? onSyncAction;
  final ShellChromeMode chromeMode;
  final String? sectionTitle;

  /// When false, the bottom sync bar is omitted (quiet ready/synced state).
  final bool showSyncStatus;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isExpanded = width >= MemoraTheme.expandedBreakpoint;
    final viewportKey = isExpanded
        ? const Key('memora-shell-layout-expanded')
        : const Key('memora-shell-layout-compact');
    final viewportSemantics = isExpanded
        ? 'Expanded shell layout'
        : 'Compact shell layout';
    final horizontalPadding = isExpanded ? 40.0 : 24.0;
    final verticalPadding = isExpanded ? 32.0 : 24.0;
    final textTheme = Theme.of(context).textTheme;
    final product = chromeMode == ShellChromeMode.product;

    return Scaffold(
      backgroundColor: MemoraTheme.highContrastSurface,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isExpanded
                  ? MemoraTheme.expandedContentMaxWidth
                  : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        key: viewportKey,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            label: viewportSemantics,
                            excludeSemantics: true,
                            child: const SizedBox(width: 1, height: 1),
                          ),
                          if (product) ...[
                            Text(
                              MemoraCopy.brandTitle,
                              key: const Key('memora-brand-title'),
                              semanticsLabel: MemoraCopy.familyWebSemantics,
                              style:
                                  (isExpanded
                                          ? textTheme.headlineMedium
                                          : textTheme.headlineSmall)
                                      ?.copyWith(
                                        color: MemoraTheme.highContrastInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                            ),
                            if (sectionTitle != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                sectionTitle!,
                                key: const Key('memora-section-title'),
                                style: textTheme.titleLarge?.copyWith(
                                  color: MemoraTheme.highContrastInk,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isExpanded ? 24 : 22,
                                ),
                              ),
                            ],
                          ] else ...[
                            const DemoBanner(),
                            SizedBox(height: isExpanded ? 28 : 20),
                            Text(
                              'Memora · ${target.englishLabel}',
                              semanticsLabel: target.semanticsLabel,
                              style:
                                  (isExpanded
                                          ? textTheme.headlineMedium
                                          : textTheme.headlineSmall)
                                      ?.copyWith(
                                        color: MemoraTheme.highContrastInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${MemoraCopy.personaPrefix}: ${persona.displayName}',
                              style: textTheme.titleMedium?.copyWith(
                                color: MemoraTheme.highContrastInk,
                                fontSize: isExpanded ? 24 : 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              persona.syntheticMarker,
                              style: textTheme.labelLarge?.copyWith(
                                color: MemoraTheme.highContrastInk,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              MemoraCopy.notMedical,
                              style: textTheme.bodyMedium?.copyWith(
                                color: MemoraTheme.highContrastInk,
                                fontSize: 16,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          body,
                          if (showSyncStatus) ...[
                            const SizedBox(height: 20),
                            SyncStatusBar(
                              label: syncLabel,
                              actionLabel: syncActionLabel,
                              onAction: onSyncAction,
                            ),
                          ],
                          if (!product) ...[
                            const SizedBox(height: 12),
                            Text(
                              MemoraCopy.noRealData,
                              style: textTheme.bodyMedium?.copyWith(
                                color: MemoraTheme.highContrastInk,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
