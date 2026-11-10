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
  });
}
