import 'package:flutter/material.dart';

enum CounterType { countdown, countUp, tally }

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

  Color get color => Color(colorValue);
  IconData get icon =>
      // ignore: non_const_argument_for_const_parameter
      IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  DateTime get effectiveStartDate => startDate ?? createdAt;

  Duration get duration {
    final now = DateTime.now();
    if (type == CounterType.countdown) {
      if (targetDate == null) return Duration.zero;
      final difference = targetDate!.difference(now);
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
      return DateTime.now().isAfter(targetDate!);
    }
    if (type == CounterType.tally && targetValue != null && targetValue! > 0) {
      return currentValue >= targetValue!;
    }
    return false;
  }

  double? get progress {
    if (type == CounterType.countdown && targetDate != null) {
      final total = targetDate!.difference(createdAt).inSeconds;
      if (total <= 0) return 1.0;
      final remaining = targetDate!.difference(DateTime.now()).inSeconds;
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
    );
  }
}
