import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/counter_repository.dart';
import '../models/counter_model.dart';
import '../services/home_screen_widget_service.dart';
import '../services/notification_service.dart';

final counterRepositoryProvider = Provider<CounterRepository>(
  (ref) => CounterRepository(),
);

final countersProvider =
    AsyncNotifierProvider<CountersNotifier, List<CounterModel>>(
  CountersNotifier.new,
);

final activeWidgetCounterProvider =
    NotifierProvider<ActiveWidgetCounterNotifier, String?>(
  ActiveWidgetCounterNotifier.new,
);

class ActiveWidgetCounterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setCounterId(String? id) => state = id;
}

class CountersNotifier extends AsyncNotifier<List<CounterModel>> {
  CounterRepository get _repository =>
      ref.read(counterRepositoryProvider);

  List<CounterModel> get _current =>
      state.asData?.value ?? const [];

  @override
  Future<List<CounterModel>> build() => _repository.load();

  Future<void> addCounter(CounterModel counter) async {
    final updated = [..._current, counter];

    state = AsyncData(updated);
    await _repository.save(updated);

    await _refreshWidget(counter);
    await NotificationService.instance.scheduleForCounter(counter);
  }

  Future<void> updateCounter(CounterModel counter) async {
    final updated = [
      for (final item in _current)
        if (item.id == counter.id) counter else item,
    ];

    state = AsyncData(updated);
    await _repository.save(updated);

    // Sync the updated counter to every widget using it.
    await _refreshWidget(counter);
    await NotificationService.instance.scheduleForCounter(counter);
  }

  Future<void> incrementTally(String id) async {
    final counter = findCounter(id);
    if (counter == null || counter.type != CounterType.tally) return;
    await updateCounter(
      counter.copyWith(currentValue: counter.currentValue + counter.step),
    );
  }

  Future<void> decrementTally(String id) async {
    final counter = findCounter(id);
    if (counter == null || counter.type != CounterType.tally) return;
    final newValue = (counter.currentValue - counter.step).clamp(0, 999999999);
    await updateCounter(
      counter.copyWith(currentValue: newValue),
    );
  }

  Future<void> resetTally(String id) async {
    final counter = findCounter(id);
    if (counter == null || counter.type != CounterType.tally) return;
    await updateCounter(
      counter.copyWith(currentValue: 0),
    );
  }

  Future<void> removeCounter(String id) async {
    final updated = _current.where((item) => item.id != id).toList();

    state = AsyncData(updated);
    await _repository.save(updated);
    await NotificationService.instance.cancelForCounter(id);

    // Gracefully handle widgets bound to this counter: mark them deleted,
    // stop background refresh alarms, and remove isolated preferences.
    await HomeScreenWidgetService.handleCounterDeleted(id);
  }

  Future<void> loadSamples() async {
    final samples = CounterRepository.getSampleCounters();
    final updated = [..._current, ...samples];
    state = AsyncData(updated);
    await _repository.save(updated);
  }

  Future<int> importJson(String jsonStr) async {
    final count = await _repository.importJson(jsonStr);
    final reloaded = await _repository.load();
    state = AsyncData(reloaded);
    await HomeScreenWidgetService.syncAll(reloaded);
    return count;
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    state = const AsyncData([]);
  }

  Future<void> syncAllWidgets() async {
    await HomeScreenWidgetService.syncAll(_current);
  }

  Future<void> _refreshWidget(CounterModel counter) async {
    try {
      await HomeScreenWidgetService.syncCounter(counter);
      debugPrint('Widget refresh requested for counter: ${counter.title}');
    } catch (error, stackTrace) {
      debugPrint('Automatic widget refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<CounterModel?> duplicateCounter(String id) async {
    final original = findCounter(id);
    if (original == null) return null;

    final existingTitles = _current.map((c) => c.title.toLowerCase().trim()).toSet();
    String newTitle = '${original.title} (Copy)';
    int copyIndex = 2;
    while (existingTitles.contains(newTitle.toLowerCase().trim())) {
      newTitle = '${original.title} (Copy $copyIndex)';
      copyIndex++;
    }

    final cloned = CounterModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: newTitle,
      type: original.type,
      createdAt: DateTime.now(),
      startDate: original.startDate,
      targetDate: original.targetDate,
      hasTargetTime: original.hasTargetTime,
      currentValue: original.currentValue,
      colorValue: original.colorValue,
      iconCodePoint: original.iconCodePoint,
      description: original.description,
      step: original.step,
      targetValue: original.targetValue,
      repeatInterval: original.repeatInterval,
      repeatCustomValue: original.repeatCustomValue,
      enableNotification: original.enableNotification,
      notificationTiming: original.notificationTiming,
      notificationSound: original.notificationSound,
      showYears: original.showYears,
      showMonths: original.showMonths,
      showWeeks: original.showWeeks,
      showDays: original.showDays,
      showHours: original.showHours,
      showMinutes: original.showMinutes,
      showSeconds: original.showSeconds,
    );

    await addCounter(cloned);

    // Persist and duplicate the original counter's widget design to the clone
    try {
      final prefs = await SharedPreferences.getInstance();
      final origDesign = prefs.getString(HomeScreenWidgetService.counterDesignKey(id));
      if (origDesign != null) {
        await prefs.setString(HomeScreenWidgetService.counterDesignKey(cloned.id), origDesign);
      }
    } catch (_) {}

    return cloned;
  }

  CounterModel? findCounter(String id) {
    for (final counter in _current) {
      if (counter.id == id) return counter;
    }
    return null;
  }
}
