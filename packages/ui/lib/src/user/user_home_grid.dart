import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import 'user_home_destination.dart';

/// Fixed two-by-two home choices. Positions never depend on sync or content.
class UserHomeGrid extends StatelessWidget {
  const UserHomeGrid({
    super.key,
    required this.orientationLabel,
    required this.onSelect,
  });

  final String orientationLabel;
  final ValueChanged<UserHomeDestination> onSelect;

  static const double _gap = 16;
  static const double _minTileExtent = 96;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final isExpanded = width >= MemoraTheme.expandedBreakpoint;

    return Column(
      key: const Key('memora-user-home'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: MemoraCopy.homeSemanticsLabel,
          container: true,
          child: const SizedBox(width: 1, height: 1),
        ),
        Text(
          MemoraCopy.userHomeGreeting,
          style: textTheme.headlineSmall?.copyWith(
            color: MemoraTheme.highContrastInk,
            fontWeight: FontWeight.w700,
            fontSize: isExpanded ? 28 : 24,
          ),
        ),
        const SizedBox(height: 4),
        Semantics(
          header: true,
          child: Text(
            orientationLabel,
            key: const Key('memora-user-orientation'),
            style: textTheme.titleMedium?.copyWith(
              color: MemoraTheme.highContrastInk,
              fontSize: isExpanded ? 20 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: isExpanded ? 20 : 12),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _HomeTile(
                        destination: UserHomeDestination.miDia,
                        label: MemoraCopy.homeTileMiDia,
                        icon: Icons.wb_sunny_outlined,
                        tileKey: const Key('memora-user-home-tile-mi-dia'),
                        onSelect: onSelect,
                      ),
                    ),
                    const SizedBox(width: _gap),
                    Expanded(
                      child: _HomeTile(
                        destination: UserHomeDestination.pasatiempos,
                        label: MemoraCopy.homeTilePasatiempos,
                        icon: Icons.extension_outlined,
                        tileKey: const Key('memora-user-home-tile-pasatiempos'),
                        onSelect: onSelect,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _gap),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _HomeTile(
                        destination: UserHomeDestination.quieroHablar,
                        label: MemoraCopy.homeTileQuieroHablar,
                        icon: Icons.chat_bubble_outline,
                        tileKey: const Key(
                          'memora-user-home-tile-quiero-hablar',
                        ),
                        onSelect: onSelect,
                      ),
                    ),
                    const SizedBox(width: _gap),
                    Expanded(
                      child: _HomeTile(
                        destination: UserHomeDestination.recuerdos,
                        label: MemoraCopy.homeTileRecuerdos,
                        icon: Icons.photo_album_outlined,
                        tileKey: const Key('memora-user-home-tile-recuerdos'),
                        onSelect: onSelect,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.destination,
    required this.label,
    required this.icon,
    required this.tileKey,
    required this.onSelect,
  });

  final UserHomeDestination destination;
  final String label;
  final IconData icon;
  final Key tileKey;
  final ValueChanged<UserHomeDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      enabled: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: MemoraTheme.accentBand,
        child: InkWell(
          key: tileKey,
          onTap: () => onSelect(destination),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: UserHomeGrid._minTileExtent,
              minHeight: UserHomeGrid._minTileExtent,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: MemoraTheme.accentOnBand),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: MemoraTheme.accentOnBand,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
