import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/local/isar_service.dart';
import '../../../core/local/user_local_cache.dart';
import '../../../core/network/dio_cache_interceptor.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/sync/sync_queue.dart';

// ─── State ────────────────────────────────────────────────────────────────────

sealed class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthGoogleLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final String userId;
  AuthSuccess({required this.userId});
}
class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}
class AuthAccountDeleting extends AuthState {}
class AuthAccountDeleted extends AuthState {}

// ─── Notifier ────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _secureStorage;
  final GoogleSignIn _googleSignIn;

  AuthNotifier({
    required FlutterSecureStorage secureStorage,
    required GoogleSignIn googleSignIn,
  })  : _secureStorage = secureStorage,
        _googleSignIn = googleSignIn,
        super(AuthInitial());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = AuthLoading();
    try {
      final client = DioClient();
      debugPrint('[AUTH] Attempting login to: ${client.dio.options.baseUrl}/auth/login');
      debugPrint('[AUTH] Email: $email');
      final response = await client.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      debugPrint('[AUTH] Login response status: ${response.statusCode}');
      final responseData = response.data['data'] ?? response.data;
      await _saveTokens(responseData);
      state = AuthSuccess(userId: responseData['user']['id'].toString());
      // Best-effort: register this device (FCM token + timezone) once logged in.
      unawaited(FirebaseService.registerDeviceWithBackend());
      unawaited(SyncManager.instance.sync());
    } catch (e) {
      debugPrint('[AUTH] ❌ Login FAILED: $e');
      if (e is DioException) {
        debugPrint('[AUTH] ❌ Status: ${e.response?.statusCode}');
        debugPrint('[AUTH] ❌ Body: ${e.response?.data}');
        debugPrint('[AUTH] ❌ URL: ${e.requestOptions.uri}');
      }
      state = AuthError(message: _parseError(e));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = AuthLoading();
    try {
      final client = DioClient();
      final response = await client.dio.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      final responseData = response.data['data'] ?? response.data;
      await _saveTokens(responseData);
      state = AuthSuccess(userId: responseData['user']['id'].toString());
      // Best-effort: register this device (FCM token + timezone) once logged in.
      unawaited(FirebaseService.registerDeviceWithBackend());
      unawaited(SyncManager.instance.sync());
    } catch (e) {
      state = AuthError(message: _parseError(e));
    }
  }

  Future<void> loginWithGoogle() async {
    state = AuthGoogleLoading();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = AuthInitial();
        return;
      }
      final googleAuth = await googleUser.authentication;
      final client = DioClient();
      final response = await client.dio.post(
        '/auth/google',
        data: {
          'googleId': googleUser.id,
          'email': googleUser.email,
          'name': googleUser.displayName ?? 'Google User',
          'avatarUrl': googleUser.photoUrl,
          'id_token': googleAuth.idToken,
        },
      );
      final responseData = response.data['data'] ?? response.data;
      await _saveTokens(responseData);
      state = AuthSuccess(userId: responseData['user']['id'].toString());
      // Best-effort: register this device (FCM token + timezone) once logged in.
      unawaited(FirebaseService.registerDeviceWithBackend());
      unawaited(SyncManager.instance.sync());
    } catch (e) {
      state = AuthError(message: _parseError(e));
    }
  }

  Future<void> forgotPassword({required String email}) async {
    state = AuthLoading();
    try {
      final client = DioClient();
      await client.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      state = AuthInitial();
    } catch (e) {
      state = AuthError(message: _parseError(e));
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    await _secureStorage.delete(key: AppConstants.userIdKey);
    await _googleSignIn.signOut();
    await UserLocalCache.instance.clear();
    DioCacheInterceptor().clear();
    await SyncQueue.instance.clear();
    if (IsarService.isAvailable) {
      try {
        await IsarService.clearAll();
      } catch (e) {
        debugPrint('[AUTH] Isar clearAll on logout failed (non-fatal): $e');
      }
    }
    state = AuthInitial();
  }

  // ─── Account Deletion ──────────────────────────────────────────────────────

  /// Permanently delete the authenticated user's account.
  ///
  /// 1. Calls DELETE /users/me on the backend (server-side deletion).
  /// 2. If the backend returns 404 (or 401 User not found), it means the account is already gone on the server.
  /// 3. In all successful/already-deleted cases: cleans up local Isar DB, secure storage, Google session, caches.
  /// 4. On network/unexpected errors: preserves local data and throws.
  ///
  /// Returns `true` on success.
  Future<bool> deleteAccount() async {
    state = AuthAccountDeleting();
    try {
      final client = DioClient();
      try {
        await client.dio.delete('/users/me');
      } on DioException catch (dioErr) {
        final statusCode = dioErr.response?.statusCode;
        final responseMsg = dioErr.response?.data is Map
            ? dioErr.response?.data['message']?.toString()
            : null;

        // 404 means user already does not exist on server.
        // 401 with 'User not found' also means the user was already deleted from DB.
        final isAlreadyDeleted = statusCode == 404 ||
            (statusCode == 401 && (responseMsg?.contains('User not found') ?? false));

        if (isAlreadyDeleted) {
          debugPrint('[AUTH] Account already deleted on server ($statusCode). Completing local cleanup.');
        } else {
          rethrow;
        }
      }

      // Server-side deletion succeeded (or was already deleted) — clean up locally.
      if (IsarService.isAvailable) {
        try {
          await IsarService.clearAll();
        } catch (e) {
          debugPrint('[AUTH] Isar clearAll failed (non-fatal): $e');
        }
      }

      // Clear secure storage (tokens, userId)
      await _secureStorage.delete(key: AppConstants.accessTokenKey);
      await _secureStorage.delete(key: AppConstants.refreshTokenKey);
      await _secureStorage.delete(key: AppConstants.userIdKey);

      // Clear caches and sync queues
      await UserLocalCache.instance.clear();
      DioCacheInterceptor().clear();
      await SyncQueue.instance.clear();

      // Sign out of Google
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('[AUTH] Google signOut failed (non-fatal): $e');
      }

      state = AuthAccountDeleted();
      return true;
    } catch (e) {
      debugPrint('[AUTH] ❌ Account deletion FAILED: $e');
      state = AuthError(message: _parseDeleteError(e));
      rethrow;
    }
  }

  String _parseDeleteError(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return 'Your session has expired. Please log in again and try deleting your account.';
      }
      if (statusCode == 404) {
        return 'Account not found. It may have already been deleted.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Unable to connect. Please check your internet connection and try again.';
      }
      if (error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'The request timed out. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: AppConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await _secureStorage.write(
      key: AppConstants.accessTokenKey,
      value: data['access_token'],
    );
    await _secureStorage.write(
      key: AppConstants.refreshTokenKey,
      value: data['refresh_token'],
    );
    await _secureStorage.write(
      key: AppConstants.userIdKey,
      value: data['user']['id'].toString(),
    );
    // Cache user profile for instant 0ms access across screens
    await UserLocalCache.instance.saveRawAuthUser(data);
  }

  String _parseError(dynamic error) {
    debugPrint('AuthNotifier Error: $error');
    try {
      final response = (error as dynamic).response;
      final statusCode = response?.statusCode as int?;

      // 503/502/504: backend is cold-starting on Render free tier.
      if (statusCode == 503 || statusCode == 502 || statusCode == 504) {
        return 'The server is starting up after a period of inactivity. '
            'Please wait a moment and try again.';
      }

      final msg = response?.data['message'];
      if (msg is List) return msg.first.toString();
      if (msg is String) return msg;
    } catch (_) {}
    if (error != null) {
      final errStr = error.toString();
      if (errStr.contains('PlatformException')) {
        return 'Google Sign-in failed: $errStr. Ensure your device\'s debug SHA-1 is registered in Google Cloud Console.';
      }
      if (errStr.contains('SocketException') || errStr.contains('Failed host lookup')) {
        return 'No internet connection. Please check your network and try again.';
      }
      return errStr;
    }
    return 'Something went wrong. Please try again.';
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    secureStorage: const FlutterSecureStorage(),
    googleSignIn: GoogleSignIn(
      scopes: ['email', 'profile'],
      // Web OAuth client ID from Firebase (client_type 3). On Android this
      // sets the audience of the ID token, which the backend verifies against
      // GOOGLE_CLIENT_ID.
      serverClientId: '768660062825-tka4s28ugud55ekh7rou9e8mt9ih8esg.apps.googleusercontent.com',
    ),
  ),
);

final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final notifier = ref.read(authNotifierProvider.notifier);
  return notifier.isAuthenticated();
});
