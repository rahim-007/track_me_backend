import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/local/isar_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../data/models/onboarding_pref_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: 'Build Better Habits',
      description:
          'Create healthy habits, track your streaks, and build lasting consistency with simple daily tracking.',
      icon: Icons.task_alt_rounded,
      gradientColors: AppColors.primaryGradientColors,
    ),
    _OnboardingPage(
      title: 'Track Your Progress',
      description:
          'Monitor your habits, goals, and daily activities in one place and see how far you\u2019ve come.',
      icon: Icons.insights_rounded,
      gradientColors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    ),
    _OnboardingPage(
      title: 'Manage Your Goals',
      description:
          'Set meaningful goals, track milestones, and stay focused on the progress that matters to you.',
      icon: Icons.track_changes_rounded,
      gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    _OnboardingPage(
      title: 'Take Control of Your Day',
      description:
          'Track your habits, goals, and finances, build better routines, and stay consistent every day.',
      icon: Icons.emoji_events_rounded,
      gradientColors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
    ),
  ];

  Future<void> _completeOnboarding() async {
    if (IsarService.isAvailable) {
      final isar = IsarService.instance;
      await isar.writeTxn(() async {
        await isar.onboardingPrefModels.put(OnboardingPrefModel()
          ..id = 1
          ..isCompleted = true
          ..completedAt = DateTime.now());
      });
    }
    if (mounted) context.go(AppRoutes.login);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isLast)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return _OnboardingPageView(page: _pages[index]);
                },
              ),
            ),

            // Bottom Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Progress Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Action Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: page.gradientColors.first,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isLast ? 'Get Started 🚀' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive sizing: short screens use a more compact illustration
          // and spacing so the content never overflows, while taller screens
          // keep the full, balanced layout.
          final compact = constraints.maxHeight < 540;
          final circleSize = compact ? 150.0 : 200.0;
          final iconSize = compact ? 54.0 : 72.0;
          final afterIllustrationGap = compact ? 32.0 : 48.0;
          final titleGap = compact ? 12.0 : 16.0;

          // Centers the content when there is room and scrolls on very small
          // screens as a fallback, guaranteeing no "bottom overflowed" errors.
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Illustration Container
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: page.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.elevated,
                      ),
                      child: Center(
                        child: Icon(
                          page.icon,
                          size: iconSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: afterIllustrationGap),

                  // Title
                  Text(
                    page.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: titleGap),

                  // Description
                  Text(
                    page.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
  });
}
