import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Category of an in-app notification, used for icon/color styling and to
/// decide which screen a tap navigates to.
enum NotificationCategory {
  habit,
  goals,
  cashflow,
  insights,
  system;

  static NotificationCategory fromName(String? name) {
    switch (name?.toLowerCase()) {
      case 'habit':
        return NotificationCategory.habit;
      case 'goals':
      case 'goal':
        return NotificationCategory.goals;
      case 'cashflow':
      case 'cash_flow':
      case 'cash-flow':
      case 'finance':
        return NotificationCategory.cashflow;
      case 'insights':
      case 'insight':
      case 'analytics':
        return NotificationCategory.insights;
      case 'system':
        return NotificationCategory.system;
      default:
        return NotificationCategory.system;
    }
  }
}

/// In-app notification model, backed by the backend `Notification` record.
/// The free-form `data` JSON carries `category`, `relatedId`, `relatedType`
/// and `route` so the Notification Center can style and route each item
/// without new database fields.
class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final NotificationCategory category;
  final String? relatedId;
  final String? relatedType;
  final String? route;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.category,
    this.relatedId,
    this.relatedType,
    this.route,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final type = (json['type'] as String? ?? '').toUpperCase();
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: type,
      title: json['title'] as String? ?? '',
      message: json['body'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
      category: _categoryFor(type, data),
      relatedId: data['relatedId']?.toString(),
      relatedType: data['relatedType']?.toString(),
      route: data['route']?.toString(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      category: category,
      relatedId: relatedId,
      relatedType: relatedType,
      route: route,
    );
  }

  /// Prefer the explicit `data.category`; fall back to a mapping from the
  /// legacy `type` enum so old notifications keep a sensible category.
  static NotificationCategory _categoryFor(
    String type,
    Map<String, dynamic> data,
  ) {
    final explicit = data['category']?.toString();
    if (explicit != null && explicit.isNotEmpty) {
      return NotificationCategory.fromName(explicit);
    }
    switch (type) {
      case 'HABIT_REMINDER':
      case 'HABIT_COMPLETED':
      case 'STREAK':
      case 'MISSED_HABIT':
      case 'ACHIEVEMENT':
        return NotificationCategory.habit;
      case 'GOAL_REMINDER':
      case 'GOAL_PROGRESS':
      case 'GOAL_COMPLETED':
        return NotificationCategory.goals;
      case 'CASH_FLOW':
      case 'BUDGET_ALERT':
      case 'INCOME_ADDED':
      case 'SAVINGS_PROGRESS':
        return NotificationCategory.cashflow;
      case 'WEEKLY_REPORT':
      case 'INSIGHT':
        return NotificationCategory.insights;
      default:
        return NotificationCategory.system;
    }
  }

  /// Destination route for this notification's category (null = no navigation).
  static String? routeFor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.habit:
        return '/habits';
      case NotificationCategory.goals:
        return '/goals';
      case NotificationCategory.cashflow:
        return '/expenses';
      case NotificationCategory.insights:
        return '/dashboard';
      case NotificationCategory.system:
        return null;
    }
  }
}

/// Styling helpers shared by the bell and the Notification Center cards.
class NotificationStyle {
  const NotificationStyle._();

  static IconData iconFor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.habit:
        return Icons.check_circle_rounded;
      case NotificationCategory.goals:
        return Icons.flag_rounded;
      case NotificationCategory.cashflow:
        return Icons.account_balance_wallet_rounded;
      case NotificationCategory.insights:
        return Icons.insights_rounded;
      case NotificationCategory.system:
        return Icons.settings_rounded;
    }
  }

  static Color colorFor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.habit:
        return AppColors.primary;
      case NotificationCategory.goals:
        return const Color(0xFF10B981); // green
      case NotificationCategory.cashflow:
        return const Color(0xFF06B6D4); // cyan
      case NotificationCategory.insights:
        return const Color(0xFF6366F1); // indigo
      case NotificationCategory.system:
        return const Color(0xFF6B7280); // neutral gray
    }
  }
}
