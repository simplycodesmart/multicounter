import 'package:flutter/material.dart';

enum CounterType { countdown, countUp, tally }

enum CounterRepeatInterval {
  none,
  hourly,
  twiceDaily,
  thriceDaily,
  customHours,
  daily,
  weekly,
  monthly,
  yearly,
  customDays;

  String get label {
    switch (this) {
      case CounterRepeatInterval.none:
        return 'Never';
      case CounterRepeatInterval.hourly:
        return 'Every Hour';
      case CounterRepeatInterval.twiceDaily:
        return 'Twice Daily (Every 12h)';
      case CounterRepeatInterval.thriceDaily:
        return 'Thrice Daily (Every 8h)';
      case CounterRepeatInterval.customHours:
        return 'Custom Hours';
      case CounterRepeatInterval.daily:
        return 'Daily';
      case CounterRepeatInterval.weekly:
        return 'Weekly';
      case CounterRepeatInterval.monthly:
        return 'Monthly';
      case CounterRepeatInterval.yearly:
        return 'Yearly (Anniversary)';
      case CounterRepeatInterval.customDays:
        return 'Custom Days';
    }
  }
}

class CounterModel {
  const CounterModel({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.colorValue,
    required this.iconCodePoint,
    this.startDate,
    this.targetDate,
    this.currentValue = 0,
    this.description = '',
    this.step = 1,
    this.targetValue,
    this.repeatInterval = CounterRepeatInterval.none,
    this.repeatCustomValue,
    this.enableNotification = false,
    this.notificationTiming = 'atEvent',
    this.notificationSound = 'default',
  });

  final String id;
  final String title;
  final String description;
  final CounterType type;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? targetDate;
  final int currentValue;
  final int colorValue;
  final int iconCodePoint;
  final int step;
  final int? targetValue;
  final CounterRepeatInterval repeatInterval;
  final int? repeatCustomValue;
  final bool enableNotification;
  final String notificationTiming;
  final String notificationSound;

  Color get color => Color(colorValue);
  IconData get icon =>
      // ignore: non_const_argument_for_const_parameter
      IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  String get eventEmoji {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('wedding') || lowerTitle.contains('marry') || lowerTitle.contains('marriage')) return '💍';
    if (lowerTitle.contains('baby') || lowerTitle.contains('birth') || lowerTitle.contains('due date')) return '👶';
    if (lowerTitle.contains('work') && lowerTitle.contains('anniversary')) return '💼';
    if (lowerTitle.contains('anniversary')) return '🥂';
    if (lowerTitle.contains('birthday') || lowerTitle.contains('bday')) return '🎂';
    if (lowerTitle.contains('graduat') || lowerTitle.contains('degree')) return '🎓';
    if (lowerTitle.contains('vacation') || lowerTitle.contains('trip') || lowerTitle.contains('holiday') || lowerTitle.contains('flight')) return '🏖️';
    if (lowerTitle.contains('retire')) return '⛵';
    if (lowerTitle.contains('home') || lowerTitle.contains('house')) return '🏡';
    if (lowerTitle.contains('car')) return '🚗';
    if (lowerTitle.contains('fitness') || lowerTitle.contains('gym') || lowerTitle.contains('workout')) return '🏋️';

