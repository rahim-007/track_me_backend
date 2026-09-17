import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  double _dragDistance = 0;

  void _onNavTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch themeProvider to rebuild MainShell instantly when dark mode is toggled
    ref.watch(themeProvider);

    final selectedIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) {
          _dragDistance = 0;
        },
        onHorizontalDragUpdate: (details) {
          _dragDistance += details.primaryDelta ?? 0;
        },
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          const minDistance = 45.0;
          const minVelocity = 220.0;

          // Drag Left (finger moves right to left, negative delta) -> Navigate to Next Screen
          if (_dragDistance < -minDistance || velocity < -minVelocity) {
            if (selectedIndex < 4) {
              _onNavTap(selectedIndex + 1);
            }
          }
          // Drag Right (finger moves left to right, positive delta) -> Navigate to Previous Screen
          else if (_dragDistance > minDistance || velocity > minVelocity) {
            if (selectedIndex > 0) {
              _onNavTap(selectedIndex - 1);
            }
          }
          _dragDistance = 0;
        },
        onHorizontalDragCancel: () {
          _dragDistance = 0;
        },
        child: widget.navigationShell,
      ),
      bottomNavigationBar: _ClayBottomNavBar(
        selectedIndex: selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

// ─── Premium Clay Bottom Navigation ──────────────────────────────────────────

class _ClayBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _ClayBottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.isDarkMode
                ? Colors.black.withOpacity(0.40)
                : Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              _ClayNavItem(
                icon: Icons.home_rounded,
                unselectedIcon: Icons.home_outlined,
                label: 'Home',
                isSelected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _ClayNavItem(
                icon: Icons.track_changes_rounded,
                unselectedIcon: Icons.track_changes_outlined,
                label: 'Habits',
                isSelected: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              _ClayNavItem(
                icon: Icons.account_balance_wallet_rounded,
                unselectedIcon: Icons.account_balance_wallet_outlined,
                label: 'Cash Flow',
                isSelected: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
              _ClayNavItem(
                icon: Icons.flag_rounded,
                unselectedIcon: Icons.flag_outlined,
                label: 'Goals',
                isSelected: selectedIndex == 3,
                onTap: () => onTap(3),
              ),
              _ClayNavItem(
                icon: Icons.person_rounded,
                unselectedIcon: Icons.person_outline_rounded,
                label: 'Profile',
                isSelected: selectedIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClayNavItem extends StatelessWidget {
  final IconData icon;
  final IconData unselectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClayNavItem({
    required this.icon,
    required this.unselectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode;
    final activeColor = isDark ? const Color(0xFFA78BFA) : const Color(0xFF5334EA);
    final inactiveColor = AppColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0x286E49E6) : const Color(0xFFEEECFE))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? icon : unselectedIcon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
