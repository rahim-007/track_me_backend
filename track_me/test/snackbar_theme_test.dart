import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/core/theme/app_colors.dart';
import 'package:track_me/core/theme/app_theme.dart';

void main() {
  Future<void> pumpSnackbarApp(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications screen coming soon!'),
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('dark theme snackbar uses dark surface background and light text',
      (tester) async {
    AppColors.isDarkMode = true;
    await pumpSnackbarApp(tester, AppTheme.darkTheme);

    final snackbar = find.byType(SnackBar);
    expect(snackbar, findsOneWidget);

    // Background must be the dark surface color, never white.
    final material = tester.widget<Material>(
      find.descendant(of: snackbar, matching: find.byType(Material)).first,
    );
    expect(material.color, AppColors.surface);
    expect(material.color, isNot(Colors.white));

    // Text must be the light on-surface color.
    final textStyle = DefaultTextStyle.of(
      tester.element(find.descendant(
        of: snackbar,
        matching: find.text('Notifications screen coming soon!'),
      )),
    );
    expect(textStyle.style.color, AppColors.onSurface);
    expect(textStyle.style.color, isNot(Colors.white));
  });

  testWidgets(
      'light theme snackbar uses light surface background and dark text',
      (tester) async {
    AppColors.isDarkMode = false;
    await pumpSnackbarApp(tester, AppTheme.lightTheme);

    final snackbar = find.byType(SnackBar);
    expect(snackbar, findsOneWidget);

    final material = tester.widget<Material>(
      find.descendant(of: snackbar, matching: find.byType(Material)).first,
    );
    expect(material.color, AppColors.surface);

    final textStyle = DefaultTextStyle.of(
      tester.element(find.descendant(
        of: snackbar,
        matching: find.text('Notifications screen coming soon!'),
      )),
    );
    expect(textStyle.style.color, AppColors.onSurface);
  });

  testWidgets('snackbar theme keeps rounded corners and edge spacing',
      (tester) async {
    AppColors.isDarkMode = true;

    final dark = AppTheme.darkTheme.snackBarTheme;
    expect(dark.behavior, SnackBarBehavior.floating);
    expect(dark.backgroundColor, AppColors.surface);
    expect(dark.contentTextStyle?.color, AppColors.onSurface);
    expect(dark.insetPadding, const EdgeInsets.fromLTRB(16, 0, 16, 16));

    AppColors.isDarkMode = false;

    final light = AppTheme.lightTheme.snackBarTheme;
    expect(light.behavior, SnackBarBehavior.floating);
    expect(light.backgroundColor, AppColors.surface);
    expect(light.contentTextStyle?.color, AppColors.onSurface);
    expect(light.insetPadding, const EdgeInsets.fromLTRB(16, 0, 16, 16));
  });
}
