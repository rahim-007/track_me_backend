import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/features/notifications/data/models/notification_model.dart';

void main() {
  Map<String, dynamic> baseJson({
    String type = 'HABIT_REMINDER',
    Map<String, dynamic>? data,
    bool isRead = false,
    String? sentAt,
  }) {
    return {
      'id': 'n1',
      'type': type,
      'title': 'Morning Run reminder',
      'body': 'Time to complete your Morning Run.',
      'data': data,
      'isRead': isRead,
      'sentAt': sentAt ?? '2026-08-15T08:30:00.000Z',
    };
  }

  test('parses the core fields from the backend payload', () {
    final n = NotificationModel.fromJson(baseJson());

    expect(n.id, 'n1');
    expect(n.type, 'HABIT_REMINDER');
    expect(n.title, 'Morning Run reminder');
    expect(n.message, 'Time to complete your Morning Run.');
    expect(n.isRead, isFalse);
    expect(n.createdAt.toUtc().hour, 8);
  });

  test('uses data.category when present', () {
    final n =
        NotificationModel.fromJson(baseJson(data: {'category': 'cashflow'}));
    expect(n.category, NotificationCategory.cashflow);
  });

  test('maps legacy type enum to a category when no data.category', () {
    expect(
      NotificationModel.fromJson(baseJson(type: 'HABIT_REMINDER')).category,
      NotificationCategory.habit,
    );
    expect(
      NotificationModel.fromJson(baseJson(type: 'GOAL_REMINDER')).category,
      NotificationCategory.goals,
    );
    expect(
      NotificationModel.fromJson(baseJson(type: 'WEEKLY_REPORT')).category,
      NotificationCategory.insights,
    );
    expect(
      NotificationModel.fromJson(baseJson(type: 'MOTIVATION')).category,
      NotificationCategory.system,
    );
  });

  test('parses relatedId/relatedType/route from the data JSON', () {
    final n = NotificationModel.fromJson(baseJson(data: {
      'category': 'goals',
      'relatedId': 'g_123',
      'relatedType': 'goal',
      'route': '/goals',
    }));
    expect(n.relatedId, 'g_123');
    expect(n.relatedType, 'goal');
    expect(n.route, '/goals');
  });

  test('routeFor maps each category to the right destination', () {
    expect(NotificationModel.routeFor(NotificationCategory.habit), '/habits');
    expect(NotificationModel.routeFor(NotificationCategory.goals), '/goals');
    expect(
        NotificationModel.routeFor(NotificationCategory.cashflow), '/expenses');
    expect(NotificationModel.routeFor(NotificationCategory.insights),
        '/dashboard');
    expect(NotificationModel.routeFor(NotificationCategory.system), isNull);
  });

  test('copyWith only overrides isRead', () {
    final n = NotificationModel.fromJson(baseJson(data: {'category': 'habit'}));
    final read = n.copyWith(isRead: true);
    expect(read.isRead, isTrue);
    expect(read.id, n.id);
    expect(read.category, n.category);
  });
}
