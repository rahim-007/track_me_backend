import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';

/// Dummy Billing Constants (Future-ready)
const String kMonthlyPrice = '₹199 / month';
const String kYearlyPrice = '₹1,499 / year';
const String kYearlySavingsBadge = 'SAVE 37%';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen>
    with SingleTickerProviderStateMixin {
  bool _isYearly = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onStartPremiumTapped() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Subscription coming soon.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onRestorePurchaseTapped() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Subscription management will be available soon.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Track Me Premium',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Current Plan Pill
              _buildCurrentPlanBadge(),
              const SizedBox(height: 16),

              // 2. Hero Section Card
              _buildHeroSection(),
              const SizedBox(height: 24),

              // 3. Billing Selector (Monthly vs Yearly)
              _buildBillingToggle(),
              const SizedBox(height: 28),

              // 4. Features List Header
              Text(
                'Everything Premium',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),

              // 5. Feature Items
              _buildFeatureItem(
                icon: Icons.all_inclusive_rounded,
                title: 'Unlimited Habits',
                description: 'Track unlimited habits and build stronger routines.',
                accentColor: AppColors.primary,
              ),
              _buildFeatureItem(
                icon: Icons.track_changes_rounded,
                title: 'Advanced Goals',
                description: 'Get deeper goal tracking and progress insights.',
                accentColor: const Color(0xFF3B82F6),
              ),
              _buildFeatureItem(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Advanced Cash Flow',
                description: 'Understand your income, expenses, savings, and financial trends.',
                accentColor: const Color(0xFF10B981),
              ),
              _buildFeatureItem(
                icon: Icons.auto_graph_rounded,
                title: 'Advanced Analytics',
                description: 'Unlock detailed weekly and monthly insights.',
                accentColor: const Color(0xFF8B5CF6),
              ),
              _buildFeatureItem(
                icon: Icons.auto_awesome_rounded,
                title: 'AI Insights',
                description: 'Get intelligent insights from your Track Me activity.',
                accentColor: const Color(0xFFEC4899),
              ),
              _buildFeatureItem(
                icon: Icons.notifications_active_rounded,
                title: 'Smart Reminders',
                description: 'Stay consistent with smarter reminders.',
                accentColor: const Color(0xFFF59E0B),
              ),
              _buildFeatureItem(
                icon: Icons.palette_rounded,
                title: 'Premium Customization',
                description: 'Unlock additional personalization options.',
                accentColor: const Color(0xFF06B6D4),
              ),
              _buildFeatureItem(
                icon: Icons.file_download_outlined,
                title: 'Data Export',
                description: 'Export and manage your Track Me data.',
                accentColor: const Color(0xFF64748B),
              ),

              const SizedBox(height: 28),

              // 6. Primary CTA Button
              ElevatedButton(
                onPressed: _onStartPremiumTapped,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Start Premium',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 7. Free Trial Details
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '7-day free trial',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '•',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    'Cancel anytime',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 8. Restore Purchase Link
              Center(
                child: TextButton(
                  onPressed: _onRestorePurchaseTapped,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    'Restore Purchase',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPlanBadge() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.soft,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current Plan: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Free',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          ...AppShadows.elevated,
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'TRACK ME PREMIUM',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Unlock the complete Track Me experience.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Build better habits, achieve your goals, and understand your money with powerful premium features.',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        children: [
          // Monthly Option
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_isYearly ? AppColors.surfaceElevated : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: !_isYearly ? AppShadows.soft : [],
                  border: !_isYearly
                      ? Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5)
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      'Monthly',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: !_isYearly ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kMonthlyPrice,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: !_isYearly ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Yearly Option (with SAVE badge)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isYearly ? AppColors.surfaceElevated : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _isYearly ? AppShadows.soft : [],
                  border: _isYearly
                      ? Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5)
                      : null,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Yearly',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _isYearly ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            kYearlySavingsBadge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kYearlyPrice,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isYearly ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
