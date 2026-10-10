import 'package:flutter/material.dart';

/// High-contrast, large-target theme shared by user and family-web shells.
abstract final class MemoraTheme {
  static const Color highContrastInk = Color(0xFF121212);
  static const Color highContrastSurface = Color(0xFFF7F7F2);
  static const Color accentBand = Color(0xFF1F4B3A);
  static const Color accentOnBand = Colors.white;
  static const Color borderInk = Color(0xFF121212);
  static const double minTouchExtent = 48;
  static const double preferredTouchExtent = 56;
  static const double expandedContentMaxWidth = 720;
  static const double expandedBreakpoint = 600;

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: accentBand,
        onPrimary: accentOnBand,
        surface: highContrastSurface,
        onSurface: highContrastInk,
        error: Color(0xFF8B1E1E),
        onError: Colors.white,
      ),
      textTheme: Typography.material2021().black.apply(
        bodyColor: highContrastInk,
        displayColor: highContrastInk,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(minTouchExtent, preferredTouchExtent),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minTouchExtent, preferredTouchExtent),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          side: const BorderSide(color: borderInk, width: 2),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: borderInk, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderInk, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accentBand, width: 2.5),
        ),
      ),
    );
  }
}
