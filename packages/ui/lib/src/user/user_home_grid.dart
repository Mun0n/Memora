import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_supported_person_typography.dart';
import '../theme/memora_theme.dart';
import 'user_home_destination.dart';

/// Fixed two-by-two home choices plus a central tap-gated `Ayúdame` control.
///
/// Tile order and positions never depend on sync, content or network status.
/// The centre control reserves a circular hit region so tile taps never claim
/// that area (geometry, not paint-order alone).
///
/// Reading order: greeting → invitation → orientation → five actions.
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
  ///
  /// Grows slightly with text scale so the ≥16 sp label still fits inside the
  /// circle without shrinking below the Slice 13 minimum.
  static double resolveAyudameExtent(
    Size constraintsSize, {
    double textScale = 1.0,
  }) {
    final candidate = constraintsSize.shortestSide * 0.30;
    final boostedMin = (ayudameMinExtent * (1 + (textScale - 1.0) * 0.4)).clamp(
      ayudameMinExtent,
      _ayudameMaxExtent,
    );
    final extent = candidate < boostedMin ? boostedMin : candidate;
    return extent.clamp(ayudameMinExtent, _ayudameMaxExtent).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final isExpanded = size.width >= MemoraTheme.expandedBreakpoint;
    final tightHeight = size.height < 820 || textScale >= 1.3;
    final veryTight = size.height < 820 && textScale >= 1.4;

    final afterGreetingGap = veryTight ? 1.0 : (tightHeight ? 3.0 : 6.0);
    final afterInvitationGap = veryTight ? 1.0 : (tightHeight ? 3.0 : 6.0);
    final beforeGridGap = isExpanded
        ? (textScale >= 1.4 ? 12.0 : 20.0)
        : (veryTight ? 4.0 : (tightHeight ? 6.0 : 12.0));
    final tileGap = textScale >= 1.3 ? 8.0 : (tightHeight ? 10.0 : _gap);

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
          style: textTheme.headlineSmall?.copyWith(
            color: MemoraTheme.highContrastInk,
            fontWeight: FontWeight.w700,
            fontSize: MemoraSupportedPersonTypography.heading,
            height: 1.2,
          ),
        ),
        SizedBox(height: afterGreetingGap),
        Semantics(
          label: MemoraCopy.userHomeInvitation,
          child: Text(
            MemoraCopy.userHomeInvitation,
            key: const Key('memora-user-home-invitation'),
            softWrap: true,
            style: textTheme.bodyLarge?.copyWith(
              color: MemoraTheme.highContrastInk,
              // Invitation is supporting orientation copy (≥18 sp secondary).
              fontSize: MemoraSupportedPersonTypography.secondary,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
        SizedBox(height: afterInvitationGap),
        Text(
          orientationLabel,
          key: const Key('memora-user-orientation'),
          softWrap: true,
          style: textTheme.titleMedium?.copyWith(
            color: MemoraTheme.highContrastInk,
            fontSize: MemoraSupportedPersonTypography.secondary,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        SizedBox(height: beforeGridGap),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ayudameExtent = resolveAyudameExtent(
                constraints.biggest,
                textScale: textScale,
              );
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
                                  compact: tightHeight,
                                ),
                              ),
                              SizedBox(width: tileGap),
                              Expanded(
                                child: _HomeTile(
                                  destination: UserHomeDestination.pasatiempos,
                                  label: MemoraCopy.homeTilePasatiempos,
                                  icon: Icons.extension_outlined,
                                  tileKey: const Key(
                                    'memora-user-home-tile-pasatiempos',
                                  ),
                                  onSelect: onSelect,
                                  compact: tightHeight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: tileGap),
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
                                  compact: tightHeight,
                                ),
                              ),
                              SizedBox(width: tileGap),
                              Expanded(
                                child: _HomeTile(
                                  destination: UserHomeDestination.recuerdos,
                                  label: MemoraCopy.homeTileRecuerdos,
                                  icon: Icons.photo_album_outlined,
                                  tileKey: const Key(
                                    'memora-user-home-tile-recuerdos',
                                  ),
                                  onSelect: onSelect,
                                  compact: tightHeight,
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
    required this.compact,
  });

  final UserHomeDestination destination;
  final String label;
  final IconData icon;
  final Key tileKey;
  final ValueChanged<UserHomeDestination> onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final pad = textScale >= 1.5 ? 2.0 : (compact ? 4.0 : 12.0);

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
              padding: EdgeInsets.all(pad),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final labelStyle = textTheme.titleLarge?.copyWith(
                    color: MemoraTheme.accentOnBand,
                    fontWeight: FontWeight.w700,
                    fontSize: MemoraSupportedPersonTypography.title,
                    height: 1.15,
                  );
                  // Long Spanish labels (e.g. Quiero hablar) need up to three
                  // lines at 1.5×; drop the icon before shrinking text.
                  // Font metrics exceed fontSize×height slightly — reserve extra.
                  final lineHeight =
                      MemoraSupportedPersonTypography.title * textScale * 1.25;
                  final reservedLabel = lineHeight * 3;
                  final showIcon =
                      textScale < 1.3 &&
                      constraints.maxHeight >= reservedLabel + 48;
                  final iconSize = showIcon
                      ? (constraints.maxHeight - reservedLabel - 8).clamp(
                          28.0,
                          44.0,
                        )
                      : 0.0;
                  final iconGap = showIcon ? 8.0 : 0.0;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (showIcon) ...[
                        Icon(
                          icon,
                          size: iconSize,
                          color: MemoraTheme.accentOnBand,
                        ),
                        SizedBox(height: iconGap),
                      ],
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: labelStyle?.copyWith(
                          height: textScale >= 1.5
                              ? 1.05
                              : (textScale >= 1.3 ? 1.1 : 1.15),
                        ),
                      ),
                    ],
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

class _AyudameControl extends StatelessWidget {
  const _AyudameControl({required this.onPressed, required this.extent});

  final VoidCallback onPressed;
  final double extent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final pad = (extent * 0.06).clamp(4.0, 10.0);
    final labelHeight =
        MemoraSupportedPersonTypography.ayudame * textScale * 1.05;
    final inner = extent - pad * 2;
    final showIcon = textScale < 1.3 && inner > labelHeight + 32;
    final iconSize = showIcon
        ? (inner - labelHeight - 4).clamp(20.0, 40.0)
        : 0.0;

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
                  if (showIcon) ...[
                    Icon(
                      Icons.mic_none,
                      size: iconSize,
                      color: MemoraTheme.accentOnBand,
                    ),
                    SizedBox(height: (pad * 0.2).clamp(2.0, 6.0)),
                  ],
                  Text(
                    MemoraCopy.homeAyudameLabel,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: textTheme.labelSmall?.copyWith(
                      color: MemoraTheme.accentOnBand,
                      fontWeight: FontWeight.w800,
                      fontSize: MemoraSupportedPersonTypography.ayudame,
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
