import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/goal_units.dart';
import '../../providers/goals_provider.dart';

class AddGoalDialog extends ConsumerStatefulWidget {
  /// When provided, the dialog runs in edit mode: all fields are pre-filled
  /// with the existing goal's values and saving updates it instead of
  /// creating a new one.
  final GoalModel? goal;

  const AddGoalDialog({super.key, this.goal});

  @override
  ConsumerState<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends ConsumerState<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _notesController = TextEditingController();

  late String _selectedCategory;
  late String _selectedPriority;
  late int _selectedDuration;
  late String _selectedUnit;

  /// True once the user picks a unit themselves, so switching the category
  /// afterwards no longer overwrites their choice.
  bool _unitTouched = false;

  /// Day the goal's plan is being made (today, date-only). Duration and target
  /// date are linked against this: target = start + duration, and a manually
  /// picked date sets the duration back to target − start.
  late DateTime _startDate;
  DateTime? _targetDate;
  bool _isLoading = false;

  bool get _isEditing => widget.goal != null;

  /// Whether the currently selected unit allows fractional values — controls
  /// the target field's keyboard and the characters the user may type.
  bool get _targetAllowsDecimals => unitAllowsDecimals(_selectedUnit);

  TextInputType get _targetKeyboardType => _targetAllowsDecimals
      ? const TextInputType.numberWithOptions(decimal: true)
      : TextInputType.number;

  List<TextInputFormatter> get _targetFormatters => [
        TextInputFormatter.withFunction((oldValue, newValue) {
          final pattern = _targetAllowsDecimals
              ? decimalValuePattern
              : integerValuePattern;
          return pattern.hasMatch(newValue.text) ? newValue : oldValue;
        }),
      ];

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _startDate = GoalModel.dateOnly(DateTime.now());
    _nameController.text = goal?.name ?? '';
    if (goal != null && goal.hasTarget) {
      _targetController.text = formatGoalValue(goal.target);
    }
    _notesController.text = goal?.notes ?? '';
    _selectedCategory =
        goal?.category ?? AppConstants.goalCategories.first;
    _selectedPriority = goal?.priority ?? 'Medium';
    _selectedDuration =
        goal?.durationDays ?? AppConstants.goalDurations.first;
    // Only accept units the picker knows about (defensive: a stray legacy
    // value would otherwise crash the DropdownButtonFormField).
    _selectedUnit = goal?.unit ?? '';
    if (_selectedUnit.isNotEmpty &&
        !goalUnits.any((u) => u.symbol == _selectedUnit)) {
      _selectedUnit = '';
    }
    if (_selectedUnit.isEmpty) {
      _selectedUnit = defaultUnitForCategory(_selectedCategory);
    }
    // New goals start with a target auto-calculated from the chosen duration;
    // edited goals keep their saved target date until the user changes it.
    _targetDate = goal?.targetDate ??
        GoalModel.targetDateForDuration(_startDate, _selectedDuration);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateTarget(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null; // optional — falls back to name parsing
    final val = double.tryParse(text.replaceAll(',', ''));
    if (val == null) return 'Enter a valid number';
    if (!_targetAllowsDecimals && val != val.roundToDouble()) {
      return _selectedUnit.isEmpty
          ? 'Whole numbers only'
          : 'Whole numbers only for $_selectedUnit';
    }
    if (val <= 0) return 'Must be greater than 0';
    return null;
  }

