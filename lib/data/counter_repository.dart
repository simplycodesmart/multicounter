import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/counter_model.dart';

class CounterRepository {
  static const _key = 'multicounter.counters.v1';

  Future<List<CounterModel>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => CounterModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<CounterModel> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<String> exportJson() async {
    final items = await load();
    return const JsonEncoder.withIndent('  ').convert(items.map((e) => e.toJson()).toList());
  }

  Future<int> importJson(String rawJson) async {
    final list = jsonDecode(rawJson) as List;
    final imported = list
        .map((e) => CounterModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    await save(imported);
    return imported.length;
  }

  Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }

  static List<CounterModel> getSampleCounters() {
    final now = DateTime.now();
    final nextYear = DateTime(now.year + 1, 1, 1);
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    return [
      CounterModel(
        id: 'sample_new_year',
        title: 'New Year ${nextYear.year}',
        type: CounterType.countdown,
        createdAt: now,
        targetDate: nextYear,
        colorValue: 0xFFFFD400, // Gold
        iconCodePoint: Icons.celebration.codePoint,
        description: 'Counting down to the brand new year!',
      ),
      CounterModel(
        id: 'sample_streak',
        title: 'Daily Coding Streak',
        type: CounterType.countUp,
        createdAt: thirtyDaysAgo,
        startDate: thirtyDaysAgo,
        colorValue: 0xFF45D6C5, // Emerald
        iconCodePoint: Icons.fitness_center.codePoint,
        description: 'Consecutive days writing clean code.',
      ),
      CounterModel(
        id: 'sample_water',
        title: 'Daily Water Glasses',
        type: CounterType.tally,
        createdAt: now,
        currentValue: 5,
        step: 1,
        targetValue: 8,
        colorValue: 0xFF5AA9FF, // Blue
        iconCodePoint: Icons.local_drink.codePoint,
        description: 'Goal: 8 glasses of water every day.',
      ),
    ];
  }
}
