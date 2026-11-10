import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/counter_model.dart';
import '../../providers/counter_provider.dart';
import '../../providers/settings_provider.dart';

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

  static const List<(IconData, String)> _presetIcons = [
    (Icons.flag_rounded, 'Flag'),
    (Icons.celebration_rounded, 'Party'),
    (Icons.cake_rounded, 'Birthday'),
    (Icons.favorite_rounded, 'Love'),
    (Icons.flight_takeoff_rounded, 'Travel'),
    (Icons.fitness_center_rounded, 'Workout'),
    (Icons.local_drink_rounded, 'Water'),
    (Icons.school_rounded, 'Study'),
    (Icons.work_rounded, 'Work'),
    (Icons.savings_rounded, 'Finance'),
    (Icons.smoke_free_rounded, 'Habit'),
    (Icons.code_rounded, 'Coding'),
    (Icons.alarm_rounded, 'Alarm'),
    (Icons.star_rounded, 'Goal'),
    (Icons.pets_rounded, 'Pet'),
    (Icons.sports_esports_rounded, 'Game'),
  ];

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
    } else {
      // Use default counter type from settings
      final settings = ref.read(settingsProvider);
      _type = settings.defaultCounterType;
      _color = settings.accentColor;
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
    if (!_formKey.currentState!.validate()) return;

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
      title: _titleController.text.trim(),
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
    );

    if (existing == null) {
      await notifier.addCounter(counter);
    } else {
      await notifier.updateCounter(counter);
    }

    if (mounted) context.pop();
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
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
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

            // Title & Description
            TextFormField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Counter title',
                hintText: 'e.g. Next Vacation, Days Sober, Reading Goal',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
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

            // Icon Picker
            const Text(
              'ICON',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetIcons.map((item) {
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
                  onSelected: (_) => setState(() => _icon = iconData),
                );
              }).toList(),
            ),

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
