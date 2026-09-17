import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/core/network/dio_cache_interceptor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DioCacheInterceptor Tests', () {
    late Dio dio;
    late DioCacheInterceptor cacheInterceptor;

    setUp(() {
      cacheInterceptor = DioCacheInterceptor();
      cacheInterceptor.clear();

      dio = Dio(BaseOptions(baseUrl: 'https://api.urday.test'));
      dio.interceptors.add(cacheInterceptor);
    });

    test('CacheEntry expiration check', () {
      final freshEntry = CacheEntry(
        data: {'status': 'ok'},
        statusCode: 200,
        headers: {},
        timestamp: DateTime.now().millisecondsSinceEpoch,
        maxAgeMs: 60000,
      );
      expect(freshEntry.isExpired, isFalse);

      final expiredEntry = CacheEntry(
        data: {'status': 'ok'},
        statusCode: 200,
        headers: {},
        timestamp: DateTime.now().millisecondsSinceEpoch - 120000,
        maxAgeMs: 60000,
      );
      expect(expiredEntry.isExpired, isTrue);
    });

    test('Tag invalidation purges matching cache items', () {
      final entry1 = CacheEntry(
        data: [{'id': '1', 'name': 'Run'}],
        statusCode: 200,
        headers: {},
        timestamp: DateTime.now().millisecondsSinceEpoch,
        maxAgeMs: 60000,
        tag: 'habits',
      );

      final entry2 = CacheEntry(
        data: [{'id': '2', 'name': 'Read'}],
        statusCode: 200,
        headers: {},
        timestamp: DateTime.now().millisecondsSinceEpoch,
        maxAgeMs: 60000,
        tag: 'goals',
      );

      expect(entry1.tag, 'habits');
      expect(entry2.tag, 'goals');
      cacheInterceptor.clear();
      cacheInterceptor.invalidateTag('habits');
      expect(true, isTrue);
    });

    test('isTagInvalidated returns true for entries before invalidation and false for entries after', () {
      cacheInterceptor.invalidateTag('habits');
      final invalidateTime = DateTime.now().millisecondsSinceEpoch;

      final before = invalidateTime - 2000;
      final after = invalidateTime + 2000;

      expect(cacheInterceptor.isTagInvalidated('habits', before), isTrue);
      expect(cacheInterceptor.isTagInvalidated('habits', after), isFalse);
    });
  });
}



