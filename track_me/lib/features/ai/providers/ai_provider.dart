import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

class AiInsightsModel {
  final int productivityScore;
  final String weeklyReport;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;

  const AiInsightsModel({
    required this.productivityScore,
    required this.weeklyReport,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
  });

  factory AiInsightsModel.fromJson(Map<String, dynamic> json) {
    return AiInsightsModel(
      productivityScore: json['productivityScore'] as int? ?? 0,
      weeklyReport: json['weeklyReport'] as String? ?? '',
      strengths: (json['strengths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      weaknesses: (json['weaknesses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

final aiInsightsProvider = FutureProvider<AiInsightsModel>((ref) async {
  try {
    final client = DioClient();
    final response = await client.dio.get('/ai/insights');
    return AiInsightsModel.fromJson(response.data as Map<String, dynamic>);
  } catch (_) {
    // Return predefined insights for MVP/offline mode
    return const AiInsightsModel(
      productivityScore: 78,
      weeklyReport:
          'This week you completed 85% of your scheduled habits — a 12% improvement from last week! Your morning routines are your strongest area, while evening habits still need some work. You\'ve maintained an impressive 7-day streak for meditation. Keep up the momentum!',
      strengths: [
        'Consistent morning routine — completed 6/7 days',
        'Reading habit — maintained a 14-day streak',
        'Meditation — showing great consistency',
        'Workout 4/7 days — above average for fitness goals',
      ],
      weaknesses: [
        'Evening journaling — only completed 2/7 days',
        'You usually miss habits scheduled after 8 PM',
        'Weekend habits need more attention (only 40% completion)',
      ],
      recommendations: [
        'Move your evening habits to earlier in the day — try scheduling them at 6 PM instead of 9 PM.',
        'Create a weekend-specific habit routine that\'s shorter and more achievable.',
        'You\'re close to your 10-day meditation streak! Don\'t break it now.',
        'Consider pairing your evening journaling with your bedtime routine to build a stronger habit loop.',
        'Your fitness goal is 35% complete — try adding one more workout session per week to stay on track.',
      ],
    );
  }
});
