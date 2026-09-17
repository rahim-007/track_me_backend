import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/data/models/local/user_local_model.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../constants/app_constants.dart';
import 'isar_service.dart';
import 'json_file_cache.dart';

/// Manages persistent offline storage and caching for the authenticated user's profile and stats.
class UserLocalCache {
  UserLocalCache._();
  static final UserLocalCache instance = UserLocalCache._();

  static const String _cacheFileName = 'user_profile_cache';

  // Fast in-memory cache for synchronous zero-latency UI access
  UserProfile? _inMemoryProfile;

  UserProfile? get inMemoryProfile => _inMemoryProfile;

  /// Load cached user profile from persistent storage (JSON File Cache & Isar).
  Future<UserProfile?> getProfile() async {
    if (_inMemoryProfile != null) {
      return _inMemoryProfile;
    }

    // 1. Try reading from namespaced JSON cache
    try {
      final json = await JsonFileCache.read<Map<String, dynamic>>(
        _cacheFileName,
        (raw) => raw as Map<String, dynamic>,
      );

      if (json != null) {
        _inMemoryProfile = UserProfile.fromJson(json);
        return _inMemoryProfile;
      }
    } catch (e) {
      debugPrint('[UserLocalCache] Error reading JSON cache: $e');
    }

    // 2. Fallback to Isar UserLocalModel if available
    if (IsarService.isAvailable) {
      try {
        const storage = FlutterSecureStorage();
        final userId = await storage.read(key: AppConstants.userIdKey);
        if (userId != null && userId.isNotEmpty) {
          final isar = IsarService.instance;
          final isarUser = await isar.userLocalModels.getByUserId(userId);
          if (isarUser != null) {
            _inMemoryProfile = UserProfile(
              id: isarUser.userId,
              name: isarUser.name,
              email: isarUser.email,
              avatarUrl: isarUser.avatarUrl,
              currentStreak: 0,
              longestStreak: 0,
              totalCompletedHabits: 0,
              activeGoals: 0,
              totalHabits: 0,
              goalsAchieved: 0,
              createdAt: null,
            );
            return _inMemoryProfile;
          }
        }
      } catch (e) {
        debugPrint('[UserLocalCache] Error reading from Isar: $e');
      }
    }

    return null;
  }

  /// Persist a UserProfile object to both JSON cache and Isar.
  Future<void> saveProfile(UserProfile profile) async {
    _inMemoryProfile = profile;

    // 1. Write to JSON cache
    final json = {
      'id': profile.id,
      'name': profile.name,
      'email': profile.email,
      'avatarUrl': profile.avatarUrl,
      'currentStreak': profile.currentStreak,
      'longestStreak': profile.longestStreak,
      'totalCompletedHabits': profile.totalCompletedHabits,
      'activeGoals': profile.activeGoals,
      'createdAt': profile.createdAt?.toIso8601String(),
      '_count': {
        'habits': profile.totalHabits,
        'goals': profile.goalsAchieved,
      },
    };

    try {
      await JsonFileCache.write(_cacheFileName, json);
    } catch (e) {
      debugPrint('[UserLocalCache] Error writing JSON cache: $e');
    }

    // 2. Sync with Isar
    if (IsarService.isAvailable && profile.id.isNotEmpty) {
      try {
        final isar = IsarService.instance;
        final localModel = UserLocalModel()
          ..userId = profile.id
          ..name = profile.name
          ..email = profile.email
          ..avatarUrl = profile.avatarUrl
          ..lastSyncedAt = DateTime.now();

        await isar.writeTxn(() async {
          await isar.userLocalModels.putByUserId(localModel);
        });
      } catch (e) {
        debugPrint('[UserLocalCache] Error saving to Isar: $e');
      }
    }
  }

  /// Save raw JSON response received from login/register endpoints.
  Future<void> saveRawAuthUser(Map<String, dynamic> authResponse) async {
    try {
      final userObj = authResponse['user'] as Map<String, dynamic>?;
      if (userObj == null) return;

      final id = userObj['id']?.toString() ?? '';
      final name = userObj['name'] as String? ?? '';
      final email = userObj['email'] as String? ?? '';
      final avatarUrl = userObj['avatarUrl'] as String?;

      final profile = UserProfile(
        id: id,
        name: name,
        email: email,
        avatarUrl: avatarUrl,
        currentStreak: userObj['currentStreak'] as int? ?? 0,
        longestStreak: userObj['longestStreak'] as int? ?? 0,
        totalCompletedHabits: userObj['totalCompletedHabits'] as int? ?? 0,
        activeGoals: 0,
        totalHabits: 0,
        goalsAchieved: 0,
        createdAt: userObj['createdAt'] != null
            ? DateTime.tryParse(userObj['createdAt'].toString())
            : null,
      );

      await saveProfile(profile);
    } catch (e) {
      debugPrint('[UserLocalCache] saveRawAuthUser error: $e');
    }
  }

  /// Clear all cached user profile data.
  Future<void> clear() async {
    _inMemoryProfile = null;
    try {
      await JsonFileCache.write(_cacheFileName, null);
    } catch (_) {}
  }
}
