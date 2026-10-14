import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import 'user_home_destination.dart';

/// Fixed two-by-two home choices plus a central tap-gated `Ayúdame` control.
///
/// Tile order and positions never depend on sync, content or network status.
/// The centre control reserves a circular hit region so tile taps never claim
/// that area (geometry, not paint-order alone).
class UserHomeGrid extends StatelessWidget {
  const UserHomeGrid({
    super.key,
    required this.orientationLabel,
    required this.onSelect,
    this.greeting = MemoraCopy.userHomeGreeting,
    this.onAyudame,
  });

  /// Safe greeting already resolved by the host (`Hola` or `Hola, <name>`).
  final String greeting;
  final String orientationLabel;
  final ValueChanged<UserHomeDestination> onSelect;

  /// Central help control. When null, the control is hidden (tests only).
  final VoidCallback? onAyudame;

  static const double _gap = 16;
  static const double _minTileExtent = 96;

  /// Required phone layout minimum diameter (Slice 12 AC7).
  static const double ayudameMinExtent = 104;
  static const double _ayudameMaxExtent = 140;

  /// Exposed for geometry / golden tests.
  static double resolveAyudameExtent(Size constraintsSize) {
    final candidate = constraintsSize.shortestSide * 0.30;
    return candidate.clamp(ayudameMinExtent, _ayudameMaxExtent).toDouble();
  }

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
          greeting,
          key: const Key('memora-user-home-greeting'),
          softWrap: true,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.headlineSmall?.copyWith(
            color: MemoraTheme.highContrastInk,
            fontWeight: FontWeight.w700,
            fontSize: isExpanded ? 28 : 24,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Semantics(
          header: true,
          child: Text(
            orientationLabel,
            key: const Key('memora-user-orientation'),
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
              final ayudameExtent = resolveAyudameExtent(constraints.biggest);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _ExcludeCentreCircle(
                    diameter: ayudameExtent,
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
                                  tileKey: const Key(
                                    'memora-user-home-tile-mi-dia',
                                  ),
                                  onSelect: onSelect,
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
                                  tileKey: const Key(
                                    'memora-user-home-tile-recuerdos',
                                  ),
                                  onSelect: onSelect,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onAyudame != null)
                    Center(
                      child: _AyudameControl(
                        onPressed: onAyudame!,
                        extent: ayudameExtent,
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
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, size: 44, color: MemoraTheme.accentOnBand),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    softWrap: true,
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
  const _AyudameControl({required this.onPressed, required this.extent});

  final VoidCallback onPressed;
  final double extent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final iconSize = (extent * 0.30).clamp(28.0, 44.0);
    final fontSize = extent < 112 ? 12.0 : 14.0;
    final pad = (extent * 0.08).clamp(6.0, 12.0);

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
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic_none,
                    size: iconSize,
                    color: MemoraTheme.accentOnBand,
                  ),
                  SizedBox(height: pad * 0.35),
                  Text(
                    MemoraCopy.homeAyudameLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: textTheme.labelLarge?.copyWith(
                      color: MemoraTheme.accentOnBand,
                      fontWeight: FontWeight.w800,
                      fontSize: fontSize,
                      height: 1.05,
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

/// Rejects pointer/semantic hits that fall inside the centred reserved circle.
class _ExcludeCentreCircle extends SingleChildRenderObjectWidget {
  const _ExcludeCentreCircle({required this.diameter, required Widget child})
    : super(child: child);

  final double diameter;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderExcludeCentreCircle(diameter: diameter);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderExcludeCentreCircle renderObject,
  ) {
    renderObject.diameter = diameter;
  }
}

class _RenderExcludeCentreCircle extends RenderProxyBox {
  _RenderExcludeCentreCircle({required double diameter}) : _diameter = diameter;

  double _diameter;
  double get diameter => _diameter;
  set diameter(double value) {
    if (_diameter == value) {
      return;
    }
    _diameter = value;
    markNeedsPaint();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final centre = size.center(Offset.zero);
    final radius = _diameter / 2;
    if ((position - centre).distance <= radius) {
      return false;
    }
    return super.hitTest(result, position: position);
  }
}
