import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: MaterialApp.router(
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
      ),
    );
  }
}
