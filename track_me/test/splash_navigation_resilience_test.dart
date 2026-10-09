import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:track_me/features/auth/providers/auth_provider.dart';

class MockFailingSecureStorage extends Fake implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('Simulated Android KeyStore hardware failure');
  }
}

class MockHangingSecureStorage extends Fake implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    // Simulates an infinite hang / deadlock in KeyStore
    await Future<void>.delayed(const Duration(seconds: 10));
    return 'token';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthNotifier & isAuthenticated Resilience', () {
    test('isAuthenticated returns false when secure storage throws an exception', () async {
      final notifier = AuthNotifier(
        secureStorage: MockFailingSecureStorage(),
        googleSignIn: GoogleSignIn(scopes: []),
      );

      final isAuthed = await notifier.isAuthenticated();
      expect(isAuthed, isFalse);
    });

    test('isAuthenticated times out and returns false if secure storage hangs', () async {
      final notifier = AuthNotifier(
        secureStorage: MockHangingSecureStorage(),
        googleSignIn: GoogleSignIn(scopes: []),
      );

      final stopwatch = Stopwatch()..start();
      final isAuthed = await notifier.isAuthenticated();
      stopwatch.stop();

      expect(isAuthed, isFalse);
      // Verify it stopped within bounded timeout (~2.5s), not hanging for 10s
      expect(stopwatch.elapsedMilliseconds, lessThan(4500));
    });

    test('isAuthenticatedProvider catches error and returns false', () async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            (ref) => AuthNotifier(
              secureStorage: MockFailingSecureStorage(),
              googleSignIn: GoogleSignIn(scopes: []),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(isAuthenticatedProvider.future);
      expect(result, isFalse);
    });
  });
}