  Future<void> _pickDate() async {
    final now = GoalModel.dateOnly(DateTime.now());
    // Max duration is 365 days, so a target beyond one year is out of scope.
    final last = GoalModel.targetDateForDuration(now, 365);
    // Keep the picker valid: initialDate must fall inside [firstDate, lastDate]
    // (handles edited goals with a past or very distant target date).
    var initial = _targetDate ?? GoalModel.targetDateForDuration(now, 30);
    if (initial.isBefore(now)) initial = now;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: last,
    );
    if (picked != null) {
      setState(() {
        _targetDate = picked;
        // Manually picking a date keeps the two in sync: the duration becomes
        // target − start (clamped to 1–365, shown as a custom option if it
        // isn't one of the presets).
        _selectedDuration =
            GoalModel.durationForTargetDate(_startDate, picked);
      });
    }
  }

  double get _parsedTarget =>
      double.tryParse(_targetController.text.trim().replaceAll(',', '')) ?? 0.0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final target = _parsedTarget;

    if (_isEditing) {
      final existing = widget.goal!;
      final updatedGoal = GoalModel(
        id: existing.id,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        targetDate: _targetDate!,
        priority: _selectedPriority,
        status: existing.status,
        progress: existing.progress,
        durationDays: _selectedDuration,
        target: target,
        unit: _selectedUnit,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: existing.createdAt,
      );
      await ref.read(goalsProvider.notifier).updateGoal(updatedGoal);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎯 Goal updated successfully!')),
        );
      }
      return;
    }

    final goal = GoalModel(
      id: '',
      name: _nameController.text.trim(),
      category: _selectedCategory,
      targetDate: _targetDate!,
      priority: _selectedPriority,
      status: 'in_progress',
      progress: 0.0,
      durationDays: _selectedDuration,
      target: target,
      unit: _selectedUnit,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    await ref.read(goalsProvider.notifier).addGoal(goal);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎯 Goal added successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorities = ['Low', 'Medium', 'High'];

    return Dialog(
      backgroundColor: AppColors.surface,
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
              Row(
                children: [
                  Text(
                    _isEditing ? 'Edit Goal' : 'New Goal',
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

              AppTextField(
                label: 'Goal Name',
                hint: 'e.g., Run a Marathon',
                controller: _nameController,
                prefixIcon: Icons.flag_rounded,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Goal name is required' : null,
              ),

              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                items: AppConstants.goalCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() {
                  if (v == null) return;
                  _selectedCategory = v;
                  // Auto-suggest a matching unit for the new category unless
                  // the user already chose one explicitly.
                  if (!_unitTouched) {
                    _selectedUnit = defaultUnitForCategory(v);
                  }
                }),
              ),

              const SizedBox(height: 16),

              // Target + Unit — the unit decides the numeric format: measurement
              // units (kg, km, L, hours) accept decimals; count/currency units
              // (books, tasks, ₹) accept whole numbers only.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Target',
                      hint: 'e.g., 5, 50, 0.5',
                      controller: _targetController,
                      keyboardType: _targetKeyboardType,
                      inputFormatters: _targetFormatters,
                      validator: _validateTarget,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 118,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('None'),
                        ),
                        ...goalUnits
                            .map((u) => DropdownMenuItem<String>(
                                  value: u.symbol,
                                  child: Text(
                                    u.symbol,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                      ],
                      onChanged: (v) => setState(() {
                        _selectedUnit = v ?? '';
                        _unitTouched = true;
                      }),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Priority
              Text(
                'Priority',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: priorities.map((p) {
                  final isSelected = _selectedPriority == p;
                  Color color;
                  switch (p) {
                    case 'High':
                      color = AppColors.priorityHigh;
                      break;
                    case 'Medium':
                      color = AppColors.priorityMedium;
                      break;
                    default:
                      color = AppColors.priorityLow;
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPriority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.15)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? color : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              p,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected ? color : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Target Date
              InkWell(
                onTap: _pickDate,
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
                      Icon(Icons.calendar_today_rounded,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _targetDate != null
                            ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                            : 'Target Date *',
                        style: TextStyle(
                          color: _targetDate != null
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Duration (includes 365 Days). Selecting a duration auto-sets
              // the target date to start + duration.
              DropdownButtonFormField<int>(
                value: _selectedDuration,
                decoration: InputDecoration(
                  labelText: 'Duration',
                  helperText:
                      'Selecting a duration sets the target date from today',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                // A manually picked target date may imply a duration that is
                // not one of the presets (e.g. 45 Days) — include it so the
                // dropdown can still display the actual value.
                items: (<int>{...AppConstants.goalDurations, _selectedDuration}
                        .toList()
                      ..sort())
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text('$d ${d == 1 ? 'Day' : 'Days'}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  if (v == null) return;
                  _selectedDuration = v;
                  _targetDate =
                      GoalModel.targetDateForDuration(_startDate, v);
                }),
              ),

              const SizedBox(height: 16),

              AppTextField(
                label: 'Notes (optional)',
                hint: 'Any additional notes...',
                controller: _notesController,
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 24),

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
                          : Text(_isEditing ? 'Update Goal' : 'Save Goal'),
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
