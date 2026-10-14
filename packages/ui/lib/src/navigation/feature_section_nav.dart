import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import 'feature_section.dart';

/// Large-target section switcher for caregiver/family web surfaces.
///
/// Primary product destinations stay on one calm row (horizontal scroll on
/// compact widths). Sync / privacy / help remain in a secondary row.
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

  static const Set<FeatureSection> secondarySections = {
    FeatureSection.sync,
    FeatureSection.privacy,
    FeatureSection.help,
  };

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < MemoraTheme.expandedBreakpoint;
    final primary = sections
        .where((section) => !secondarySections.contains(section))
        .toList(growable: false);
    final secondary = sections
        .where(secondarySections.contains)
        .toList(growable: false);

    return Column(
      key: const Key('memora-feature-section-nav'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: MemoraCopy.navPrimarySemantics,
          child: _NavRow(
            rowKey: const Key('memora-nav-primary'),
            sections: primary,
            selected: selected,
            onSelected: onSelected,
            scrollHorizontally: compact,
          ),
        ),
        if (secondary.isNotEmpty) ...[
          const SizedBox(height: 12),
          Semantics(
            label: MemoraCopy.navSecondarySemantics,
            child: _NavRow(
              rowKey: const Key('memora-nav-secondary'),
              sections: secondary,
              selected: selected,
              onSelected: onSelected,
              scrollHorizontally: compact,
            ),
          ),
        ],
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.rowKey,
    required this.sections,
    required this.selected,
    required this.onSelected,
    required this.scrollHorizontally,
  });

  final Key rowKey;
  final List<FeatureSection> sections;
  final FeatureSection selected;
  final ValueChanged<FeatureSection> onSelected;
  final bool scrollHorizontally;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final section in sections)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _NavChip(
            section: section,
            selected: section == selected,
            onTap: () => onSelected(section),
          ),
        ),
    ];

    if (!scrollHorizontally) {
      return Wrap(
        key: rowKey,
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

    // Row + horizontal scroll keeps every chip mounted (unlike ListView lazy
    // build) so Persona apoyada / Ayuda remain findable and operable.
    return SingleChildScrollView(
      key: rowKey,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(height: MemoraTheme.preferredTouchExtent),
          ...chips,
        ],
      ),
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
      FeatureSection.pastimes => MemoraCopy.navPastimes,
      FeatureSection.conversations => MemoraCopy.navConversations,
      FeatureSection.memories => MemoraCopy.navMemories,
      FeatureSection.observations => MemoraCopy.navObservations,
      FeatureSection.supportedPersonProfile =>
        MemoraCopy.navSupportedPersonProfile,
      FeatureSection.sync => MemoraCopy.navSync,
      FeatureSection.privacy => MemoraCopy.navPrivacy,
      FeatureSection.help => MemoraCopy.navHelp,
    };
    final keyName = switch (section) {
      FeatureSection.routines => 'memora-nav-routines',
      FeatureSection.pastimes => 'memora-nav-pastimes',
      FeatureSection.conversations => 'memora-nav-conversations',
      FeatureSection.memories => 'memora-nav-memories',
      FeatureSection.observations => 'memora-nav-observations',
      FeatureSection.supportedPersonProfile =>
        'memora-nav-supported-person-profile',
      FeatureSection.sync => 'memora-nav-sync',
      FeatureSection.privacy => 'memora-nav-privacy',
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
