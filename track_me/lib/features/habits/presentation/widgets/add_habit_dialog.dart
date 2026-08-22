import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/habit_model.dart';
import '../../providers/habits_provider.dart';
import 'habit_emoji_picker_sheet.dart';

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

    // Preset categories map straight onto the dropdown; anything else is a
    // custom name typed under "Others".
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
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // When "Others" is picked, the user's own category name is saved.
    final category = _isCustomCategorySelected
        ? _customCategoryController.text.trim()
        : _selectedCategory;

    final reminderTime = _reminderTime != null
        ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final existing = widget.initialHabit;
    if (existing != null) {
      // Edit mode — carry over the id, creation date and today's logs so the
      // streak/completion state is untouched.
      final updated = HabitModel(
        id: existing.id,
        name: _nameController.text.trim(),
        category: category,
        emoji: _selectedEmoji,
        color: _selectedColor,
        repeatDays: _repeatDays,
        reminderTime: reminderTime,
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

              // Reminder Time
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
                            : 'Set Reminder Time (optional)',
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
