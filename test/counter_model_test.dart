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
      expect(restored.showWeeks, isFalse);
      expect(restored.showYears, isFalse);
      expect(restored.showMonths, isFalse);

      final pregnancyCounter = counter.copyWith(showWeeks: true, showYears: true, showMonths: true);
      final pregnancyJson = pregnancyCounter.toJson();
      final restoredPregnancy = CounterModel.fromJson(pregnancyJson);
      expect(restoredPregnancy.showWeeks, isTrue);
      expect(restoredPregnancy.showYears, isTrue);
      expect(restoredPregnancy.showMonths, isTrue);
    });

    test('Smart cascade calculations: Years, Months, Weeks, Days, Hours, Mins, Secs', () {
      final now = DateTime(2026, 1, 1, 0, 0);
      final twoYearsLater = DateTime(2028, 1, 1, 0, 0);

      // Case 1: Both Years and Months enabled -> 2 Years, 0 Months
      final counterYearsMonths = CounterModel(
        id: 'c_ym',
        title: 'Two Years',
        type: CounterType.countdown,
        createdAt: now,
        targetDate: twoYearsLater,
        colorValue: 0xFFFFD400,
        iconCodePoint: 0xe8b5,
        showYears: true,
        showMonths: true,
        showDays: false,
        showHours: false,
        showMinutes: false,
        showSeconds: false,
      );
      final b1 = counterYearsMonths.calculateBreakdown(at: now);
      expect(b1.years, 2);
      expect(b1.months, 0);

      // Case 2: Year NOT selected, Month selected -> 24 Months!
      final counterMonthsOnly = counterYearsMonths.copyWith(
        showYears: false,
        showMonths: true,
      );
      final b2 = counterMonthsOnly.calculateBreakdown(at: now);
      expect(b2.years, 0);
      expect(b2.months, 24);

      // Case 3: Year NOT selected, Month NOT selected, Weeks selected -> 104 Weeks!
      final counterWeeksOnly = counterYearsMonths.copyWith(
        showYears: false,
        showMonths: false,
        showWeeks: true,
      );
      final b3 = counterWeeksOnly.calculateBreakdown(at: now);
      expect(b3.years, 0);
      expect(b3.months, 0);
      expect(b3.weeks, 104);

      // Case 4: No date units selected, Hours selected -> absorbs into hours (e.g. 48 hours for 2 days)
      final twoDaysLater = now.add(const Duration(days: 2));
      final counterHours = CounterModel(
        id: 'c_h',
        title: 'Two Days in Hours',
        type: CounterType.countdown,
        createdAt: now,
        targetDate: twoDaysLater,
        colorValue: 0xFFFFD400,
        iconCodePoint: 0xe8b5,
        showYears: false,
        showMonths: false,
        showWeeks: false,
        showDays: false,
        showHours: true,
        showMinutes: true,
        showSeconds: true,
      );
      final b4 = counterHours.calculateBreakdown(at: now);
      expect(b4.hours, 48);
      expect(b4.minutes, 0);
      expect(b4.seconds, 0);

      // Case 5: Only Seconds selected -> 3600 seconds for 1 hour
      final oneHourLater = now.add(const Duration(hours: 1));
      final counterSeconds = CounterModel(
        id: 'c_s',
        title: 'Seconds Only',
        type: CounterType.countdown,
        createdAt: now,
        targetDate: oneHourLater,
        colorValue: 0xFFFFD400,
        iconCodePoint: 0xe8b5,
        showYears: false,
        showMonths: false,
        showWeeks: false,
        showDays: false,
        showHours: false,
        showMinutes: false,
        showSeconds: true,
      );
      final b5 = counterSeconds.calculateBreakdown(at: now);
      expect(b5.seconds, 3600);
    });

    test('Pregnancy emoji detection and weeks calculation', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 171, hours: 5));
      final counter = CounterModel(
        id: 'preg_1',
        title: 'Baby Pregnancy Due Date',
        type: CounterType.countdown,
        createdAt: now,
        targetDate: futureDate,
        colorValue: 0xFFFF8DA1,
        iconCodePoint: 0xe8b5,
        showWeeks: true,
      );

      // Emoji should detect pregnancy
      expect(counter.eventEmoji, '🤰');

      // Weeks and days calculation verification
      final totalDays = counter.duration.inDays;
      final weeks = totalDays ~/ 7;
      final days = totalDays % 7;
      expect(weeks, 24);
      expect(days, 3);
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

    test('Optional Target Time (date-only events and weeks/days calculation)', () {
      final realNow = DateTime.now();
      final now = DateTime(realNow.year, realNow.month, realNow.day, 15, 30); // 3:30 PM today
      final targetDate = DateTime(realNow.year, realNow.month, realNow.day).add(const Duration(days: 14)); // exact 14 calendar days away

      // When hasTargetTime is false: exact 2 weeks without hours/mins interference
      final dateOnlyCounter = CounterModel(
        id: 'date_only_1',
        title: 'Baby Milestone',
        type: CounterType.countdown,
        createdAt: now,
        targetDate: targetDate,
        colorValue: 0xFFFF8DA1,
        iconCodePoint: 0xe8b5,
        hasTargetTime: false,
        showWeeks: true,
        showDays: true,
        showHours: false,
        showMinutes: false,
        showSeconds: false,
      );

      expect(dateOnlyCounter.hasTargetTime, isFalse);

      final breakdown = dateOnlyCounter.calculateBreakdown(at: now);
      expect(breakdown.weeks, 2);
      expect(breakdown.days, 0);
      expect(breakdown.hours, 0);
      expect(breakdown.minutes, 0);
      expect(breakdown.seconds, 0);

      // Duration in days should be exact 14 calendar days
      expect(dateOnlyCounter.duration.inDays, 14);

      // Serialization round-trip
      final json = dateOnlyCounter.toJson();
      expect(json['hasTargetTime'], isFalse);
      final restored = CounterModel.fromJson(json);
      expect(restored.hasTargetTime, isFalse);

      // On the day of event, isCompleted is false (it's the event day!)
      final onEventDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 10, 0);
      expect(dateOnlyCounter.calculateBreakdown(at: onEventDay).weeks, 0);
      expect(dateOnlyCounter.calculateBreakdown(at: onEventDay).days, 0);

      // Explicit target time enabled
      final specificTimeCounter = dateOnlyCounter.copyWith(
        hasTargetTime: true,
        showHours: true,
        showMinutes: true,
      );
      expect(specificTimeCounter.hasTargetTime, isTrue);
      expect(specificTimeCounter.toJson()['hasTargetTime'], isTrue);
    });
  });
}
