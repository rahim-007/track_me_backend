import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/habit_model.dart';
import '../../providers/habits_provider.dart';
import 'habit_emoji_picker_sheet.dart';
import 'interval_custom_picker_sheet.dart';

class AddHabitDialog extends ConsumerStatefulWidget {
  const AddHabitDialog({super.key, this.initialHabit});

  /// When provided, the dialog edits this habit (pre-filled fields) instead
  /// of creating a new one.
  final HabitModel? initialHabit;

  @override
  ConsumerState<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends ConsumerState<AddHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _customCategoryController = TextEditingController();

  String _selectedCategory = AppConstants.habitCategories.first;
  String _selectedEmoji = '💪';
  String _selectedColor = AppConstants.habitColors.first;
  List<bool> _repeatDays = List.filled(7, true);
  TimeOfDay? _reminderTime;
  bool _isLoading = false;

  // Interval reminder fields
  bool _isInterval = false;
  TimeOfDay _windowStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _windowEndTime = const TimeOfDay(hour: 22, minute: 0);
  int _intervalMinutes = 60;
  final _targetValueController = TextEditingController();
  String _selectedUnit = 'ml';
  bool _rollingInterval = false;

  bool get _isCustomCategorySelected =>
      _selectedCategory == AppConstants.habitCustomCategoryLabel;

