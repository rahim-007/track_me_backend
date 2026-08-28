import 'package:flutter/material.dart';

/// Centralized adaptive color system for Premium Minimal Claymorphism (Dark + Light Mode).
class AppColors {
  AppColors._();

  static bool isDarkMode = true;

  // ─── Light Mode Foundations ──────────────────────────────────────────────────
  static const Color _lightEnvironment = Color(0xFFF8F9FD);
  static const Color _lightEnvironmentSecondary = Color(0xFFF0EEF8);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color _lightSurfaceInset = Color(0xFFF1EFF8);

  static const Color _lightTextPrimary = Color(0xFF1E1B39);
  static const Color _lightTextSecondary = Color(0xFF718096);
  static const Color _lightTextMuted = Color(0xFFA0AEC0);
  static const Color _lightTextDisabled = Color(0xFFCBD5E0);

  // ─── Dark Mode Foundations ───────────────────────────────────────────────────
  static const Color _darkEnvironment = Color(0xFF111118);
  static const Color _darkEnvironmentSecondary = Color(0xFF16161F);
  static const Color _darkSurface = Color(0xFF1A1A24);
  static const Color _darkSurfaceElevated = Color(0xFF222230);
  static const Color _darkSurfaceInset = Color(0xFF0D0D14);

  static const Color _darkTextPrimary = Color(0xFFEDEDF4);
  static const Color _darkTextSecondary = Color(0xFF8A899A);
  static const Color _darkTextMuted = Color(0xFF5E5D6E);
  static const Color _darkTextDisabled = Color(0xFF3E3D4E);

  // ─── Dynamic Adaptive Getters ────────────────────────────────────────────────
  static Color get background => isDarkMode ? _darkEnvironment : _lightEnvironment;
  static Color get environmentSecondary => isDarkMode ? _darkEnvironmentSecondary : _lightEnvironmentSecondary;
  static Color get surfaceColor => isDarkMode ? _darkSurface : _lightSurface;
  static Color get surfaceElevatedColor => isDarkMode ? _darkSurfaceElevated : _lightSurfaceElevated;
  static Color get surfaceInset => isDarkMode ? _darkSurfaceInset : _lightSurfaceInset;

  static Color get surface => surfaceColor;
  static Color get surfaceElevated => surfaceElevatedColor;
  static Color get surfaceVariant => surfaceElevatedColor;

  // ─── Primary Foundations (Static across Light & Dark Mode) ───────────────────
  static const Color primary = Color(0xFF6E49E6);
  static const Color primaryDark = Color(0xFF5334B8);
  static const Color primaryLight = Color(0xFF8B6EF5);

  static Color get primaryContainer => isDarkMode ? const Color(0x286E49E6) : const Color(0x1A6E49E6);
  static Color get onPrimaryContainer => isDarkMode ? const Color(0xFFC4B5FD) : const Color(0xFF5334B8);

  static Color get secondary => primaryLight;
  static Color get secondaryContainer => isDarkMode ? const Color(0x1A8B6EF5) : const Color(0x166E49E6);
  static Color get accent => primary;

  // ─── Text Palette ────────────────────────────────────────────────────────────
  static Color get textPrimaryColor => isDarkMode ? _darkTextPrimary : _lightTextPrimary;
  static Color get textSecondaryColor => isDarkMode ? _darkTextSecondary : _lightTextSecondary;
  static Color get textMutedColor => isDarkMode ? _darkTextMuted : _lightTextMuted;
  static Color get textDisabledColor => isDarkMode ? _darkTextDisabled : _lightTextDisabled;

  static Color get onSurface => textPrimaryColor;
  static Color get textPrimary => textPrimaryColor;
  static Color get textSecondary => textSecondaryColor;
  static Color get textHint => textMutedColor;
  static Color get textDisabled => textDisabledColor;

  // ─── Semantic Colors (Muted & Premium) ───────────────────────────────────────
  static const Color _successDark = Color(0xFF4ADE80);
  static const Color _successLightColor = Color(0xFF22C55E);
  static Color get success => isDarkMode ? _successDark : _successLightColor;
  static Color get successLight => isDarkMode ? const Color(0x224ADE80) : const Color(0x1A22C55E);

  static const Color _warningDark = Color(0xFFE8A84E);
  static const Color _warningLightColor = Color(0xFFD4883A);
  static Color get warning => isDarkMode ? _warningDark : _warningLightColor;
  static Color get warningLight => isDarkMode ? const Color(0x22E8A84E) : const Color(0x1AD4883A);

  static const Color _dangerDark = Color(0xFFE06B6B);
  static const Color _dangerLightColor = Color(0xFFC95252);
  static Color get error => isDarkMode ? _dangerDark : _dangerLightColor;
  static Color get errorLight => isDarkMode ? const Color(0x22E06B6B) : const Color(0x1AC95252);

  static const Color _infoDark = Color(0xFF6BA4E0);
  static const Color _infoLightColor = Color(0xFF4580C4);
  static Color get info => isDarkMode ? _infoDark : _infoLightColor;
  static Color get infoLight => isDarkMode ? const Color(0x226BA4E0) : const Color(0x1A4580C4);

  // ─── Claymorphism Surface Tokens ──────────────────────────────────────────────
  /// Subtle inner highlight for clay surfaces (top-left light catch)
  static Color get clayHighlight => isDarkMode
      ? const Color(0x12FFFFFF)
      : const Color(0x60FFFFFF);

  /// Ambient light shadow (clay depth — bottom-right)
  static Color get clayShadowDark => isDarkMode
      ? const Color(0x80000000)
      : const Color(0x18000000);

  /// Ambient light shadow (clay lift — top-left)
  static Color get clayShadowLight => isDarkMode
      ? const Color(0x0AFFFFFF)
      : const Color(0x80FFFFFF);

  /// Very subtle border for clay surfaces
  static Color get clayBorder => isDarkMode
      ? const Color(0x0EFFFFFF)
      : const Color(0x08000000);

  // ─── Bevels, Borders & Legacy Compat ──────────────────────────────────────────
  static Color get topBevelHighlight => clayHighlight;
  static Color get bottomBevelShade => clayShadowDark;
  static Color get borderLine => clayBorder;

  static Color get border => borderLine;
  static Color get divider => isDarkMode ? const Color(0x0EFFFFFF) : const Color(0x08000000);

  static const List<Color> primaryGradientColors = [
    Color(0xFF5334EA),
    Color(0xFF7551FF),
  ];

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: primaryGradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static List<Color> get cardGradientColors => isDarkMode
      ? [const Color(0xFF1E1E2C), const Color(0xFF1A1A24)]
      : [const Color(0xFFFCFBFF), const Color(0xFFF6F4FC)];

  static List<Color> get progressCardGradient => isDarkMode
      ? [const Color(0xFF1E1A30), const Color(0xFF161224)]
      : [const Color(0xFFF0ECFF), const Color(0xFFEAE4FC)];

  static List<Color> get streakCardGradient => isDarkMode
      ? [const Color(0xFF261E14), const Color(0xFF1C160E)]
      : [const Color(0xFFFFF6EC), const Color(0xFFFEEEDA)];

  static Color get streakText => warning;
  static Color get navBackground => isDarkMode ? const Color(0xF01A1A24) : const Color(0xF0F8F7FC);

  // Priority Colors (Goals)
  static Color get priorityHigh => error;
  static Color get priorityMedium => warning;
  static Color get priorityLow => success;

  // Habit Category Colors
  static Color get habitHealth => success;
  static Color get habitWork => primary;
  static Color get habitLearning => info;
  static Color get habitFinance => warning;
}
