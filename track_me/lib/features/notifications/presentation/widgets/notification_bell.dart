import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/notifications_provider.dart';

/// Notification bell used by the Home screens. Shows no badge when everything
/// is read, a small dot when one unread notification exists, and a count pill
/// when there are several. Tapping opens the Notification Center.
class NotificationBell extends ConsumerWidget {
  final double size;
  final Color? color;

  const NotificationBell({super.key, this.size = 26, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread =
        ref.watch(notificationsProvider.select((s) => s.unreadCount));
    final iconColor = color ?? AppColors.textPrimary;

    return IconButton(
      onPressed: () => context.push(AppRoutes.notifications),
      tooltip: 'Notifications',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: size,
            color: iconColor,
          ),
          if (unread > 0)
            Positioned(
              top: -5,
              right: -9,
              child: unread == 1
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.background,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '$unread',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