  @override
  void initState() {
    super.initState();
    final habit = widget.initialHabit;
    if (habit == null) return;

    _nameController.text = habit.name;
    _notesController.text = habit.notes ?? '';
    _selectedEmoji = habit.emoji ?? '💪';
    _selectedColor = AppConstants.habitColors.contains(habit.color)
        ? habit.color!
        : AppConstants.habitColors.first;
    _repeatDays = habit.repeatDays.length == 7
        ? List<bool>.from(habit.repeatDays)
        : List.filled(7, true);

    _isInterval = habit.isInterval;
    _intervalMinutes = habit.intervalMinutes ?? 60;
    _selectedUnit = habit.unit ?? 'ml';
    _rollingInterval = habit.rollingInterval;
    if (habit.targetValue != null) {
      _targetValueController.text = habit.targetValue!.toStringAsFixed(0);
    }

    if (habit.windowStartTime != null) {
      final parts = habit.windowStartTime!.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) _windowStartTime = TimeOfDay(hour: h, minute: m);
      }
    }
    if (habit.windowEndTime != null) {
      final parts = habit.windowEndTime!.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) _windowEndTime = TimeOfDay(hour: h, minute: m);
      }
    }

    if (habit.reminderTime != null) {
      final parts = habit.reminderTime!.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          _reminderTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    final preset = AppConstants.habitCategories
        .where((c) => c.toLowerCase() == habit.category.toLowerCase())
        .toList();
    if (preset.isNotEmpty) {
      _selectedCategory = preset.first;
    } else {
      _selectedCategory = AppConstants.habitCustomCategoryLabel;
      _customCategoryController.text = habit.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _customCategoryController.dispose();
    _targetValueController.dispose();
    super.dispose();
  }

  void _applyPreset({
    required String name,
    required String emoji,
    required String category,
    required String color,
    required int intervalMinutes,
    required TimeOfDay start,
    required TimeOfDay end,
    required String target,
    required String unit,
    bool rolling = false,
  }) {
    setState(() {
      _nameController.text = name;
      _selectedEmoji = emoji;
      _selectedColor = color;
      _selectedCategory = category;
      _isInterval = true;
      _intervalMinutes = intervalMinutes;
      _windowStartTime = start;
      _windowEndTime = end;
      _targetValueController.text = target;
      _selectedUnit = unit;
      _rollingInterval = rolling;
    });
  }

  int get _calculatedSlotsCount {
    final start = _windowStartTime.hour * 60 + _windowStartTime.minute;
    final end = _windowEndTime.hour * 60 + _windowEndTime.minute;
    if (end <= start || _intervalMinutes <= 0) return 0;
    return ((end - start) / _intervalMinutes).floor() + 1;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final category = _isCustomCategorySelected
        ? _customCategoryController.text.trim()
        : _selectedCategory;

    final reminderTime = (!_isInterval && _reminderTime != null)
        ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final windowStartTime = _isInterval
        ? '${_windowStartTime.hour.toString().padLeft(2, '0')}:${_windowStartTime.minute.toString().padLeft(2, '0')}'
        : null;
    final windowEndTime = _isInterval
        ? '${_windowEndTime.hour.toString().padLeft(2, '0')}:${_windowEndTime.minute.toString().padLeft(2, '0')}'
        : null;
    final targetValue = _isInterval
        ? double.tryParse(_targetValueController.text.trim())
        : null;
    final unit = _isInterval ? _selectedUnit : null;

    final existing = widget.initialHabit;
    if (existing != null) {
      final updated = HabitModel(
        id: existing.id,
        name: _nameController.text.trim(),
        category: category,
        emoji: _selectedEmoji,
        color: _selectedColor,
        repeatDays: _repeatDays,
        reminderTime: reminderTime,
        isInterval: _isInterval,
        intervalMinutes: _isInterval ? _intervalMinutes : null,
        windowStartTime: windowStartTime,
        windowEndTime: windowEndTime,
        targetValue: targetValue,
        unit: unit,
        rollingInterval: _isInterval ? _rollingInterval : false,
        currentValueToday: existing.currentValueToday,
        notes: _notesController.text.trim(),
        createdAt: existing.createdAt,
        completedDates: existing.completedDates,
        skippedDates: existing.skippedDates,
      );
      await ref.read(habitsProvider.notifier).updateHabit(updated);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Habit updated successfully!')),
        );
      }
      return;
    }

    final habit = HabitModel(
      id: '',
      name: _nameController.text.trim(),
      category: category,
      emoji: _selectedEmoji,
      color: _selectedColor,
      repeatDays: _repeatDays,
      reminderTime: reminderTime,
      isInterval: _isInterval,
      intervalMinutes: _isInterval ? _intervalMinutes : null,
      windowStartTime: windowStartTime,
      windowEndTime: windowEndTime,
      targetValue: targetValue,
      unit: unit,
      rollingInterval: _isInterval ? _rollingInterval : false,
      currentValueToday: 0.0,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
      completedDates: [],
      skippedDates: [],
    );

    await ref.read(habitsProvider.notifier).addHabit(habit);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Habit added successfully!')),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _openEmojiPicker() async {
    final picked = await HabitEmojiPickerSheet.show(context);
    if (picked != null && picked.isNotEmpty && mounted) {
      setState(() => _selectedEmoji = picked);
    }
  }

  bool get _isCustomInterval =>
      _intervalMinutes != 30 &&
      _intervalMinutes != 60 &&
      _intervalMinutes != 120 &&
      _intervalMinutes != 180 &&
      _intervalMinutes != 240;

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

  Future<void> _openCustomIntervalPicker() async {
    final picked = await IntervalCustomPickerSheet.show(
      context: context,
      initialMinutes: _intervalMinutes,
      windowStartTime: _windowStartTime,
      windowEndTime: _windowEndTime,
    );
    if (picked != null && picked >= 15 && mounted) {
      setState(() => _intervalMinutes = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row
              Row(
                children: [
                  Text(
                    widget.initialHabit != null ? 'Edit Habit' : 'New Habit',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick Presets
              if (widget.initialHabit == null) ...[
                Text(
                  'Quick Presets',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        label: const Text('💧 4L Water (1h)'),
                        backgroundColor: AppColors.surfaceVariant,
                        onPressed: () => _applyPreset(
                          name: 'Drink 4L Water',
                          emoji: '💧',
                          category: 'Health',
                          color: '#06B6D4',
                          intervalMinutes: 60,
                          start: const TimeOfDay(hour: 8, minute: 0),
                          end: const TimeOfDay(hour: 22, minute: 0),
                          target: '4000',
                          unit: 'ml',
                        ),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('💊 Medicine (2h Gap)'),
                        backgroundColor: AppColors.surfaceVariant,
                        onPressed: () => _applyPreset(
                          name: 'Take Medicine',
                          emoji: '💊',
                          category: 'Health',
                          color: '#EF4444',
                          intervalMinutes: 120,
                          start: const TimeOfDay(hour: 8, minute: 0),
                          end: const TimeOfDay(hour: 20, minute: 0),
                          target: '4',
                          unit: 'doses',
                          rolling: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('🏃 Stand & Move (1h)'),
                        backgroundColor: AppColors.surfaceVariant,
                        onPressed: () => _applyPreset(
                          name: 'Stand & Stretch',
                          emoji: '🏃',
                          category: 'Fitness',
                          color: '#10B981',
                          intervalMinutes: 60,
                          start: const TimeOfDay(hour: 9, minute: 0),
                          end: const TimeOfDay(hour: 18, minute: 0),
                          target: '8',
                          unit: 'times',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Name
              AppTextField(
                label: 'Habit Name',
                hint: 'e.g., Morning Run',
                controller: _nameController,
                prefixIcon: Icons.edit_rounded,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),

              const SizedBox(height: 16),

              // Emoji Picker — tap to open the full emoji picker
              Text(
                'Choose Emoji',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              InkWell(
                key: const ValueKey('habit_emoji_selector'),
                onTap: _openEmojiPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedEmoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tap to pick from the full emoji set',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: AppConstants.habitCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedCategory = v ?? _selectedCategory),
              ),

              // Custom category name (only when "Others" is selected)
              if (_isCustomCategorySelected) ...[
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Custom Category',
                  hint: 'e.g., Learning, Productivity, Social',
                  controller: _customCategoryController,
                  prefixIcon: Icons.label_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a category name'
                      : null,
                )
              ],

              const SizedBox(height: 16),

              // Repeat Days
              Text(
                'Repeat',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _repeatDays[i] = !_repeatDays[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _repeatDays[i]
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _repeatDays[i]
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Reminder Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reminder Schedule',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Interval Mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isInterval
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: _isInterval
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: _isInterval,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _isInterval = val;
                            if (val && _targetValueController.text.isEmpty) {
                              _targetValueController.text = '4000';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (!_isInterval) ...[
                // Single Reminder Time
                InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.alarm_rounded,
                            color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _reminderTime != null
                              ? _reminderTime!.format(context)
                              : 'Set Daily Reminder Time (optional)',
                          style: TextStyle(
                            color: _reminderTime != null
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        if (_reminderTime != null)
                          GestureDetector(
                            onTap: () => setState(() => _reminderTime = null),
                            child: Icon(Icons.clear_rounded,
                                size: 16, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Interval Habit Configuration
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Time Window (Start -> End)
                      Text(
                        'Active Window (e.g. 8:00 AM to 10:00 PM)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final p = await showTimePicker(
                                  context: context,
                                  initialTime: _windowStartTime,
                                );
                                if (p != null) {
                                  setState(() => _windowStartTime = p);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.wb_sunny_outlined, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'From: ${_windowStartTime.format(context)}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final p = await showTimePicker(
                                  context: context,
                                  initialTime: _windowEndTime,
                                );
                                if (p != null) {
                                  setState(() => _windowEndTime = p);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.nightlight_round, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'To: ${_windowEndTime.format(context)}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Frequency Gap
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remind Every',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          InkWell(
                            onTap: _openCustomIntervalPicker,
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.tune_rounded,
                                      size: 14, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Customize',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('30 Mins'),
                            selected: _intervalMinutes == 30,
                            onSelected: (_) =>
                                setState(() => _intervalMinutes = 30),
                          ),
                          ChoiceChip(
                            label: const Text('1 Hour'),
                            selected: _intervalMinutes == 60,
                            onSelected: (_) =>
                                setState(() => _intervalMinutes = 60),
                          ),
                          ChoiceChip(
                            label: const Text('2 Hours'),
                            selected: _intervalMinutes == 120,
                            onSelected: (_) =>
                                setState(() => _intervalMinutes = 120),
                          ),
                          ChoiceChip(
                            label: const Text('3 Hours'),
                            selected: _intervalMinutes == 180,
                            onSelected: (_) =>
                                setState(() => _intervalMinutes = 180),
                          ),
                          ChoiceChip(
                            label: const Text('4 Hours'),
                            selected: _intervalMinutes == 240,
                            onSelected: (_) =>
                                setState(() => _intervalMinutes = 240),
                          ),
                          ChoiceChip(
                            avatar: Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: _isCustomInterval
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            label: Text(
                              _isCustomInterval
                                  ? 'Custom (${_formatIntervalBrief(_intervalMinutes)})'
                                  : 'Custom',
                            ),
                            selected: _isCustomInterval,
                            onSelected: (_) => _openCustomIntervalPicker(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Target and Unit
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: AppTextField(
                              label: 'Daily Target',
                              hint: 'e.g. 4000',
                              controller: _targetValueController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedUnit,
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'ml', child: Text('ml')),
                                        DropdownMenuItem(
                                            value: 'L', child: Text('L')),
                                        DropdownMenuItem(
                                            value: 'doses',
                                            child: Text('doses')),
                                        DropdownMenuItem(
                                            value: 'times',
                                            child: Text('times')),
                                        DropdownMenuItem(
                                            value: 'glasses',
                                            child: Text('glasses')),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _selectedUnit = v);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Rolling gap switch for medicine
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text(
                          'Dynamic Rolling Gap (Safe for Medicine)',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Schedules next alarm ${_formatIntervalBrief(_intervalMinutes)} from actual intake time',
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: _rollingInterval,
                        activeColor: AppColors.primary,
                        onChanged: (v) =>
                            setState(() => _rollingInterval = v ?? false),
                      ),

                      // Live preview card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$_calculatedSlotsCount alarms per day (${_windowStartTime.format(context)} to ${_windowEndTime.format(context)}).\nAlarms auto-silence once target is achieved!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Notes
              AppTextField(
                label: 'Notes (optional)',
                hint: 'Any additional notes...',
                controller: _notesController,
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.initialHabit != null
                                  ? 'Save Changes'
                                  : 'Save Habit',
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