    switch (iconCodePoint) {
      case 0xe25b: // favorite / favorite_rounded
      case 0xf0289:
        return '❤️';
      case 0xe170: // church
        return '⛪';
      case 0xe16d: // child_care
      case 0xe16e: // child_friendly
      case 0xe194: // crib
        return '👶';
      case 0xe12f: // cake
        return '🎂';
      case 0xf028b: // volunteer_activism (Anniversary)
        return '🥂';
      case 0xf033b: // workspace_premium (Work Anniversary)
      case 0xe126: // business_center
        return '💼';
      case 0xe559: // school (Graduation)
        return '🎓';
      case 0xe54d: // sailing
        return '⛵';
      case 0xe318: // home
        return '🏡';
      case 0xe1d7: // directions_car
        return '🚗';
      case 0xe153: // celebration
      case 0xf02e6: // wine_bar
        return '🎉';
      case 0xe13c: // card_giftcard
        return '🎁';
      case 0xe293: // flight_takeoff
      case 0xe0c6: // beach_access
        return '🏖️';
      case 0xe4a1: // pets
        return '🐾';
      case 0xe5df: // sports_esports
        return '🎮';
      case 0xe28d: // fitness_center
      case 0xe1d9: // directions_run
        return '🏋️';
      case 0xe072: // alarm
      case 0xe661: // timer
        return '⏱️';
    }

