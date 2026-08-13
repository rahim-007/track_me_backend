import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool isDarkMode = false;

  // Primary — Purple
  static const Color _primaryLight = Color(0xFF7C3AED);
  static const Color _primaryDark = Color(0xFF9F7AEA);
  static Color get primary => isDarkMode ? _primaryDark : _primaryLight;

  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryLight = Color(0xFF8B5CF6);

  static const Color _primaryContainerLight = Color(0xFFEDE9FE);
  static const Color _primaryContainerDark = Color(0xFF2D1E54);
  static Color get primaryContainer => isDarkMode ? _primaryContainerDark : _primaryContainerLight;

  static const Color _onPrimaryContainerLight = Color(0xFF4C1D95);
  static const Color _onPrimaryContainerDark = Color(0xFFE2E8F0);
  static Color get onPrimaryContainer => isDarkMode ? _onPrimaryContainerDark : _onPrimaryContainerLight;

  // Secondary — Cyan
  static const Color _secondaryLight = Color(0xFF06B6D4);
  static const Color _secondaryDark = Color(0xFF22D3EE);
  static Color get secondary => isDarkMode ? _secondaryDark : _secondaryLight;

  static const Color _secondaryContainerLight = Color(0xFFCFFAFE);
  static const Color _secondaryContainerDark = Color(0xFF083344);
  static Color get secondaryContainer => isDarkMode ? _secondaryContainerDark : _secondaryContainerLight;

  // Accent — Indigo
  static const Color _accentLight = Color(0xFF6366F1);
  static const Color _accentDark = Color(0xFF818CF8);
  static Color get accent => isDarkMode ? _accentDark : _accentLight;

  // Status Colors
  static const Color _successLight = Color(0xFF10B981);
  static const Color _successDark = Color(0xFF34D399);
  static Color get success => isDarkMode ? _successDark : _successLight;

  static const Color successLight = Color(0xFFD1FAE5);

  static const Color _warningLight = Color(0xFFF59E0B);
  static const Color _warningDark = Color(0xFFFBBF24);
  static Color get warning => isDarkMode ? _warningDark : _warningLight;

  static const Color warningLight = Color(0xFFFEF3C7);

  static const Color _errorLight = Color(0xFFEF4444);
  static const Color _errorDark = Color(0xFFF87171);
  static Color get error => isDarkMode ? _errorDark : _errorLight;

  static const Color errorLight = Color(0xFFFEE2E2);

  static const Color _infoLight = Color(0xFF3B82F6);
  static const Color _infoDark = Color(0xFF60A5FA);
  static Color get info => isDarkMode ? _infoDark : _infoLight;

  static const Color infoLight = Color(0xFFDBEAFE);

  // Surfaces
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _surfaceDark = Color(0xFF1F1D2B);
  static Color get surface => isDarkMode ? _surfaceDark : _surfaceLight;

  static const Color _backgroundLight = Color(0xFFF8F7FF);
  static const Color _backgroundDark = Color(0xFF13111A);
  static Color get background => isDarkMode ? _backgroundDark : _backgroundLight;

  static const Color _surfaceVariantLight = Color(0xFFF3F4F6);
  static const Color _surfaceVariantDark = Color(0xFF2D2A3A);
  static Color get surfaceVariant => isDarkMode ? _surfaceVariantDark : _surfaceVariantLight;

  static const Color _surfaceElevatedLight = Color(0xFFF9FAFB);
  static const Color _surfaceElevatedDark = Color(0xFF252333);
  static Color get surfaceElevated => isDarkMode ? _surfaceElevatedDark : _surfaceElevatedLight;

  // Text
  static const Color _onSurfaceLight = Color(0xFF111827);
  static const Color _onSurfaceDark = Color(0xFFF9FAFB);
  static Color get onSurface => isDarkMode ? _onSurfaceDark : _onSurfaceLight;

  static Color get textPrimary => onSurface;

  static const Color _textSecondaryLight = Color(0xFF6B7280);
  static const Color _textSecondaryDark = Color(0xFF9CA3AF);
  static Color get textSecondary => isDarkMode ? _textSecondaryDark : _textSecondaryLight;

  static const Color _textHintLight = Color(0xFF9CA3AF);
  static const Color _textHintDark = Color(0xFF6B7280);
  static Color get textHint => isDarkMode ? _textHintDark : _textHintLight;

  static const Color _textDisabledLight = Color(0xFFD1D5DB);
  static const Color _textDisabledDark = Color(0xFF4B5563);
  static Color get textDisabled => isDarkMode ? _textDisabledDark : _textDisabledLight;

  // Borders & Dividers
  static const Color _borderLight = Color(0xFFE5E7EB);
  static const Color _borderDark = Color(0xFF2D2A3A);
  static Color get border => isDarkMode ? _borderDark : _borderLight;

  static const Color _dividerLight = Color(0xFFF3F4F6);
  static const Color _dividerDark = Color(0xFF2D2A3A);
  static Color get divider => isDarkMode ? _dividerDark : _dividerLight;

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
  static List<Color> get primaryGradientColors => isDarkMode 
      ? [const Color(0xFF9F7AEA), const Color(0xFF818CF8)] 
      : [const Color(0xFF7C3AED), const Color(0xFF6366F1)];

  static LinearGradient get primaryGradient => LinearGradient(
    colors: primaryGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<Color> get cardGradientColors => isDarkMode 
      ? [const Color(0xFFB57CFF), const Color(0xFF9F7AEA)] 
      : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];

  static LinearGradient get cardGradient => LinearGradient(
    colors: cardGradientColors,
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
