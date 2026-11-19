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
    this.hasTargetTime = true,
    this.showYears = false,
    this.showMonths = false,
    this.showWeeks = false,
    this.showDays = true,
    this.showHours = true,
    this.showMinutes = true,
    this.showSeconds = true,
  });

  final String id;
  final String title;
  final String description;
  final CounterType type;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? targetDate;
  final bool hasTargetTime;
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
  final bool showYears;
  final bool showMonths;
  final bool showWeeks;
  final bool showDays;
  final bool showHours;
  final bool showMinutes;
  final bool showSeconds;

  Color get color => Color(colorValue);
  IconData get icon =>
      // ignore: non_const_argument_for_const_parameter
      IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  String get eventEmoji {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('pregnant') || lowerTitle.contains('pregnancy') || lowerTitle.contains('trimester')) return '🤰';
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
    DateTime current = targetDate!;
    if (!hasTargetTime) {
      current = DateTime(current.year, current.month, current.day);
    }
    if (repeatInterval == CounterRepeatInterval.none) return current;

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
      if (!hasTargetTime) {
        final today = DateTime(now.year, now.month, now.day);
        final targetDay = DateTime(target.year, target.month, target.day);
        final difference = targetDay.difference(today);
        return difference.isNegative ? Duration.zero : difference;
      }
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
      if (!hasTargetTime) {
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final targetDay = DateTime(targetDate!.year, targetDate!.month, targetDate!.day);
        return today.isAfter(targetDay);
      }
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
      final now = DateTime.now();
      if (!hasTargetTime) {
        final start = DateTime(createdAt.year, createdAt.month, createdAt.day);
        final today = DateTime(now.year, now.month, now.day);
        final end = DateTime(target.year, target.month, target.day);
        final total = end.difference(start).inDays;
        if (total <= 0) return 1.0;
        final remaining = end.difference(today).inDays;
        if (remaining <= 0) return 1.0;
        final done = total - remaining;
        return (done / total).clamp(0.0, 1.0);
      }
      final total = target.difference(createdAt).inSeconds;
      if (total <= 0) return 1.0;
      final remaining = target.difference(now).inSeconds;
      if (remaining <= 0) return 1.0;
      final done = total - remaining;
      return (done / total).clamp(0.0, 1.0);
    }
    if (type == CounterType.tally && targetValue != null && targetValue! > 0) {
      return (currentValue / targetValue!).clamp(0.0, 1.0);
    }
    return null;
  }

  static DateTime _addYears(DateTime dt, int y) {
    final targetYear = dt.year + y;
    final isLeapDay = dt.month == 2 && dt.day == 29;
    final isLeapYear = (targetYear % 4 == 0 && targetYear % 100 != 0) || (targetYear % 400 == 0);
    final day = (isLeapDay && !isLeapYear) ? 28 : dt.day;
    return DateTime(targetYear, dt.month, day, dt.hour, dt.minute, dt.second, dt.millisecond);
  }

  static DateTime _addMonths(DateTime dt, int m) {
    final totalMonths = dt.month - 1 + m;
    final targetYear = dt.year + (totalMonths ~/ 12);
    final targetMonth = (totalMonths % 12) + 1;
    final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final day = dt.day > daysInMonth ? daysInMonth : dt.day;
    return DateTime(targetYear, targetMonth, day, dt.hour, dt.minute, dt.second, dt.millisecond);
  }

  CounterBreakdown calculateBreakdown({
    DateTime? at,
    bool? overrideYears,
    bool? overrideMonths,
    bool? overrideWeeks,
    bool? overrideDays,
    bool? overrideHours,
    bool? overrideMinutes,
    bool? overrideSeconds,
  }) {
    final useYears = overrideYears ?? showYears;
    final useMonths = overrideMonths ?? showMonths;
    final useWeeks = overrideWeeks ?? showWeeks;
    final useDays = overrideDays ?? showDays;
    final useHours = overrideHours ?? showHours;
    final useMinutes = overrideMinutes ?? showMinutes;
    final useSeconds = overrideSeconds ?? showSeconds;

    final now = at ?? DateTime.now();

    DateTime start;
    DateTime end;

    if (type == CounterType.countdown) {
      final target = effectiveTargetDate;
      if (!hasTargetTime) {
        final today = DateTime(now.year, now.month, now.day);
        final targetDay = DateTime(target.year, target.month, target.day);
        if (today.isAfter(targetDay)) {
          return const CounterBreakdown();
        }
        start = today;
        end = targetDay;
      } else {
        if (now.isAfter(target)) {
          return const CounterBreakdown();
        }
        start = now;
        end = target;
      }
    } else if (type == CounterType.countUp) {
      final startPt = effectiveStartDate;
      if (startPt.isAfter(now)) {
        return const CounterBreakdown();
      }
      start = startPt;
      end = now;
    } else {
      return const CounterBreakdown();
    }

    var cursor = start;
    int years = 0;
    int months = 0;
    int weeks = 0;
    int days = 0;
    int hours = 0;
    int minutes = 0;
    int seconds = 0;

    // 1. Years
    if (useYears) {
      int y = 0;
      while (true) {
        final next = _addYears(cursor, y + 1);
        if (next.isAfter(end)) break;
        y++;
      }
      if (y > 0) {
        years = y;
        cursor = _addYears(cursor, y);
      }
    }

    // 2. Months
    if (useMonths) {
      int m = 0;
      while (true) {
        final next = _addMonths(cursor, m + 1);
        if (next.isAfter(end)) break;
        m++;
      }
      if (m > 0) {
        months = m;
        cursor = _addMonths(cursor, m);
      }
    }

    // 3. Weeks
    final remDays = end.difference(cursor).inDays;
    if (useWeeks) {
      final w = remDays ~/ 7;
      weeks = w;
      cursor = cursor.add(Duration(days: w * 7));
    }

    // 4. Days
    if (useDays) {
      final d = end.difference(cursor).inDays;
      days = d;
      cursor = cursor.add(Duration(days: d));
    }

    // 5. Hours (only if countdown has target time, or for count-up)
    if (useHours && (type != CounterType.countdown || hasTargetTime)) {
      final h = end.difference(cursor).inHours;
      hours = h;
      cursor = cursor.add(Duration(hours: h));
    }

    // 6. Minutes (only if countdown has target time, or for count-up)
    if (useMinutes && (type != CounterType.countdown || hasTargetTime)) {
      final min = end.difference(cursor).inMinutes;
      minutes = min;
      cursor = cursor.add(Duration(minutes: min));
    }

    // 7. Seconds (only if countdown has target time, or for count-up)
    if (useSeconds && (type != CounterType.countdown || hasTargetTime)) {
      final s = end.difference(cursor).inSeconds;
      seconds = s;
    }

    return CounterBreakdown(
      years: years,
      months: months,
      weeks: weeks,
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }

  CounterModel copyWith({
    String? title,
    CounterType? type,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? targetDate,
    bool? hasTargetTime,
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
    bool? showYears,
    bool? showMonths,
    bool? showWeeks,
    bool? showDays,
    bool? showHours,
    bool? showMinutes,
    bool? showSeconds,
  }) {
    return CounterModel(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      hasTargetTime: hasTargetTime ?? this.hasTargetTime,
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
      showYears: showYears ?? this.showYears,
      showMonths: showMonths ?? this.showMonths,
      showWeeks: showWeeks ?? this.showWeeks,
      showDays: showDays ?? this.showDays,
      showHours: showHours ?? this.showHours,
      showMinutes: showMinutes ?? this.showMinutes,
      showSeconds: showSeconds ?? this.showSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'startDate': startDate?.toIso8601String(),
    'targetDate': targetDate?.toIso8601String(),
    'hasTargetTime': hasTargetTime,
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
    'showYears': showYears,
    'showMonths': showMonths,
    'showWeeks': showWeeks,
    'showDays': showDays,
    'showHours': showHours,
    'showMinutes': showMinutes,
    'showSeconds': showSeconds,
  };

  factory CounterModel.fromJson(Map<String, dynamic> json) {
    final targetDate = json['targetDate'] == null
        ? null
        : DateTime.tryParse(json['targetDate'] as String);
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
      targetDate: targetDate,
      hasTargetTime: json['hasTargetTime'] as bool? ??
          (targetDate != null
              ? (targetDate.hour != 0 || targetDate.minute != 0 || targetDate.second != 0)
              : false),
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
      showYears: json['showYears'] as bool? ?? false,
      showMonths: json['showMonths'] as bool? ?? false,
      showWeeks: json['showWeeks'] as bool? ?? false,
      showDays: json['showDays'] as bool? ?? true,
      showHours: json['showHours'] as bool? ?? true,
      showMinutes: json['showMinutes'] as bool? ?? true,
      showSeconds: json['showSeconds'] as bool? ?? true,
    );
  }
}

class CounterBreakdown {
  final int years;
  final int months;
  final int weeks;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;

  const CounterBreakdown({
    this.years = 0,
    this.months = 0,
    this.weeks = 0,
    this.days = 0,
    this.hours = 0,
    this.minutes = 0,
    this.seconds = 0,
  });
}
