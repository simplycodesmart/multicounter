import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/counter_model.dart';

class CounterCard extends StatelessWidget {
  const CounterCard({
    super.key,
    required this.counter,
    this.onTap,
    this.onDelete,
    this.onIncrement,
    this.onDecrement,
    this.onReset,
    this.onAddWidget,
    this.haptic = true,
  });

  final CounterModel counter;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onReset;
  final VoidCallback? onAddWidget;
  final bool haptic;

  void _vibrate() {
    if (haptic) {
      HapticFeedback.selectionClick();
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Counter?'),
        content: Text('Are you sure you want to delete "${counter.title}"? This cannot be undone.'),
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
            onPressed: () {
              Navigator.of(ctx).pop();
              _vibrate();
              onDelete?.call();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = counter.duration;
    final isDone = counter.isCompleted;
    final theme = Theme.of(context);

    final timeString = counter.type == CounterType.tally
        ? '${counter.currentValue}'
        : '${d.inDays}d  ${d.inHours.remainder(24).toString().padLeft(2, '0')}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Icon, Title, Type, and Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: counter.color.withValues(alpha: 0.2),
                    child: Icon(counter.icon, color: counter.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          counter.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: counter.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                counter.type == CounterType.countdown
                                    ? 'COUNTDOWN'
                                    : counter.type == CounterType.countUp
                                        ? 'COUNT UP'
                                        : 'TALLY',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: counter.color,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            if (isDone) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'COMPLETED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.greenAccent,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onAddWidget != null)
                    IconButton(
                      tooltip: 'Add widget to Home screen',
                      onPressed: () {
                        _vibrate();
                        onAddWidget?.call();
                      },
                      icon: const Icon(Icons.widgets_outlined, size: 20),
                    ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Delete counter',
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline, size: 20),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Main Value / Duration Display
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: counter.type == CounterType.tally ? 34 : 26,
                      fontWeight: FontWeight.w800,
                      color: isDone ? Colors.greenAccent : counter.color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (counter.type == CounterType.tally && counter.targetValue != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '/ ${counter.targetValue}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),

              // Progress Bar if applicable
              if (counter.progress != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: counter.progress,
                    backgroundColor: counter.color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? Colors.greenAccent : counter.color,
                    ),
                    minHeight: 5,
                  ),
                ),
              ],

              // Subtitle / Date details
              const SizedBox(height: 6),
              if (counter.type == CounterType.countdown && counter.targetDate != null)
                Text(
                  'Target: ${DateFormat.yMMMd().add_jm().format(counter.targetDate!)}',
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                )
              else if (counter.type == CounterType.countUp)
                Text(
                  'Since: ${DateFormat.yMMMd().add_jm().format(counter.effectiveStartDate)}',
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                ),

              if (counter.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  counter.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],

              // Interactive controls for Tally Counter
              if (counter.type == CounterType.tally) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onReset != null && counter.currentValue > 0)
                      IconButton.outlined(
                        tooltip: 'Reset tally',
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: () {
                          _vibrate();
                          onReset?.call();
                        },
                      ),
                    const SizedBox(width: 8),
                    if (onDecrement != null)
                      IconButton.filledTonal(
                        tooltip: 'Decrease (-${counter.step})',
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: counter.currentValue <= 0
                            ? null
                            : () {
                                _vibrate();
                                onDecrement?.call();
                              },
                      ),
                    const SizedBox(width: 8),
                    if (onIncrement != null)
                      FilledButton.icon(
                        onPressed: () {
                          _vibrate();
                          onIncrement?.call();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(counter.step > 1 ? '+${counter.step}' : '+1'),
                        style: FilledButton.styleFrom(
                          backgroundColor: counter.color,
                          foregroundColor: counter.color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
