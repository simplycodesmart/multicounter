import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/counter_model.dart';
import '../../providers/counter_provider.dart';
import '../../services/home_screen_widget_service.dart';

class WidgetStudioScreen extends ConsumerStatefulWidget {
  const WidgetStudioScreen({super.key});

  @override
  ConsumerState<WidgetStudioScreen> createState() => _WidgetStudioScreenState();
}

class _WidgetStudioScreenState extends ConsumerState<WidgetStudioScreen> {
  static const _storageKey = 'multicounter.widget_studio.v1';
  static const _backgrounds = <Color>[
    Color(0xFF090909),
    Color(0xFF171717),
    Color(0xFF202020),
    Color(0xFF101827),
    Color(0xFF1E1B4B),
    Color(0xFF064E3B),
    Color(0xFFF4F1E8),
  ];
  static const _accents = <Color>[
    Color(0xFFFFD400),
    Color(0xFFFFA726),
    Color(0xFF70D6C4),
    Color(0xFF00E5FF),
    Color(0xFF8B9CFF),
    Color(0xFFFF7D9C),
    Color(0xFFFFFFFF),
  ];

  Timer? _ticker;
  String? _selectedCounterId;
  String _layout = 'Classic';
  String _size = 'Medium';
  Color _background = AppTheme.surface;
  Color _accent = AppTheme.accentGold;
  double _fontSize = 25;
  bool _showDays = true;
  bool _showHours = true;
  bool _showMinutes = true;
  bool _showSeconds = true;
  bool _showLabels = true;
  bool _showTitle = true;
  bool _loaded = false;
  List<int> _installedWidgetIds = [];

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadDesign();
    _loadInstalledWidgets();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadInstalledWidgets() async {
    final ids = await HomeScreenWidgetService.getInstalledWidgetIds();
    if (mounted) {
      setState(() => _installedWidgetIds = ids);
    }
  }

  Future<void> _loadDesign() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    Map<String, dynamic>? data;
    if (raw != null) {
      try {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (error) {
        debugPrint('Could not load widget design: $error');
      }
    }
    if (!mounted) return;
    setState(() {
      _layout = data?['layout'] as String? ?? 'Classic';
      _size = data?['size'] as String? ?? 'Medium';
      _background = Color((data?['background'] as num?)?.toInt() ?? AppTheme.surface.toARGB32());
      _accent = Color((data?['accent'] as num?)?.toInt() ?? AppTheme.accentGold.toARGB32());
      _fontSize = (data?['fontSize'] as num?)?.toDouble() ?? 25;
      _showDays = data?['showDays'] as bool? ?? true;
      _showHours = data?['showHours'] as bool? ?? true;
      _showMinutes = data?['showMinutes'] as bool? ?? true;
      _showSeconds = data?['showSeconds'] as bool? ?? true;
      _showLabels = data?['showLabels'] as bool? ?? true;
      _showTitle = data?['showTitle'] as bool? ?? true;
      _loaded = true;
    });
  }

  Map<String, dynamic> _currentDesign() => {
    'layout': _layout,
    'size': _size,
    'background': _background.toARGB32().toSigned(32),
    'accent': _accent.toARGB32().toSigned(32),
    'fontSize': _fontSize,
    'showDays': _showDays,
    'showHours': _showHours,
    'showMinutes': _showMinutes,
    'showSeconds': _showSeconds,
    'showLabels': _showLabels,
    'showTitle': _showTitle,
  };

  Future<void> _saveDesign() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Capture the latest Widget Studio design.
      final design = _currentDesign();

      // Save as the default design for newly created widgets.
      await prefs.setString(
        _storageKey,
        jsonEncode(design),
      );

