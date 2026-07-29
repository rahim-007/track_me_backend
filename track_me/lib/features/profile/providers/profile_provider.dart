import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int currentStreak;
  final int totalCompletedHabits;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.currentStreak,
    required this.totalCompletedHabits,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      currentStreak: json['currentStreak'] as int? ?? 0,
      totalCompletedHabits: json['totalCompletedHabits'] as int? ?? 0,
    );
  }
}

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  try {
    final client = DioClient();
    final response = await client.dio.get('/users/me');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  } catch (_) {
    // Return mock profile for offline/dev mode
    return const UserProfile(
      id: '1',
      name: 'Alex Johnson',
      email: 'alex@trackme.app',
      currentStreak: 7,
      totalCompletedHabits: 142,
    );
  }
});
