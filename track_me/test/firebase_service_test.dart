import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/core/services/firebase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getFcmToken returns null when Firebase is unavailable (no crash)', () async {
    // In a unit test there is no FirebaseMessaging plugin channel, so
    // getToken() throws — the helper must swallow it and return null.
    final token = await FirebaseService.getFcmToken();
    expect(token, isNull);
  });

  test('registerTokenWithBackend is a no-op when no token exists (no crash)', () async {
    // Same environment: getFcmToken() -> null -> early return, never hits the
    // network. Must complete without throwing.
    await FirebaseService.registerTokenWithBackend();
  });

  test('syncTimezoneWithBackend is a no-op when the timezone plugin is missing (no crash)', () async {
    // In a unit test there is no flutter_timezone channel, so the lookup
    // throws — the helper must swallow it and never touch the network.
    await FirebaseService.syncTimezoneWithBackend();
  });

  test('registerDeviceWithBackend completes without throwing in a test env', () async {
    // Both sub-steps are best-effort; this must never throw.
    await FirebaseService.registerDeviceWithBackend();
  });
}
