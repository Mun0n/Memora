import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import 'feature_section.dart';

/// Large-target section switcher for Slice 5 surfaces.
class FeatureSectionNav extends StatelessWidget {
  const FeatureSectionNav({
    super.key,
    required this.sections,
    required this.selected,
    required this.onSelected,
  });

  final List<FeatureSection> sections;
  final FeatureSection selected;
  final ValueChanged<FeatureSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final section in sections)
          _NavChip(
            section: section,
            selected: section == selected,
            onTap: () => onSelected(section),
          ),
      ],
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final FeatureSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (section) {
      FeatureSection.routines => MemoraCopy.navRoutines,
      FeatureSection.memories => MemoraCopy.navMemories,
      FeatureSection.observations => MemoraCopy.navObservations,
      FeatureSection.help => MemoraCopy.navHelp,
    };
    final keyName = switch (section) {
      FeatureSection.routines => 'memora-nav-routines',
      FeatureSection.memories => 'memora-nav-memories',
      FeatureSection.observations => 'memora-nav-observations',
      FeatureSection.help => 'memora-nav-help',
    };
    return OutlinedButton(
      key: Key(keyName),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? MemoraTheme.accentBand : Colors.white,
        foregroundColor: selected
            ? MemoraTheme.accentOnBand
            : MemoraTheme.highContrastInk,
        side: const BorderSide(color: MemoraTheme.borderInk, width: 2),
        minimumSize: const Size(
          MemoraTheme.minTouchExtent,
          MemoraTheme.preferredTouchExtent,
        ),
      ),
      child: Text(label),
    );
  }
}
