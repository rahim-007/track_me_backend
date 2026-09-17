import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../local/json_file_cache.dart';

/// Representation of a cached HTTP response.
class CacheEntry {
  final dynamic data;
  final int statusCode;
  final Map<String, List<String>> headers;
  final int timestamp;
  final int maxAgeMs;
  final String? tag;

  CacheEntry({
    required this.data,
    required this.statusCode,
    required this.headers,
    required this.timestamp,
    required this.maxAgeMs,
    this.tag,
  });

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch - timestamp > maxAgeMs;

  Map<String, dynamic> toJson() => {
        'data': data,
        'statusCode': statusCode,
        'headers': headers,
        'timestamp': timestamp,
        'maxAgeMs': maxAgeMs,
        'tag': tag,
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
        data: json['data'],
        statusCode: json['statusCode'] as int? ?? 200,
        headers: (json['headers'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as List).cast<String>()),
            ) ??
            {},
        timestamp: json['timestamp'] as int? ?? 0,
        maxAgeMs: json['maxAgeMs'] as int? ?? (5 * 60 * 1000),
        tag: json['tag'] as String?,
      );
}

/// High-performance Dio caching interceptor.
///
/// Features:
/// 1. Dual-layer cache: ultra-fast In-Memory LRU + Persistent Disk Cache.
/// 2. Zero-latency instant responses for idempotent GET requests.
/// 3. Transparent Offline Fallback: serves cached data even when offline or during server cold-starts.
/// 4. Smart Auto-Invalidation: automatically purges relevant cache tags on POST, PUT, PATCH, DELETE mutations.
class DioCacheInterceptor extends Interceptor {
  static final DioCacheInterceptor _instance = DioCacheInterceptor._();
  factory DioCacheInterceptor() => _instance;
  DioCacheInterceptor._();

  static const String cacheDiskPrefix = 'http_cache_';
  static const int defaultMaxAgeMs = 5 * 60 * 1000; // 5 minutes default

  // In-memory LRU cache
  final Map<String, CacheEntry> _memoryCache = {};
  static const int _maxMemoryEntries = 100;

  // Track timestamp of last invalidation per tag (and global '*')
  final Map<String, int> _tagInvalidatedAt = {};

  bool isTagInvalidated(String tag, int timestamp) {
    final tagInvalidated = _tagInvalidatedAt[tag] ?? 0;
    final globalInvalidated = _tagInvalidatedAt['*'] ?? 0;
    return timestamp <= tagInvalidated || timestamp <= globalInvalidated;
  }

  /// Generate a consistent cache key from a request.
  String _generateCacheKey(RequestOptions options) {
    final query = options.queryParameters.isNotEmpty
        ? '?${jsonEncode(options.queryParameters)}'
        : '';
    return '${options.method.toUpperCase()}_${options.uri.path}$query';
  }

  /// Derive cache tag from path to allow bulk invalidations.
  String _deriveTag(String path) {
    if (path.startsWith('/habits') || path.startsWith('/habit-logs') || path.startsWith('/missed-reasons')) {
      return 'habits';
    }
    if (path.startsWith('/goals')) {
      return 'goals';
    }
    if (path.startsWith('/users')) {
      return 'users';
    }
    if (path.startsWith('/cashflow')) {
      return 'cashflow';
    }
    if (path.startsWith('/notifications')) {
      return 'notifications';
    }
    if (path.startsWith('/ai')) {
      return 'ai';
    }
    return 'default';
  }

  /// Determine default TTL based on endpoint.
  int _determineTtl(RequestOptions options) {
    if (options.extra.containsKey('cacheMaxAge')) {
      final val = options.extra['cacheMaxAge'];
      if (val is Duration) return val.inMilliseconds;
      if (val is int) return val;
    }

    final path = options.uri.path;
    if (path.startsWith('/ai/')) {
      return 15 * 60 * 1000; // 15 mins for AI insights
    }
    if (path.startsWith('/users/me/stats')) {
      return 2 * 60 * 1000; // 2 mins for stats
    }
    if (path.startsWith('/users/me')) {
      return 10 * 60 * 1000; // 10 mins for profile
    }
    if (path.startsWith('/notifications')) {
      return 2 * 60 * 1000; // 2 mins for notifications
    }
    return defaultMaxAgeMs;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Only cache GET or HEAD requests
    final method = options.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD') {
      return handler.next(options);
    }

    // Check if bypass requested
    final noCache = options.extra['noCache'] == true;
    if (noCache) {
      return handler.next(options);
    }

    final cacheKey = _generateCacheKey(options);
    final tag = _deriveTag(options.uri.path);

    // 1. Check memory cache
    final memEntry = _memoryCache[cacheKey];
    if (memEntry != null) {
      if (!memEntry.isExpired && !isTagInvalidated(tag, memEntry.timestamp)) {
        options.extra['_fromCache'] = true;
        return handler.resolve(_buildResponse(memEntry, options));
      } else {
        _memoryCache.remove(cacheKey);
      }
    }

