import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/counter_model.dart';

class HomeScreenWidgetService {
  const HomeScreenWidgetService._();

  static const MethodChannel _channel =
      MethodChannel('multicounter/widget_config');
  static const String _designKey = 'multicounter.widget_studio.v1';
  static String widgetDesignKey(int id) => '$_designKey.widget.$id';

  static Future<List<int>> getInstalledWidgetIds() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return [];
    try {
      final ids = await _channel.invokeMethod<List<dynamic>>('getWidgetIds');
      return ids?.map((id) => (id as num).toInt()).toList() ?? [];
    } catch (error) {
      debugPrint('Could not get widget IDs: $error');
      return [];
    }
  }

  /// Starts Android's native pin-widget flow with the selected counter assigned.
  static Future<bool> requestPinWidget(
    CounterModel counter, {
    Map<String, dynamic>? customDesign,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_designKey);

      final savedDesign = raw == null
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;

      final design = <String, dynamic>{
        ...savedDesign,
        ...?customDesign,
      };

      // If pinning directly from a counter card without custom styling,
      // respect that counter's own theme color instead of global studio default!
      final useCounterColor =
          customDesign == null || !customDesign.containsKey('accent');

      final config = _makeConfig(
        counter,
        design,
        useCounterColor: useCounterColor,
      );

      debugPrint(
        'PIN WIDGET: counter=${counter.title}, accent=${config['accent']}, '
        'hex=0x${(config['accent'] as int).toRadixString(16)}',
      );

      return await _channel.invokeMethod<bool>(
            'requestPinWidget',
            {'config': config},
          ) ??
          false;
    } catch (error, stackTrace) {
      debugPrint('Could not start widget pin flow: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  /// Updates one already-installed widget instance.
  static Future<bool> sync({
    required int widgetId,
    required CounterModel counter,
    required Map<String, dynamic> design,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        widgetDesignKey(widgetId),
        jsonEncode({
          ...design,
          'counterId': counter.id,
        }),
      );
      final result = await _channel.invokeMethod<bool>('saveWidgetConfig', {
        'widgetId': widgetId,
        'config': _makeConfig(counter, design),
      });
      return result ?? false;
    } catch (error, stackTrace) {
      debugPrint('Widget $widgetId sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  /// Refreshes every installed widget that is currently assigned to this counter.
  static Future<void> syncCounter(CounterModel counter) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<bool>('syncCounter', {
        'counterId': counter.id,
        'title': counter.title,
        'type': counter.type.name,
        'targetEpoch': counter.targetDate?.millisecondsSinceEpoch ?? 0,
        'createdEpoch': counter.effectiveStartDate.millisecondsSinceEpoch,
        'currentValue': counter.currentValue,
        'accent': counter.colorValue.toSigned(32),
      });
    } catch (error, stackTrace) {
      debugPrint('Counter widget refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Refreshes all widgets for all counters with updated themes and values.
  static Future<void> syncAll(List<CounterModel> counters) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    for (final counter in counters) {
      await syncCounter(counter);
    }
  }

  /// Applies a newly saved Widget Studio design to all currently installed widgets.
  static Future<void> updateAllInstalledWidgetDesigns(
    Map<String, dynamic> design,
    List<CounterModel> counters,
  ) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final widgetIds = await getInstalledWidgetIds();
      final prefs = await SharedPreferences.getInstance();

      for (final widgetId in widgetIds) {
        final key = widgetDesignKey(widgetId);
        final raw = prefs.getString(key);
        String? counterId;
        if (raw != null) {
          try {
            final existing = jsonDecode(raw) as Map<String, dynamic>;
            counterId = existing['counterId'] as String?;
          } catch (_) {}
        }

        CounterModel? matchingCounter;
        if (counterId != null) {
          for (final c in counters) {
            if (c.id == counterId) {
              matchingCounter = c;
              break;
            }
          }
        }
        matchingCounter ??= counters.isNotEmpty ? counters.first : null;

        if (matchingCounter != null) {
          await sync(
            widgetId: widgetId,
            counter: matchingCounter,
            design: design,
          );
        }
      }
    } catch (error) {
      debugPrint('Failed to update installed widget designs: $error');
    }
  }

  static Map<String, dynamic> _makeConfig(
    CounterModel counter,
    Map<String, dynamic> design, {
    bool useCounterColor = false,
  }) {
    final rawAccent = useCounterColor
        ? counter.colorValue
        : ((design['accent'] as num?)?.toInt() ?? counter.colorValue);

    final rawBackground =
        (design['background'] as num?)?.toInt() ?? 0xFF171717;

    return <String, dynamic>{
      'title': counter.title,
      'counterId': counter.id,
      'type': counter.type.name,
      'targetEpoch': counter.targetDate?.millisecondsSinceEpoch ?? 0,
      'createdEpoch': counter.effectiveStartDate.millisecondsSinceEpoch,
      'currentValue': counter.currentValue,
      'refreshIntervalMs':
          (design['refreshIntervalMs'] as num?)?.toInt() ?? 60000,
      'background': rawBackground.toSigned(32),
      'accent': rawAccent.toSigned(32),
      'fontSize': (design['fontSize'] as num?)?.toDouble() ?? 25.0,
      'showTitle': design['showTitle'] as bool? ?? true,
      'showDays': design['showDays'] as bool? ?? true,
      'showHours': design['showHours'] as bool? ?? true,
      'showMinutes': design['showMinutes'] as bool? ?? true,
      'showSeconds': design['showSeconds'] as bool? ?? true,
      'showLabels': design['showLabels'] as bool? ?? true,
      'layout': design['layout'] as String? ?? 'Classic',
      'size': design['size'] as String? ?? 'Medium',
    };
  }
}
