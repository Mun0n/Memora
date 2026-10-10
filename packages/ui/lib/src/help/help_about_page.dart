import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';

/// Shared Help/About surface with the non-medical / non-emergency notice.
class HelpAboutPage extends StatelessWidget {
  const HelpAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          MemoraCopy.helpAboutTitle,
          key: const Key('memora-help-title'),
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: MemoraTheme.highContrastInk,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          MemoraCopy.helpAboutBody,
          style: textTheme.bodyLarge?.copyWith(fontSize: 17),
        ),
        const SizedBox(height: 16),
        Text(
          MemoraCopy.helpAboutDisclaimer,
          key: const Key('memora-help-disclaimer'),
          style: textTheme.bodyLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: MemoraTheme.highContrastInk,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          MemoraCopy.notMedical,
          style: textTheme.bodyLarge?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          MemoraCopy.noRealData,
          style: textTheme.bodyMedium?.copyWith(fontSize: 16),
        ),
      ],
    );
  }
}