    // 2. Check disk cache
    try {
      final diskEntry = await JsonFileCache.read<CacheEntry>(
        '$cacheDiskPrefix$cacheKey',
        (json) => CacheEntry.fromJson(json as Map<String, dynamic>),
      );

      if (diskEntry != null) {
        if (isTagInvalidated(tag, diskEntry.timestamp) || diskEntry.isExpired) {
          // Stale or invalidated disk entry - purge it so it never poisons future requests
          unawaited(JsonFileCache.delete('$cacheDiskPrefix$cacheKey'));
        } else {
          // Populate memory cache
          _putInMemory(cacheKey, diskEntry);
          options.extra['_fromCache'] = true;
          return handler.resolve(_buildResponse(diskEntry, options));
        }
      }
    } catch (_) {
      // Ignore disk read error and proceed to network
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final method = response.requestOptions.method.toUpperCase();

    // Cache successful GET responses
    if ((method == 'GET' || method == 'HEAD') &&
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final noCache = response.requestOptions.extra['noCache'] == true;
      if (!noCache && response.data != null) {
        _saveToCache(response);
      }
    }

    // On mutations, invalidate related caches
    if (method == 'POST' || method == 'PUT' || method == 'PATCH' || method == 'DELETE') {
      _invalidateForMutation(response.requestOptions);
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final method = err.requestOptions.method.toUpperCase();

    // If network error on GET, attempt to serve cached copy (even if expired)
    if (method == 'GET' || method == 'HEAD') {
      final cacheKey = _generateCacheKey(err.requestOptions);
      final memEntry = _memoryCache[cacheKey];

      if (memEntry != null) {
        debugPrint('[DioCache] Serving stale memory cache for ${err.requestOptions.uri.path}');
        return handler.resolve(_buildResponse(memEntry, err.requestOptions, isStaleFallback: true));
      }

      try {
        final diskEntry = await JsonFileCache.read<CacheEntry>(
          '$cacheDiskPrefix$cacheKey',
          (json) => CacheEntry.fromJson(json as Map<String, dynamic>),
        );
        if (diskEntry != null) {
          _putInMemory(cacheKey, diskEntry);
          debugPrint('[DioCache] Serving stale disk cache for ${err.requestOptions.uri.path}');
          return handler.resolve(_buildResponse(diskEntry, err.requestOptions, isStaleFallback: true));
        }
      } catch (_) {}
    }

    handler.next(err);
  }

  void _saveToCache(Response response) {
    final cacheKey = _generateCacheKey(response.requestOptions);
    final tag = _deriveTag(response.requestOptions.uri.path);
    final maxAge = _determineTtl(response.requestOptions);

    final entry = CacheEntry(
      data: response.data,
      statusCode: response.statusCode ?? 200,
      headers: response.headers.map,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      maxAgeMs: maxAge,
      tag: tag,
    );

    _putInMemory(cacheKey, entry);

    // Asynchronously write to disk cache
    JsonFileCache.write('$cacheDiskPrefix$cacheKey', entry.toJson());
  }

  void _putInMemory(String key, CacheEntry entry) {
    if (_memoryCache.length >= _maxMemoryEntries) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
    _memoryCache[key] = entry;
  }

  Response _buildResponse(
    CacheEntry entry,
    RequestOptions options, {
    bool isStaleFallback = false,
  }) {
    return Response(
      data: entry.data,
      statusCode: entry.statusCode,
      headers: Headers.fromMap(entry.headers),
      requestOptions: options,
      extra: {
        ...options.extra,
        'fromCache': true,
        'isStaleFallback': isStaleFallback,
        'cachedAt': entry.timestamp,
      },
    );
  }

  /// Automatically invalidate cache entries when a mutation occurs.
  void _invalidateForMutation(RequestOptions options) {
    final path = options.uri.path;
    final tag = _deriveTag(path);
    invalidateTag(tag);

    // Cross-tag dependencies
    if (tag == 'habits' || tag == 'goals') {
      invalidateTag('users'); // streak & stats change
      invalidateTag('ai');    // ai insights change
    }
  }

  /// Invalidate all cache entries associated with a tag (both in-memory and on disk).
  void invalidateTag(String tag) {
    _tagInvalidatedAt[tag] = DateTime.now().millisecondsSinceEpoch;
    final keysToRemove = <String>[];
    _memoryCache.removeWhere((k, v) {
      if (v.tag == tag) {
        keysToRemove.add(k);
        return true;
      }
      return false;
    });
    for (final k in keysToRemove) {
      unawaited(JsonFileCache.delete('$cacheDiskPrefix$k'));
    }
    debugPrint('[DioCache] Invalidate cache tag: $tag (purged ${keysToRemove.length} entries)');
  }

  /// Invalidate cache entries matching a path substring.
  void invalidatePath(String pathSubstring) {
    final keysToRemove = <String>[];
    _memoryCache.removeWhere((k, _) {
      if (k.contains(pathSubstring)) {
        keysToRemove.add(k);
        return true;
      }
      return false;
    });
    for (final k in keysToRemove) {
      unawaited(JsonFileCache.delete('$cacheDiskPrefix$k'));
    }
    debugPrint('[DioCache] Invalidate path matching: $pathSubstring (purged ${keysToRemove.length} entries)');
  }

  /// Completely clear all in-memory and disk cache.
  void clear() {
    _tagInvalidatedAt['*'] = DateTime.now().millisecondsSinceEpoch;
    for (final k in _memoryCache.keys) {
      unawaited(JsonFileCache.delete('$cacheDiskPrefix$k'));
    }
    _memoryCache.clear();
    debugPrint('[DioCache] Memory cache cleared and all tags invalidated');
  }
}

