import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/counter_model.dart';
import '../../providers/counter_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared/counter_card.dart';
import '../../services/home_screen_widget_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _ticker;
  CounterType? _selectedTypeFilter;

  @override
  void initState() {
    super.initState();
    // Live ticker updates duration every second
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countersAsync = ref.watch(countersProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MultiCounter', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              'Make every moment count',
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/counter/new'),
        icon: const Icon(Icons.add),
        label: const Text('New counter'),
      ),
      body: countersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (counters) {
          final countdowns = counters
              .where((c) => c.type == CounterType.countdown)
              .length;
          final countUps = counters
              .where((c) => c.type == CounterType.countUp)
              .length;
          final tallies = counters
              .where((c) => c.type == CounterType.tally)
              .length;

          final displayedCounters = _selectedTypeFilter == null
              ? counters
              : counters.where((c) => c.type == _selectedTypeFilter).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              Text(
                'Your time, your way',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Keep track of the dates, streaks, and tallies that matter.',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 18),

              // Metric tiles
              Row(
                children: [
                  _MetricTile(
                    label: 'ALL',
                    value: counters.length,
                    selected: _selectedTypeFilter == null,
                    onTap: () => setState(() => _selectedTypeFilter = null),
                  ),
                  const SizedBox(width: 8),
                  _MetricTile(
                    label: 'COUNTDOWN',
                    value: countdowns,
                    selected: _selectedTypeFilter == CounterType.countdown,
                    onTap: () => setState(() => _selectedTypeFilter =
                        _selectedTypeFilter == CounterType.countdown
                            ? null
                            : CounterType.countdown),
                  ),
                  const SizedBox(width: 8),
                  _MetricTile(
                    label: 'COUNT UP',
                    value: countUps,
                    selected: _selectedTypeFilter == CounterType.countUp,
                    onTap: () => setState(() => _selectedTypeFilter =
                        _selectedTypeFilter == CounterType.countUp
                            ? null
                            : CounterType.countUp),
                  ),
                  const SizedBox(width: 8),
                  _MetricTile(
                    label: 'TALLY',
                    value: tallies,
                    selected: _selectedTypeFilter == CounterType.tally,
                    onTap: () => setState(() => _selectedTypeFilter =
                        _selectedTypeFilter == CounterType.tally
                            ? null
                            : CounterType.tally),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTypeFilter == null
                        ? 'Recent counters'
                        : '${_selectedTypeFilter!.name.toUpperCase()} counters',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (counters.isNotEmpty)
                    TextButton(
                      onPressed: () => context.go('/counters'),
                      child: const Text('See all'),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (counters.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.hourglass_empty,
                          size: 44,
                          color: Color(0xFFFFD400),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your counters start here',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create a countdown, track elapsed days, or track daily goals with a tally counter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton.icon(
                              onPressed: () => context.push('/counter/new'),
                              icon: const Icon(Icons.add),
                              label: const Text('Create counter'),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  ref.read(countersProvider.notifier).loadSamples(),
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Load samples'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else if (displayedCounters.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('No counters in this category.'),
                  ),
                )
              else
                ...displayedCounters.take(6).map(
                  (counter) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CounterCard(
                      counter: counter,
                      haptic: settings.hapticFeedback,
                      onAddWidget: () async {
                        final added = await HomeScreenWidgetService.requestPinWidget(counter);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              added
                                  ? 'Widget ready! Choose where to place it.'
                                  : 'Widget pinning unavailable. Add it from your launcher\'s Widgets menu.',
                            ),
                          ),
                        );
                      },
                      onTap: () => context.push('/counter/${counter.id}/edit'),
                      onDelete: () =>
                          ref.read(countersProvider.notifier).removeCounter(counter.id),
                      onIncrement: counter.type == CounterType.tally
                          ? () => ref
                              .read(countersProvider.notifier)
                              .incrementTally(counter.id)
                          : null,
                      onDecrement: counter.type == CounterType.tally
                          ? () => ref
                              .read(countersProvider.notifier)
                              .decrementTally(counter.id)
                          : null,
                      onReset: counter.type == CounterType.tally
                          ? () => ref
                              .read(countersProvider.notifier)
                              .resetTally(counter.id)
                          : null,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) context.go('/counters');
          if (index == 2) context.go('/widgets');
          if (index == 3) context.go('/settings');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Counters',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets),
            label: 'Widgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final int value;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.16)
                : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.1),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: selected ? theme.colorScheme.primary : null,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
