import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/local/user_local_cache.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/sync/sync_queue.dart';
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      totalHabits: json['_count']?['habits'] as int? ?? 0,
      goalsAchieved: json['_count']?['goals'] as int? ?? 0,
    );
  }
}

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  ProfileNotifier()
      : super(
          UserLocalCache.instance.inMemoryProfile != null
              ? AsyncValue.data(UserLocalCache.instance.inMemoryProfile)
              : const AsyncValue.loading(),
        ) {
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    // 1. Instant load from persistent disk/Isar cache if not already loaded
    if (state.valueOrNull == null) {
      final cached = await UserLocalCache.instance.getProfile();
      if (cached != null && mounted) {
        state = AsyncValue.data(cached);
      }
    }

    // 2. Fetch fresh data from network
    await fetchProfile();
  }

  Future<void> fetchProfile() async {
    // Sticky loading: keep showing the cached/previous profile while refreshing
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
      await UserLocalCache.instance.saveProfile(profile);
      if (!mounted) return;
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      if (!mounted) return;
      // If we already have a cached profile, keep showing it smoothly
      if (state.valueOrNull != null) {
        return;
      }
      final cached = await UserLocalCache.instance.getProfile();
      if (cached != null && mounted) {
        state = AsyncValue.data(cached);
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> updateProfile({required String name, String? avatarUrl}) async {
    final currentProfile = state.valueOrNull;
    if (currentProfile == null) return;

    // 1. Optimistic local update & instant cache save
    final updatedProfile = UserProfile(
      id: currentProfile.id,
      name: name,
      email: currentProfile.email,
      avatarUrl: avatarUrl ?? currentProfile.avatarUrl,
      currentStreak: currentProfile.currentStreak,
      longestStreak: currentProfile.longestStreak,
      totalCompletedHabits: currentProfile.totalCompletedHabits,
      activeGoals: currentProfile.activeGoals,
      createdAt: currentProfile.createdAt,
      totalHabits: currentProfile.totalHabits,
      goalsAchieved: currentProfile.goalsAchieved,
    );
    state = AsyncValue.data(updatedProfile);
    await UserLocalCache.instance.saveProfile(updatedProfile);

    // 2. Dispatch network update or enqueue for background sync
    try {
      final client = DioClient();
      final response = await client.dio.patch('/users/me', data: {
        'name': name,
        'avatarUrl': avatarUrl,
      });

      final updatedData = response.data['data'] ?? response.data;
      final serverProfile = UserProfile(
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
      await UserLocalCache.instance.saveProfile(serverProfile);
      if (!mounted) return;
      state = AsyncValue.data(serverProfile);
    } catch (e) {
      // Network failed: enqueue in background sync queue
      await SyncManager.instance.enqueue(
        SyncAction(
          type: SyncActionType.updateProfile,
          endpoint: '/users/me',
          method: 'PATCH',
          payload: {
            'name': name,
            'avatarUrl': avatarUrl,
          },
        ),
      );
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
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

  // When habits are loaded, the live habit calculations are authoritative.
  // Fall back to apiProfile only if habits haven't loaded yet.
  final int apiStreak = apiProfile?.currentStreak ?? 0;
  final int currentStreak =
      habitsState.hasValue ? liveCurrentStreak : apiStreak;

  final int apiLongest = apiProfile?.longestStreak ?? 0;
  final int longestStreak = habitsState.hasValue
      ? (liveLongestStreak > apiLongest ? liveLongestStreak : apiLongest)
      : apiLongest;

  final int totalCompletedHabits =
      (apiProfile?.totalCompletedHabits ?? 0) >= liveCompletedHabits
          ? (apiProfile?.totalCompletedHabits ?? 0)
          : (habitsState.hasValue
              ? liveCompletedHabits
              : (apiProfile?.totalCompletedHabits ?? 0));
  final int totalHabits =
      habitsState.hasValue ? liveTotalHabits : (apiProfile?.totalHabits ?? 0);

  final int activeGoals =
      goalsState.hasValue ? liveActiveGoals : (apiProfile?.activeGoals ?? 0);
  final int totalGoals = goalsState.hasValue
      ? liveTotalGoals
      : ((apiProfile?.goalsAchieved ?? 0) + (apiProfile?.activeGoals ?? 0));
  final int goalsAchieved = goalsState.hasValue
      ? liveGoalsAchieved
      : (apiProfile?.goalsAchieved ?? 0);

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
