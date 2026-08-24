import 'package:flutter/material.dart';

/// Centralized adaptive color system for Spatial 3D Design System (Dark + Light Mode).
class AppColors {
  AppColors._();

  static bool isDarkMode = true;

  // ─── Dark Mode Foundations ───────────────────────────────────────────────────
  static const Color _darkEnvironment = Color(0xFF09090D);
  static const Color _darkEnvironmentSecondary = Color(0xFF101117);
  static const Color _darkSurface = Color(0xFF14161E);
  static const Color _darkSurfaceElevated = Color(0xFF1B1E27);
  static const Color _darkSurfaceInset = Color(0xFF0E1016);

  static const Color _darkPrimary = Color(0xFF8B7CFF);
  static const Color _darkPrimaryDark = Color(0xFF6F63D9);
  static const Color _darkPrimaryLight = Color(0xFFAAA1FF);

  static const Color _darkTextPrimary = Color(0xFFF4F4F7);
  static const Color _darkTextSecondary = Color(0xFFA7A9B4);
  static const Color _darkTextMuted = Color(0xFF686B78);
  static const Color _darkTextDisabled = Color(0xFF454751);

  // ─── Light Mode Foundations ──────────────────────────────────────────────────
  static const Color _lightEnvironment = Color(0xFFF5F5F7);
  static const Color _lightEnvironmentSecondary = Color(0xFFEBEBF0);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color _lightSurfaceInset = Color(0xFFE9E9EE);

  static const Color _lightPrimary = Color(0xFF6858D8);
  static const Color _lightPrimaryDark = Color(0xFF5244B8);
  static const Color _lightPrimaryLight = Color(0xFF8174E8);

  static const Color _lightTextPrimary = Color(0xFF17171C);
  static const Color _lightTextSecondary = Color(0xFF62636C);
  static const Color _lightTextMuted = Color(0xFF8C8D96);
  static const Color _lightTextDisabled = Color(0xFFB5B6C0);

  // ─── Dynamic Adaptive Getters ────────────────────────────────────────────────
  static Color get background => isDarkMode ? _darkEnvironment : _lightEnvironment;
  static Color get environmentSecondary => isDarkMode ? _darkEnvironmentSecondary : _lightEnvironmentSecondary;
  static Color get surfaceColor => isDarkMode ? _darkSurface : _lightSurface;
  static Color get surfaceElevatedColor => isDarkMode ? _darkSurfaceElevated : _lightSurfaceElevated;
  static Color get surfaceInset => isDarkMode ? _darkSurfaceInset : _lightSurfaceInset;

  static Color get surface => surfaceColor;
  static Color get surfaceElevated => surfaceElevatedColor;
  static Color get surfaceVariant => surfaceElevatedColor;

  static Color get primary => isDarkMode ? _darkPrimary : _lightPrimary;
  static Color get primaryDark => isDarkMode ? _darkPrimaryDark : _lightPrimaryDark;
  static Color get primaryLight => isDarkMode ? _darkPrimaryLight : _lightPrimaryLight;
  static Color get primaryContainer => isDarkMode ? const Color(0x2B8B7CFF) : const Color(0x1F6858D8);
  static Color get onPrimaryContainer => isDarkMode ? _darkPrimaryLight : _lightPrimary;

  static Color get secondary => isDarkMode ? _darkPrimaryDark : _lightPrimaryLight;
  static Color get secondaryContainer => isDarkMode ? const Color(0x1F6F63D9) : const Color(0x1A8174E8);
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

  // ─── Muted & Premium Semantic Colors ─────────────────────────────────────────
  static const Color _successDark = Color(0xFF65C98A);
  static const Color _successLightColor = Color(0xFF2E7D47);
  static Color get success => isDarkMode ? _successDark : _successLightColor;
  static Color get successLight => isDarkMode ? const Color(0x2465C98A) : const Color(0x1C2E7D47);

  static const Color _warningDark = Color(0xFFE8B86A);
  static const Color _warningLightColor = Color(0xFFB8822B);
  static Color get warning => isDarkMode ? _warningDark : _warningLightColor;
  static Color get warningLight => isDarkMode ? const Color(0x24E8B86A) : const Color(0x1CB8822B);

  static const Color _dangerDark = Color(0xFFE47777);
  static const Color _dangerLightColor = Color(0xFFC74343);
  static Color get error => isDarkMode ? _dangerDark : _dangerLightColor;
  static Color get errorLight => isDarkMode ? const Color(0x24E47777) : const Color(0x1CC74343);

  static const Color _infoDark = Color(0xFF79A9E8);
  static const Color _infoLightColor = Color(0xFF386CB5);
  static Color get info => isDarkMode ? _infoDark : _infoLightColor;
  static Color get infoLight => isDarkMode ? const Color(0x2479A9E8) : const Color(0x1C386CB5);

  // ─── Physical Bevels, Borders & Glass ─────────────────────────────────────────
  static Color get topBevelHighlight => isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x99FFFFFF);
  static Color get bottomBevelShade => isDarkMode ? const Color(0x66000000) : const Color(0x0F000000);
  static Color get borderLine => isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x0E000000);

  static Color get border => borderLine;
  static Color get divider => isDarkMode ? const Color(0x14FFFFFF) : const Color(0x0A000000);

  static List<Color> get primaryGradientColors => isDarkMode
      ? [const Color(0xFF8B7CFF), const Color(0xFF6F63D9)]
      : [const Color(0xFF6858D8), const Color(0xFF8174E8)];

  static LinearGradient get primaryGradient => LinearGradient(
        colors: primaryGradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static List<Color> get cardGradientColors => isDarkMode
      ? [const Color(0xFF1B1E27), const Color(0xFF14161E)]
      : [const Color(0xFFFFFFFF), const Color(0xFFF9F9FB)];

  static List<Color> get progressCardGradient => isDarkMode
      ? [const Color(0xFF1B1832), const Color(0xFF131124)]
      : [const Color(0xFFF0ECFF), const Color(0xFFE8E2FF)];

  static List<Color> get streakCardGradient => isDarkMode
      ? [const Color(0xFF261E14), const Color(0xFF1A140C)]
      : [const Color(0xFFFFF6EB), const Color(0xFFFEEDD8)];

  static Color get streakText => warning;
  static Color get navBackground => isDarkMode ? const Color(0xE6101117) : const Color(0xE6FFFFFF);

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
