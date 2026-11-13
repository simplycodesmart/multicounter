import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/counter_model.dart';
import '../../providers/counter_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/home_screen_widget_service.dart';
import '../../services/notification_service.dart';

class CounterEditorScreen extends ConsumerStatefulWidget {
  const CounterEditorScreen({super.key, this.counterId});

  final String? counterId;

  @override
  ConsumerState<CounterEditorScreen> createState() => _CounterEditorScreenState();
}

class _CounterEditorScreenState extends ConsumerState<CounterEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tallyController = TextEditingController(text: '0');
  final _stepController = TextEditingController(text: '1');
  final _targetValueController = TextEditingController();

  CounterType _type = CounterType.countdown;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 7));
  DateTime _startDate = DateTime.now();
  Color _color = const Color(0xFFFFD400);
  IconData _icon = Icons.flag_rounded;
  bool _initialized = false;

  CounterRepeatInterval _repeatInterval = CounterRepeatInterval.none;
  int _repeatCustomValue = 2;
  bool _enableNotification = false;
  String _notificationTiming = 'atEvent';
  String _notificationSound = 'default';
  bool _userSelectedCustomIcon = false;
  bool _isSaving = false;

  static const List<Color> _presetColors = [
    Color(0xFFFFD400), // Gold
    Color(0xFFFFA000), // Amber
    Color(0xFFFF6B35), // Orange
    Color(0xFFFF5252), // Red
    Color(0xFFFF70A6), // Pink
    Color(0xFF8B5CF6), // Violet
    Color(0xFF5AA9FF), // Sky Blue
    Color(0xFF00E5FF), // Cyan
    Color(0xFF45D6C5), // Teal
    Color(0xFF00E676), // Green
    Color(0xFFEEEEEE), // Silver
  ];

  static final List<({String label, String title, IconData icon, Color color, CounterRepeatInterval repeat, String sound})> _quickEventPresets = [
    (
      label: 'Wedding',
      title: 'Our Wedding',
      icon: Icons.favorite_rounded,
      color: const Color(0xFFFF70A6),
      repeat: CounterRepeatInterval.yearly,
      sound: 'celebration',
    ),
    (
      label: 'Baby Birth',
      title: 'Baby Arrival',
      icon: Icons.child_care_rounded,
      color: const Color(0xFF5AA9FF),
      repeat: CounterRepeatInterval.none,
      sound: 'chime',
    ),
    (
      label: 'Anniversary',
      title: 'Anniversary',
      icon: Icons.volunteer_activism_rounded,
      color: const Color(0xFFFF5252),
      repeat: CounterRepeatInterval.yearly,
      sound: 'celebration',
    ),
    (
      label: 'Work Anniversary',
      title: 'Work Anniversary',
      icon: Icons.workspace_premium_rounded,
      color: const Color(0xFFFFD400),
      repeat: CounterRepeatInterval.yearly,
      sound: 'default',
    ),
    (
      label: 'Birthday',
      title: 'Birthday',
      icon: Icons.cake_rounded,
      color: const Color(0xFFFFA000),
      repeat: CounterRepeatInterval.yearly,
      sound: 'celebration',
    ),
    (
      label: 'Vacation',
      title: 'Vacation Trip',
      icon: Icons.flight_takeoff_rounded,
      color: const Color(0xFF00E5FF),
      repeat: CounterRepeatInterval.none,
      sound: 'chime',
    ),
    (
      label: 'Graduation',
      title: 'Graduation Day',
      icon: Icons.school_rounded,
      color: const Color(0xFF8B5CF6),
      repeat: CounterRepeatInterval.none,
      sound: 'celebration',
    ),
    (
      label: 'New Home',
      title: 'New Home Move',
      icon: Icons.home_rounded,
      color: const Color(0xFF00E676),
      repeat: CounterRepeatInterval.none,
      sound: 'default',
    ),
    (
      label: 'New Car',
      title: 'New Car',
      icon: Icons.directions_car_rounded,
      color: const Color(0xFF45D6C5),
      repeat: CounterRepeatInterval.none,
      sound: 'default',
    ),
    (
      label: 'Retirement',
      title: 'Retirement Freedom',
      icon: Icons.sailing_rounded,
      color: const Color(0xFFFFD400),
      repeat: CounterRepeatInterval.none,
      sound: 'celebration',
    ),
    (
      label: 'Milestone',
      title: 'Major Milestone',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFFFD400),
      repeat: CounterRepeatInterval.none,
      sound: 'celebration',
    ),
    (
      label: 'Fitness Goal',
      title: 'Fitness Goal',
      icon: Icons.fitness_center_rounded,
      color: const Color(0xFFFF6B35),
      repeat: CounterRepeatInterval.weekly,
      sound: 'chime',
    ),
  ];

  static const Map<String, List<(IconData, String)>> _categorizedIcons = {
    'Life Events & Milestones': [
      (Icons.favorite_rounded, 'Wedding / Love'),
      (Icons.church_rounded, 'Ceremony / Church'),
      (Icons.child_care_rounded, 'Baby Birth'),
      (Icons.child_friendly_rounded, 'Stroller'),
      (Icons.crib_rounded, 'Crib'),
      (Icons.family_restroom_rounded, 'Family'),
      (Icons.cake_rounded, 'Birthday / Cake'),
      (Icons.volunteer_activism_rounded, 'Anniversary'),
      (Icons.workspace_premium_rounded, 'Work Anniversary'),
      (Icons.military_tech_rounded, 'Service Medal'),
      (Icons.badge_rounded, 'Work Badge'),
      (Icons.business_center_rounded, 'Career'),
      (Icons.school_rounded, 'Graduation'),
      (Icons.sailing_rounded, 'Retirement'),
      (Icons.home_rounded, 'New Home'),
      (Icons.directions_car_rounded, 'New Car'),
    ],
    'Celebrations & Lifestyle': [
      (Icons.celebration_rounded, 'Party'),
      (Icons.wine_bar_rounded, 'Cheers / Toast'),
      (Icons.card_giftcard_rounded, 'Gift'),
      (Icons.flight_takeoff_rounded, 'Travel / Flight'),
      (Icons.beach_access_rounded, 'Vacation'),
      (Icons.pets_rounded, 'Pet'),
      (Icons.sports_esports_rounded, 'Gaming'),
      (Icons.code_rounded, 'Coding'),
      (Icons.music_note_rounded, 'Music'),
    ],
    'Goals & Habits': [
      (Icons.emoji_events_rounded, 'Trophy / Milestone'),
      (Icons.star_rounded, 'Star Goal'),
      (Icons.fitness_center_rounded, 'Workout'),
      (Icons.directions_run_rounded, 'Running'),
      (Icons.local_drink_rounded, 'Water'),
      (Icons.savings_rounded, 'Finance'),
      (Icons.smoke_free_rounded, 'Habit'),
      (Icons.alarm_rounded, 'Alarm'),
      (Icons.flag_rounded, 'Flag'),
    ],
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tallyController.dispose();
    _stepController.dispose();
    _targetValueController.dispose();
    super.dispose();
  }

  void _initialize(CounterModel? counter) {
    if (_initialized) return;
    _initialized = true;

    if (counter != null) {
      _titleController.text = counter.title;
      _descriptionController.text = counter.description;
      _tallyController.text = counter.currentValue.toString();
      _stepController.text = counter.step.toString();
      _targetValueController.text = counter.targetValue?.toString() ?? '';
      _type = counter.type;
      _targetDate = counter.targetDate ?? _targetDate;
      _startDate = counter.startDate ?? counter.createdAt;
      _color = counter.color;
      _icon = counter.icon;
      _repeatInterval = counter.repeatInterval;
      _repeatCustomValue = counter.repeatCustomValue ?? 2;
      _enableNotification = counter.enableNotification;
      _notificationTiming = counter.notificationTiming;
      _notificationSound = counter.notificationSound;
      _userSelectedCustomIcon = true;
    } else {
      // Use default counter type from settings
      final settings = ref.read(settingsProvider);
      _type = settings.defaultCounterType;
      _color = settings.accentColor;
    }
  }

  void _applyEventPreset(({String label, String title, IconData icon, Color color, CounterRepeatInterval repeat, String sound}) preset) {
    setState(() {
      _titleController.text = preset.title;
      _icon = preset.icon;
      _color = preset.color;
      _repeatInterval = preset.repeat;
      _notificationSound = preset.sound;
      _enableNotification = true;
      _userSelectedCustomIcon = true;
    });
  }

  void _onTitleChanged(String text) {
    setState(() {});
    if (_userSelectedCustomIcon) return;
    final lower = text.toLowerCase().trim();
    if (lower.contains('wedding') || lower.contains('marriage')) {
      setState(() {
        _icon = Icons.favorite_rounded;
        _color = const Color(0xFFFF70A6);
        _repeatInterval = CounterRepeatInterval.yearly;
        _notificationSound = 'celebration';
        _enableNotification = true;
      });
    } else if (lower.contains('baby') || lower.contains('birth') || lower.contains('due date') || lower.contains('newborn') || lower.contains('pregnant')) {
      setState(() {
        _icon = Icons.child_care_rounded;
        _color = const Color(0xFF5AA9FF);
        _notificationSound = 'chime';
        _enableNotification = true;
      });
    } else if (lower.contains('work anniversary') || lower.contains('job anniversary') || lower.contains('tenure')) {
      setState(() {
        _icon = Icons.workspace_premium_rounded;
        _color = const Color(0xFFFFD400);
        _repeatInterval = CounterRepeatInterval.yearly;
        _enableNotification = true;
      });
    } else if (lower.contains('anniversary')) {
      setState(() {
        _icon = Icons.volunteer_activism_rounded;
        _color = const Color(0xFFFF5252);
        _repeatInterval = CounterRepeatInterval.yearly;
        _notificationSound = 'celebration';
        _enableNotification = true;
      });
    } else if (lower.contains('birthday') || lower.contains('bday')) {
      setState(() {
        _icon = Icons.cake_rounded;
        _color = const Color(0xFFFFA000);
        _repeatInterval = CounterRepeatInterval.yearly;
        _notificationSound = 'celebration';
        _enableNotification = true;
      });
    } else if (lower.contains('vacation') || lower.contains('trip') || lower.contains('flight') || lower.contains('holiday')) {
      setState(() {
        _icon = Icons.flight_takeoff_rounded;
        _color = const Color(0xFF00E5FF);
        _notificationSound = 'chime';
        _enableNotification = true;
      });
    } else if (lower.contains('exam') || lower.contains('graduat') || lower.contains('college') || lower.contains('school')) {
      setState(() {
        _icon = Icons.school_rounded;
        _color = const Color(0xFF8B5CF6);
        _enableNotification = true;
      });
    }
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _targetDate.isBefore(today) ? today : _targetDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _targetDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _targetDate.hour,
        _targetDate.minute,
      );
    });
  }

  Future<void> _pickTargetTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_targetDate),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _targetDate = DateTime(
        _targetDate.year,
        _targetDate.month,
        _targetDate.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _startDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _startDate.hour,
        _startDate.minute,
      );
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDate),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _startDate = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _applyQuickCountdownPreset(Duration duration) {
    setState(() {
      _targetDate = DateTime.now().add(duration);
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final trimmedTitle = _titleController.text.trim();
    final allCounters = ref.read(countersProvider).asData?.value ?? [];
    final hasDuplicate = allCounters.any(
      (c) => c.id != widget.counterId && c.title.toLowerCase().trim() == trimmedTitle.toLowerCase(),
    );
    if (hasDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A counter with title "$trimmedTitle" already exists. Please choose a unique title or use Duplicate.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(countersProvider.notifier);
      final existing = widget.counterId == null
          ? null
          : notifier.findCounter(widget.counterId!);

      final targetVal = _targetValueController.text.trim().isNotEmpty
          ? int.tryParse(_targetValueController.text.trim())
          : null;

      final stepVal = int.tryParse(_stepController.text.trim()) ?? 1;

      final counter = CounterModel(
        id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: trimmedTitle,
        description: _descriptionController.text.trim(),
        type: _type,
        createdAt: existing?.createdAt ?? DateTime.now(),
        startDate: _type == CounterType.countUp ? _startDate : null,
        targetDate: _type == CounterType.countdown ? _targetDate : null,
        currentValue: _type == CounterType.tally
            ? (int.tryParse(_tallyController.text) ?? 0)
            : 0,
        step: stepVal > 0 ? stepVal : 1,
        targetValue: targetVal,
        colorValue: _color.toARGB32(),
        iconCodePoint: _icon.codePoint,
        repeatInterval: _type == CounterType.countdown ? _repeatInterval : CounterRepeatInterval.none,
        repeatCustomValue: _type == CounterType.countdown ? _repeatCustomValue : null,
        enableNotification: _type == CounterType.countdown ? _enableNotification : false,
        notificationTiming: _notificationTiming,
        notificationSound: _notificationSound,
      );

      if (existing == null) {
        await notifier.addCounter(counter);
      } else {
        await notifier.updateCounter(counter);
      }

      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.counterId == null
        ? null
        : ref.read(countersProvider.notifier).findCounter(widget.counterId!);

    _initialize(existing);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.counterId == null ? 'Create Counter' : 'Edit Counter'),
        actions: [
          if (existing != null) ...[
            IconButton(
              tooltip: 'Add / Duplicate widget on Home screen',
              icon: const Icon(Icons.widgets_outlined),
              onPressed: () async {
                final isInstalled = await HomeScreenWidgetService.isCounterWidgetInstalled(existing.id);
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
                        'A home screen widget for "${existing.title}" is already active on your launcher.\n\nDo you want to add another (duplicate) widget for this counter?',
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
                final added = await HomeScreenWidgetService.requestPinWidget(existing);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      added
                          ? 'Widget ready! Choose where to place it.'
                          : 'Widget pinning is unavailable. Add it from your launcher widgets panel.',
                    ),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Duplicate counter',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () async {
                final clone = await ref.read(countersProvider.notifier).duplicateCounter(existing.id);
                if (clone != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Duplicated as "${clone.title}"'),
                    ),
                  );
                  context.pop();
                }
              },
            ),
          ],
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
          children: [
            // Preview Card
            _buildLivePreview(),

            const SizedBox(height: 24),

            // Counter Type Selector
            const Text(
              'COUNTER TYPE',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            SegmentedButton<CounterType>(
              segments: const [
                ButtonSegment(
                  value: CounterType.countdown,
                  icon: Icon(Icons.hourglass_bottom),
                  label: Text('Countdown'),
                ),
                ButtonSegment(
                  value: CounterType.countUp,
                  icon: Icon(Icons.history),
                  label: Text('Count up'),
                ),
                ButtonSegment(
                  value: CounterType.tally,
                  icon: Icon(Icons.add_circle_outline),
                  label: Text('Tally'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() => _type = selection.first);
              },
            ),

            const SizedBox(height: 20),

            // Quick Event Selection Presets
            const Text(
              'EVENT PRESETS',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickEventPresets.map((preset) {
                  final isSelected = _titleController.text.trim().toLowerCase() == preset.title.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(preset.icon, size: 16, color: preset.color),
                      label: Text(preset.label),
                      backgroundColor: isSelected ? preset.color.withValues(alpha: 0.2) : null,
                      side: BorderSide(color: isSelected ? preset.color : Colors.white12),
                      onPressed: () => _applyEventPreset(preset),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Title & Description
            TextFormField(
              controller: _titleController,
              onChanged: _onTitleChanged,
              decoration: InputDecoration(
                labelText: 'Counter title',
                hintText: 'e.g. Wedding, Baby Arrival, Anniversary',
                prefixIcon: Icon(_icon, color: _color),
              ),
              validator: (v) {
                final trimmed = v?.trim() ?? '';
                if (trimmed.isEmpty) return 'Please enter a title';
                final counters = ref.read(countersProvider).asData?.value ?? [];
                final isDuplicate = counters.any(
                  (c) => c.id != widget.counterId && c.title.toLowerCase().trim() == trimmed.toLowerCase(),
                );
                if (isDuplicate) {
                  return 'A counter with this title already exists. Use Duplicate to make a copy.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Notes / description (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            // Date / Time Settings based on Type
            if (_type == CounterType.countdown) ...[
              const Text(
                'TARGET DATE & TIME',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: const Text('Target Date'),
                      subtitle: Text(DateFormat.yMMMMEEEEd().format(_targetDate)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickTargetDate,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Target Time'),
                      subtitle: Text(TimeOfDay.fromDateTime(_targetDate).format(context)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickTargetTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Quick presets
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('+1 Day'),
                    onPressed: () => _applyQuickCountdownPreset(const Duration(days: 1)),
                  ),
                  ActionChip(
                    label: const Text('+1 Week'),
                    onPressed: () => _applyQuickCountdownPreset(const Duration(days: 7)),
                  ),
                  ActionChip(
                    label: const Text('+1 Month'),
                    onPressed: () => _applyQuickCountdownPreset(const Duration(days: 30)),
                  ),
                  ActionChip(
                    label: const Text('New Year'),
                    onPressed: () {
                      final now = DateTime.now();
                      setState(() {
                        _targetDate = DateTime(now.year + 1, 1, 1);
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Event Repeat / Recurrence Options
              const Text(
                'REPEAT EVENT',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.repeat_rounded, size: 20, color: _color),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recurrence / Rollover Interval',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'Rolls over automatically to next cycle after event passes',
                                  style: TextStyle(fontSize: 11, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CounterRepeatInterval>(
                        initialValue: _repeatInterval,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.sync_rounded),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: CounterRepeatInterval.none, child: Text('Never (One-time Event)')),
                          DropdownMenuItem(value: CounterRepeatInterval.hourly, child: Text('Every Hour')),
                          DropdownMenuItem(value: CounterRepeatInterval.twiceDaily, child: Text('Twice Daily (Every 12 Hours)')),
                          DropdownMenuItem(value: CounterRepeatInterval.thriceDaily, child: Text('Thrice Daily (Every 8 Hours)')),
                          DropdownMenuItem(value: CounterRepeatInterval.customHours, child: Text('Custom Hours (Every X Hours)')),
                          DropdownMenuItem(value: CounterRepeatInterval.daily, child: Text('Daily (Every Day)')),
                          DropdownMenuItem(value: CounterRepeatInterval.weekly, child: Text('Weekly (Every 7 Days)')),
                          DropdownMenuItem(value: CounterRepeatInterval.monthly, child: Text('Monthly')),
                          DropdownMenuItem(value: CounterRepeatInterval.yearly, child: Text('Yearly (Anniversary / Birthday)')),
                          DropdownMenuItem(value: CounterRepeatInterval.customDays, child: Text('Custom Days (Every X Days)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _repeatInterval = val);
                        },
                      ),
                      if (_repeatInterval == CounterRepeatInterval.customHours || _repeatInterval == CounterRepeatInterval.customDays) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              _repeatInterval == CounterRepeatInterval.customHours
                                  ? 'Repeat Interval (Hours):'
                                  : 'Repeat Interval (Days):',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const Spacer(),
                            IconButton.filledTonal(
                              onPressed: _repeatCustomValue > 1
                                  ? () => setState(() => _repeatCustomValue--)
                                  : null,
                              icon: const Icon(Icons.remove, size: 16),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '$_repeatCustomValue',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed: () => setState(() => _repeatCustomValue++),
                              icon: const Icon(Icons.add, size: 16),
                            ),
                          ],
                        ),
                      ],
                      if (_repeatInterval == CounterRepeatInterval.yearly) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: _color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ideal for Wedding, Birthday & Work Anniversaries. Automatically resets to next year!',
                                  style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_repeatInterval != CounterRepeatInterval.none) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.autorenew_rounded, size: 16, color: Colors.blueAccent),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Smart recurrence active: counter automatically advances to next cycle after expiration.',
                                  style: TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Notifications and Sounds Option
              const Text(
                'NOTIFICATIONS & SOUNDS',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: _enableNotification,
                      activeThumbColor: _color,
                      title: const Text(
                        'Event Reminder Notification',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Get notified with alarm sound on or before the event',
                        style: TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                      secondary: Icon(
                        Icons.notifications_active_rounded,
                        color: _enableNotification ? _color : Colors.white38,
                      ),
                      onChanged: (val) {
                        setState(() => _enableNotification = val);
                      },
                    ),
                    if (_enableNotification) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'REMINDER TIMING',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white60),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _notificationTiming,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.access_time_rounded),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'atEvent', child: Text('At exact time of event')),
                                DropdownMenuItem(value: 'hourBefore', child: Text('1 hour before')),
                                DropdownMenuItem(value: 'dayBefore', child: Text('1 day before (at 9:00 AM)')),
                                DropdownMenuItem(value: 'weekBefore', child: Text('1 week before')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _notificationTiming = val);
                              },
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'NOTIFICATION SOUND / ALERT',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white60),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _notificationSound,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.music_note_rounded),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'default', child: Text('🔔 Default Notification Sound')),
                                DropdownMenuItem(value: 'celebration', child: Text('🎉 Celebration & Fanfare')),
                                DropdownMenuItem(value: 'chime', child: Text('🎵 Gentle Chime')),
                                DropdownMenuItem(value: 'bell', child: Text('⏰ Bell / Alarm')),
                                DropdownMenuItem(value: 'silent', child: Text('🔕 Silent (Vibrate Only)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _notificationSound = val);
                              },
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                NotificationService.instance.testNotificationSound(
                                  _notificationSound,
                                  _titleController.text.trim().isEmpty ? 'Event' : _titleController.text.trim(),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Playing sound preview...'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.volume_up_rounded, size: 16),
                              label: const Text('Test Notification Alert Sound'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else if (_type == CounterType.countUp) ...[
              const Text(
                'START DATE & TIME',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.history_toggle_off),
                      title: const Text('Counting Up Since'),
                      subtitle: Text(DateFormat.yMMMMEEEEd().format(_startDate)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickStartDate,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Start Time'),
                      subtitle: Text(TimeOfDay.fromDateTime(_startDate).format(context)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickStartTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Today'),
                    onPressed: () => setState(() => _startDate = DateTime.now()),
                  ),
                  ActionChip(
                    label: const Text('1 Week Ago'),
                    onPressed: () => setState(() => _startDate = DateTime.now().subtract(const Duration(days: 7))),
                  ),
                  ActionChip(
                    label: const Text('30 Days Ago'),
                    onPressed: () => setState(() => _startDate = DateTime.now().subtract(const Duration(days: 30))),
                  ),
                  ActionChip(
                    label: const Text('1 Year Ago'),
                    onPressed: () => setState(() => _startDate = DateTime.now().subtract(const Duration(days: 365))),
                  ),
                ],
              ),
            ] else if (_type == CounterType.tally) ...[
              const Text(
                'TALLY SETTINGS',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tallyController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Initial count',
                        prefixIcon: Icon(Icons.pin),
                      ),
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Enter number' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stepController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Step size',
                        prefixIcon: Icon(Icons.unfold_more),
                      ),
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val <= 0) return 'Must be >= 1';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetValueController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Target goal (optional)',
                  hintText: 'e.g. 100',
                  prefixIcon: Icon(Icons.flag_circle_outlined),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Color Picker
            const Text(
              'ACCENT COLOR',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _presetColors.map((color) {
                  final isSelected = _color.toARGB32() == color.toARGB32();
                
                  return GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 20,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
            ),

            const SizedBox(height: 24),

            // Event Icon Picker
            const Text(
              'RELEVANT EVENT ICON',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            for (final entry in _categorizedIcons.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white54,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((item) {
                  final iconData = item.$1;
                  final label = item.$2;
                  final isSelected = _icon.codePoint == iconData.codePoint;
                  return ChoiceChip(
                    avatar: Icon(
                      iconData,
                      size: 18,
                      color: isSelected ? _color : null,
                    ),
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _icon = iconData;
                        _userSelectedCustomIcon = true;
                      });
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(widget.counterId == null ? 'Create Counter' : 'Save Changes'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: _color,
                foregroundColor: _color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreview() {
    final title = _titleController.text.trim().isEmpty ? 'Preview Counter' : _titleController.text.trim();
    final desc = _descriptionController.text.trim();

    String displayTime;
    if (_type == CounterType.tally) {
      displayTime = _tallyController.text.isEmpty ? '0' : _tallyController.text;
    } else if (_type == CounterType.countdown) {
      final diff = _targetDate.difference(DateTime.now());
      final d = diff.isNegative ? Duration.zero : diff;
      displayTime = '${d.inDays}d  ${d.inHours.remainder(24).toString().padLeft(2, '0')}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    } else {
      final diff = DateTime.now().difference(_startDate);
      final d = diff.isNegative ? Duration.zero : diff;
      displayTime = '${d.inDays}d  ${d.inHours.remainder(24).toString().padLeft(2, '0')}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _color.withValues(alpha: 0.2),
                  child: Icon(_icon, color: _color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Wrap(
                        spacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: _color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _type.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _color,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          if (_type == CounterType.countdown && _repeatInterval != CounterRepeatInterval.none)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _repeatInterval.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blueAccent,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          if (_type == CounterType.countdown && _enableNotification)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_active, size: 9, color: Colors.greenAccent),
                                  SizedBox(width: 2),
                                  Text(
                                    'ALARM',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.greenAccent,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              displayTime,
              style: TextStyle(
                fontSize: _type == CounterType.tally ? 32 : 24,
                fontWeight: FontWeight.w800,
                color: _color,
              ),
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
