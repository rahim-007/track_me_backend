import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/features/notifications/data/models/notification_model.dart';
import 'package:track_me/features/notifications/providers/notifications_provider.dart';

NotificationModel make(String id, {bool isRead = false, DateTime? createdAt}) {
  return NotificationModel(
    id: id,
    type: 'HABIT_REMINDER',
    title: 'Title $id',
    message: 'Message $id',
    isRead: isRead,
    createdAt: createdAt ?? DateTime(2026, 8, 15, 8),
    category: NotificationCategory.habit,
  );
}

class _FakeApi implements NotificationsApi {
  _FakeApi(this.items,
      {this.unreadCount = 0, this.failReads = false, this.failDeletes = false});

  List<NotificationModel> items;
  int unreadCount;
  bool failReads;
  bool failDeletes;
  int fetchCount = 0;
  final List<String> markedRead = [];
  int markAllCount = 0;
  final List<String> deleted = [];

  @override
  Future<List<NotificationModel>> fetch(int take, int skip) async {
    fetchCount++;
    final start = skip < items.length ? skip : items.length;
    final end = (start + take) > items.length ? items.length : start + take;
    return items.sublist(start, end);
  }

  @override
  Future<int> fetchUnreadCount() async => unreadCount;

  @override
  Future<void> markRead(String id) async {
    if (failReads) throw Exception('network down');
    markedRead.add(id);
    unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
  }

  @override
  Future<void> markAllRead() async {
    markAllCount++;
    unreadCount = 0;
  }

  @override
  Future<void> delete(String id) async {
    if (failDeletes) throw Exception('network down');
    deleted.add(id);
    items = items.where((n) => n.id != id).toList();
  }

  @override
  Future<void> clearAll() async {
    items.clear();
    unreadCount = 0;
  }
}

void main() {
  test('load fetches items and the unread count', () async {
    final api = _FakeApi([make('a'), make('b', isRead: true)], unreadCount: 1);
    final notifier = NotificationsNotifier(api: api);

    await notifier.load();
    expect(notifier.state.items.length, 2);
    expect(notifier.state.unreadCount, 1);
    expect(notifier.state.loading, isFalse);
    expect(notifier.state.error, isNull);
  });

  test('markAsRead marks the item read and decrements the unread count',
      () async {
    final api = _FakeApi([make('a'), make('b', isRead: true)], unreadCount: 1);
    final notifier = NotificationsNotifier(api: api);
    await notifier.load();

    await notifier.markAsRead(notifier.state.items.first);
    expect(api.markedRead, ['a']);
    expect(notifier.state.items.every((n) => n.isRead), isTrue);
    expect(notifier.state.unreadCount, 0);
  });

  test('markAsRead reverts optimistically when the API fails', () async {
    final api = _FakeApi([make('a')], unreadCount: 1, failReads: true);
    final notifier = NotificationsNotifier(api: api);
    await notifier.load();

    await notifier.markAsRead(notifier.state.items.first);
    expect(notifier.state.items.first.isRead, isFalse);
    expect(notifier.state.unreadCount, 1);
  });

  test('markAllAsRead marks every item read and zeroes the count', () async {
    final api = _FakeApi([make('a'), make('b'), make('c', isRead: true)],
        unreadCount: 2);
    final notifier = NotificationsNotifier(api: api);
    await notifier.load();

    await notifier.markAllAsRead();
    expect(api.markAllCount, 1);
    expect(notifier.state.items.every((n) => n.isRead), isTrue);
    expect(notifier.state.unreadCount, 0);
  });

  test('remove deletes the item and decrements the count when unread',
      () async {
    final api = _FakeApi([make('a'), make('b', isRead: true)], unreadCount: 1);
    final notifier = NotificationsNotifier(api: api);
    await notifier.load();

    await notifier.remove(notifier.state.items.first);
    expect(api.deleted, ['a']);
    expect(notifier.state.items.map((n) => n.id), ['b']);
    expect(notifier.state.unreadCount, 0);
  });

  test('remove restores the item when the API fails', () async {
    final api = _FakeApi([make('a')], unreadCount: 1, failDeletes: true);
    final notifier = NotificationsNotifier(api: api);
    await notifier.load();

    await notifier.remove(notifier.state.items.first);
    expect(notifier.state.items.length, 1);
    expect(notifier.state.items.first.id, 'a');
    expect(notifier.state.unreadCount, 1);
  });

  test('load surfaces an error state on failure', () async {
    final api = _ThrowingApi([], unreadCount: 0);
    final notifier = NotificationsNotifier(api: api);
    await notifier.load();
    expect(notifier.state.error, isNotNull);
    expect(notifier.state.loading, isFalse);
  });

  test('loadMore appends the next page while hasMore is true', () async {
    final items = [for (int i = 0; i < 5; i++) make('n$i')];
    final api = _FakeApi(items, unreadCount: 0);
    final notifier = NotificationsNotifier(api: api, pageSize: 2);
    await notifier.load();

    expect(notifier.state.items.length, 2);
    expect(notifier.state.hasMore, isTrue);

    await notifier.loadMore();
    expect(notifier.state.items.length, 4);
    expect(notifier.state.hasMore, isTrue);

    await notifier.loadMore();
    expect(notifier.state.items.length, 5);
    expect(notifier.state.hasMore, isFalse);
  });
}

class _ThrowingApi implements NotificationsApi {
  _ThrowingApi(this.items, {this.unreadCount = 0});

  final List<NotificationModel> items;
  final int unreadCount;

  @override
  Future<List<NotificationModel>> fetch(int take, int skip) async =>
      throw Exception('network down');

  @override
  Future<int> fetchUnreadCount() async => throw Exception('network down');

  @override
  Future<void> markRead(String id) async => throw Exception('network down');

  @override
  Future<void> markAllRead() async => throw Exception('network down');

  @override
  Future<void> delete(String id) async => throw Exception('network down');

  @override
  Future<void> clearAll() async => throw Exception('network down');
}
