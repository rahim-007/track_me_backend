import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/local/json_file_cache.dart';
import '../../../core/network/dio_client.dart';
import '../data/models/notification_model.dart';

/// Minimal API surface for the Notification Center so tests can inject an
/// in-memory backend instead of hitting the network.
abstract class NotificationsApi {
  Future<List<NotificationModel>> fetch(int take, int skip);
  Future<int> fetchUnreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> delete(String id);
  Future<void> clearAll();
}

/// Real implementation backed by the UrDay backend.
class DioNotificationsApi implements NotificationsApi {
  DioNotificationsApi();

  @override
  Future<List<NotificationModel>> fetch(int take, int skip) async {
    final client = DioClient();
    final response = await client.dio.get(
      '/notifications',
      queryParameters: {'take': take, 'skip': skip},
    );
    final data = response.data['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  @override
  Future<int> fetchUnreadCount() async {
    final client = DioClient();
    final response = await client.dio.get('/notifications/unread-count');
    return response.data['data']?['count'] as int? ?? 0;
  }

  @override
  Future<void> markRead(String id) async {
    final client = DioClient();
    await client.dio.patch('/notifications/$id/read');
  }

  @override
  Future<void> markAllRead() async {
    final client = DioClient();
    await client.dio.patch('/notifications/read-all');
  }

  @override
  Future<void> delete(String id) async {
    final client = DioClient();
    await client.dio.delete('/notifications/$id');
  }

  @override
  Future<void> clearAll() async {
    final client = DioClient();
    try {
      await client.dio.delete('/notifications/clear-all');
    } catch (_) {
      await client.dio.delete('/notifications');
    }
  }
}

/// Combined state so the Notification Center and the Home bell always agree:
/// the unread count is derived from the same notifier that owns the list.
class NotificationsState {
  final List<NotificationModel> items;
  final int unreadCount;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final Object? error;

  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = false,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationModel>? items,
    int? unreadCount,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsApi _api;
  final int pageSize;
  static const String _cacheKey = 'notifications_cache';

  NotificationsNotifier({NotificationsApi? api, this.pageSize = 30})
      : _api = api ?? DioNotificationsApi(),
        super(const NotificationsState()) {
    load();
  }

  Future<void> load() async {
    final isRealApi = _api is DioNotificationsApi;
    if (isRealApi && state.items.isEmpty) {
      try {
        final cachedData = await JsonFileCache.read<Map<String, dynamic>>(
          _cacheKey,
          (raw) => raw as Map<String, dynamic>,
        );
        if (cachedData != null) {
          final items = (cachedData['items'] as List<dynamic>?)
                  ?.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];
          final unread = cachedData['unreadCount'] as int? ?? 0;
          if (items.isNotEmpty) {
            state = state.copyWith(
              items: items,
              unreadCount: unread,
              loading: false,
            );
          }
        }
      } catch (_) {}
    }

    state = state.copyWith(loading: state.items.isEmpty, clearError: true);
    try {
      final results = await Future.wait([
        _api.fetch(pageSize, 0),
        _api.fetchUnreadCount(),
      ]);
      final items = results[0] as List<NotificationModel>;
      final unread = results[1] as int;
      state = state.copyWith(
        items: items,
        unreadCount: unread,
        loading: false,
        hasMore: items.length == pageSize,
      );
      if (isRealApi) {
        await _persist();
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> _persist() async {
    try {
      await JsonFileCache.write(_cacheKey, {
        'items': state.items.map((n) => {
          'id': n.id,
          'title': n.title,
          'body': n.message,
          'type': n.type,
          'isRead': n.isRead,
          'sentAt': n.createdAt.toIso8601String(),
          'data': {
            'category': n.category.name,
            'relatedId': n.relatedId,
            'relatedType': n.relatedType,
            'route': n.route,
          },
        }).toList(),
        'unreadCount': state.unreadCount,
      });
    } catch (_) {}
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final more = await _api.fetch(pageSize, state.items.length);
      final items = [...state.items, ...more];
      state = state.copyWith(
        items: items,
        loadingMore: false,
        hasMore: more.length == pageSize,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }

  /// Marks a single notification read (optimistic; reverts on failure).
  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;
    final items = [
      for (final n in state.items)
        n.id == notification.id ? n.copyWith(isRead: true) : n,
    ];
    state = state.copyWith(
      items: items,
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );
    try {
      await _api.markRead(notification.id);
    } catch (_) {
      // Revert the optimistic change so the UI never lies about state.
      final reverted = [
        for (final n in state.items)
          n.id == notification.id ? n.copyWith(isRead: false) : n,
      ];
      state = state.copyWith(
        items: reverted,
        unreadCount: state.unreadCount + 1,
      );
    }
  }

  Future<void> markAllAsRead() async {
    final hadUnread = state.items.any((n) => !n.isRead);
    if (!hadUnread) return;
    final items = [for (final n in state.items) n.copyWith(isRead: true)];
    state = state.copyWith(items: items, unreadCount: 0);
    try {
      await _api.markAllRead();
    } catch (_) {
      await load(); // reload authoritative state on failure
    }
  }

  /// Deletes a notification (optimistic; restores it on failure).
  Future<void> remove(NotificationModel notification) async {
    final items = state.items.where((n) => n.id != notification.id).toList();
    final wasUnread = !notification.isRead;
    state = state.copyWith(
      items: items,
      unreadCount: wasUnread && state.unreadCount > 0
          ? state.unreadCount - 1
          : state.unreadCount,
    );
    try {
      await _api.delete(notification.id);
    } catch (_) {
      // Restore the item so the UI never loses a notification silently.
      final restored = [...state.items, notification]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        items: restored,
        unreadCount: wasUnread ? state.unreadCount + 1 : state.unreadCount,
      );
    }
  }

  /// Clears all notifications for the user (optimistic; restores on failure).
  Future<void> clearAll() async {
    if (state.items.isEmpty) return;
    final previousItems = state.items;
    final previousUnread = state.unreadCount;

    state = state.copyWith(items: [], unreadCount: 0);

    try {
      await _api.clearAll();
    } catch (_) {
      state = state.copyWith(
        items: previousItems,
        unreadCount: previousUnread,
      );
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
  (ref) => NotificationsNotifier(),
);
