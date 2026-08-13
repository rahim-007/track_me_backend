import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_colors.dart';

class ThemeNotifier extends StateNotifier<bool> {
  static const _storage = FlutterSecureStorage();

  ThemeNotifier(super.initialState) {
    AppColors.isDarkMode = state;
  }

  Future<void> toggleTheme() async {
    final nextState = !state;
    await _storage.write(key: 'is_dark_mode', value: nextState.toString());
    AppColors.isDarkMode = nextState;
    state = nextState;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier(false);
});
