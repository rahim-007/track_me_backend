import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — Purple
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color primaryContainer = Color(0xFFEDE9FE);
  static const Color onPrimaryContainer = Color(0xFF4C1D95);

  // Secondary — Cyan
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryContainer = Color(0xFFCFFAFE);

  // Accent — Indigo
  static const Color accent = Color(0xFF6366F1);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Surfaces
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8F7FF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color surfaceElevated = Color(0xFFF9FAFB);

  // Text
  static const Color onSurface = Color(0xFF111827);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);

  // Borders & Dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Habit Category Colors
  static const Color habitHealth = Color(0xFF10B981);
  static const Color habitFitness = Color(0xFFF59E0B);
  static const Color habitLearning = Color(0xFF3B82F6);
  static const Color habitMindfulness = Color(0xFF8B5CF6);
  static const Color habitProductivity = Color(0xFF6366F1);
  static const Color habitSocial = Color(0xFFEC4899);
  static const Color habitFinance = Color(0xFF059669);
  static const Color habitOther = Color(0xFF6B7280);

  // Goal Priority Colors
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF10B981);

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
