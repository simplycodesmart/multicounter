import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multicounter/core/theme/app_theme.dart';
import 'package:multicounter/models/counter_model.dart';
import 'package:multicounter/services/home_screen_widget_service.dart';

void main() {
  group('Accessibility & Color Blind Mode Tests', () {
    test('All ColorBlindMode options provide valid labels and descriptions', () {
      for (final mode in ColorBlindMode.values) {
        expect(mode.label.isNotEmpty, isTrue);
        expect(mode.description.isNotEmpty, isTrue);
      }
    });

    test('Color-safe palettes are generated correctly for each mode', () {
      final protanColors = AppTheme.getColorsForMode(ColorBlindMode.protanopiaDeuteranopia);
      expect(protanColors.isNotEmpty, isTrue);

      final tritanColors = AppTheme.getColorsForMode(ColorBlindMode.tritanopia);
      expect(tritanColors.isNotEmpty, isTrue);

      final hcColors = AppTheme.getColorsForMode(ColorBlindMode.highContrast);
      expect(hcColors.contains(const Color(0xFFFFFFFF)), isTrue);
      expect(hcColors.contains(const Color(0xFFFFD400)), isTrue);
    });

    test('High Contrast Dark theme applies WCAG AAA high contrast borders and pitch black background', () {
      final theme = AppTheme.dark(
        accent: const Color(0xFFFFD400),
        mode: ColorBlindMode.highContrast,
      );

      expect(theme.scaffoldBackgroundColor, Colors.black);
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.side.width, 2.0);
      expect(cardShape.side.color, const Color(0xFFFFFFFF));
    });

    test('High Contrast Light theme applies solid black border and pure white background', () {
      final theme = AppTheme.light(
        accent: const Color(0xFFFFD400),
        mode: ColorBlindMode.highContrast,
      );

      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.side.width, 2.0);
      expect(cardShape.side.color, Colors.black);
    });
  });

  group('Per-Counter Design Isolation & Duplication Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Fresh counter gets clean default design with its own accent color', () {
      final now = DateTime.now();
      final counterA = CounterModel(
        id: 'counter-a-123',
        title: 'Wedding Countdown',
        type: CounterType.countdown,
        targetDate: now.add(const Duration(days: 30)),
        createdAt: now,
        colorValue: 0xFF00E5FF, // Cyan
        iconCodePoint: 0xe072,
      );

      final design = HomeScreenWidgetService.defaultDesignForCounter(counterA);
      expect(design['layout'], 'Classic');
      expect(design['size'], 'Medium');
      expect(design['fontSize'], 25.0);
      expect(design['accent'], counterA.colorValue.toSigned(32));
      expect(design['showDays'], isTrue);
      expect(design['showHours'], isTrue);
      expect(design['showMinutes'], isTrue);
      expect(design['showSeconds'], isTrue);
    });

    test('Each counter has a distinct, isolated storage key', () {
      const idA = 'counter-1';
      const idB = 'counter-2';

      final keyA = HomeScreenWidgetService.counterDesignKey(idA);
      final keyB = HomeScreenWidgetService.counterDesignKey(idB);

      expect(keyA, isNot(equals(keyB)));
      expect(keyA, contains(idA));
      expect(keyB, contains(idB));
    });

    test('Customizing Counter A does not affect fresh Counter B design', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      final counterA = CounterModel(
        id: 'counter-a',
        title: 'Counter A',
        type: CounterType.countdown,
        createdAt: now,
        colorValue: 0xFFFF5252,
        iconCodePoint: 0xe072,
      );

      final counterB = CounterModel(
        id: 'counter-b',
        title: 'Counter B',
        type: CounterType.tally,
        createdAt: now,
        colorValue: 0xFF69F0AE,
        iconCodePoint: 0xe072,
      );

      // Save custom design for Counter A (custom font 42, Minimal layout, OLED black)
      final customDesignA = {
        'layout': 'Minimal',
        'size': 'Large',
        'fontSize': 42.0,
        'background': 0xFF000000,
        'accent': 0xFFFF5252,
      };
      await prefs.setString(
        HomeScreenWidgetService.counterDesignKey(counterA.id),
        jsonEncode(customDesignA),
      );

      // Verify Counter A has custom design
      final rawA = prefs.getString(HomeScreenWidgetService.counterDesignKey(counterA.id));
      expect(rawA, isNotNull);
      final decodedA = jsonDecode(rawA!) as Map<String, dynamic>;
      expect(decodedA['fontSize'], 42.0);
      expect(decodedA['layout'], 'Minimal');

      // Verify Counter B does NOT inherit Counter A design
      final rawB = prefs.getString(HomeScreenWidgetService.counterDesignKey(counterB.id));
      expect(rawB, isNull);

      // Counter B falls back to its own default options
      final defaultB = HomeScreenWidgetService.defaultDesignForCounter(counterB);
      expect(defaultB['fontSize'], 25.0);
      expect(defaultB['layout'], 'Classic');
      expect(defaultB['accent'], counterB.colorValue.toSigned(32));
    });

    test('Cloning/Duplicating a counter properly clones its customized widget design', () async {
      final prefs = await SharedPreferences.getInstance();
      const originalId = 'counter-original';
      const duplicateId = 'counter-copy-1';

      final customDesign = {
        'layout': 'Bold',
        'size': 'Small',
        'fontSize': 32.0,
        'background': 0xFF101827,
        'accent': 0xFFFFD400,
      };

      // Store design for original
      await prefs.setString(
        HomeScreenWidgetService.counterDesignKey(originalId),
        jsonEncode(customDesign),
      );

      // Duplicate operation (simulating duplicateCounter logic)
      final originalDesign = prefs.getString(HomeScreenWidgetService.counterDesignKey(originalId));
      if (originalDesign != null) {
        await prefs.setString(
          HomeScreenWidgetService.counterDesignKey(duplicateId),
          originalDesign,
        );
      }

      // Verify duplicate inherited original's design
      final rawClone = prefs.getString(HomeScreenWidgetService.counterDesignKey(duplicateId));
      expect(rawClone, isNotNull);
      final decodedClone = jsonDecode(rawClone!) as Map<String, dynamic>;
      expect(decodedClone['fontSize'], 32.0);
      expect(decodedClone['layout'], 'Bold');
      expect(decodedClone['background'], 0xFF101827);
    });
  });
}
