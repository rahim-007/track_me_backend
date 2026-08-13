import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../habits/providers/habits_provider.dart';
import '../../goals/providers/goals_provider.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletedHabits;
  final int activeGoals;
  final DateTime? createdAt;
  final int totalHabits;
  final int goalsAchieved;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletedHabits,
    required this.activeGoals,
    this.createdAt,
    required this.totalHabits,
    required this.goalsAchieved,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalCompletedHabits: json['totalCompletedHabits'] as int? ?? 0,
      activeGoals: json['activeGoals'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      totalHabits: json['_count']?['habits'] as int? ?? 0,
      goalsAchieved: json['_count']?['goals'] as int? ?? 0,
    );
  }
}

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  ProfileNotifier() : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    // Sticky loading: keep showing the previous profile while refreshing so the
    // header doesn't flash blank on every stats refresh.
    state = const AsyncValue<UserProfile?>.loading().copyWithPrevious(state);
    try {
      final client = DioClient();
      final responses = await Future.wait([
        client.dio.get('/users/me'),
        client.dio.get('/users/me/stats'),
      ]);
      
      final profileData = responses[0].data['data'] ?? responses[0].data;
      final statsData = responses[1].data['data'] ?? responses[1].data;
      
      final merged = {
        ...profileData as Map<String, dynamic>,
        ...statsData as Map<String, dynamic>,
      };
      
      final profile = UserProfile.fromJson(merged);
      if (!mounted) return;
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      if (!mounted) return;
      // Surface the error instead of showing fake data.
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfile({required String name, String? avatarUrl}) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;
    
    try {
      final client = DioClient();
      final response = await client.dio.patch('/users/me', data: {
        'name': name,
        'avatarUrl': avatarUrl,
      });
      
      final updatedData = response.data['data'] ?? response.data;
      
      final updatedProfile = UserProfile(
        id: currentProfile.id,
        name: updatedData['name'] as String? ?? name,
        email: currentProfile.email,
        avatarUrl: updatedData['avatarUrl'] as String? ?? avatarUrl,
        currentStreak: currentProfile.currentStreak,
        longestStreak: currentProfile.longestStreak,
        totalCompletedHabits: currentProfile.totalCompletedHabits,
        activeGoals: currentProfile.activeGoals,
        createdAt: currentProfile.createdAt,
        totalHabits: currentProfile.totalHabits,
        goalsAchieved: currentProfile.goalsAchieved,
      );
      if (!mounted) return;
      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      rethrow;
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  // NOTE: no watches on habits/goals here — those providers changing (e.g. on
  // every habit toggle) used to recreate this notifier, re-fetching the profile
  // (and re-running the backend streak scan) and flashing the loading state.
  // Live stats are derived separately in userProfileStatsProvider instead.
  return ProfileNotifier();
});

class UserProfileStats {
  final int currentStreak;
  final int longestStreak;
  final int totalCompletedHabits;
  final int activeGoals;
  final int totalHabits;
  final int totalGoals;
  final int goalsAchieved;

  const UserProfileStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletedHabits,
    required this.activeGoals,
    required this.totalHabits,
    required this.totalGoals,
    required this.goalsAchieved,
  });
}

final userProfileStatsProvider = Provider<UserProfileStats>((ref) {
  final habitsState = ref.watch(habitsProvider);
  final goalsState = ref.watch(goalsProvider);
  final profileState = ref.watch(profileProvider);

  final apiProfile = profileState.valueOrNull;

  final liveCurrentStreak = ref.watch(currentStreakProvider);
  final liveLongestStreak = ref.watch(longestStreakProvider);
  final liveCompletedHabits = ref.watch(completedHabitsCountProvider);
  final liveTotalHabits = ref.watch(totalHabitsCountProvider);

  final liveActiveGoals = ref.watch(activeGoalsCountProvider);
  final liveTotalGoals = ref.watch(totalGoalsCountProvider);
  final liveGoalsAchieved = ref.watch(completedGoalsCountProvider);

  final int currentStreak = habitsState.hasValue ? liveCurrentStreak : (apiProfile?.currentStreak ?? 0);
  final int longestStreak = habitsState.hasValue
      ? (liveLongestStreak > (apiProfile?.longestStreak ?? 0) ? liveLongestStreak : (apiProfile?.longestStreak ?? 0))
      : (apiProfile?.longestStreak ?? 0);
  final int totalCompletedHabits = habitsState.hasValue ? liveCompletedHabits : (apiProfile?.totalCompletedHabits ?? 0);
  final int totalHabits = habitsState.hasValue ? liveTotalHabits : (apiProfile?.totalHabits ?? 0);

  final int activeGoals = goalsState.hasValue ? liveActiveGoals : (apiProfile?.activeGoals ?? 0);
  final int totalGoals = goalsState.hasValue ? liveTotalGoals : ((apiProfile?.goalsAchieved ?? 0) + (apiProfile?.activeGoals ?? 0));
  final int goalsAchieved = goalsState.hasValue ? liveGoalsAchieved : (apiProfile?.goalsAchieved ?? 0);

  return UserProfileStats(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    totalCompletedHabits: totalCompletedHabits,
    activeGoals: activeGoals,
    totalHabits: totalHabits,
    totalGoals: totalGoals,
    goalsAchieved: goalsAchieved,
  );
});

