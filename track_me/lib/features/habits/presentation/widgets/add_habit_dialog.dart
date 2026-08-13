import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/habit_model.dart';
import '../../providers/habits_provider.dart';

class AddHabitDialog extends ConsumerStatefulWidget {
  const AddHabitDialog({super.key});

  @override
  ConsumerState<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends ConsumerState<AddHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = AppConstants.habitCategories.first;
  String _selectedEmoji = AppConstants.habitEmojis.first;
  String _selectedColor = AppConstants.habitColors.first;
  List<bool> _repeatDays = List.filled(7, true);
  TimeOfDay? _reminderTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final habit = HabitModel(
      id: '',
      name: _nameController.text.trim(),
      category: _selectedCategory,
      emoji: _selectedEmoji,
      color: _selectedColor,
      repeatDays: _repeatDays,
      reminderTime: _reminderTime != null
          ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
          : null,
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
                    'New Habit',
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

              // Emoji Picker
              Text(
                'Choose Emoji',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppConstants.habitEmojis.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final emoji = AppConstants.habitEmojis[i];
                    final selected = emoji == _selectedEmoji;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedEmoji = emoji),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryContainer
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    );
                  },
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
                    onTap: () => setState(() => _repeatDays[i] = !_repeatDays[i]),
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
                          : const Text('Save Habit'),
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
