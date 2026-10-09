import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Modal bottom sheet allowing users to customize habit reminder intervals
/// using an interactive wheel scroller (Hours and Minutes) or quick presets.
class IntervalCustomPickerSheet extends StatefulWidget {
  const IntervalCustomPickerSheet({
    super.key,
    required this.initialMinutes,
    this.windowStartTime,
    this.windowEndTime,
  });

  final int initialMinutes;
  final TimeOfDay? windowStartTime;
  final TimeOfDay? windowEndTime;

  /// Displays the interval picker sheet and returns the selected interval in
  /// minutes, or `null` if dismissed without confirming.
  static Future<int?> show({
    required BuildContext context,
    required int initialMinutes,
    TimeOfDay? windowStartTime,
    TimeOfDay? windowEndTime,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IntervalCustomPickerSheet(
        initialMinutes: initialMinutes,
        windowStartTime: windowStartTime,
        windowEndTime: windowEndTime,
      ),
    );
  }

  @override
  State<IntervalCustomPickerSheet> createState() =>
      _IntervalCustomPickerSheetState();
}

class _IntervalCustomPickerSheetState extends State<IntervalCustomPickerSheet> {
  static const List<int> _minuteOptions = [
    0,
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    45,
    50,
    55,
  ];

  static const List<int> _quickPresets = [
    30,
    60,
    120,
    180,
    240,
    300,
    360,
    480,
  ];

  late int _selectedHours;
  late int _selectedMinutes;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    final total = widget.initialMinutes > 0 ? widget.initialMinutes : 60;
    _selectedHours = (total ~/ 60).clamp(0, 24);
    final rawMin = total % 60;

    // Find closest 5-minute step
    int closestMinIndex = 0;
    int minDiff = 999;
    for (int i = 0; i < _minuteOptions.length; i++) {
      final diff = (_minuteOptions[i] - rawMin).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestMinIndex = i;
      }
    }
    _selectedMinutes = _minuteOptions[closestMinIndex];

    _hourController =
        FixedExtentScrollController(initialItem: _selectedHours);
    _minuteController =
        FixedExtentScrollController(initialItem: closestMinIndex);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  int get _totalMinutes => _selectedHours * 60 + _selectedMinutes;
  bool get _isValid => _totalMinutes >= 15;

  int get _calculatedAlarms {
    final start =
        widget.windowStartTime ?? const TimeOfDay(hour: 8, minute: 0);
    final end = widget.windowEndTime ?? const TimeOfDay(hour: 22, minute: 0);
    final startMins = start.hour * 60 + start.minute;
    final endMins = end.hour * 60 + end.minute;
    if (endMins <= startMins || _totalMinutes <= 0) return 0;
    return ((endMins - startMins) / _totalMinutes).floor() + 1;
  }

  String _formatInterval(int minutes) {
    if (minutes % 60 == 0) {
      final h = minutes ~/ 60;
      return '$h ${h == 1 ? "Hour" : "Hours"}';
    } else if (minutes < 60) {
      return '$minutes Mins';
    } else {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return '${h}h ${m}m';
    }
  }

  String _formatIntervalBrief(int minutes) {
    if (minutes % 60 == 0) {
      return '${minutes ~/ 60}h';
    } else if (minutes < 60) {
      return '${minutes}m';
    } else {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return '${h}h ${m}m';
    }
  }

  void _applyPreset(int minutes) {
    final h = (minutes ~/ 60).clamp(0, 24);
    final m = minutes % 60;
    final mIndex = _minuteOptions.indexOf(m);

    setState(() {
      _selectedHours = h;
      _selectedMinutes = mIndex >= 0 ? m : 0;
    });

    if (_hourController.hasClients) {
      _hourController.animateToItem(
        h,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
    if (_minuteController.hasClients && mIndex >= 0) {
      _minuteController.animateToItem(
        mIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final startTime =
        widget.windowStartTime ?? const TimeOfDay(hour: 8, minute: 0);
    final endTime =
        widget.windowEndTime ?? const TimeOfDay(hour: 22, minute: 0);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customize Reminder Gap',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        Text(
                          'Scroll to choose your preferred interval',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick presets pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final preset in _quickPresets) ...[
                      ChoiceChip(
                        label: Text(_formatIntervalBrief(preset)),
                        selected: _totalMinutes == preset,
                        onSelected: (_) => _applyPreset(preset),
                        selectedColor: AppColors.primary.withOpacity(0.18),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _totalMinutes == preset
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Scroller Wheels (Hours and Minutes)
              Container(
                height: 175,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Hours Picker
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _hourController,
                        itemExtent: 44.0,
                        squeeze: 1.15,
                        useMagnifier: true,
                        magnification: 1.15,
                        selectionOverlay: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.35),
                              width: 1.5,
                            ),
                          ),
                        ),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedHours = index;
                          });
                        },
                        children: List.generate(
                          25,
                          (h) => Center(
                            child: Text(
                              h == 1 ? '1 Hour' : '$h Hours',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _selectedHours == h
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Center separator
                    Container(
                      width: 1,
                      height: 70,
                      color: AppColors.border,
                    ),

                    // Minutes Picker
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _minuteController,
                        itemExtent: 44.0,
                        squeeze: 1.15,
                        useMagnifier: true,
                        magnification: 1.15,
                        selectionOverlay: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.35),
                              width: 1.5,
                            ),
                          ),
                        ),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedMinutes = _minuteOptions[index];
                          });
                        },
                        children: _minuteOptions
                            .map(
                              (m) => Center(
                                child: Text(
                                  '$m Mins',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedMinutes == m
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Dynamic Preview Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isValid
                      ? AppColors.primary.withOpacity(0.08)
                      : Colors.orange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isValid
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isValid
                          ? Icons.notifications_active_rounded
                          : Icons.warning_amber_rounded,
                      color: _isValid ? AppColors.primary : Colors.orange,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isValid
                                ? 'Remind every ${_formatInterval(_totalMinutes)}'
                                : 'Minimum gap is 15 minutes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _isValid
                                  ? AppColors.textPrimary
                                  : Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isValid
                                ? '≈ $_calculatedAlarms alarms per day (${startTime.format(context)} to ${endTime.format(context)})'
                                : 'Please select at least 15 minutes for habit reminders.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isValid
                          ? () => Navigator.pop(context, _totalMinutes)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Set Interval',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
