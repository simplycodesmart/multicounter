import 'package:flutter_test/flutter_test.dart';
import 'package:multicounter/models/counter_model.dart';

void main() {
  group('CounterModel', () {
    test('Countdown calculations and completion', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 2, hours: 3));
      final counter = CounterModel(
        id: '1',
        title: 'Trip to Tokyo',
        type: CounterType.countdown,
        createdAt: now,
        targetDate: futureDate,
        colorValue: 0xFFFFD400,
        iconCodePoint: 0xe8b5,
      );

      expect(counter.isCompleted, isFalse);
      expect(counter.duration.inDays, 2);

      final expiredCounter = counter.copyWith(
        targetDate: now.subtract(const Duration(minutes: 5)),
      );
      expect(expiredCounter.isCompleted, isTrue);
      expect(expiredCounter.duration, Duration.zero);
    });

    test('CountUp calculation with custom start date', () {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 45));
      final counter = CounterModel(
        id: '2',
        title: 'Clean Habit',
        type: CounterType.countUp,
        createdAt: now,
        startDate: startDate,
        colorValue: 0xFF45D6C5,
        iconCodePoint: 0xe8b5,
      );

      expect(counter.effectiveStartDate, startDate);
      expect(counter.duration.inDays, greaterThanOrEqualTo(44));
      expect(counter.isCompleted, isFalse);
    });

    test('Tally counter operations and step', () {
      final counter = CounterModel(
        id: '3',
        title: 'Water Glasses',
        type: CounterType.tally,
        createdAt: DateTime.now(),
        currentValue: 3,
        step: 2,
        targetValue: 8,
        colorValue: 0xFF5AA9FF,
        iconCodePoint: 0xe8b5,
      );

      expect(counter.currentValue, 3);
      expect(counter.step, 2);
      expect(counter.targetValue, 8);
      expect(counter.progress, closeTo(3 / 8, 0.01));
      expect(counter.isCompleted, isFalse);

      final completedTally = counter.copyWith(currentValue: 8);
      expect(completedTally.isCompleted, isTrue);
      expect(completedTally.progress, 1.0);
    });

    test('Serialization and deserialization', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final counter = CounterModel(
        id: 'test_json',
        title: 'Test Counter',
        type: CounterType.tally,
        createdAt: now,
        startDate: now,
        currentValue: 42,
        step: 5,
        targetValue: 100,
        colorValue: 0xFFFF5252,
        iconCodePoint: 0xe8b5,
        description: 'Test description',
      );

      final json = counter.toJson();
      final restored = CounterModel.fromJson(json);

      expect(restored.id, counter.id);
      expect(restored.title, counter.title);
      expect(restored.type, counter.type);
      expect(restored.currentValue, counter.currentValue);
      expect(restored.step, counter.step);
      expect(restored.targetValue, counter.targetValue);
      expect(restored.colorValue, counter.colorValue);
      expect(restored.description, counter.description);
    });

    test('Repeat interval yearly rollover for anniversaries', () {
      final pastWeddingDate = DateTime(2024, 6, 15, 10, 0);
      final weddingCounter = CounterModel(
        id: 'wedding_1',
        title: 'Wedding Anniversary',
        type: CounterType.countdown,
        createdAt: DateTime(2024, 1, 1),
        targetDate: pastWeddingDate,
        colorValue: 0xFFFF70A6,
        iconCodePoint: 0xe8b5,
        repeatInterval: CounterRepeatInterval.yearly,
        enableNotification: true,
        notificationSound: 'celebration',
      );

      final nextTarget = weddingCounter.effectiveTargetDate;
      expect(nextTarget.isAfter(DateTime.now()), isTrue);
      expect(nextTarget.month, 6);
      expect(nextTarget.day, 15);
      expect(weddingCounter.isCompleted, isFalse);
      expect(weddingCounter.duration.isNegative, isFalse);
    });

    test('Repeat intervals: hourly, twice daily, and custom hours/days', () {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(hours: 3));

      final hourlyCounter = CounterModel(
        id: 'hourly_1',
        title: 'Drink Water',
        type: CounterType.countdown,
        createdAt: now.subtract(const Duration(days: 1)),
        targetDate: pastDate,
        colorValue: 0xFF00E5FF,
        iconCodePoint: 0xe8b5,
        repeatInterval: CounterRepeatInterval.hourly,
      );

      final nextHourly = hourlyCounter.effectiveTargetDate;
      expect(nextHourly.isAfter(now), isTrue);

      final twiceDailyCounter = CounterModel(
        id: 'twice_1',
        title: 'Meds',
        type: CounterType.countdown,
        createdAt: now.subtract(const Duration(days: 1)),
        targetDate: now.subtract(const Duration(hours: 14)),
        colorValue: 0xFF00E676,
        iconCodePoint: 0xe8b5,
        repeatInterval: CounterRepeatInterval.twiceDaily,
      );
      expect(twiceDailyCounter.effectiveTargetDate.isAfter(now), isTrue);

      final customHoursCounter = CounterModel(
        id: 'custom_h_1',
        title: 'Eye Rest',
        type: CounterType.countdown,
        createdAt: now.subtract(const Duration(days: 1)),
        targetDate: now.subtract(const Duration(hours: 5)),
        colorValue: 0xFFFFD400,
        iconCodePoint: 0xe8b5,
        repeatInterval: CounterRepeatInterval.customHours,
        repeatCustomValue: 2,
      );
      expect(customHoursCounter.effectiveTargetDate.isAfter(now), isTrue);
    });
  });
}
