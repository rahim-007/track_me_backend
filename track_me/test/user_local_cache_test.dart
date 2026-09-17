import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/core/local/user_local_cache.dart';
import 'package:track_me/features/profile/providers/profile_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserLocalCache Tests', () {
    test('saves and retrieves profile in memory', () async {
      final cache = UserLocalCache.instance;
      const profile = UserProfile(
        id: 'user_123',
        name: 'Test User',
        email: 'test@example.com',
        avatarUrl: 'https://example.com/avatar.png',
        currentStreak: 5,
        longestStreak: 12,
        totalCompletedHabits: 42,
        activeGoals: 3,
        totalHabits: 10,
        goalsAchieved: 2,
      );

      await cache.saveProfile(profile);
      expect(cache.inMemoryProfile, isNotNull);
      expect(cache.inMemoryProfile!.id, 'user_123');
      expect(cache.inMemoryProfile!.name, 'Test User');
      expect(cache.inMemoryProfile!.email, 'test@example.com');
      expect(cache.inMemoryProfile!.currentStreak, 5);

      final retrieved = await cache.getProfile();
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'user_123');
      expect(retrieved.name, 'Test User');
    });

    test('saveRawAuthUser properly parses auth response and caches', () async {
      final cache = UserLocalCache.instance;
      final authResponse = {
        'access_token': 'test_token',
        'refresh_token': 'refresh_token',
        'user': {
          'id': 'auth_user_999',
          'name': 'Auth User',
          'email': 'auth@example.com',
          'avatarUrl': 'https://example.com/pic.jpg',
          'currentStreak': 7,
          'longestStreak': 14,
          'totalCompletedHabits': 25,
        },
      };

      await cache.saveRawAuthUser(authResponse);
      expect(cache.inMemoryProfile, isNotNull);
      expect(cache.inMemoryProfile!.id, 'auth_user_999');
      expect(cache.inMemoryProfile!.name, 'Auth User');
      expect(cache.inMemoryProfile!.email, 'auth@example.com');
      expect(cache.inMemoryProfile!.currentStreak, 7);
    });

    test('clear resets inMemoryProfile', () async {
      final cache = UserLocalCache.instance;
      await cache.clear();
      expect(cache.inMemoryProfile, isNull);
    });
  });
}
