import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Claymorphism multi-layered shadow system for Dark + Light themes.
///
/// Five depth levels matching the clay surface hierarchy:
/// - [soft]     → Level 1 — backgrounds, nav, secondary containers
/// - [raised]   → Level 2 — cards, items, interactive surfaces (previously `medium`)
/// - [elevated] → Level 3 — primary buttons, hero sections, FABs
/// - [inset]    → Recessed/pressed-into-surface — inputs, pressed buttons
/// - [pressed]  → Active press state — reduced outer shadow + inner shadow
class AppShadows {
  AppShadows._();

  // ─── Level 1: Soft Surface ─────────────────────────────────────────────────
  /// Minimal ambient clay shadow — nav bars, section backgrounds, secondary cards
  static List<BoxShadow> get soft => AppColors.isDarkMode
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.03),
            blurRadius: 2,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.70),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(-1, -1),
          ),
        ];

  // ─── Level 2: Raised Surface ───────────────────────────────────────────────
  /// Standard clay card shadow — cards, habit items, stat cards, interactive surfaces
  static List<BoxShadow> get raised => AppColors.isDarkMode
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 14,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            spreadRadius: -2,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ];

  // ─── Level 3: Elevated Surface ─────────────────────────────────────────────
  /// Premium elevated clay shadow — primary buttons, hero cards, FABs, selected nav
  static List<BoxShadow> get elevated => AppColors.isDarkMode
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 22,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 22,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ];

  // ─── Inset Shadow (for inputs / recessed surfaces) ─────────────────────────
  /// Inner shadow list for recessed/inset surfaces (text inputs, pressed buttons)
  static List<BoxShadow> get inset => AppColors.isDarkMode
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.50),
            blurRadius: 6,
            spreadRadius: -1,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.04),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(-1, -1),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            spreadRadius: -1,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.80),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(-1, -1),
          ),
        ];

  // ─── Pressed State Shadow ──────────────────────────────────────────────────
  /// Button pressed state — reduced outer shadow + subtle inner shadow
  static List<BoxShadow> get pressed => AppColors.isDarkMode
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 4,
            spreadRadius: -1,
            offset: const Offset(0, 1),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            spreadRadius: -1,
            offset: const Offset(0, 1),
          ),
        ];

  // ─── Legacy Aliases ────────────────────────────────────────────────────────
  /// Alias: `small` maps to [soft] for backward compatibility
  static List<BoxShadow> get small => soft;

  /// Alias: `medium` maps to [raised] for backward compatibility
  static List<BoxShadow> get medium => raised;

  /// Alias: `large` maps to [elevated] for backward compatibility
  static List<BoxShadow> get large => elevated;

  /// Inset top shadow gradient (recessed depth simulation for surfaces)
  static LinearGradient get insetTopShadow => AppColors.isDarkMode
      ? LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.40),
            Colors.black.withOpacity(0.0),
          ],
        )
      : LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.05),
            Colors.black.withOpacity(0.0),
          ],
        );

  /// Inner highlight gradient for clay surfaces (top → transparent)
  static LinearGradient get clayInnerHighlight => AppColors.isDarkMode
      ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.4],
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.0),
          ],
        )
      : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.4],
          colors: [
            Colors.white.withOpacity(0.65),
            Colors.white.withOpacity(0.0),
          ],
        );
}
