import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/counter_model.dart';
import '../../providers/counter_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared/counter_card.dart';
import '../../services/home_screen_widget_service.dart';

enum CounterSortBy { dateCreated, title, targetDate }

class CountersScreen extends ConsumerStatefulWidget {
  const CountersScreen({super.key});

  @override
  ConsumerState<CountersScreen> createState() => _CountersScreenState();
}

class _CountersScreenState extends ConsumerState<CountersScreen> {
  Timer? _ticker;
  String _query = '';
  CounterType? _filterType;
  CounterSortBy _sortBy = CounterSortBy.dateCreated;

  @override
  void initState() {
    super.initState();
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
        title: const Text('All Counters', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<CounterSortBy>(
            tooltip: 'Sort by',
            icon: const Icon(Icons.sort_rounded),
            initialValue: _sortBy,
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: CounterSortBy.dateCreated,
                child: Text('Date Created'),
              ),
              PopupMenuItem(
                value: CounterSortBy.title,
                child: Text('Name (A-Z)'),
              ),
              PopupMenuItem(
                value: CounterSortBy.targetDate,
                child: Text('Target / Start Date'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/counter/new'),
        child: const Icon(Icons.add),
      ),
      body: countersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (counters) {
          // Filter
          var filtered = counters.where((c) {
            final matchesQuery = _query.isEmpty ||
                c.title.toLowerCase().contains(_query.toLowerCase()) ||
                c.description.toLowerCase().contains(_query.toLowerCase());
            final matchesType = _filterType == null || c.type == _filterType;
            return matchesQuery && matchesType;
          }).toList();

          // Sort
          switch (_sortBy) {
            case CounterSortBy.title:
              filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
              break;
            case CounterSortBy.dateCreated:
              filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              break;
            case CounterSortBy.targetDate:
              filtered.sort((a, b) {
                final dateA = a.targetDate ?? a.effectiveStartDate;
                final dateB = b.targetDate ?? b.effectiveStartDate;
                return dateA.compareTo(dateB);
              });
              break;
          }

          return Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by title or note...',
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _query = ''),
                          )
                        : null,
                    isDense: true,
                  ),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filterType == null,
                      onSelected: (_) => setState(() => _filterType = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Countdown'),
                      selected: _filterType == CounterType.countdown,
                      onSelected: (_) => setState(() => _filterType =
                          _filterType == CounterType.countdown ? null : CounterType.countdown),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Count Up'),
                      selected: _filterType == CounterType.countUp,
                      onSelected: (_) => setState(() => _filterType =
                          _filterType == CounterType.countUp ? null : CounterType.countUp),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Tally'),
                      selected: _filterType == CounterType.tally,
                      onSelected: (_) => setState(() => _filterType =
                          _filterType == CounterType.tally ? null : CounterType.tally),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // List of counters
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              counters.isEmpty
                                  ? 'No counters yet. Tap + to create one.'
                                  : 'No matching counters found.',
                              style: const TextStyle(color: Colors.white60),
                            ),
                            if (counters.isEmpty) ...[
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => context.push('/counter/new'),
                                icon: const Icon(Icons.add),
                                label: const Text('Create counter'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final counter = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CounterCard(
                              counter: counter,
                              haptic: settings.hapticFeedback,
                              onAddWidget: () async {
                                final isInstalled = await HomeScreenWidgetService.isCounterWidgetInstalled(counter.id);
                                if (isInstalled && context.mounted) {
                                  final proceed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Row(
                                        children: [
                                          Icon(Icons.widgets_rounded, color: Colors.amberAccent),
                                          SizedBox(width: 8),
                                          Text('Widget Already Placed'),
                                        ],
                                      ),
                                      content: Text(
                                        'A home screen widget for "${counter.title}" is already active on your launcher.\n\nDo you want to add another (duplicate) widget for this counter?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton.icon(
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          icon: const Icon(Icons.copy_all_rounded, size: 16),
                                          label: const Text('Duplicate Widget'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (proceed != true) return;
                                }
                                final added = await HomeScreenWidgetService
                                    .requestPinWidget(counter);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      added
                                          ? 'Widget ready! Choose where to place it.'
                                          : 'Widget pinning is unavailable. Add it from your launcher’s Widgets panel.',
                                    ),
                                  ),
                                );
                              },
                              onTap: () =>
                                  context.push('/counter/${counter.id}/edit'),
                              onDuplicate: () async {
                                final clone = await ref
                                    .read(countersProvider.notifier)
                                    .duplicateCounter(counter.id);
                                if (clone != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Duplicated as "${clone.title}"'),
                                      action: SnackBarAction(
                                        label: 'Edit',
                                        onPressed: () => context.push('/counter/${clone.id}/edit'),
                                      ),
                                    ),
                                  );
                                }
                              },
                              onDelete: () => ref
                                  .read(countersProvider.notifier)
                                  .removeCounter(counter.id),
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
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/');
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
