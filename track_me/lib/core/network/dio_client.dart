import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../config/app_env.dart';
import '../constants/app_constants.dart';

class DioClient {
  DioClient._();

  static final DioClient _instance = DioClient._();
  factory DioClient() => _instance;

  late final Dio dio;
  final _secureStorage = const FlutterSecureStorage();
  final _logger = Logger();

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
          } else {
            await _clearTokens();
          }
        }
        handler.next(error);
      },
    );
  }

  InterceptorsWrapper _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (AppEnv.isDevelopment) {
          _logger.d(
            '→ ${options.method} ${options.uri}\n'
            'Headers: ${options.headers}\n'
            'Data: ${options.data}',
          );
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (AppEnv.isDevelopment) {
          _logger.d(
            '← ${response.statusCode} ${response.requestOptions.uri}\n'
            'Data: ${response.data}',
          );
        }
        handler.next(response);
      },
      onError: (error, handler) {
        _logger.e(
          '✖ ${error.response?.statusCode} ${error.requestOptions.uri}\n'
          'Message: ${error.message}',
        );
        handler.next(error);
      },
    );
  }

  InterceptorsWrapper _retryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.receiveTimeout) {
          try {
            final response = await dio.fetch(error.requestOptions);
            return handler.resolve(response);
          } catch (_) {}
        }
        handler.next(error);
      },
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(
        key: AppConstants.refreshTokenKey,
      );
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${AppEnv.baseUrl}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'] as String?;
      final newRefreshToken = response.data['refresh_token'] as String?;

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
