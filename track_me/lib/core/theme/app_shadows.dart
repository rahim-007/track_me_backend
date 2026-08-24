import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Adaptive multi-layered physical shadow system for Dark + Light themes.
class AppShadows {
  AppShadows._();

  /// Small shadow — chips, small buttons, icon buttons
  static List<BoxShadow> get small => AppColors.isDarkMode
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.03),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];

  /// Medium shadow — cards, panels, interactive surfaces
  static List<BoxShadow> get medium => AppColors.isDarkMode
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];

  /// Large shadow — dialogs, bottom sheets, floating navigation
  static List<BoxShadow> get large => AppColors.isDarkMode
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.70),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF8B7CFF).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];

  /// Inset shadow gradient (recessed depth simulation)
  static LinearGradient get insetTopShadow => AppColors.isDarkMode
      ? LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.60),
            Colors.black.withOpacity(0.0),
          ],
        )
      : LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.08),
            Colors.black.withOpacity(0.0),
          ],
        );
}
