import 'package:flutter/material.dart';

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

  static ThemeData dark({Color accent = accentGold}) {
    final scheme = ColorScheme.dark(
      primary: accent,
      onPrimary: const Color(0xFF111111),
      secondary: accent.withValues(alpha: 0.8),
      onSecondary: const Color(0xFF111111),
      surface: surface,
      onSurface: const Color(0xFFF5F5F5),
      error: const Color(0xFFFF6B6B),
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF292929)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? accent : Colors.white70,
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
        backgroundColor: accent,
        foregroundColor: const Color(0xFF111111),
        elevation: 2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF111111),
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
        fillColor: surfaceElevated,
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
        side: const BorderSide(color: Color(0xFF383838)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData light({Color accent = const Color(0xFFE6B800)}) {
    const lightSurface = Color(0xFFFFFFFF);
    const lightBackground = Color(0xFFF7F8FA);
    const lightElevated = Color(0xFFECEFF3);

    final scheme = ColorScheme.light(
      primary: accent,
      onPrimary: Colors.white,
      secondary: accent.withValues(alpha: 0.85),
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
          side: const BorderSide(color: Color(0xFFE5E7EB)),
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
