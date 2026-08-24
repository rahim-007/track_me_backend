import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/habit_model.dart';
import '../../providers/missed_habits_provider.dart';

/// Full-screen mandatory reflection dialog.
/// Cannot be dismissed via back button or barrier tap.
/// User must enter ≥5 chars for every missed habit before continuing.
class MissedHabitsReflectionDialog extends ConsumerStatefulWidget {
  final List<HabitModel> missedHabits;
  final VoidCallback onSubmitted;

  const MissedHabitsReflectionDialog({
    super.key,
    required this.missedHabits,
    required this.onSubmitted,
  });

  @override
  ConsumerState<MissedHabitsReflectionDialog> createState() =>
      _MissedHabitsReflectionDialogState();
}

class _MissedHabitsReflectionDialogState
    extends ConsumerState<MissedHabitsReflectionDialog>
    with SingleTickerProviderStateMixin {
  late final List<MissedHabitEntry> _entries;
  late final List<TextEditingController> _controllers;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _isSubmitting = false;
  bool _showMotivation = false;

  @override
  void initState() {
    super.initState();
    _entries = widget.missedHabits
        .map((h) => MissedHabitEntry(habit: h))
        .toList();
    _controllers = List.generate(
      _entries.length,
      (_) => TextEditingController(),
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _allValid => _entries.every((e) => e.isValid);

  Future<void> _submit() async {
    if (!_allValid || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Get userId from secure storage
    const storage = FlutterSecureStorage();
    final userId = await storage.read(key: AppConstants.userIdKey) ?? '';

    final success = await ref.read(missedReasonsNotifierProvider.notifier).saveReasons(
          entries: _entries,
          userId: userId,
        );

    if (!mounted) return;

    if (success) {
      // Show brief motivational message before closing
      setState(() {
        _showMotivation = true;
        _isSubmitting = false;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        widget.onSubmitted();
      }
    } else {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save reasons. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope prevents back-button dismissal
    return PopScope(
      canPop: false,
      child: Dialog.fullscreen(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: _showMotivation
                  ? _MotivationView()
                  : _ReflectionContent(
                      entries: _entries,
                      controllers: _controllers,
                      allValid: _allValid,
                      isSubmitting: _isSubmitting,
                      onChanged: (i, text) {
                        setState(() {
                          _entries[i].reason = text;
                        });
                      },
                      onSubmit: _submit,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Reflection content ───────────────────────────────────────────────────────

class _ReflectionContent extends StatelessWidget {
  final List<MissedHabitEntry> entries;
  final List<TextEditingController> controllers;
  final bool allValid;
  final bool isSubmitting;
  final void Function(int index, String text) onChanged;
  final VoidCallback onSubmit;

  const _ReflectionContent({
    required this.entries,
    required this.controllers,
    required this.allValid,
    required this.isSubmitting,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Header ──
          _Header(habitCount: entries.length),

          // ── Scrollable habit cards ──
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _HabitReasonCard(
                entry: entries[i],
                controller: controllers[i],
                index: i,
                onChanged: (text) => onChanged(i, text),
              ),
            ),
          ),

          // ── Submit button ──
          _SubmitButton(
            allValid: allValid,
            isSubmitting: isSubmitting,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int habitCount;
  const _Header({required this.habitCount});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D1E54), const Color(0xFF1F1D2B)]
              : [const Color(0xFFF3E8FF), const Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Illustration emoji
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Text('📝', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Yesterday's Reflection",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFDDD6FE) : const Color(0xFF4C1D95),
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You missed ${habitCount == 1 ? 'a habit' : '$habitCount habits'} yesterday.\nTake a moment to reflect before continuing.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '✨ Every missed habit is a chance to improve.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primary.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Individual habit reason card ─────────────────────────────────────────────

class _HabitReasonCard extends StatefulWidget {
  final MissedHabitEntry entry;
  final TextEditingController controller;
  final int index;
  final ValueChanged<String> onChanged;

  const _HabitReasonCard({
    required this.entry,
    required this.controller,
    required this.index,
    required this.onChanged,
  });

  @override
  State<_HabitReasonCard> createState() => _HabitReasonCardState();
}

class _HabitReasonCardState extends State<_HabitReasonCard> {
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() => _charCount = widget.controller.text.length);
      widget.onChanged(widget.controller.text);
    });
  }

  bool get _isValid => _charCount >= 5;
  bool get _isTooLong => _charCount > 250;

  @override
  Widget build(BuildContext context) {
    final habit = widget.entry.habit;
    final emoji = habit.emoji ?? '📋';
    final isDark = AppColors.isDarkMode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isValid
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.border,
          width: _isValid ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Habit name row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.cancel_outlined,
                              size: 12, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            'Not completed yesterday',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.redAccent.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isValid)
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 22),
              ],
            ),

            const SizedBox(height: 14),

            // Reason label
            Text(
              'Why couldn\'t you complete this habit?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            // Text field
            TextField(
              controller: widget.controller,
              maxLines: 3,
              maxLength: 250,
              buildCounter: (_,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null, // Hide default counter
              decoration: InputDecoration(
                hintText: 'e.g. Was busy with work and came home late...',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
              ),
              style: TextStyle(fontSize: 14, color: AppColors.onSurface),
            ),

            const SizedBox(height: 6),

            // Character count + validation hint
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _charCount < 5
                      ? '${5 - _charCount} more characters needed'
                      : _isTooLong
                          ? 'Too long (max 250)'
                          : '✓ Looks good!',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isTooLong
                        ? Colors.red
                        : _isValid
                            ? AppColors.success
                            : AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$_charCount / 250',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isTooLong ? Colors.red : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Submit button ────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final bool allValid;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _SubmitButton({
    required this.allValid,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!allValid)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Fill in all reasons (min. 5 characters each) to continue',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: allValid && !isSubmitting ? onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: allValid
                      ? AppColors.primary
                      : (isDark ? const Color(0xFF2D2A3A) : const Color(0xFFD1D5DB)),
                  foregroundColor: Colors.white,
                  elevation: allValid ? 4 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save & Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Motivation view (shown after submit) ─────────────────────────────────────

class _MotivationView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 24),
            Text(
              'Reflection completed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Every setback is a chance to grow.\nLet\'s make today count! 🌟',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
