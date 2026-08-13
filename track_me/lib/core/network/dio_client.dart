import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_env.dart';
import '../constants/app_constants.dart';

class DioClient {
  DioClient._();

  static final DioClient _instance = DioClient._();
  factory DioClient() => _instance;

  late final Dio dio;
  final _secureStorage = const FlutterSecureStorage();

  void init() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppEnv.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _authInterceptor(),
      _loggingInterceptor(),
      _retryInterceptor(),
    ]);
  }

  /// In-flight refresh future. All parallel 401s share the same refresh call so
  /// the rotating refresh token is never consumed by two requests at once (which
  /// previously invalidated the token and logged the user out).
  Future<bool>? _refreshing;

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(
          key: AppConstants.accessTokenKey,
        );
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final token = await _secureStorage.read(
              key: AppConstants.accessTokenKey,
            );
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
          // On definitive refresh failure the tokens were already cleared inside
          // _refreshToken; on transient network failures we intentionally keep
          // the session so the next app launch doesn't demand a login.
        }
        handler.next(error);
      },
    );
  }

  InterceptorsWrapper _loggingInterceptor() {
    // Lean debug logging: one compact line per request (method, path, status,
    // duration). Printing full request/response JSON bodies on every call is
    // surprisingly expensive on a phone in debug mode and made screens feel
    // sluggish.
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (AppEnv.isDevelopment) {
          options.extra['_startedAt'] = DateTime.now().millisecondsSinceEpoch;
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (AppEnv.isDevelopment) {
          _logRequestLine(response.requestOptions, response.statusCode);
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (AppEnv.isDevelopment) {
          _logRequestLine(error.requestOptions, error.response?.statusCode);
        }
        handler.next(error);
      },
    );
  }

  void _logRequestLine(RequestOptions options, int? status) {
    final startedAt = options.extra['_startedAt'] as int?;
    final ms = startedAt == null
        ? ''
        : ' (${DateTime.now().millisecondsSinceEpoch - startedAt}ms)';
    debugPrint('[api] ${options.method} ${options.uri.path} → $status$ms');
  }

  InterceptorsWrapper _retryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.receiveTimeout) {
          // Only auto-retry idempotent reads — retrying a POST on a flaky link
          // can duplicate data (e.g. double expenses) and doubles latency.
          final method = error.requestOptions.method.toUpperCase();
          if (method == 'GET' || method == 'HEAD') {
            try {
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (_) {}
          }
        }
        handler.next(error);
      },
    );
  }

  Future<bool> _refreshToken() {
    final inFlight = _refreshing;
    if (inFlight != null) return inFlight;

    final future = _doRefreshToken();
    _refreshing = future;
    future.whenComplete(() {
      if (identical(_refreshing, future)) {
        _refreshing = null;
      }
    });
    return future;
  }

  Future<bool> _doRefreshToken() async {
    final refreshToken = await _secureStorage.read(
      key: AppConstants.refreshTokenKey,
    );
    if (refreshToken == null) return false;

    try {
      final response = await Dio(
        BaseOptions(
          connectTimeout:
              const Duration(milliseconds: AppConstants.connectTimeout),
          receiveTimeout:
              const Duration(milliseconds: AppConstants.receiveTimeout),
          sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
        ),
      ).post(
        '${AppEnv.baseUrl}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final responseData = response.data['data'] ?? response.data;
      final newAccessToken = responseData['access_token'] as String?;
      final newRefreshToken = responseData['refresh_token'] as String?;

      if (newAccessToken != null) {
        await _secureStorage.write(
          key: AppConstants.accessTokenKey,
          value: newAccessToken,
        );
        if (newRefreshToken != null) {
          await _secureStorage.write(
            key: AppConstants.refreshTokenKey,
            value: newRefreshToken,
          );
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401) {
        // The refresh token was definitively rejected (expired/invalid) —
        // only then is it safe to drop the session.
        await _clearTokens();
      }
      // Network / timeout errors keep the stored tokens so a temporary outage
      // never forces the user to log in again.
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    await _secureStorage.delete(key: AppConstants.userIdKey);
  }
}
