import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  transport,
  shopping,
  bills,
  health,
  education,
  entertainment,
  travel,
  salary,
  other;

  String get label {
    switch (this) {
      case ExpenseCategory.food: return 'Food';
      case ExpenseCategory.transport: return 'Transport';
      case ExpenseCategory.shopping: return 'Shopping';
      case ExpenseCategory.bills: return 'Bills';
      case ExpenseCategory.health: return 'Health';
      case ExpenseCategory.education: return 'Education';
      case ExpenseCategory.entertainment: return 'Entertainment';
      case ExpenseCategory.travel: return 'Travel';
      case ExpenseCategory.salary: return 'Salary';
      case ExpenseCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ExpenseCategory.food: return '🍔';
      case ExpenseCategory.transport: return '🚗';
      case ExpenseCategory.shopping: return '🛍️';
      case ExpenseCategory.bills: return '📄';
      case ExpenseCategory.health: return '💊';
      case ExpenseCategory.education: return '📚';
      case ExpenseCategory.entertainment: return '🎬';
      case ExpenseCategory.travel: return '✈️';
      case ExpenseCategory.salary: return '💰';
      case ExpenseCategory.other: return '📦';
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food: return const Color(0xFFF97316);       // Orange
      case ExpenseCategory.transport: return const Color(0xFF3B82F6);  // Blue
      case ExpenseCategory.shopping: return const Color(0xFF8B5CF6);   // Purple
      case ExpenseCategory.bills: return const Color(0xFFEAB308);      // Yellow
      case ExpenseCategory.health: return const Color(0xFF10B981);     // Green
      case ExpenseCategory.education: return const Color(0xFF6366F1);  // Indigo
      case ExpenseCategory.entertainment: return const Color(0xFFEC4899); // Pink
      case ExpenseCategory.travel: return const Color(0xFF14B8A6);     // Teal
      case ExpenseCategory.salary: return const Color(0xFF059669);     // Emerald
      case ExpenseCategory.other: return const Color(0xFF6B7280);      // Grey
    }
  }

  Color get lightColor => color.withOpacity(0.12);

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food: return Icons.restaurant_rounded;
      case ExpenseCategory.transport: return Icons.directions_car_rounded;
      case ExpenseCategory.shopping: return Icons.shopping_bag_rounded;
      case ExpenseCategory.bills: return Icons.receipt_long_rounded;
      case ExpenseCategory.health: return Icons.medical_services_rounded;
      case ExpenseCategory.education: return Icons.school_rounded;
      case ExpenseCategory.entertainment: return Icons.movie_rounded;
      case ExpenseCategory.travel: return Icons.flight_rounded;
      case ExpenseCategory.salary: return Icons.account_balance_wallet_rounded;
      case ExpenseCategory.other: return Icons.category_rounded;
    }
  }

  String get apiValue => name.toUpperCase();

  static ExpenseCategory fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'FOOD': return ExpenseCategory.food;
      case 'TRANSPORT': return ExpenseCategory.transport;
      case 'SHOPPING': return ExpenseCategory.shopping;
      case 'BILLS': return ExpenseCategory.bills;
      case 'HEALTH': return ExpenseCategory.health;
      case 'EDUCATION': return ExpenseCategory.education;
      case 'ENTERTAINMENT': return ExpenseCategory.entertainment;
      case 'TRAVEL': return ExpenseCategory.travel;
      case 'SALARY': return ExpenseCategory.salary;
      default: return ExpenseCategory.other;
    }
  }
}
