import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/local/isar_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../onboarding/data/models/onboarding_pref_model.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7)),
    );
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    // Show splash screen smoothly for ~2.2 seconds before navigating
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    bool onboardingDone = false;
    if (!IsarService.isAvailable) {
      // Isar initializes in the background (non-blocking startup)
      try {
        await IsarService.initialize().timeout(const Duration(seconds: 2));
      } catch (_) {
        // Local DB unavailable — fall through with onboardingDone = false.
      }
    }
    if (!mounted) return;
    if (IsarService.isAvailable) {
      final isar = IsarService.instance;
      final pref = await isar.onboardingPrefModels.get(1);
      onboardingDone = pref?.isCompleted ?? false;
    }

    if (!mounted) return;
    if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
      return;
    }

    // Check if authenticated
    final authenticated = await ref.read(isAuthenticatedProvider.future);
    if (!mounted) return;

    if (authenticated) {
      // Best-effort: keep the backend's FCM token + timezone fresh on every
      // launch while logged in (tokens rotate, the device timezone can change,
      // and the previous device may be long gone).
      unawaited(FirebaseService.registerDeviceWithBackend());
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: const Color(0xFF8B6EF5).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      fontFamily: 'Inter',
                    ),
                    children: [
                      TextSpan(
                        text: 'Ur',
                        style: TextStyle(
                          color: Color(0xFFD8B4FE),
                        ),
                      ),
                      TextSpan(
                        text: 'Day',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The product of BEx Sigma Tech',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 64),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