      // Also apply this updated theme/design to all currently installed widgets!
      final counters = ref.read(countersProvider).asData?.value ?? [];
      await HomeScreenWidgetService.updateAllInstalledWidgetDesigns(design, counters);
      await _loadInstalledWidgets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Widget design saved and applied to home screen widgets!',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Widget design save failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save widget design: $error'),
        ),
      );
    }
  }

  Future<void> _pinCurrentWidget(CounterModel counter) async {
    final success = await HomeScreenWidgetService.requestPinWidget(
      counter,
      customDesign: _currentDesign(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Widget ready! Choose where to place it on your home screen.'
              : 'Could not pin automatically. Please add MultiCounter from your launcher widgets tray.',
        ),
      ),
    );
    _loadInstalledWidgets();
  }

  void _resetDesign() {
    setState(() {
      _layout = 'Classic';
      _size = 'Medium';
      _background = AppTheme.surface;
      _accent = AppTheme.accentGold;
      _fontSize = 25;
      _showDays = true;
      _showHours = true;
      _showMinutes = true;
      _showSeconds = true;
      _showLabels = true;
      _showTitle = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final countersAsync = ref.watch(countersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Widget Studio',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Customize multiple widgets for your home screen',
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reset design',
            onPressed: _resetDesign,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: countersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load counters: $error')),
        data: (counters) {
          if (counters.isEmpty) return _emptyState();

          // Pick the currently selected counter or default to first
          final selectedCounter = counters.firstWhere(
            (c) => c.id == _selectedCounterId,
            orElse: () => counters.first,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
            children: [
              // Counter Selector for Widget
              _sectionHeading('SELECT COUNTER', 'Choose which counter to preview & pin'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedCounter.id,
                    items: counters.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Row(
                          children: [
                            Icon(c.icon, color: c.color, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: c.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.type.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: c.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) {
                        setState(() {
                          _selectedCounterId = id;
                          final picked = counters.firstWhere((c) => c.id == id);
                          _accent = picked.color;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Live Preview
              _sectionHeading('LIVE PREVIEW', 'Real-time look of your home screen widget'),
              const SizedBox(height: 12),
              _WidgetPreview(
                counter: selectedCounter,
                layout: _layout,
                size: _size,
                background: _background,
                accent: _accent,
                fontSize: _fontSize,
                showDays: _showDays,
                showHours: _showHours,
                showMinutes: _showMinutes,
                showSeconds: _showSeconds,
                showLabels: _showLabels,
                showTitle: _showTitle,
              ),

              const SizedBox(height: 16),

              // Action Buttons: Add to Home Screen and Save Default
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      onPressed: () => _pinCurrentWidget(selectedCounter),
                      icon: const Icon(Icons.add_to_home_screen),
                      label: const Text('Add to Home Screen'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: _accent,
                        foregroundColor: _accent.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: _loaded ? _saveDesign : null,
                      icon: const Icon(Icons.bookmark_outline, size: 18),
                      label: const Text('Save Default'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Layout Selection
              _sectionHeading('LAYOUT STYLE', 'Pick a presentation template'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _LayoutOption(
                    label: 'Classic',
                    icon: Icons.view_agenda_rounded,
                    selected: _layout == 'Classic',
                    onTap: () => setState(() => _layout = 'Classic'),
                  ),
                  const SizedBox(width: 9),
                  _LayoutOption(
                    label: 'Minimal',
                    icon: Icons.short_text_rounded,
                    selected: _layout == 'Minimal',
                    onTap: () => setState(() => _layout = 'Minimal'),
                  ),
                  const SizedBox(width: 9),
                  _LayoutOption(
                    label: 'Bold',
                    icon: Icons.dashboard_rounded,
                    selected: _layout == 'Bold',
                    onTap: () => setState(() => _layout = 'Bold'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Widget Size Selector
              _sectionHeading('WIDGET SIZE', 'Preview proportions'),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Small', label: Text('Small (2x1)')),
                  ButtonSegment(value: 'Medium', label: Text('Medium (3x2)')),
                  ButtonSegment(value: 'Large', label: Text('Large (4x2)')),
                ],
                selected: {_size},
                onSelectionChanged: (value) => setState(() => _size = value.first),
              ),

              const SizedBox(height: 22),

              // Appearance
              _sectionHeading('COLORS', 'Match your home screen wallpaper'),
              const SizedBox(height: 12),
              _ColorPicker(
                title: 'Widget Background',
                colors: _backgrounds,
                selected: _background,
                onSelected: (color) => setState(() => _background = color),
              ),
              const SizedBox(height: 16),
              _ColorPicker(
                title: 'Numbers & Accent Color',
                colors: _accents,
                selected: _accent,
                onSelected: (color) => setState(() => _accent = color),
              ),

              const SizedBox(height: 16),

              // Font Size Slider
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Number Size',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${_fontSize.round()} px',
                            style: TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _fontSize,
                        min: 16,
                        max: 36,
                        divisions: 20,
                        onChanged: (value) => setState(() => _fontSize = value),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Visible Elements Toggles
              _sectionHeading('VISIBLE ELEMENTS', 'Toggle display units'),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    _VisibilityTile(
                      title: 'Counter Title',
                      value: _showTitle,
                      onChanged: (v) => setState(() => _showTitle = v),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _VisibilityTile(
                      title: 'Days',
                      value: _showDays,
                      onChanged: (v) => setState(() => _showDays = v),
                    ),
                    _VisibilityTile(
                      title: 'Hours',
                      value: _showHours,
                      onChanged: (v) => setState(() => _showHours = v),
                    ),
                    _VisibilityTile(
                      title: 'Minutes',
                      value: _showMinutes,
                      onChanged: (v) => setState(() => _showMinutes = v),
                    ),
                    _VisibilityTile(
                      title: 'Seconds',
                      value: _showSeconds,
                      onChanged: (v) => setState(() => _showSeconds = v),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _VisibilityTile(
                      title: 'Unit Labels (DAYS, HRS, MIN, SEC)',
                      value: _showLabels,
                      onChanged: (v) => setState(() => _showLabels = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Active Widgets Info Card
              _sectionHeading('INSTALLED WIDGETS', 'Active widgets on your launcher'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _installedWidgetIds.isNotEmpty
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            color: _installedWidgetIds.isNotEmpty
                                ? Colors.greenAccent
                                : Colors.white60,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _installedWidgetIds.isNotEmpty
                                ? '${_installedWidgetIds.length} widget(s) currently active'
                                : 'No active widgets detected yet',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async {
                              await _loadInstalledWidgets();
                              await ref.read(countersProvider.notifier).syncAllWidgets();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All widgets refreshed!')),
                              );
                            },
                            icon: const Icon(Icons.sync, size: 16),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You can place multiple widgets on your home screen for different counters! Each widget stays in sync independently.',
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/');
          if (index == 1) context.go('/counters');
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

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.widgets_rounded,
              size: 38,
              color: AppTheme.accentGold,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Create a counter first',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Widgets connect directly to your counters. Create one or load sample counters to design widgets.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, height: 1.5),
          ),
          const SizedBox(height: 18),
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
                onPressed: () => ref.read(countersProvider.notifier).loadSamples(),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Load samples'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _sectionHeading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: AppTheme.accentGold,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(color: Colors.white60, fontSize: 13),
      ),
    ],
  );
}

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({
    required this.counter,
    required this.layout,
    required this.size,
    required this.background,
    required this.accent,
    required this.fontSize,
    required this.showDays,
    required this.showHours,
    required this.showMinutes,
    required this.showSeconds,
    required this.showLabels,
    required this.showTitle,
  });

  final CounterModel counter;
  final String layout;
  final String size;
  final Color background;
  final Color accent;
  final double fontSize;
  final bool showDays,
      showHours,
      showMinutes,
      showSeconds,
      showLabels,
      showTitle;

  @override
  Widget build(BuildContext context) {
    final duration = counter.duration;
    final isTally = counter.type == CounterType.tally;

    final values = <(String, String, bool)>[
      ('${duration.inDays}', 'DAYS', showDays),
      (
        duration.inHours.remainder(24).toString().padLeft(2, '0'),
        'HRS',
        showHours,
      ),
      (
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        'MIN',
        showMinutes,
      ),
      (
        duration.inSeconds.remainder(60).toString().padLeft(2, '0'),
        'SEC',
        showSeconds,
      ),
    ].where((item) => item.$3).toList();

    final display = values.isEmpty
        ? <(String, String, bool)>[('—', '', true)]
        : values;
    final isLight = background.computeLuminance() > .55;
    final foreground = isLight ? const Color(0xFF171717) : Colors.white;
    final actualSize = size == 'Small'
        ? 128.0
        : size == 'Large'
        ? 190.0
        : 158.0;

    return Center(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: actualSize),
        padding: EdgeInsets.all(size == 'Small' ? 14 : 18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(layout == 'Bold' ? 28 : 22),
          border: Border.all(color: isLight ? Colors.black12 : Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showTitle) ...[
              Row(
                children: [
                  Icon(counter.icon, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      counter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: layout == 'Minimal' ? 13 : 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (isTally)
              Text(
                '${counter.currentValue}',
                style: TextStyle(
                  color: accent,
                  fontSize: fontSize + 8,
                  fontWeight: FontWeight.w900,
                ),
              )
            else if (layout == 'Minimal')
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: display
                    .map(
                      (item) => Text(
                        item.$1,
                        style: TextStyle(
                          color: accent,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < display.length; i++) ...[
                    if (i > 0) SizedBox(width: size == 'Small' ? 5 : 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              display[i].$1,
                              style: TextStyle(
                                color: accent,
                                fontSize: fontSize,
                                fontWeight: FontWeight.w900,
                                letterSpacing: layout == 'Bold' ? -1.2 : -.5,
                              ),
                            ),
                          ),
                          if (showLabels && display[i].$2.isNotEmpty)
                            Text(
                              display[i].$2,
                              style: TextStyle(
                                color: foreground.withValues(alpha: .58),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .8,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            if (layout == 'Bold') ...[
              const SizedBox(height: 12),
              Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LayoutOption extends StatelessWidget {
  const _LayoutOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentGold.withValues(alpha: .12)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.accentGold : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppTheme.accentGold : Colors.white70),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.accentGold : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.title,
    required this.colors,
    required this.selected,
    required this.onSelected,
  });
  final String title;
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 9),
      Wrap(
        spacing: 10,
        children: colors
            .map(
              (color) => InkWell(
                onTap: () => onSelected(color),
                borderRadius: BorderRadius.circular(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected.toARGB32() == color.toARGB32()
                          ? AppTheme.accentGold
                          : Colors.white24,
                      width: selected.toARGB32() == color.toARGB32() ? 3 : 1,
                    ),
                  ),
                  child: selected.toARGB32() == color.toARGB32()
                      ? Icon(
                          Icons.check,
                          size: 17,
                          color: color.computeLuminance() > .5
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class _VisibilityTile extends StatelessWidget {
  const _VisibilityTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    dense: true,
    title: Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    value: value,
    activeThumbColor: AppTheme.accentGold,
    onChanged: onChanged,
  );
}
