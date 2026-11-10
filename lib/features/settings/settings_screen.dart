import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/counter_model.dart';
import '../../providers/counter_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Counters JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste previously exported MultiCounter JSON below to restore your counters:',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '[{"id": "...", "title": "..."}]',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              try {
                final count = await ref.read(countersProvider.notifier).importJson(text);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully imported $count counter(s)!')),
                );
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invalid JSON format: $e')),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) async {
    final jsonStr = await ref.read(counterRepositoryProvider).exportJson();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Counters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Copy your counters JSON below to back up or transfer your data:',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonStr,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Counters JSON copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Counters?'),
        content: const Text(
          'This will permanently delete all your counters and remove them from all home screen widgets. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(countersProvider.notifier).clearAll();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All counters cleared.')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showWidgetHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adding Home Screen Widgets'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Method 1: From the App (Recommended)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Tap the widget icon on any counter card or use the "Add to Home Screen" button in Widget Studio. Android will prompt you to place it.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            SizedBox(height: 14),
            Text(
              'Method 2: From Android Launcher',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Long press on any empty space on your Android home screen -> Tap Widgets -> Search for "MultiCounter" -> Drag and drop to place it, then select your counter.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        children: [
          // Section: Appearance
          _sectionHeader('APPEARANCE & THEME'),
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Theme Mode',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode, size: 16),
                            label: Text('Dark'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode, size: 16),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.settings_brightness, size: 16),
                            label: Text('Auto'),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (val) =>
                            settingsNotifier.setThemeMode(val.first),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'App Accent Color',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: AppTheme.accentColors.map((color) {
                          final isSelected =
                              settings.accentColor.toARGB32() == color.toARGB32();
                          return InkWell(
                            onTap: () => settingsNotifier.setAccentColor(color),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 18,
                                      color: color.computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Counter Preferences
          _sectionHeader('COUNTER PREFERENCES'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Default Counter Type'),
                  subtitle: Text(
                    settings.defaultCounterType == CounterType.countdown
                        ? 'Countdown'
                        : settings.defaultCounterType == CounterType.countUp
                            ? 'Count Up'
                            : 'Tally',
                  ),
                  trailing: DropdownButton<CounterType>(
                    value: settings.defaultCounterType,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: CounterType.countdown,
                        child: Text('Countdown'),
                      ),
                      DropdownMenuItem(
                        value: CounterType.countUp,
                        child: Text('Count Up'),
                      ),
                      DropdownMenuItem(
                        value: CounterType.tally,
                        child: Text('Tally'),
                      ),
                    ],
                    onChanged: (type) {
                      if (type != null) {
                        settingsNotifier.setDefaultCounterType(type);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.vibration),
                  title: const Text('Haptic Feedback'),
                  subtitle: const Text('Vibrate gently on button and counter taps'),
                  value: settings.hapticFeedback,
                  onChanged: (val) => settingsNotifier.setHapticFeedback(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Home Screen Widgets
          _sectionHeader('HOME SCREEN WIDGETS'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brush_outlined),
                  title: const Text('Widget Studio'),
                  subtitle: const Text('Design styles, layouts, and colors for home widgets'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/widgets'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Sync All Widgets'),
                  subtitle: const Text('Force refresh all active home screen widgets now'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () async {
                    await ref.read(countersProvider.notifier).syncAllWidgets();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All home screen widgets updated!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: const Text('Widget Placement Help'),
                  subtitle: const Text('Learn how to add multiple widgets to Android'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showWidgetHelp(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Data & Backup
          _sectionHeader('DATA & BACKUP'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('Export Counters'),
                  subtitle: const Text('Copy JSON data to clipboard or file'),
                  onTap: () => _showExportDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Import Counters'),
                  subtitle: const Text('Restore counters from JSON backup'),
                  onTap: () => _showImportDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('Add Sample Counters'),
                  subtitle: const Text('Explore pre-built countdown, streak, and tally counters'),
                  onTap: () async {
                    await ref.read(countersProvider.notifier).loadSamples();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sample counters loaded!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: const Text(
                    'Clear All Counters',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  subtitle: const Text('Delete all counters and reset widget data'),
                  onTap: () => _confirmClearAll(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: About
          _sectionHeader('ABOUT'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('MultiCounter'),
                  subtitle: const Text('Version 1.0.0 • Simple, highly customizable multi-counter with home screen widgets'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/');
          if (index == 1) context.go('/counters');
          if (index == 2) context.go('/widgets');
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

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Colors.white60,
      ),
    ),
  );
}
