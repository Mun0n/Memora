import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';

/// Unmistakable Demo/Ejemplo non-production banner.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: MemoraCopy.demoBannerSemantics,
      child: Container(
        key: const Key('memora-demo-banner'),
        constraints: const BoxConstraints(
          minHeight: MemoraTheme.minTouchExtent,
        ),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: MemoraTheme.accentBand,
        child: Text(
          MemoraCopy.demoBanner,
          style: textTheme.titleMedium?.copyWith(
            color: MemoraTheme.accentOnBand,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
