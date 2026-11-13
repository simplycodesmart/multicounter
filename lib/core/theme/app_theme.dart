import 'package:flutter/material.dart';

enum ColorBlindMode {
  none,
  protanopiaDeuteranopia, // Red-Green safe
  tritanopia,             // Blue-Yellow safe
  highContrast;           // High contrast 7:1

  String get label {
    switch (this) {
      case ColorBlindMode.none:
        return 'Standard (Full Spectrum)';
      case ColorBlindMode.protanopiaDeuteranopia:
        return 'Red-Green Safe (Protan/Deutan)';
      case ColorBlindMode.tritanopia:
        return 'Blue-Yellow Safe (Tritan)';
      case ColorBlindMode.highContrast:
        return 'High Contrast (WCAG AAA 7:1)';
    }
  }

  String get description {
    switch (this) {
      case ColorBlindMode.none:
        return 'Vibrant standard color palette';
      case ColorBlindMode.protanopiaDeuteranopia:
        return 'Replaces red/green with high-contrast blues, cyans, and ambers';
      case ColorBlindMode.tritanopia:
        return 'Replaces blue/yellow with distinct magentas, teals, and corals';
      case ColorBlindMode.highContrast:
        return 'Stark white & pure black with maximum legible borders';
    }
  }
}

class AppTheme {
  static const Color accentGold = Color(0xFFFFD400);
  static const Color background = Color(0xFF090909);
  static const Color surface = Color(0xFF171717);
  static const Color surfaceElevated = Color(0xFF202020);

  static const List<Color> accentColors = [
    Color(0xFFFFD400), // Gold
    Color(0xFF00E5FF), // Cyan
    Color(0xFF00E676), // Emerald
    Color(0xFFFF6B6B), // Coral
    Color(0xFF8B5CF6), // Violet
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFFFF70A6), // Pink
  ];

  static const List<Color> protanDeutanColors = [
    Color(0xFFFFD400), // Gold
    Color(0xFF00E5FF), // Cyan
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFFFFA000), // Amber
    Color(0xFF8B5CF6), // Violet
    Color(0xFFFFFFFF), // High White
  ];

  static const List<Color> tritanColors = [
    Color(0xFFFF6B6B), // Coral
    Color(0xFFFF70A6), // Pink/Magenta
    Color(0xFF00E676), // Emerald Mint
    Color(0xFF45D6C5), // Teal
    Color(0xFFFFA000), // Amber
    Color(0xFFFFFFFF), // High White
  ];

  static const List<Color> highContrastColors = [
    Color(0xFFFFFFFF), // White
    Color(0xFFFFD400), // Vivid Gold
    Color(0xFF00FFFF), // Electric Cyan
    Color(0xFFFF5252), // Bright Red
  ];

  static List<Color> getColorsForMode(ColorBlindMode mode) {
    switch (mode) {
      case ColorBlindMode.protanopiaDeuteranopia:
        return protanDeutanColors;
      case ColorBlindMode.tritanopia:
        return tritanColors;
      case ColorBlindMode.highContrast:
        return highContrastColors;
      case ColorBlindMode.none:
        return accentColors;
    }
  }

  static ThemeData dark({
    Color accent = accentGold,
    ColorBlindMode mode = ColorBlindMode.none,
  }) {
    final effectiveAccent = mode == ColorBlindMode.highContrast
        ? Colors.white
        : accent;
    final isHighContrast = mode == ColorBlindMode.highContrast;
    final activeBg = isHighContrast ? Colors.black : background;
    final activeSurface = isHighContrast ? const Color(0xFF0D0D0D) : surface;
    final cardBorder = isHighContrast
        ? const BorderSide(color: Colors.white, width: 2.0)
        : const BorderSide(color: Color(0xFF292929));

    final scheme = ColorScheme.dark(
      primary: effectiveAccent,
      onPrimary: const Color(0xFF111111),
      secondary: effectiveAccent.withValues(alpha: 0.8),
      onSecondary: const Color(0xFF111111),
      surface: activeSurface,
      onSurface: const Color(0xFFF5F5F5),
      error: const Color(0xFFFF6B6B),
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: activeBg,
      appBarTheme: AppBarTheme(
        backgroundColor: activeBg,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: activeSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: cardBorder,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: activeSurface,
        indicatorColor: effectiveAccent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? effectiveAccent : Colors.white70,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? const Color(0xFF111111) : Colors.white70,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: effectiveAccent,
        foregroundColor: const Color(0xFF111111),
        elevation: 2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: effectiveAccent,
          foregroundColor: const Color(0xFF111111),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: effectiveAccent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isHighContrast ? const Color(0xFF1A1A1A) : surfaceElevated,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: effectiveAccent,
            width: isHighContrast ? 2.5 : 1.5,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: isHighContrast
              ? const BorderSide(color: Colors.white38, width: 1.5)
              : BorderSide.none,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: effectiveAccent),
      chipTheme: ChipThemeData(
        selectedColor: effectiveAccent.withValues(alpha: 0.18),
        side: cardBorder,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData light({
    Color accent = const Color(0xFFE6B800),
    ColorBlindMode mode = ColorBlindMode.none,
  }) {
    final effectiveAccent = mode == ColorBlindMode.highContrast
        ? Colors.black
        : accent;
    final isHighContrast = mode == ColorBlindMode.highContrast;
    const lightSurface = Color(0xFFFFFFFF);
    const lightBackground = Color(0xFFF7F8FA);
    const lightElevated = Color(0xFFECEFF3);
    final cardBorder = isHighContrast
        ? const BorderSide(color: Colors.black, width: 2.0)
        : const BorderSide(color: Color(0xFFE2E4E8));

    final scheme = ColorScheme.light(
      primary: effectiveAccent,
      onPrimary: Colors.white,
      secondary: effectiveAccent.withValues(alpha: 0.85),
      onSecondary: Colors.white,
      surface: lightSurface,
      onSurface: const Color(0xFF1C1C1E),
      error: const Color(0xFFDC2626),
    );

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: Color(0xFF1C1C1E),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: cardBorder,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: accent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? accent : const Color(0xFF6B7280),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? Colors.white : const Color(0xFF6B7280),
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightElevated,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      chipTheme: ChipThemeData(
        selectedColor: accent.withValues(alpha: 0.18),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
