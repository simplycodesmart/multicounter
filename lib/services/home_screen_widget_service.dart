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
  static String counterDesignKey(String counterId) => '$_designKey.counter.$counterId';

  static Map<String, dynamic> defaultDesignForCounter(CounterModel counter) => {
    'layout': 'Classic',
    'size': 'Medium',
    'background': 0xFF171717,
    'accent': counter.colorValue.toSigned(32),
    'fontSize': 25.0,
    'showDays': true,
    'showHours': true,
    'showMinutes': true,
    'showSeconds': true,
    'showLabels': true,
    'showTitle': true,
    'refreshIntervalMs': 60000,
  };

  /// Checks whether a widget is already placed on the launcher for this counter ID.
  static Future<bool> isCounterWidgetInstalled(String counterId) async {
    final installed = await getInstalledWidgetsInfo();
    return installed.any((w) => w['counterId']?.toString() == counterId);
  }

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

  /// Returns detailed information for each installed widget on the launcher.
  static Future<List<Map<String, dynamic>>> getInstalledWidgetsInfo() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return [];
    try {
      final list = await _channel.invokeMethod<List<dynamic>>(
        'getInstalledWidgetsInfo',
      );
      if (list == null) return [];
      return list
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (error) {
      debugPrint('Could not get installed widgets info: $error');
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
      final rawCounterDesign = prefs.getString(counterDesignKey(counter.id));

      final baseDesign = rawCounterDesign != null
          ? (jsonDecode(rawCounterDesign) as Map<String, dynamic>)
          : defaultDesignForCounter(counter);

      final design = <String, dynamic>{
        ...baseDesign,
        ...?customDesign,
      };

      // If pinning directly without explicit custom accent, respect counter's own color
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
        'targetValue': counter.targetValue ?? 0,
        'accent': counter.colorValue.toSigned(32),
        'iconEmoji': counter.eventEmoji,
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

  /// Updates all installed widgets with the given design options.
  /// If [widgetId] is provided, updates only that widget.
  /// If [assignCounter] is provided, assigns that counter directly to the widget.
  /// If [fallbackCounter] is provided, any widget without a counter assigned will be bound to it.
  static Future<bool> updateAllWidgetDesigns({
    required Map<String, dynamic> design,
    int? widgetId,
    CounterModel? assignCounter,
    CounterModel? fallbackCounter,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final args = <String, dynamic>{
        'design': design,
      };
      if (widgetId != null) {
        args['widgetId'] = widgetId;
      }
      if (assignCounter != null) {
        args['assignCounterId'] = assignCounter.id;
        args['assignTitle'] = assignCounter.title;
        args['assignType'] = assignCounter.type.name;
        args['assignTargetEpoch'] =
            assignCounter.targetDate?.millisecondsSinceEpoch ?? 0;
        args['assignCreatedEpoch'] =
            assignCounter.effectiveStartDate.millisecondsSinceEpoch;
        args['assignCurrentValue'] = assignCounter.currentValue;
        args['assignIconEmoji'] = assignCounter.eventEmoji;
      }
      if (fallbackCounter != null) {
        args['fallbackCounterId'] = fallbackCounter.id;
        args['fallbackTitle'] = fallbackCounter.title;
        args['fallbackType'] = fallbackCounter.type.name;
        args['fallbackTargetEpoch'] =
            fallbackCounter.targetDate?.millisecondsSinceEpoch ?? 0;
        args['fallbackCreatedEpoch'] =
            fallbackCounter.effectiveStartDate.millisecondsSinceEpoch;
        args['fallbackCurrentValue'] = fallbackCounter.currentValue;
        args['fallbackAccent'] = fallbackCounter.colorValue.toSigned(32);
        args['fallbackIconEmoji'] = fallbackCounter.eventEmoji;
      }

      final result = await _channel.invokeMethod<bool>(
        'updateAllWidgetDesigns',
        args,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_designKey, jsonEncode(design));

      return result ?? false;
    } catch (error, stackTrace) {
      debugPrint('updateAllWidgetDesigns failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  /// Applies a newly saved Widget Studio design to all currently installed widgets.
  static Future<void> updateAllInstalledWidgetDesigns(
    Map<String, dynamic> design,
    List<CounterModel> counters,
  ) async {
    final fallback = counters.isNotEmpty ? counters.first : null;
    await updateAllWidgetDesigns(design: design, fallbackCounter: fallback);
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
      'iconEmoji': counter.eventEmoji,
      'type': counter.type.name,
      'targetEpoch': counter.targetDate?.millisecondsSinceEpoch ?? 0,
      'createdEpoch': counter.effectiveStartDate.millisecondsSinceEpoch,
      'currentValue': counter.currentValue,
      'targetValue': counter.targetValue ?? 0,
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
