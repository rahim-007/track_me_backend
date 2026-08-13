import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'expenses_provider.dart';

class AnalyticsData {
  final String period;
  final double totalAmount;
  final int transactionCount;
  final double dailyAverage;
  final List<CategoryBreakdown> categoryBreakdown;
  final List<DailyBreakdown> dailyBreakdown;
  final String? highestCategory;
  final String? lowestCategory;
  final List<Map<String, dynamic>> topTransactions;
  final List<PaymentBreakdown> paymentBreakdown;

  AnalyticsData({
    required this.period,
    required this.totalAmount,
    required this.transactionCount,
    required this.dailyAverage,
    required this.categoryBreakdown,
    required this.dailyBreakdown,
    this.highestCategory,
    this.lowestCategory,
    required this.topTransactions,
    required this.paymentBreakdown,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      period: json['period'] as String? ?? 'monthly',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      dailyAverage: (json['dailyAverage'] as num?)?.toDouble() ?? 0.0,
      categoryBreakdown: (json['categoryBreakdown'] as List? ?? [])
          .map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyBreakdown: (json['dailyBreakdown'] as List? ?? [])
          .map((e) => DailyBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      highestCategory: json['highestCategory'] as String?,
      lowestCategory: json['lowestCategory'] as String?,
      topTransactions: (json['topTransactions'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      paymentBreakdown: (json['paymentBreakdown'] as List? ?? [])
          .map((e) => PaymentBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory AnalyticsData.empty() => AnalyticsData(
        period: 'monthly',
        totalAmount: 0,
        transactionCount: 0,
        dailyAverage: 0,
        categoryBreakdown: [],
        dailyBreakdown: [],
        topTransactions: [],
        paymentBreakdown: [],
      );
}

class CategoryBreakdown {
  final String category;
  final double amount;
  final double percentage;

  CategoryBreakdown({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      category: json['category'] as String? ?? 'OTHER',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DailyBreakdown {
  final String date;
  final double amount;

  DailyBreakdown({required this.date, required this.amount});

  factory DailyBreakdown.fromJson(Map<String, dynamic> json) {
    return DailyBreakdown(
      date: json['date'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PaymentBreakdown {
  final String method;
  final double amount;
  final double percentage;

  PaymentBreakdown({
    required this.method,
    required this.amount,
    required this.percentage,
  });

  factory PaymentBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentBreakdown(
      method: json['method'] as String? ?? 'CASH',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

typedef AnalyticsState = AsyncValue<AnalyticsData>;

class ExpenseAnalyticsNotifier extends StateNotifier<AnalyticsState> {
  ExpenseAnalyticsNotifier() : super(const AsyncValue.loading());

  String? _lastPeriod;
  String? _lastStartDate;
  String? _lastEndDate;

  Future<void> loadAnalytics({String? period, String? startDate, String? endDate}) async {
    _lastPeriod = period;
    _lastStartDate = startDate;
    _lastEndDate = endDate;

    // Sticky loading: keep the previous charts visible while refreshing.
    state = const AsyncValue<AnalyticsData>.loading().copyWithPrevious(state);
    try {
      final client = DioClient();
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final response = await client.dio.get('/expenses/analytics', queryParameters: {
        'today': todayStr,
        if (period != null) 'period': period,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      });
      final data = AnalyticsData.fromJson(response.data['data'] as Map<String, dynamic>);
      state = AsyncValue.data(data);
    } catch (_) {
      state = AsyncValue.data(AnalyticsData.empty());
    }
  }

  /// Reload using the last requested period. Used after saves/edits so the
  /// screen keeps showing current charts instead of a full-screen spinner.
  Future<void> reload() =>
      loadAnalytics(period: _lastPeriod, startDate: _lastStartDate, endDate: _lastEndDate);
}

// ─── Provider ────────────────────────────────────────────────────────────────

final expenseAnalyticsProvider =
    StateNotifierProvider<ExpenseAnalyticsNotifier, AnalyticsState>((ref) {
  final notifier = ExpenseAnalyticsNotifier();
  
  final filter = ref.watch(expenseFilterProvider);
  final customRange = ref.watch(expenseCustomRangeProvider);
  
  String? startDate;
  String? endDate;
  if (filter == ExpenseFilterType.custom && customRange != null) {
    startDate = '${customRange.start.year}-${customRange.start.month.toString().padLeft(2, '0')}-${customRange.start.day.toString().padLeft(2, '0')}';
    endDate = '${customRange.end.year}-${customRange.end.month.toString().padLeft(2, '0')}-${customRange.end.day.toString().padLeft(2, '0')}';
  }
  
  notifier.loadAnalytics(
    period: filter.apiValue,
    startDate: startDate,
    endDate: endDate,
  );
  
  return notifier;
});
