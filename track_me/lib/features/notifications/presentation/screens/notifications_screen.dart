import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/notification_model.dart';
import '../../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _NotificationsHeader(
              unreadCount: state.unreadCount,
              onMarkAllAsRead: notifier.markAllAsRead,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: notifier.load,
                child: _buildBody(context, ref, state, notifier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    NotificationsState state,
    NotificationsNotifier notifier,
  ) {
    if (state.loading) {
      return const _LoadingList();
    }
    if (state.error != null) {
      return _ErrorState(onRetry: notifier.load);
    }
    if (state.items.isEmpty) {
      return const _EmptyState();
    }

    return NotificationListView(
      items: state.items,
      hasMore: state.hasMore,
      loadingMore: state.loadingMore,
      notifier: notifier,
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _NotificationsHeader extends StatelessWidget {
  final int unreadCount;
  final Future<void> Function() onMarkAllAsRead;

  const _NotificationsHeader({
    required this.unreadCount,
    required this.onMarkAllAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final canMarkAll = unreadCount > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stay updated with your habits, goals, and progress.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: canMarkAll ? onMarkAllAsRead : null,
            style: TextButton.styleFrom(
              foregroundColor:
                  canMarkAll ? AppColors.primary : AppColors.textDisabled,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
            ),
            child: const Text(
              'Mark all as read',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── List with date sections ─────────────────────────────────────────────────

class NotificationListView extends StatelessWidget {
  const NotificationListView({
    super.key,
    required this.items,
    required this.hasMore,
    required this.loadingMore,
    required this.notifier,
  });

  final List<NotificationModel> items;
  final bool hasMore;
  final bool loadingMore;
  final NotificationsNotifier notifier;

  static String _sectionFor(DateTime createdAt, DateTime now) {
    final d = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final t = DateTime(now.year, now.month, now.day);
    final diff = t.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return 'Earlier';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sections = <String, List<NotificationModel>>{};
    for (final n in items) {
      sections.putIfAbsent(_sectionFor(n.createdAt, now), () => []).add(n);
    }
    const order = ['Today', 'Yesterday', 'Earlier'];

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 200 && hasMore && !loadingMore) {
          notifier.loadMore();
        }
        return false;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          for (final title in order)
            if (sections.containsKey(title)) ...[
              _SectionHeader(title: title),
              for (final n in sections[title]!)
                _NotificationCard(notification: n, notifier: notifier),
            ],
          if (loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Notification card ────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final NotificationsNotifier notifier;

  const _NotificationCard({
    required this.notification,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = NotificationStyle.colorFor(notification.category);
    final unread = !notification.isRead;

    return Dismissible(
      key: ValueKey('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => notifier.remove(notification),
      background: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ),
      child: GestureDetector(
        onTap: () => _open(context, notification, notifier),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: unread
                ? AppColors.primary
                    .withOpacity(AppColors.isDarkMode ? 0.10 : 0.06)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unread
                  ? AppColors.primary.withOpacity(0.28)
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purple accent indicator for unread cards
              if (unread)
                Container(
                  width: 3.5,
                  height: 44,
                  margin: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    NotificationStyle.iconFor(notification.category),
                    size: 22,
                    color: categoryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    unread ? FontWeight.w800 : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _timestamp(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _timestamp(DateTime createdAt) {
    final now = DateTime.now();
    final section = NotificationListView._sectionFor(createdAt, now);
    final time = DateFormat('h:mm a').format(createdAt);
    switch (section) {
      case 'Today':
        return 'Today · $time';
      case 'Yesterday':
        return 'Yesterday · $time';
      default:
        return '${DateFormat('MMM d').format(createdAt)} · $time';
    }
  }

  void _open(BuildContext context, NotificationModel notification,
      NotificationsNotifier notifier) {
    if (!notification.isRead) {
      notifier.markAsRead(notification);
    }
    final route =
        notification.route ?? NotificationModel.routeFor(notification.category);
    if (route != null) {
      context.go(route);
    }
  }
}

// ─── Loading / empty / error states ───────────────────────────────────────────

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (int i = 0; i < 5; i++)
          Container(
            height: 84,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "You're all caught up",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 44),
          child: Text(
            "No new notifications right now. We'll let you know when something needs your attention.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              size: 38,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Couldn't load notifications",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Try again',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
