import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:track_me/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Login Screen'))),
        ),
      ],
    );
  }

  Future<void> pumpOnboarding(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: buildRouter()),
    );
    await tester.pumpAndSettle();
  }

  /// The active page indicator is the pill (width 24) among the dots.
  int activeIndicatorCount(WidgetTester tester) {
    return tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .where((w) => w.constraints?.maxWidth == 24)
        .length;
  }

  testWidgets('shows the four onboarding pages and advances with Next',
      (tester) async {
    await pumpOnboarding(tester);

    // Page 1
    expect(find.text('Build Better Habits'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Get Started 🚀'), findsNothing);
    expect(activeIndicatorCount(tester), 1);

    // Page 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Track Your Progress'), findsOneWidget);
    expect(activeIndicatorCount(tester), 1);

    // Page 3
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Manage Your Goals'), findsOneWidget);
    expect(activeIndicatorCount(tester), 1);

    // Page 4 — last page: Get Started replaces Next, Skip is hidden
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Take Control of Your Day'), findsOneWidget);
    expect(find.text('Get Started 🚀'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Skip'), findsNothing);
    expect(activeIndicatorCount(tester), 1);
  });

  testWidgets('swiping between pages updates the page and indicators',
      (tester) async {
    await pumpOnboarding(tester);

    // Swipe left to page 2
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Track Your Progress'), findsOneWidget);
    expect(activeIndicatorCount(tester), 1);

    // Swipe right back to page 1
    await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Build Better Habits'), findsOneWidget);
    expect(activeIndicatorCount(tester), 1);
  });

  testWidgets('Skip completes onboarding and navigates to login',
      (tester) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Login Screen'), findsOneWidget);
  });

  testWidgets('Get Started completes onboarding and navigates to login',
      (tester) async {
    await pumpOnboarding(tester);

    // Advance to the last page
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Get Started 🚀'));
    await tester.pumpAndSettle();

    expect(find.text('Login Screen'), findsOneWidget);
  });

  testWidgets('renders without overflow on small, medium, and large screens',
      (tester) async {
    const sizes = [
      Size(320, 480), // small Android
      Size(360, 640), // medium Android
      Size(412, 915), // large Android
      Size(432, 960), // extra-large Android
    ];

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpOnboarding(tester);
      expect(tester.takeException(), isNull,
          reason: 'page 1 overflowed at $size');

      // Swipe through every page and check for layout overflow.
      for (var i = 0; i < 3; i++) {
        await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'page ${i + 2} overflowed at $size');
      }
    }
  });
}
