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

  // Rich background options with transparent, frosted glass, and solid shades
  static const _backgrounds = <Color>[
    Colors.transparent,       // 100% Fully Transparent
    Color(0x33000000),        // 20% Dark Glass
    Color(0x66000000),        // 40% Dark Glass
    Color(0x99171717),        // 60% Glass Slate
    Color(0xCC171717),        // 80% Glass Slate
    Color(0xFF000000),        // OLED Pitch Black
    Color(0xFF171717),        // Classic Charcoal
    Color(0xFF202020),        // Slate Gray
    Color(0xFF101827),        // Midnight Navy
    Color(0xFF1E1B4B),        // Deep Indigo
    Color(0xFF064E3B),        // Forest Green
    Color(0x4DFFFFFF),        // Frost White
    Color(0xFFF4F1E8),        // Clean Light
  ];

  static const _accents = <Color>[
    Color(0xFFFFD400), // Gold
    Color(0xFFFFA726), // Amber
    Color(0xFF70D6C4), // Teal
    Color(0xFF00E5FF), // Cyan
    Color(0xFF8B9CFF), // Indigo
    Color(0xFFFF7D9C), // Rose
    Color(0xFFFFFFFF), // Pure White
    Color(0xFF69F0AE), // Mint
    Color(0xFFFF5252), // Coral
  ];

  Timer? _ticker;
  Timer? _debounceTimer;
  int? _selectedWidgetId; // Target specific home screen widget or null for default template
  String? _selectedCounterId;
  String _layout = 'Classic';
  String _size = 'Medium';
  Color _background = AppTheme.surface;
  double _backgroundOpacity = 1.0;
  Color _accent = AppTheme.accentGold;
  bool _useCounterColor = true;
  double _fontSize = 25;
  bool _showDays = true;
  bool _showHours = true;
  bool _showMinutes = true;
  bool _showSeconds = true;
  bool _showLabels = true;
  bool _showTitle = true;
  int _refreshIntervalMs = 60000; // 1 min default
  bool _previewExpiredState = false;
  bool _autoSyncToWidgets = true;
  bool _loaded = false;
  bool _hasInitialWidgetSelection = false;
  bool _counterDesignLoaded = false;
  List<int> _installedWidgetIds = [];
  List<Map<String, dynamic>> _installedWidgetsInfo = [];
  bool _isRefreshing = false;

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
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncAccentToCounter(CounterModel counter, Color newColor) async {
    try {
      if (counter.colorValue != newColor.toARGB32()) {
        final updated = counter.copyWith(colorValue: newColor.toARGB32());
        await ref.read(countersProvider.notifier).updateCounter(updated);
      }
    } catch (e) {
      debugPrint('Sync accent to counter failed: $e');
    }
  }

  Future<void> _loadInstalledWidgets() async {
    final ids = await HomeScreenWidgetService.getInstalledWidgetIds();
    final info = await HomeScreenWidgetService.getInstalledWidgetsInfo();
    if (!mounted) return;

    setState(() {
      _installedWidgetIds = ids;
      _installedWidgetsInfo = info;

      // Select active widget on initial load only so user template choice is preserved
      if (!_hasInitialWidgetSelection && info.isNotEmpty) {
        _hasInitialWidgetSelection = true;
        final activeNavId = ref.read(activeWidgetCounterProvider);
        Map<String, dynamic>? match;
        if (activeNavId != null) {
          match = info.firstWhere(
            (item) => item['counterId']?.toString() == activeNavId,
            orElse: () => info.first,
          );
        } else {
          match = info.first;
        }
        _applySettingsFromWidgetInfo(match);
      }
    });
  }

  void _applySettingsFromWidgetInfo(Map<String, dynamic> widgetInfo) {
    _selectedWidgetId = (widgetInfo['widgetId'] as num).toInt();
    final cId = widgetInfo['counterId']?.toString();
    if (cId != null && cId.isNotEmpty && cId != 'null') {
      _selectedCounterId = cId;
    }
    _layout = widgetInfo['layout']?.toString() ?? 'Classic';
    _size = widgetInfo['size']?.toString() ?? 'Medium';

    if (widgetInfo['background'] != null) {
      final bgVal = (widgetInfo['background'] as num).toInt();
      _background = Color(bgVal);
      _backgroundOpacity = _background.a;
    }

    if (widgetInfo['accent'] != null) {
      final accVal = (widgetInfo['accent'] as num).toInt();
      _accent = Color(accVal);
      final counters = ref.read(countersProvider).asData?.value ?? [];
      final match = counters.where((c) => c.id == _selectedCounterId).firstOrNull;
      if (match != null && match.colorValue == accVal) {
        _useCounterColor = true;
      } else {
        _useCounterColor = false;
      }
    }

    if (widgetInfo['fontSize'] != null) {
      _fontSize = (widgetInfo['fontSize'] as num).toDouble();
    }

    _showTitle = widgetInfo['showTitle'] as bool? ?? true;
    _showDays = widgetInfo['showDays'] as bool? ?? true;
    _showHours = widgetInfo['showHours'] as bool? ?? true;
    _showMinutes = widgetInfo['showMinutes'] as bool? ?? true;
    _showSeconds = widgetInfo['showSeconds'] as bool? ?? true;
    _showLabels = widgetInfo['showLabels'] as bool? ?? true;
    _refreshIntervalMs = (widgetInfo['refreshIntervalMs'] as num?)?.toInt() ?? 60000;
  }

  Future<void> _loadCounterDesign(CounterModel counter) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(HomeScreenWidgetService.counterDesignKey(counter.id));
    final Map<String, dynamic> data = raw != null
        ? (jsonDecode(raw) as Map<String, dynamic>)
        : HomeScreenWidgetService.defaultDesignForCounter(counter);

    if (!mounted) return;
    setState(() {
      _layout = data['layout'] as String? ?? 'Classic';
      _size = data['size'] as String? ?? 'Medium';
      final bgVal = (data['background'] as num?)?.toInt() ?? AppTheme.surface.toARGB32();
      _background = Color(bgVal);
      _backgroundOpacity = _background.a;
      final accVal = (data['accent'] as num?)?.toInt() ?? counter.colorValue;
      _accent = Color(accVal);
      _useCounterColor = (accVal == counter.colorValue);
      _fontSize = (data['fontSize'] as num?)?.toDouble() ?? 25.0;
      _showDays = data['showDays'] as bool? ?? true;
      _showHours = data['showHours'] as bool? ?? true;
      _showMinutes = data['showMinutes'] as bool? ?? true;
      _showSeconds = data['showSeconds'] as bool? ?? true;
      _showLabels = data['showLabels'] as bool? ?? true;
      _showTitle = data['showTitle'] as bool? ?? true;
      _refreshIntervalMs = (data['refreshIntervalMs'] as num?)?.toInt() ?? 60000;
      _loaded = true;
    });
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
      final bgVal = (data?['background'] as num?)?.toInt() ?? AppTheme.surface.toARGB32();
      _background = Color(bgVal);
      _backgroundOpacity = _background.a;
      _accent = Color((data?['accent'] as num?)?.toInt() ?? AppTheme.accentGold.toARGB32());
      _fontSize = (data?['fontSize'] as num?)?.toDouble() ?? 25;
      _showDays = data?['showDays'] as bool? ?? true;
      _showHours = data?['showHours'] as bool? ?? true;
      _showMinutes = data?['showMinutes'] as bool? ?? true;
      _showSeconds = data?['showSeconds'] as bool? ?? true;
      _showLabels = data?['showLabels'] as bool? ?? true;
      _showTitle = data?['showTitle'] as bool? ?? true;
      _refreshIntervalMs = (data?['refreshIntervalMs'] as num?)?.toInt() ?? 60000;
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
    'refreshIntervalMs': _refreshIntervalMs,
  };

  void _notifyOptionChanged(CounterModel counter) {
    if (_autoSyncToWidgets) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 250), () {
        _applyCurrentDesignSilently(counter);
      });
    }
  }

  Future<void> _applyCurrentDesignSilently(CounterModel counter) async {
    try {
      CounterModel target = counter;
      if (target.colorValue != _accent.toARGB32()) {
        target = target.copyWith(colorValue: _accent.toARGB32());
        await ref.read(countersProvider.notifier).updateCounter(target);
      }

      final design = _currentDesign();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(design));
      await prefs.setString(
        HomeScreenWidgetService.counterDesignKey(target.id),
        jsonEncode(design),
      );

      await HomeScreenWidgetService.updateAllWidgetDesigns(
        design: design,
        widgetId: _selectedWidgetId,
        assignCounter: _selectedWidgetId != null ? target : null,
        fallbackCounter: target,
      );
    } catch (e) {
      debugPrint('Silent auto-sync failed: $e');
    }
  }

  Future<void> _saveDesign([CounterModel? fallbackCounter]) async {
    try {
      final counters = ref.read(countersProvider).asData?.value ?? [];
      CounterModel? target = fallbackCounter;
      if (target == null && counters.isNotEmpty) {
        for (final c in counters) {
          if (c.id == _selectedCounterId) {
            target = c;
            break;
          }
        }
        target ??= counters.first;
      }

      // Sync color to counter model in countersProvider so other screens reflect it
      if (target != null && target.colorValue != _accent.toARGB32()) {
        final updated = target.copyWith(colorValue: _accent.toARGB32());
        await ref.read(countersProvider.notifier).updateCounter(updated);
        target = updated;
      }

      final design = _currentDesign();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(design));
      if (target != null) {
        await prefs.setString(
          HomeScreenWidgetService.counterDesignKey(target.id),
          jsonEncode(design),
        );
      }

      await HomeScreenWidgetService.updateAllWidgetDesigns(
        design: design,
        widgetId: _selectedWidgetId,
        assignCounter: _selectedWidgetId != null ? target : null,
        fallbackCounter: target,
      );
      await _loadInstalledWidgets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedWidgetId != null
                ? 'Widget #$_selectedWidgetId saved & updated on home screen!'
                : 'Widget default template saved & applied to all widgets!',
          ),
          backgroundColor: Colors.green,
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

  Future<void> _refreshAndApplyWidgets({CounterModel? counter, int? widgetId}) async {
    setState(() => _isRefreshing = true);
    try {
      final counters = ref.read(countersProvider).asData?.value ?? [];
      CounterModel? target = counter;
      if (target == null && counters.isNotEmpty) {
        for (final c in counters) {
          if (c.id == _selectedCounterId) {
            target = c;
            break;
          }
        }
        target ??= counters.first;
      }

      // Sync color to counter model in countersProvider so Home & Counter screens reflect it
      if (target != null && target.colorValue != _accent.toARGB32()) {
        final updated = target.copyWith(colorValue: _accent.toARGB32());
        await ref.read(countersProvider.notifier).updateCounter(updated);
        target = updated;
      }

      final design = _currentDesign();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(design));
      if (target != null) {
        await prefs.setString(
          HomeScreenWidgetService.counterDesignKey(target.id),
          jsonEncode(design),
        );
      }

      final targetWId = widgetId ?? _selectedWidgetId;
      await HomeScreenWidgetService.updateAllWidgetDesigns(
        design: design,
        widgetId: targetWId,
        assignCounter: targetWId != null ? target : null,
        fallbackCounter: target,
      );
      await _loadInstalledWidgets();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            targetWId != null
                ? 'Widget #$targetWId updated with current options!'
                : 'All widgets refreshed & updated on home screen!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      debugPrint('Refresh & apply failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh widgets: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _pinCurrentWidget(CounterModel counter) async {
    final isInstalled = await HomeScreenWidgetService.isCounterWidgetInstalled(counter.id);
    if (isInstalled && mounted) {
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
            'A home screen widget for "${counter.title}" (${counter.type.name.toUpperCase()}) is already active on your launcher.\n\nMultiple widgets of the same counter are not allowed unless you duplicate it.\n\nDo you want to create a duplicate widget on your home screen?',
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

  void _resetDesign([CounterModel? counter]) {
    if (counter != null) {
      final def = HomeScreenWidgetService.defaultDesignForCounter(counter);
      setState(() {
        _layout = def['layout'] as String;
        _size = def['size'] as String;
        final bgVal = (def['background'] as num).toInt();
        _background = Color(bgVal);
        _backgroundOpacity = _background.a;
        final accVal = (def['accent'] as num).toInt();
        _accent = Color(accVal);
        _useCounterColor = true;
        _fontSize = (def['fontSize'] as num).toDouble();
        _showDays = def['showDays'] as bool;
        _showHours = def['showHours'] as bool;
        _showMinutes = def['showMinutes'] as bool;
        _showSeconds = def['showSeconds'] as bool;
        _showLabels = def['showLabels'] as bool;
        _showTitle = def['showTitle'] as bool;
        _refreshIntervalMs = (def['refreshIntervalMs'] as num).toInt();
      });
    } else {
      setState(() {
        _layout = 'Classic';
        _size = 'Medium';
        _background = AppTheme.surface;
        _backgroundOpacity = 1.0;
        _accent = AppTheme.accentGold;
        _useCounterColor = true;
        _fontSize = 25;
        _showDays = true;
        _showHours = true;
        _showMinutes = true;
        _showSeconds = true;
        _showLabels = true;
        _showTitle = true;
        _refreshIntervalMs = 60000;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final countersAsync = ref.watch(countersProvider);
    final activeNavId = ref.watch(activeWidgetCounterProvider);

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
              'Customize widgets & sync with home screen',
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

          // If launched from a widget or if not set, choose active counter
          final targetId = _selectedCounterId ?? activeNavId;
          final selectedCounter = counters.firstWhere(
            (c) => c.id == targetId,
            orElse: () => counters.first,
          );

          if (!_counterDesignLoaded && _selectedWidgetId == null) {
            _counterDesignLoaded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _loadCounterDesign(selectedCounter);
              }
            });
          }

          // If user hasn't explicitly chosen custom accent, keep synced with counter's theme color
          if (_useCounterColor && _accent != selectedCounter.color) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _accent = selectedCounter.color);
              }
            });
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
            children: [
              // Target Selection: Edit Installed Home Screen Widget or New Default Template
              if (_installedWidgetsInfo.isNotEmpty) ...[
                _sectionHeading(
                  'ACTIVE HOME SCREEN WIDGETS',
                  'Select a widget to edit directly on your launcher',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedWidgetId != null
                        ? _accent.withValues(alpha: 0.12)
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedWidgetId != null ? _accent : Colors.white12,
                      width: _selectedWidgetId != null ? 1.5 : 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      isExpanded: true,
                      value: _selectedWidgetId,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.palette_outlined, size: 18, color: Colors.white70),
                              SizedBox(width: 10),
                              Text(
                                'Global Default Template (All Widgets)',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        ..._installedWidgetsInfo.map((info) {
                          final wId = (info['widgetId'] as num).toInt();
                          final title = info['title']?.toString() ?? 'Counter';
                          final layout = info['layout']?.toString() ?? 'Classic';
                          return DropdownMenuItem<int?>(
                            value: wId,
                            child: Row(
                              children: [
                                const Icon(Icons.widgets_rounded, size: 18, color: Colors.greenAccent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Widget #$wId: $title ($layout)',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (id) {
                        setState(() {
                          _selectedWidgetId = id;
                          if (id != null) {
                            final info = _installedWidgetsInfo.firstWhere(
                              (item) => (item['widgetId'] as num).toInt() == id,
                            );
                            _applySettingsFromWidgetInfo(info);
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Counter Selector for Widget
              _sectionHeading('ASSIGN COUNTER', 'Choose which counter this widget tracks'),
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
                    onChanged: (id) async {
                      if (id != null) {
                        _selectedCounterId = id;
                        final picked = counters.firstWhere((c) => c.id == id);
                        if (_selectedWidgetId == null) {
                          // Clean per-counter isolation: load this counter's saved options or fresh defaults
                          await _loadCounterDesign(picked);
                        } else {
                          setState(() {
                            if (_useCounterColor) {
                              _accent = picked.color;
                            }
                          });
                          _notifyOptionChanged(picked);
                        }
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Live Preview with Goal Reached Preview Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _sectionHeading('LIVE PREVIEW', 'Real-time look of your home screen widget'),
                  ),
                  FilterChip(
                    visualDensity: VisualDensity.compact,
                    selected: _previewExpiredState,
                    avatar: Icon(
                      _previewExpiredState ? Icons.check_circle_rounded : Icons.celebration_rounded,
                      size: 14,
                      color: _previewExpiredState ? _accent : Colors.white60,
                    ),
                    label: Text(
                      _previewExpiredState ? 'Goal Reached / Expired' : 'Normal State',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onSelected: (val) => setState(() => _previewExpiredState = val),
                  ),
                ],
              ),
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
                previewExpired: _previewExpiredState,
              ),

              const SizedBox(height: 16),

              // Primary Action: Apply Options Directly to Active Widgets
              FilledButton.icon(
                onPressed: _isRefreshing
                    ? null
                    : () => _refreshAndApplyWidgets(counter: selectedCounter),
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.flash_on_rounded, size: 20),
                label: Text(
                  _isRefreshing
                      ? 'Applying to Home Screen...'
                      : _selectedWidgetId != null
                          ? 'Apply Options to Widget #$_selectedWidgetId'
                          : 'Apply Options to Active Widgets',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: _accent,
                  foregroundColor:
                      _accent.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 10),

              // Secondary Buttons: Add to Home Screen & Save Default
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      onPressed: () => _pinCurrentWidget(selectedCounter),
                      icon: const Icon(Icons.add_to_home_screen, size: 18),
                      label: const Text('Add to Home Screen'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: _loaded ? () => _saveDesign(selectedCounter) : null,
                      icon: const Icon(Icons.bookmark_outline, size: 18),
                      label: const Text('Save Default'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Auto-Sync Toggle Card
              Card(
                color: Colors.white.withValues(alpha: 0.03),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white12),
                ),
                child: SwitchListTile.adaptive(
                  dense: true,
                  value: _autoSyncToWidgets,
                  activeThumbColor: _accent,
                  title: const Text(
                    'Live Auto-Sync to Home Screen',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    _selectedWidgetId != null
                        ? 'Changes apply instantly to Widget #$_selectedWidgetId'
                        : 'Changes apply automatically to all active launcher widgets',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                  onChanged: (val) {
                    setState(() => _autoSyncToWidgets = val);
                    if (val) _notifyOptionChanged(selectedCounter);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Layout Selection
              _sectionHeading('LAYOUT STYLE', 'Pick a presentation template'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _LayoutOption(
                    label: 'Classic',
                    icon: Icons.view_agenda_rounded,
                    selected: _layout == 'Classic',
                    onTap: () {
                      setState(() => _layout = 'Classic');
                      _notifyOptionChanged(selectedCounter);
                    },
                  ),
                  const SizedBox(width: 9),
                  _LayoutOption(
                    label: 'Minimal',
                    icon: Icons.short_text_rounded,
                    selected: _layout == 'Minimal',
                    onTap: () {
                      setState(() => _layout = 'Minimal');
                      _notifyOptionChanged(selectedCounter);
                    },
                  ),
                  const SizedBox(width: 9),
                  _LayoutOption(
                    label: 'Bold',
                    icon: Icons.dashboard_rounded,
                    selected: _layout == 'Bold',
                    onTap: () {
                      setState(() => _layout = 'Bold');
                      _notifyOptionChanged(selectedCounter);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Widget Size Selector
              _sectionHeading('WIDGET SIZE', 'Scale proportions'),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Small', label: Text('Small (2x1)')),
                  ButtonSegment(value: 'Medium', label: Text('Medium (3x2)')),
                  ButtonSegment(value: 'Large', label: Text('Large (4x2)')),
                ],
                selected: {_size},
                onSelectionChanged: (value) {
                  setState(() => _size = value.first);
                  _notifyOptionChanged(selectedCounter);
                },
              ),

              const SizedBox(height: 22),

              // Appearance: Background Color & Transparency
              _sectionHeading('WIDGET BACKGROUND & TRANSPARENCY', 'Choose color and glass opacity'),
              const SizedBox(height: 12),
              _ColorPicker(
                title: 'Background Color',
                colors: _backgrounds,
                selected: _background,
                onSelected: (color) {
                  setState(() {
                    if (color == Colors.transparent) {
                      _background = Colors.transparent;
                      _backgroundOpacity = 0.0;
                    } else {
                      _backgroundOpacity = color.a > 0 ? color.a : 1.0;
                      _background = color;
                    }
                  });
                  _notifyOptionChanged(selectedCounter);
                },
              ),

              const SizedBox(height: 12),

              // Background Opacity Slider Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Background Opacity / Glass',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            _backgroundOpacity == 0
                                ? '100% Transparent'
                                : '${(_backgroundOpacity * 100).round()}%',
                            style: TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _backgroundOpacity,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        label: '${(_backgroundOpacity * 100).round()}%',
                        onChanged: (val) {
                          setState(() {
                            _backgroundOpacity = val;
                            if (val == 0.0) {
                              _background = Colors.transparent;
                            } else {
                              final base = _background == Colors.transparent
                                  ? const Color(0xFF171717)
                                  : _background;
                              _background = base.withValues(alpha: val);
                            }
                          });
                          _notifyOptionChanged(selectedCounter);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _OpacityChip(
                            label: 'Clear (0%)',
                            selected: _backgroundOpacity == 0.0,
                            onTap: () {
                              setState(() {
                                _backgroundOpacity = 0.0;
                                _background = Colors.transparent;
                              });
                              _notifyOptionChanged(selectedCounter);
                            },
                          ),
                          _OpacityChip(
                            label: 'Glass (35%)',
                            selected: (_backgroundOpacity - 0.35).abs() < 0.05,
                            onTap: () {
                              setState(() {
                                _backgroundOpacity = 0.35;
                                final base = _background == Colors.transparent
                                    ? const Color(0xFF171717)
                                    : _background;
                                _background = base.withValues(alpha: 0.35);
                              });
                              _notifyOptionChanged(selectedCounter);
                            },
                          ),
                          _OpacityChip(
                            label: 'Tint (70%)',
                            selected: (_backgroundOpacity - 0.70).abs() < 0.05,
                            onTap: () {
                              setState(() {
                                _backgroundOpacity = 0.70;
                                final base = _background == Colors.transparent
                                    ? const Color(0xFF171717)
                                    : _background;
                                _background = base.withValues(alpha: 0.70);
                              });
                              _notifyOptionChanged(selectedCounter);
                            },
                          ),
                          _OpacityChip(
                            label: 'Solid (100%)',
                            selected: _backgroundOpacity == 1.0,
                            onTap: () {
                              setState(() {
                                _backgroundOpacity = 1.0;
                                final base = _background == Colors.transparent
                                    ? const Color(0xFF171717)
                                    : _background;
                                _background = base.withValues(alpha: 1.0);
                              });
                              _notifyOptionChanged(selectedCounter);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Appearance: Accent / Number Color
              _sectionHeading('NUMBERS & ACCENT COLOR', 'Choose theme or custom color'),
              const SizedBox(height: 8),

              // Counter Theme Color Quick Toggle
              InkWell(
                onTap: () {
                  setState(() {
                    _useCounterColor = true;
                    _accent = selectedCounter.color;
                  });
                  _notifyOptionChanged(selectedCounter);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _useCounterColor
                        ? selectedCounter.color.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _useCounterColor ? selectedCounter.color : Colors.white12,
                      width: _useCounterColor ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: selectedCounter.color,
                          shape: BoxShape.circle,
                        ),
                        child: _useCounterColor
                            ? Icon(
                                Icons.check,
                                size: 14,
                                color: selectedCounter.color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Use Counter Theme Color (${selectedCounter.title})',
                          style: TextStyle(
                            fontWeight: _useCounterColor ? FontWeight.bold : FontWeight.w500,
                            color: _useCounterColor ? selectedCounter.color : Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (_useCounterColor)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: selectedCounter.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SYNCED',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              _ColorPicker(
                title: 'Or Pick Custom Accent',
                colors: _accents,
                selected: _accent,
                onSelected: (color) {
                  setState(() {
                    _useCounterColor = false;
                    _accent = color;
                  });
                  _syncAccentToCounter(selectedCounter, color);
                  _notifyOptionChanged(selectedCounter.copyWith(colorValue: color.toARGB32()));
                },
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
                            'Number & Unit Size',
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
                        min: 14,
                        max: 42,
                        divisions: 28,
                        onChanged: (value) {
                          setState(() => _fontSize = value);
                          _notifyOptionChanged(selectedCounter);
                        },
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
                      onChanged: (v) {
                        setState(() => _showTitle = v);
                        _notifyOptionChanged(selectedCounter);
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _VisibilityTile(
                      title: 'Days',
                      value: _showDays,
                      onChanged: (v) {
                        setState(() => _showDays = v);
                        _notifyOptionChanged(selectedCounter);
                      },
                    ),
                    _VisibilityTile(
                      title: 'Hours',
                      value: _showHours,
                      onChanged: (v) {
                        setState(() => _showHours = v);
                        _notifyOptionChanged(selectedCounter);
                      },
                    ),
                    _VisibilityTile(
                      title: 'Minutes',
                      value: _showMinutes,
                      onChanged: (v) {
                        setState(() => _showMinutes = v);
                        _notifyOptionChanged(selectedCounter);
                      },
                    ),
                    _VisibilityTile(
                      title: 'Seconds',
                      value: _showSeconds,
                      onChanged: (v) {
                        setState(() => _showSeconds = v);
                        _notifyOptionChanged(selectedCounter);
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _VisibilityTile(
                      title: 'Unit Labels (DAYS, HRS, MIN, SEC)',
                      value: _showLabels,
                      onChanged: (v) {
                        setState(() => _showLabels = v);
                        _notifyOptionChanged(selectedCounter);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Update Frequency & Battery Impact
              _sectionHeading('UPDATE FREQUENCY & BATTERY IMPACT', 'Configure background refresh rate for home screen widget'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: _refreshIntervalMs,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.speed_rounded),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1000, child: Text('Every 1 second (Live Ticker)')),
                          DropdownMenuItem(value: 60000, child: Text('Every 1 minute (Recommended)')),
                          DropdownMenuItem(value: 900000, child: Text('Every 15 minutes')),
                          DropdownMenuItem(value: 3600000, child: Text('Every 1 hour')),
                          DropdownMenuItem(value: 86400000, child: Text('Daily / Every 24 hours')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _refreshIntervalMs = val);
                            _notifyOptionChanged(selectedCounter);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _refreshIntervalMs == 1000
                              ? Colors.orangeAccent.withValues(alpha: 0.12)
                              : _refreshIntervalMs == 60000
                                  ? Colors.greenAccent.withValues(alpha: 0.12)
                                  : Colors.blueAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _refreshIntervalMs == 1000
                                ? Colors.orangeAccent.withValues(alpha: 0.3)
                                : _refreshIntervalMs == 60000
                                    ? Colors.greenAccent.withValues(alpha: 0.3)
                                    : Colors.blueAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _refreshIntervalMs == 1000
                                  ? Icons.bolt_rounded
                                  : _refreshIntervalMs == 60000
                                      ? Icons.battery_charging_full_rounded
                                      : Icons.battery_saver_rounded,
                              size: 18,
                              color: _refreshIntervalMs == 1000
                                  ? Colors.orangeAccent
                                  : _refreshIntervalMs == 60000
                                      ? Colors.greenAccent
                                      : Colors.blueAccent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _refreshIntervalMs == 1000
                                        ? '⚡ High Battery Consumption'
                                        : _refreshIntervalMs == 60000
                                            ? '🟢 Balanced Battery (Recommended)'
                                            : _refreshIntervalMs == 900000
                                                ? '🔋 Low Battery Usage'
                                                : _refreshIntervalMs == 3600000
                                                    ? '🍃 Very Low Battery Usage'
                                                    : '⭐ Ultra Battery Saver',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: _refreshIntervalMs == 1000
                                          ? Colors.orangeAccent
                                          : _refreshIntervalMs == 60000
                                              ? Colors.greenAccent
                                              : Colors.blueAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _refreshIntervalMs == 1000
                                        ? 'Wakes CPU every second to tick seconds. Android limits sub-minute alarms when screen is off to protect battery.'
                                        : _refreshIntervalMs == 60000
                                            ? 'Optimal balance between live responsiveness and Android system battery life.'
                                            : _refreshIntervalMs == 900000
                                                ? 'Updates 4 times per hour. Great for multi-day countdowns and long counters.'
                                                : _refreshIntervalMs == 3600000
                                                    ? 'Updates once per hour. Negligible impact on battery life.'
                                                    : 'Updates once a day at midnight. Virtually zero battery drain.',
                                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                          Expanded(
                            child: Text(
                              _installedWidgetIds.isNotEmpty
                                  ? '${_installedWidgetIds.length} widget(s) currently active'
                                  : 'No active widgets detected yet',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _isRefreshing
                                ? null
                                : () => _refreshAndApplyWidgets(counter: selectedCounter),
                            icon: _isRefreshing
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.sync, size: 16),
                            label: Text(_isRefreshing ? 'Syncing...' : 'Refresh & Apply'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Updates here (layout, colors, number size, unit toggles) apply to your home screen widgets automatically or on tapping "Refresh & Apply".',
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                      if (_installedWidgetsInfo.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        const Text(
                          'ACTIVE WIDGET INSTANCES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ..._installedWidgetsInfo.map((widgetInfo) {
                          final wId = (widgetInfo['widgetId'] as num).toInt();
                          final title = widgetInfo['title']?.toString() ?? 'Counter';
                          final layout = widgetInfo['layout']?.toString() ?? 'Classic';
                          final type = widgetInfo['type']?.toString().toUpperCase() ?? '';
                          final isTargeted = _selectedWidgetId == wId;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isTargeted
                                  ? _accent.withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isTargeted ? _accent : Colors.white10,
                                width: isTargeted ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.widgets_rounded, size: 20, color: _accent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title.isEmpty ? 'Widget #$wId' : title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isTargeted ? _accent : Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'ID: $wId • Layout: $layout${type.isNotEmpty ? " • $type" : ""}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _applySettingsFromWidgetInfo(widgetInfo);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Loaded settings for Widget #$wId into Studio!'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  child: Text(isTargeted ? 'Editing' : 'Edit'),
                                ),
                                const SizedBox(width: 4),
                                OutlinedButton(
                                  onPressed: _isRefreshing
                                      ? null
                                      : () => _refreshAndApplyWidgets(
                                            counter: selectedCounter,
                                            widgetId: wId,
                                          ),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  child: const Text('Apply Here', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 4),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final success = await HomeScreenWidgetService.requestPinWidget(
                                      selectedCounter,
                                      customDesign: _currentDesign(),
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Duplicate widget ready! Place it on your launcher.'
                                              : 'Could not pin duplicate widget automatically.',
                                        ),
                                      ),
                                    );
                                    _loadInstalledWidgets();
                                  },
                                  icon: const Icon(Icons.copy_all_rounded, size: 14),
                                  label: const Text('Duplicate', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
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

class _OpacityChip extends StatelessWidget {
  const _OpacityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentGold.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.accentGold : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? AppTheme.accentGold : Colors.white70,
          ),
        ),
      ),
    );
  }
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
    this.previewExpired = false,
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
  final bool previewExpired;

  @override
  Widget build(BuildContext context) {
    final duration = previewExpired ? Duration.zero : counter.duration;
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

    // Readable text color logic matching Android
    final isTransparent = background.a < 0.55;
    final isLight = !isTransparent && background.computeLuminance() > .55;
    final foreground = isLight ? const Color(0xFF171717) : Colors.white;

    final actualMinHeight = size == 'Small'
        ? 110.0
        : size == 'Large'
        ? 170.0
        : 140.0;

    // Static sizes for other elements matching Android widget specification
    const staticTitleFontSize = 13.0;
    const staticLabelFontSize = 9.0;

    // Main font auto-adjusts based on widget size
    final autoAdjustedMainFontSize = size == 'Small'
        ? (fontSize * 0.85).clamp(16.0, 26.0)
        : size == 'Large'
            ? (fontSize * 1.30).clamp(28.0, 48.0)
            : fontSize.clamp(20.0, 36.0);

    final widgetBody = Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: actualMinHeight),
      padding: EdgeInsets.symmetric(
        horizontal: size == 'Small' ? 10 : size == 'Large' ? 18 : 14,
        vertical: size == 'Small' ? 8 : size == 'Large' ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(layout == 'Bold' ? 24 : 18),
        border: Border.all(
          color: isTransparent
              ? Colors.white30
              : isLight
                  ? Colors.black12
                  : Colors.white12,
          width: isTransparent ? 1.5 : 1.0,
        ),
        boxShadow: isTransparent
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showTitle &&
              counter.title.trim().isNotEmpty &&
              counter.title.trim().toLowerCase() != 'multicounter') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  counter.eventEmoji,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    counter.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: staticTitleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (previewExpired || counter.isCompleted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                isTally
                    ? (counter.targetValue != null
                        ? 'GOAL REACHED! 🎉 (${previewExpired ? (counter.targetValue ?? counter.currentValue) : counter.currentValue}/${counter.targetValue})'
                        : 'GOAL REACHED! 🎉')
                    : 'EVENT ARRIVED! 🎉',
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          if (isTally)
            Text(
              '${previewExpired && counter.targetValue != null ? counter.targetValue : counter.currentValue}',
              style: TextStyle(
                color: accent,
                fontSize: (autoAdjustedMainFontSize * 1.35).clamp(24.0, 60.0),
                fontWeight: FontWeight.w900,
              ),
            )
          else if (layout == 'Minimal')
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: display
                  .map(
                    (item) => Text(
                      item.$1,
                      style: TextStyle(
                        color: accent,
                        fontSize: autoAdjustedMainFontSize,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Row 1: Digits, '·' separator, and ':' colons (100% vertically centered)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (var i = 0; i < display.length; i++) ...[
                      if (i > 0) ...[
                        SizedBox(
                          width: display[i - 1].$2 == 'DAYS' ? 12 : 14,
                          child: Center(
                            child: Text(
                              display[i - 1].$2 == 'DAYS' ? '·' : ':',
                              style: TextStyle(
                                color: accent,
                                fontSize: display[i - 1].$2 == 'DAYS'
                                    ? (autoAdjustedMainFontSize * 0.55).clamp(10.0, 26.0)
                                    : (autoAdjustedMainFontSize * 0.85).clamp(12.0, 52.0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              display[i].$1,
                              style: TextStyle(
                                color: accent,
                                fontSize: autoAdjustedMainFontSize,
                                fontWeight: FontWeight.w900,
                                letterSpacing: layout == 'Bold' ? -1.0 : -.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Row 2: Sub-labels directly underneath numbers (tight spacing)
                if (showLabels && display.any((item) => item.$2.isNotEmpty)) ...[
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (var i = 0; i < display.length; i++) ...[
                        if (i > 0) ...[
                          SizedBox(
                            width: display[i - 1].$2 == 'DAYS' ? 12 : 14,
                          ),
                        ],
                        Expanded(
                          child: Center(
                            child: Text(
                              display[i].$2,
                              style: TextStyle(
                                color: foreground.withValues(alpha: .75),
                                fontSize: staticLabelFontSize,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          if (layout == 'Bold') ...[
            const SizedBox(height: 8),
            Container(
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ],
      ),
    );

    // If transparent or glass, wrap inside a simulated launcher wallpaper frame
    if (isTransparent) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E293B),
              Color(0xFF0F172A),
              Color(0xFF312E81),
              Color(0xFF1E1B4B),
            ],
          ),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.wallpaper_rounded, size: 12, color: Colors.white60),
                    SizedBox(width: 4),
                    Text(
                      'HOME SCREEN WALLPAPER PREVIEW',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white60),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    background.a == 0 ? 'TRANSPARENT' : 'GLASS ${(background.a * 100).round()}%',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            widgetBody,
          ],
        ),
      );
    }

    return widgetBody;
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
        runSpacing: 10,
        children: colors
            .map(
              (color) {
                final isTransparent = color == Colors.transparent || color.a == 0;
                final isGlass = !isTransparent && color.a < 1.0;
                final isPicked = selected.toARGB32() == color.toARGB32();

                return InkWell(
                  onTap: () => onSelected(color),
                  borderRadius: BorderRadius.circular(30),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isTransparent ? Colors.transparent : color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPicked
                            ? AppTheme.accentGold
                            : isTransparent
                                ? Colors.white70
                                : Colors.white24,
                        width: isPicked ? 3 : 1.5,
                      ),
                      gradient: isTransparent
                          ? const SweepGradient(
                              colors: [
                                Colors.white24,
                                Colors.transparent,
                                Colors.white24,
                                Colors.transparent,
                              ],
                            )
                          : null,
                    ),
                    child: Center(
                      child: isPicked
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: isTransparent
                                  ? Colors.white
                                  : color.computeLuminance() > .5
                                      ? Colors.black
                                      : Colors.white,
                            )
                          : isTransparent
                              ? const Icon(
                                  Icons.block_rounded,
                                  size: 16,
                                  color: Colors.white70,
                                )
                              : isGlass
                                  ? const Icon(
                                      Icons.blur_on_rounded,
                                      size: 14,
                                      color: Colors.white70,
                                    )
                                  : null,
                    ),
                  ),
                );
              },
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
