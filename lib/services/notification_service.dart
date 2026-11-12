import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/counter_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();

        // Standard event channel
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'multicounter_events',
            'Event Reminders',
            description: 'Alerts and countdown reminders for your tracked events',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        // Celebration channel
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'multicounter_celebration',
            'Celebration Alerts',
            description: 'Special alerts for weddings, birthdays, and anniversaries',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        // Gentle Chime channel
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'multicounter_chime',
            'Gentle Chime',
            description: 'Soft chime reminder for milestones and habits',
            importance: Importance.defaultImportance,
            playSound: true,
            enableVibration: true,
          ),
        );

        // Silent channel
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'multicounter_silent',
            'Silent Reminders',
            description: 'Vibrate-only event notifications',
            importance: Importance.low,
            playSound: false,
            enableVibration: true,
          ),
        );
      }

      _initialized = true;
    } catch (e, stack) {
      debugPrint('NotificationService init error: $e\n$stack');
    }
  }

  Future<void> scheduleForCounter(CounterModel counter) async {
    if (!counter.enableNotification || counter.type != CounterType.countdown) {
      await cancelForCounter(counter.id);
      return;
    }

    await init();

    final target = counter.effectiveTargetDate;
    final now = DateTime.now();

    DateTime notifyTime = target;
    String timingPrefix = '';
    if (counter.notificationTiming == 'dayBefore') {
      notifyTime = target.subtract(const Duration(days: 1));
      timingPrefix = 'Tomorrow: ';
    } else if (counter.notificationTiming == 'weekBefore') {
      notifyTime = target.subtract(const Duration(days: 7));
      timingPrefix = '1 week until: ';
    } else if (counter.notificationTiming == 'hourBefore') {
      notifyTime = target.subtract(const Duration(hours: 1));
      timingPrefix = 'In 1 hour: ';
    }

    if (notifyTime.isBefore(now)) {
      return;
    }

    final id = counter.id.hashCode & 0x7FFFFFFF;
    final channelId = _getChannelIdForSound(counter.notificationSound);

    final Int64List vibration = Int64List.fromList([0, 600, 250, 600, 250, 800]);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelNameForSound(counter.notificationSound),
      channelDescription: 'MultiCounter event reminder',
      importance: Importance.max,
      priority: Priority.high,
      playSound: counter.notificationSound != 'silent',
      enableVibration: true,
      vibrationPattern: vibration,
      icon: '@drawable/ic_notification',
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    final tzDateTime = tz.TZDateTime.from(notifyTime, tz.local);

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: '$timingPrefix${counter.title}',
        body: counter.description.isNotEmpty
            ? counter.description
            : (counter.repeatInterval == CounterRepeatInterval.yearly
                ? 'Happy Anniversary / Celebration!'
                : 'Your countdown event has arrived!'),
        scheduledDate: tzDateTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: counter.id,
      );
    } catch (e) {
      debugPrint('Exact alarm failed ($e), falling back to inexact...');
      try {
        await _notifications.zonedSchedule(
          id: id,
          title: '$timingPrefix${counter.title}',
          body: counter.description.isNotEmpty
              ? counter.description
              : 'Your countdown event has arrived!',
          scheduledDate: tzDateTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
          payload: counter.id,
        );
      } catch (err) {
        debugPrint('Inexact schedule failed: $err');
      }
    }
  }

  Future<void> cancelForCounter(String counterId) async {
    try {
      await init();
      final id = counterId.hashCode & 0x7FFFFFFF;
      await _notifications.cancel(id: id);
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }

  Future<void> testNotificationSound(String sound, String title) async {
    await init();
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final channelId = _getChannelIdForSound(sound);
    final Int64List vibration = sound == 'silent'
        ? Int64List.fromList([0, 500, 200, 500])
        : Int64List.fromList([0, 600, 250, 600, 250, 800]);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelNameForSound(sound),
      channelDescription: 'Sound preview test',
      importance: Importance.max,
      priority: Priority.high,
      playSound: sound != 'silent',
      enableVibration: true,
      vibrationPattern: vibration,
      icon: '@drawable/ic_notification',
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: 999999,
      title: 'Sound & Alert Preview: ${_getSoundLabel(sound)}',
      body: 'Alert test for "$title" (with tactile pulse for accessibility)',
      notificationDetails: notificationDetails,
    );
  }

  String _getChannelIdForSound(String sound) {
    switch (sound) {
      case 'celebration':
        return 'multicounter_celebration';
      case 'chime':
        return 'multicounter_chime';
      case 'silent':
        return 'multicounter_silent';
      default:
        return 'multicounter_events';
    }
  }

  String _getChannelNameForSound(String sound) {
    switch (sound) {
      case 'celebration':
        return 'Celebration Alerts';
      case 'chime':
        return 'Gentle Chime';
      case 'silent':
        return 'Silent Reminders';
      default:
        return 'Event Reminders';
    }
  }

  String _getSoundLabel(String sound) {
    switch (sound) {
      case 'celebration':
        return 'Celebration & Fanfare';
      case 'chime':
        return 'Gentle Chime';
      case 'bell':
        return 'Bell / Alarm';
      case 'silent':
        return 'Silent (Vibrate only)';
      default:
        return 'Default Alert';
    }
  }
}
