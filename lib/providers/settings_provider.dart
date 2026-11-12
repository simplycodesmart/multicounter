import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../models/counter_model.dart';

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.accentColor = AppTheme.accentGold,
    this.hapticFeedback = true,
    this.defaultCounterType = CounterType.countdown,
    this.colorBlindMode = ColorBlindMode.none,
    this.deafHapticAlert = true,
  });

  final ThemeMode themeMode;
  final Color accentColor;
  final bool hapticFeedback;
  final CounterType defaultCounterType;
  final ColorBlindMode colorBlindMode;
  final bool deafHapticAlert;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    bool? hapticFeedback,
    CounterType? defaultCounterType,
    ColorBlindMode? colorBlindMode,
    bool? deafHapticAlert,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      defaultCounterType: defaultCounterType ?? this.defaultCounterType,
      colorBlindMode: colorBlindMode ?? this.colorBlindMode,
      deafHapticAlert: deafHapticAlert ?? this.deafHapticAlert,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _keyThemeMode = 'multicounter.settings.theme_mode';
  static const _keyAccentColor = 'multicounter.settings.accent_color';
  static const _keyHaptic = 'multicounter.settings.haptic';
  static const _keyDefaultType = 'multicounter.settings.default_type';
  static const _keyColorBlindMode = 'multicounter.settings.color_blind';
  static const _keyDeafHaptic = 'multicounter.settings.deaf_haptic';

  @override
  SettingsState build() {
    _loadSettings();
    return const SettingsState();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeStr = prefs.getString(_keyThemeMode);
    final themeMode = themeStr == 'light'
        ? ThemeMode.light
        : themeStr == 'system'
            ? ThemeMode.system
            : ThemeMode.dark;

    final accentVal = prefs.getInt(_keyAccentColor);
    final accentColor = accentVal != null ? Color(accentVal) : AppTheme.accentGold;

    final haptic = prefs.getBool(_keyHaptic) ?? true;
    final deafHaptic = prefs.getBool(_keyDeafHaptic) ?? true;

    final colorBlindStr = prefs.getString(_keyColorBlindMode);
    final colorBlindMode = ColorBlindMode.values.firstWhere(
      (e) => e.name == colorBlindStr,
      orElse: () => ColorBlindMode.none,
    );

    final typeStr = prefs.getString(_keyDefaultType);
    final defaultType = CounterType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => CounterType.countdown,
    );

    state = SettingsState(
      themeMode: themeMode,
      accentColor: accentColor,
      hapticFeedback: haptic,
      defaultCounterType: defaultType,
      colorBlindMode: colorBlindMode,
      deafHapticAlert: deafHaptic,
    );
  }

  Future<void> setColorBlindMode(ColorBlindMode mode) async {
    state = state.copyWith(colorBlindMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyColorBlindMode, mode.name);
  }

  Future<void> setDeafHapticAlert(bool enabled) async {
    state = state.copyWith(deafHapticAlert: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDeafHaptic, enabled);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyThemeMode,
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.system
              ? 'system'
              : 'dark',
    );
  }

  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccentColor, color.toARGB32());
  }

  Future<void> setHapticFeedback(bool enabled) async {
    state = state.copyWith(hapticFeedback: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHaptic, enabled);
  }

  Future<void> setDefaultCounterType(CounterType type) async {
    state = state.copyWith(defaultCounterType: type);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultType, type.name);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
