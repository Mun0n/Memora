import 'package:flutter/material.dart';

import 'memora_theme.dart';

/// Centralized supported-person typography scale (Slice 13).
///
/// Logical sizes are minima at Android text scale 1.0. Device text scaling must
/// remain enabled — never clamp or disable [MediaQuery] / platform scaling.
abstract final class MemoraSupportedPersonTypography {
  /// Secondary / supporting copy.
  static const double secondary = 18;

  /// Primary body copy and button text.
  static const double body = 20;

  /// Home tile labels and list / card titles.
  static const double title = 22;

  /// Greeting and destination page headings.
  static const double heading = 28;

  /// Compact central `Ayúdame` label.
  static const double ayudame = 16;

  /// Comfortable body line height (normally at least 1.25).
  static const double bodyHeight = 1.25;

  /// Text theme mapped onto Material roles for the supported-person shell.
  static TextTheme textTheme() {
    final base = Typography.material2021().black.apply(
      bodyColor: MemoraTheme.highContrastInk,
      displayColor: MemoraTheme.highContrastInk,
    );
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: heading,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: MemoraTheme.highContrastInk,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: heading,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: MemoraTheme.highContrastInk,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: heading,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: MemoraTheme.highContrastInk,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: title,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: MemoraTheme.highContrastInk,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: secondary,
        fontWeight: FontWeight.w600,
        height: bodyHeight,
        color: MemoraTheme.highContrastInk,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: secondary,
        fontWeight: FontWeight.w600,
        height: bodyHeight,
        color: MemoraTheme.highContrastInk,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: body,
        fontWeight: FontWeight.w400,
        height: bodyHeight,
        color: MemoraTheme.highContrastInk,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: secondary,
        fontWeight: FontWeight.w400,
        height: bodyHeight,
        color: MemoraTheme.highContrastInk,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: secondary,
        fontWeight: FontWeight.w400,
        height: bodyHeight,
        color: MemoraTheme.highContrastInk,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: body,
        fontWeight: FontWeight.w700,
        height: bodyHeight,
        color: MemoraTheme.highContrastInk,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: secondary,
        fontWeight: FontWeight.w600,
        height: bodyHeight,
        color: MemoraTheme.highContrastInk,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: ayudame,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: MemoraTheme.highContrastInk,
      ),
    );
  }
}