    if (type == CounterType.tally) return '🎯';
    if (type == CounterType.countUp) return '📈';
    return '⏱️';
  }

  DateTime get effectiveStartDate => startDate ?? createdAt;

  DateTime get effectiveTargetDate {
    if (targetDate == null) return DateTime.now();
    if (repeatInterval == CounterRepeatInterval.none) return targetDate!;

    final current = targetDate!;
    final now = DateTime.now();
    if (!now.isAfter(current)) return current;

    switch (repeatInterval) {
      case CounterRepeatInterval.hourly:
        final diffHours = now.difference(current).inHours + 1;
        return current.add(Duration(hours: diffHours));
      case CounterRepeatInterval.twiceDaily:
        final intervals = (now.difference(current).inHours / 12).floor() + 1;
        return current.add(Duration(hours: intervals * 12));
      case CounterRepeatInterval.thriceDaily:
        final intervals = (now.difference(current).inHours / 8).floor() + 1;
        return current.add(Duration(hours: intervals * 8));
      case CounterRepeatInterval.customHours:
        final step = (repeatCustomValue != null && repeatCustomValue! > 0) ? repeatCustomValue! : 1;
        final intervals = (now.difference(current).inHours / step).floor() + 1;
        return current.add(Duration(hours: intervals * step));
      case CounterRepeatInterval.customDays:
        final step = (repeatCustomValue != null && repeatCustomValue! > 0) ? repeatCustomValue! : 1;
        final intervals = (now.difference(current).inDays / step).floor() + 1;
        return current.add(Duration(days: intervals * step));
      case CounterRepeatInterval.daily:
        final diffDays = now.difference(current).inDays + 1;
        return current.add(Duration(days: diffDays));
      case CounterRepeatInterval.weekly:
        final weeks = (now.difference(current).inDays / 7).floor() + 1;
        return current.add(Duration(days: weeks * 7));
      case CounterRepeatInterval.monthly:
        var next = current;
        while (now.isAfter(next)) {
          final nextYear = next.month == 12 ? next.year + 1 : next.year;
          final nextMonth = next.month == 12 ? 1 : next.month + 1;
          final daysInMonth = DateUtils.getDaysInMonth(nextYear, nextMonth);
          final day = next.day > daysInMonth ? daysInMonth : next.day;
          next = DateTime(nextYear, nextMonth, day, next.hour, next.minute);
        }
        return next;
      case CounterRepeatInterval.yearly:
        var next = current;
        while (now.isAfter(next)) {
          final targetYear = next.year + 1;
          final isLeapDay = next.month == 2 && next.day == 29;
          final isLeapYear = (targetYear % 4 == 0 && targetYear % 100 != 0) || (targetYear % 400 == 0);
          final day = (isLeapDay && !isLeapYear) ? 28 : next.day;
          next = DateTime(targetYear, next.month, day, next.hour, next.minute);
        }
        return next;
      case CounterRepeatInterval.none:
        return current;
    }
  }

  Duration get duration {
    final now = DateTime.now();
    if (type == CounterType.countdown) {
      if (targetDate == null) return Duration.zero;
      final target = effectiveTargetDate;
      final difference = target.difference(now);
      return difference.isNegative ? Duration.zero : difference;
    }
    if (type == CounterType.countUp) {
      final difference = now.difference(effectiveStartDate);
      return difference.isNegative ? Duration.zero : difference;
    }
    return Duration.zero;
  }

  bool get isCompleted {
    if (type == CounterType.countdown) {
      if (targetDate == null) return false;
      if (repeatInterval != CounterRepeatInterval.none) return false;
      return DateTime.now().isAfter(targetDate!);
    }
    if (type == CounterType.tally && targetValue != null && targetValue! > 0) {
      return currentValue >= targetValue!;
    }
    return false;
  }

  double? get progress {
    if (type == CounterType.countdown && targetDate != null) {
      final target = effectiveTargetDate;
      final total = target.difference(createdAt).inSeconds;
      if (total <= 0) return 1.0;
      final remaining = target.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) return 1.0;
      final done = total - remaining;
      return (done / total).clamp(0.0, 1.0);
    }
    if (type == CounterType.tally && targetValue != null && targetValue! > 0) {
      return (currentValue / targetValue!).clamp(0.0, 1.0);
    }
    return null;
  }

  CounterModel copyWith({
    String? title,
    CounterType? type,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? targetDate,
    int? currentValue,
    int? colorValue,
    int? iconCodePoint,
    String? description,
    int? step,
    int? targetValue,
    bool clearTargetValue = false,
    CounterRepeatInterval? repeatInterval,
    int? repeatCustomValue,
    bool? enableNotification,
    String? notificationTiming,
    String? notificationSound,
  }) {
    return CounterModel(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      currentValue: currentValue ?? this.currentValue,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      description: description ?? this.description,
      step: step ?? this.step,
      targetValue: clearTargetValue ? null : (targetValue ?? this.targetValue),
      repeatInterval: repeatInterval ?? this.repeatInterval,
      repeatCustomValue: repeatCustomValue ?? this.repeatCustomValue,
      enableNotification: enableNotification ?? this.enableNotification,
      notificationTiming: notificationTiming ?? this.notificationTiming,
      notificationSound: notificationSound ?? this.notificationSound,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'startDate': startDate?.toIso8601String(),
    'targetDate': targetDate?.toIso8601String(),
    'currentValue': currentValue,
    'colorValue': colorValue,
    'iconCodePoint': iconCodePoint,
    'description': description,
    'step': step,
    'targetValue': targetValue,
    'repeatInterval': repeatInterval.name,
    'repeatCustomValue': repeatCustomValue,
    'enableNotification': enableNotification,
    'notificationTiming': notificationTiming,
    'notificationSound': notificationSound,
  };

  factory CounterModel.fromJson(Map<String, dynamic> json) {
    return CounterModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: CounterType.values.firstWhere(
        (item) => item.name == json['type'],
        orElse: () => CounterType.countdown,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startDate: json['startDate'] == null
          ? null
          : DateTime.tryParse(json['startDate'] as String),
      targetDate: json['targetDate'] == null
          ? null
          : DateTime.tryParse(json['targetDate'] as String),
      currentValue: (json['currentValue'] as num?)?.toInt() ?? 0,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFFFFD400,
      iconCodePoint: (json['iconCodePoint'] as num?)?.toInt() ?? 0xe8b5,
      description: json['description'] as String? ?? '',
      step: (json['step'] as num?)?.toInt() ?? 1,
      targetValue: (json['targetValue'] as num?)?.toInt(),
      repeatInterval: CounterRepeatInterval.values.firstWhere(
        (item) => item.name == json['repeatInterval'],
        orElse: () => CounterRepeatInterval.none,
      ),
      repeatCustomValue: (json['repeatCustomValue'] as num?)?.toInt(),
      enableNotification: json['enableNotification'] as bool? ?? false,
      notificationTiming: json['notificationTiming'] as String? ?? 'atEvent',
      notificationSound: json['notificationSound'] as String? ?? 'default',
    );
  }
}
