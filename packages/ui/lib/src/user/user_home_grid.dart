import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import 'user_home_destination.dart';

/// Fixed two-by-two home choices plus a central tap-gated `Ayúdame` control.
///
/// Tile order and positions never depend on sync, content or network status.
class UserHomeGrid extends StatelessWidget {
  const UserHomeGrid({
    super.key,
    required this.orientationLabel,
    required this.onSelect,
    this.onAyudame,
  });

  final String orientationLabel;
  final ValueChanged<UserHomeDestination> onSelect;

  /// Central help control. When null, the control is hidden (tests only).
  final VoidCallback? onAyudame;

  static const double _gap = 16;
  static const double _minTileExtent = 96;
  static const double _ayudameExtent = 88;
  static const double _ayudameMinExtent = 56;

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
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
                                tileKey: const Key(
                                  'memora-user-home-tile-mi-dia',
                                ),
                                onSelect: onSelect,
                                contentBias: _TileContentBias.topLeft,
                              ),
                            ),
                            const SizedBox(width: _gap),
                            Expanded(
                              child: _HomeTile(
                                destination: UserHomeDestination.pasatiempos,
                                label: MemoraCopy.homeTilePasatiempos,
                                icon: Icons.extension_outlined,
                                tileKey: const Key(
                                  'memora-user-home-tile-pasatiempos',
                                ),
                                onSelect: onSelect,
                                contentBias: _TileContentBias.topRight,
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
                                contentBias: _TileContentBias.bottomLeft,
                              ),
                            ),
                            const SizedBox(width: _gap),
                            Expanded(
                              child: _HomeTile(
                                destination: UserHomeDestination.recuerdos,
                                label: MemoraCopy.homeTileRecuerdos,
                                icon: Icons.photo_album_outlined,
                                tileKey: const Key(
                                  'memora-user-home-tile-recuerdos',
                                ),
                                onSelect: onSelect,
                                contentBias: _TileContentBias.bottomRight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (onAyudame != null)
                    Center(
                      child: _AyudameControl(
                        onPressed: onAyudame!,
                        maxExtent: constraints.biggest.shortestSide * 0.28,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

enum _TileContentBias { topLeft, topRight, bottomLeft, bottomRight }

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.destination,
    required this.label,
    required this.icon,
    required this.tileKey,
    required this.onSelect,
    required this.contentBias,
  });

  final UserHomeDestination destination;
  final String label;
  final IconData icon;
  final Key tileKey;
  final ValueChanged<UserHomeDestination> onSelect;
  final _TileContentBias contentBias;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Bias icon+label away from the centre so `Ayúdame` never covers tile text.
    final edge = switch (contentBias) {
      _TileContentBias.topLeft => const EdgeInsets.only(right: 28, bottom: 28),
      _TileContentBias.topRight => const EdgeInsets.only(left: 28, bottom: 28),
      _TileContentBias.bottomLeft => const EdgeInsets.only(right: 28, top: 28),
      _TileContentBias.bottomRight => const EdgeInsets.only(left: 28, top: 28),
    };

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
              padding: const EdgeInsets.all(12).add(edge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 44, color: MemoraTheme.accentOnBand),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: MemoraTheme.accentOnBand,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
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

class _AyudameControl extends StatelessWidget {
  const _AyudameControl({required this.onPressed, required this.maxExtent});

  final VoidCallback onPressed;
  final double maxExtent;

  @override
  Widget build(BuildContext context) {
    final extent = maxExtent
        .clamp(UserHomeGrid._ayudameMinExtent, UserHomeGrid._ayudameExtent)
        .toDouble();
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      enabled: true,
      label: MemoraCopy.homeAyudameSemantics,
      excludeSemantics: true,
      child: Material(
        color: MemoraTheme.highContrastInk,
        shape: const CircleBorder(
          side: BorderSide(color: MemoraTheme.accentOnBand, width: 3),
        ),
        elevation: 4,
        shadowColor: Colors.black54,
        child: InkWell(
          key: const Key('memora-user-home-ayudame'),
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: extent,
            height: extent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic_none,
                  size: extent * 0.34,
                  color: MemoraTheme.accentOnBand,
                ),
                const SizedBox(height: 2),
                Text(
                  MemoraCopy.homeAyudameLabel,
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(
                    color: MemoraTheme.accentOnBand,
                    fontWeight: FontWeight.w800,
                    fontSize: extent < 72 ? 11 : 13,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
