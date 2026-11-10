import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/counter_repository.dart';
import '../models/counter_model.dart';
import '../services/home_screen_widget_service.dart';

final counterRepositoryProvider = Provider<CounterRepository>(
  (ref) => CounterRepository(),
);

final countersProvider =
    AsyncNotifierProvider<CountersNotifier, List<CounterModel>>(
  CountersNotifier.new,
);

class CountersNotifier extends AsyncNotifier<List<CounterModel>> {
  static const _widgetStoragePrefix =
      'multicounter.widget_studio.v1.widget.';

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

    try {
      final prefs = await SharedPreferences.getInstance();
      final widgetIds =
          await HomeScreenWidgetService.getInstalledWidgetIds();

      if (updated.isEmpty) {
        debugPrint('No counters remain for home-screen widgets.');
        return;
      }

      final replacement = updated.first;

      for (final widgetId in widgetIds) {
        final storageKey = '$_widgetStoragePrefix$widgetId';
        final raw = prefs.getString(storageKey);

        if (raw == null) continue;

        try {
          final design = jsonDecode(raw) as Map<String, dynamic>;

          if (design['counterId'] != id) continue;

          // Assign the next available counter to this widget.
          design['counterId'] = replacement.id;

          await prefs.setString(
            storageKey,
            jsonEncode(design),
          );

          await HomeScreenWidgetService.sync(
            widgetId: widgetId,
            counter: replacement,
            design: design,
          );
        } catch (error) {
          debugPrint(
            'Could not update widget $widgetId after deletion: $error',
          );
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Widget deletion sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
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

  CounterModel? findCounter(String id) {
    for (final counter in _current) {
      if (counter.id == id) return counter;
    }
    return null;
  }
}
