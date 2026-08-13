import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';

import '../core/theme/theme_provider.dart';

class TrackMeApp extends ConsumerWidget {
  const TrackMeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp.router(
      // Rebuilding the whole tree on theme change forces every widget that
      // reads the static AppColors.* palette to re-evaluate — otherwise cards,
      // buttons and text that don't depend on Theme.of() stay light after
      // switching to dark mode.
      key: ValueKey(isDarkMode),
      title: 'Track Me',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
