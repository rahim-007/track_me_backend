import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../providers/profile_provider.dart';
import '../../../auth/providers/auth_provider.dart';

/// Renders base64 data URLs, network URLs, or initial avatar fallback cleanly.
Widget buildAvatarWidget(
  String? avatarUrl, {
  String name = 'User',
  double fontSize = 32,
  Color iconColor = Colors.white,
}) {
  if (avatarUrl == null || avatarUrl.trim().isEmpty) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: iconColor,
        ),
      ),
    );
  }
  final url = avatarUrl.trim();
  if (url.startsWith('data:image/')) {
    try {
      final base64Data = url.split(',').last;
      final bytes = base64Decode(base64Data);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: iconColor,
            ),
          ),
        ),
      );
    } catch (_) {
      return Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: iconColor,
          ),
        ),
      );
    }
  }

  return CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (context, url) => const Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
    errorWidget: (context, url, error) => Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: iconColor,
        ),
      ),
    ),
  );
}

final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  } catch (_) {
    return '1.0.1';
  }
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserProfile? user) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => EditProfileDialog(user: user),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of Track Me? Your offline data will be kept safe on this device.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─── Account Deletion Flow ─────────────────────────────────────────────────

  void _showDeleteAccountWarning(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you delete your account, the following data will be permanently removed:',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildDeletionItem('Your profile and personal information'),
            _buildDeletionItem('All habits and completion history'),
            _buildDeletionItem('All goals and progress records'),
            _buildDeletionItem('Cash flow and financial records'),
            _buildDeletionItem('AI reports and analytics data'),
            _buildDeletionItem('Notification history'),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showDeleteAccountFinalConfirm(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.remove_circle_outline, size: 14, color: AppColors.error.withOpacity(0.7)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountFinalConfirm(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DeleteAccountFinalDialog(
        onConfirm: () async {
          try {
            await ref.read(authNotifierProvider.notifier).deleteAccount();
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Your account has been permanently deleted.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              );
              context.go(AppRoutes.login);
            }
          } catch (_) {
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
            final authState = ref.read(authNotifierProvider);
            if (context.mounted && authState is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(authState.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              );
            }
          }
        },
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch themeProvider to rebuild instantly when Dark Mode toggles
    ref.watch(themeProvider);
    final isDark = AppColors.isDarkMode;
    final profileAsync = ref.watch(profileProvider);
    final stats = ref.watch(userProfileStatsProvider);
    final versionAsync = ref.watch(appVersionProvider);

    final user = profileAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(profileProvider.notifier).fetchProfile(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              // ─── 1. Header Row (Matching Dashboard / Habits / Cash Flow) ───────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Account, statistics & app preferences',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Quick Edit Button
                  GestureDetector(
                    onTap: () => _showEditProfileDialog(context, ref, user),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B162C) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2A2244) : const Color(0xFFEAE8F5),
                        ),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Notifications Shortcut Button
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.notifications),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5848D6),
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6942FF), Color(0xFF4930D8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5848D6).withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ─── 2. Signature Profile Hero Card ──────────────────────────────
              _ProfileHeroCard(
                user: user,
                onEdit: () => _showEditProfileDialog(context, ref, user),
              ),

              const SizedBox(height: 20),

              // ─── 3. Metrics Trio Row ─────────────────────────────────────────
              _ProfileMetricsRow(stats: stats),

              const SizedBox(height: 20),

              // ─── 4. Track Me Premium Promo Card ──────────────────────────────
              _PremiumPromoBanner(
                onTap: () => context.push(AppRoutes.premium),
              ),

              const SizedBox(height: 24),

              // ─── 5. Achievements Section ─────────────────────────────────────
              const _SectionHeader('ACHIEVEMENTS'),
              const SizedBox(height: 12),
              _AchievementsCarousel(stats: stats),

              const SizedBox(height: 24),

              // ─── 6. Detailed Lifetime Statistics ─────────────────────────────
              const _SectionHeader('LIFETIME STATISTICS'),
              const SizedBox(height: 12),
              _DetailedStatsCard(
                user: user,
                stats: stats,
              ),

              const SizedBox(height: 24),

              // ─── 7. App Preferences Section ──────────────────────────────────
              const _SectionHeader('APP PREFERENCES'),
              const SizedBox(height: 12),
              _SettingsGroupCard(
                children: [
                  _SettingsSwitchTile(
                    icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    title: 'Dark Mode',
                    subtitle: isDark ? 'Obsidian theme enabled' : 'Clean light theme enabled',
                    value: isDark,
                    onChanged: (_) {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                  ),
                  _SettingsNavTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'Notification Center',
                    subtitle: 'Inbox, habit reminders & reports',
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── 8. Account & Security Section ───────────────────────────────
              const _SectionHeader('ACCOUNT & SECURITY'),
              const SizedBox(height: 12),
              _SettingsGroupCard(
                children: [
                  _SettingsNavTile(
                    icon: Icons.person_rounded,
                    title: 'Edit Profile Information',
                    subtitle: 'Change your display name and photo',
                    onTap: () => _showEditProfileDialog(context, ref, user),
                  ),
                  _SettingsNavTile(
                    icon: Icons.shield_rounded,
                    title: 'Privacy & Security',
                    subtitle: 'RLS database security & data safety',
                    onTap: () {
                      _showInfoDialog(
                        context,
                        'Privacy & Data Security',
                        'Track Me uses Supabase Row Level Security (RLS). All habit entries, goals, and financial cashflow items are private and strictly accessible only to your authenticated user account.',
                      );
                    },
                  ),
                  _SettingsNavTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account and data',
                    onTap: () => _showDeleteAccountWarning(context, ref),
                  ),
                  _SettingsNavTile(
                    icon: Icons.cloud_done_rounded,
                    title: 'Offline Sync Status',
                    subtitle: 'All records synced with local Isar cache',
                    trailingWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Synced',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    onTap: () {
                      _showInfoDialog(
                        context,
                        'Offline First Sync',
                        'Track Me functions seamlessly offline. Your changes are instantly written to your device storage and synchronized automatically when an active connection is available.',
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── 9. Support & About Section ──────────────────────────────────
              const _SectionHeader('SUPPORT & ABOUT'),
              const SizedBox(height: 12),
              _SettingsGroupCard(
                children: [
                  _SettingsNavTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & FAQ',
                    subtitle: 'Frequently asked questions & guides',
                    onTap: () {
                      _showInfoDialog(
                        context,
                        'Help & Support',
                        'Need assistance with Track Me?\n\n• Habits: Check in daily or record skip reasons.\n• Goals: Set target dates and adjust progress percentage.\n• Cash Flow: Record income and outflow to track net liquidity.\n\nFor support inquiries, reach out to support@trackme.app.',
                      );
                    },
                  ),
                  _SettingsNavTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About Track Me',
                    subtitle: 'AI-Powered Productivity Application',
                    trailingWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'v${versionAsync.valueOrNull ?? '1.0.1'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    onTap: () {
                      _showInfoDialog(
                        context,
                        'Track Me v${versionAsync.valueOrNull ?? '1.0.1'}',
                        'Track Me combines Habit Tracking, Goal Tracking, and Cash Flow Financial Management into one unified, offline-first productivity platform powered by Gemini AI.',
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ─── 10. Logout Button ───────────────────────────────────────────
              GestureDetector(
                onTap: () => _confirmLogout(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x1CE06B6B) : const Color(0x10C95252),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header Widget ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ─── 2. Signature Profile Hero Card ──────────────────────────────────────────

class _ProfileHeroCard extends StatelessWidget {
  final UserProfile? user;
  final VoidCallback onEdit;

  const _ProfileHeroCard({
    required this.user,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5848D6),
        gradient: const LinearGradient(
          colors: [Color(0xFF5848D6), Color(0xFF4325D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5848D6).withOpacity(0.35),
            blurRadius: 28,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ProfileWavePainter()),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Pill Row: Plan Badge & Edit Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              size: 14,
                              color: Color(0xFFFFD166),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'TRACK ME MEMBER',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // User Avatar + Details
                  Row(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: buildAvatarWidget(
                                user?.avatarUrl,
                                name: user?.name ?? 'User',
                                fontSize: 28,
                                iconColor: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: onEdit,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6942FF),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name.isNotEmpty == true ? user!.name : 'User',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email.isNotEmpty == true ? user!.email : 'user@trackme.app',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (user?.createdAt != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Member since ${DateFormat('MMM yyyy').format(user!.createdAt!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.95),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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

// ─── 3. Metrics Trio Row (Matching Dashboard / Cashflow) ─────────────────────

class _ProfileMetricsRow extends StatelessWidget {
  final UserProfileStats stats;
  const _ProfileMetricsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode;

    return Row(
      children: [
        _buildMetricItem(
          emoji: '🔥',
          value: '${stats.currentStreak}',
          unit: 'Days',
          label: 'Current Streak',
          valueColor: AppColors.warning,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _buildMetricItem(
          emoji: '✅',
          value: '${stats.totalCompletedHabits}',
          unit: 'Done',
          label: 'Habits Done',
          valueColor: AppColors.success,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _buildMetricItem(
          emoji: '🎯',
          value: '${stats.activeGoals}',
          unit: 'Active',
          label: 'Goals Active',
          valueColor: const Color(0xFF3B82F6),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required String emoji,
    required String value,
    required String unit,
    required String label,
    required Color valueColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B162C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2244) : const Color(0xFFEAE8F5),
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: valueColor,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 4. Track Me Premium Promo Card ──────────────────────────────────────────

class _PremiumPromoBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumPromoBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1434) : const Color(0xFFF3F0FF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF3B2F6E) : const Color(0xFFDED7FC),
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB800), Color(0xFFFF8A00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB800).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Track Me Premium',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5848D6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Unlock AI Insights & Unlimited Habits',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF5848D6).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Color(0xFF5848D6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 5. Achievements Carousel ────────────────────────────────────────────────

class _AchievementsCarousel extends StatelessWidget {
  final UserProfileStats stats;
  const _AchievementsCarousel({required this.stats});

  @override
  Widget build(BuildContext context) {
    final streak = stats.longestStreak > stats.currentStreak ? stats.longestStreak : stats.currentStreak;
    final completed = stats.totalCompletedHabits;
    final habits = stats.totalHabits;
    final goals = stats.totalGoals;
    final achieved = stats.goalsAchieved;

    final badges = [
      _BadgeData('🔥', '7-Day Streak', streak >= 7, '7 consecutive days'),
      _BadgeData('⭐', 'First Habit', habits >= 1, 'Created first habit'),
      _BadgeData('🎯', 'Goal Setter', goals >= 1, 'Target locked in'),
      _BadgeData('💪', 'Consistent', completed >= 10, '10 habit completions'),
      _BadgeData('🧘', 'Mindful', completed >= 5, '5 reflections done'),
      _BadgeData('🏆', 'Achiever', achieved >= 1, 'Completed first goal'),
      _BadgeData('👑', 'Habit Master', completed >= 50, '50 habit completions'),
    ];

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = badges[index];
          return _AchievementBadgeCard(item: item);
        },
      ),
    );
  }
}

class _BadgeData {
  final String emoji;
  final String title;
  final bool isUnlocked;
  final String description;

  const _BadgeData(this.emoji, this.title, this.isUnlocked, this.description);
}

class _AchievementBadgeCard extends StatelessWidget {
  final _BadgeData item;
  const _AchievementBadgeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode;

    return Opacity(
      opacity: item.isUnlocked ? 1.0 : 0.45,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B162C) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: item.isUnlocked
                ? const Color(0xFF5848D6).withOpacity(0.35)
                : (isDark ? const Color(0xFF2A2244) : const Color(0xFFEAE8F5)),
            width: item.isUnlocked ? 1.5 : 1,
          ),
          boxShadow: item.isUnlocked ? AppShadows.soft : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 26)),
                if (!item.isUnlocked)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF64748B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded, size: 9, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: item.isUnlocked ? FontWeight.w800 : FontWeight.w600,
                color: item.isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.description,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 6. Detailed Lifetime Statistics ─────────────────────────────────────────

class _DetailedStatsCard extends StatelessWidget {
  final UserProfile? user;
  final UserProfileStats stats;

  const _DetailedStatsCard({
    required this.user,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode;
    final double completionRate = stats.totalHabits > 0
        ? ((stats.totalCompletedHabits / (stats.totalHabits * 7.0)) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B162C) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2244) : const Color(0xFFEAE8F5),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          _buildStatRow(
            icon: Icons.calendar_today_rounded,
            iconBgColor: const Color(0xFF6E49E6),
            label: 'Member Since',
            value: user?.createdAt != null
                ? DateFormat('MMMM dd, yyyy').format(user!.createdAt!)
                : 'Active User',
          ),
          _buildDivider(isDark),
          _buildStatRow(
            icon: Icons.track_changes_rounded,
            iconBgColor: const Color(0xFF3B82F6),
            label: 'Total Habits Created',
            value: '${stats.totalHabits}',
          ),
          _buildDivider(isDark),
          _buildStatRow(
            icon: Icons.done_all_rounded,
            iconBgColor: const Color(0xFF10B981),
            label: 'Total Completed Habits',
            value: '${stats.totalCompletedHabits}',
          ),
          _buildDivider(isDark),
          _buildStatRow(
            icon: Icons.percent_rounded,
            iconBgColor: const Color(0xFFF59E0B),
            label: 'Habit Completion Rate',
            value: '${completionRate.toStringAsFixed(1)}%',
            trailingWidget: SizedBox(
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: completionRate / 100.0,
                  backgroundColor: AppColors.surfaceInset,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                  minHeight: 6,
                ),
              ),
            ),
          ),
          _buildDivider(isDark),
          _buildStatRow(
            icon: Icons.local_fire_department_rounded,
            iconBgColor: const Color(0xFFFF6B00),
            label: 'Longest Streak',
            value: '${stats.longestStreak} Days',
          ),
          _buildDivider(isDark),
          _buildStatRow(
            icon: Icons.emoji_events_rounded,
            iconBgColor: const Color(0xFFEAB308),
            label: 'Goals Achieved',
            value: '${stats.goalsAchieved} of ${stats.totalGoals}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color iconBgColor,
    required String label,
    required String value,
    Widget? trailingWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconBgColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (trailingWidget != null) ...[
            trailingWidget,
            const SizedBox(width: 8),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 66,
      endIndent: 16,
      color: isDark ? const Color(0xFF2A2244).withOpacity(0.6) : const Color(0xFFEAE8F5),
    );
  }
}

// ─── 7. Grouped Settings Widgets ─────────────────────────────────────────────

class _SettingsGroupCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B162C) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2244) : const Color(0xFFEAE8F5),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 66,
                endIndent: 16,
                color: isDark ? const Color(0xFF2A2244).withOpacity(0.6) : const Color(0xFFEAE8F5),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailingWidget;

  const _SettingsNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 19, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: trailingWidget ??
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
      onTap: onTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      activeColor: const Color(0xFF5848D6),
      value: value,
      onChanged: onChanged,
      secondary: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 19, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─── Edit Profile Modal Dialog ────────────────────────────────────────────────

class EditProfileDialog extends ConsumerStatefulWidget {
  final UserProfile? user;
  const EditProfileDialog({super.key, this.user});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _avatarController;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedAvatarUrl;

  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=150',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name);
    _avatarController = TextEditingController(text: widget.user?.avatarUrl);
    _selectedAvatarUrl = widget.user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final mimeType = pickedFile.path.endsWith('.png') ? 'image/png' : 'image/jpeg';
        final base64String = 'data:$mimeType;base64,${base64Encode(bytes)}';
        setState(() {
          _selectedAvatarUrl = base64String;
          _avatarController.text = base64String;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not select image. Please try again.';
      });
    }
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Select a photo from your device'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Use camera to take a new picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(profileProvider.notifier).updateProfile(
            name: _nameController.text.trim(),
            avatarUrl: _selectedAvatarUrl?.isNotEmpty == true
                ? _selectedAvatarUrl
                : null,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!', style: TextStyle(fontWeight: FontWeight.w600)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to update profile. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceInset,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Avatar Preview
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF5848D6), width: 2.5),
                        ),
                        child: ClipOval(
                          child: buildAvatarWidget(
                            _selectedAvatarUrl,
                            name: _nameController.text,
                            fontSize: 34,
                            iconColor: const Color(0xFF5848D6),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showImageSourceSheet(context),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5848D6),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: AppShadows.soft,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Gallery / Camera Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickImage(ImageSource.gallery),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5848D6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF5848D6).withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library_rounded, size: 16, color: Color(0xFF5848D6)),
                              SizedBox(width: 6),
                              Text(
                                'Gallery',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5848D6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickImage(ImageSource.camera),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5848D6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF5848D6).withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded, size: 16, color: Color(0xFF5848D6)),
                              SizedBox(width: 6),
                              Text(
                                'Camera',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5848D6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Or Choose a Preset Avatar',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetAvatars.length,
                    itemBuilder: (context, index) {
                      final avatarUrl = _presetAvatars[index];
                      final isSelected = _selectedAvatarUrl == avatarUrl;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatarUrl = avatarUrl;
                            _avatarController.text = avatarUrl;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF5848D6) : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: const Color(0xFF5848D6).withOpacity(0.12),
                              ),
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(Icons.person_rounded, size: 22, color: Color(0xFF5848D6)),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Full Name',
                  hint: 'Enter your name',
                  controller: _nameController,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Name is required' : null,
                  prefixIcon: Icons.person_outline_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Custom Image URL (Optional)',
                  hint: 'https://...',
                  controller: _avatarController,
                  prefixIcon: Icons.link_rounded,
                  onChanged: (val) {
                    setState(() {
                      _selectedAvatarUrl = val.trim();
                    });
                  },
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Save Profile Changes',
                  isLoading: _isLoading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Custom Painter for Profile Hero Ambient Texture ─────────────────────────

class _ProfileWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path1 = Path();
    path1.moveTo(-20, size.height * 0.4);
    path1.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.1,
      size.width * 0.8,
      size.height * 0.7,
    );
    path1.quadraticBezierTo(
      size.width * 0.95,
      size.height * 0.9,
      size.width + 30,
      size.height * 0.8,
    );
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(-30, size.height * 0.8);
    path2.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.95,
      size.width * 0.7,
      size.height * 0.3,
    );
    path2.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.05,
      size.width + 40,
      size.height * 0.25,
    );
    canvas.drawPath(path2, paint);

    final arcPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.9, -10), 80, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Delete Account Final Confirmation Dialog ────────────────────────────────

class _DeleteAccountFinalDialog extends StatefulWidget {
  final Future<void> Function() onConfirm;
  final VoidCallback onCancel;

  const _DeleteAccountFinalDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_DeleteAccountFinalDialog> createState() => _DeleteAccountFinalDialogState();
}

class _DeleteAccountFinalDialogState extends State<_DeleteAccountFinalDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Are you absolutely sure?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your account, all habits, goals, cash flow records, and associated data will be permanently deleted. This cannot be reversed.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (_isDeleting) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Deleting your account...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : widget.onCancel,
          child: Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _isDeleting ? AppColors.textDisabled : AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isDeleting
              ? null
              : () async {
                  setState(() => _isDeleting = true);
                  await widget.onConfirm();
                  // If still mounted (i.e. onConfirm didn't pop the dialog
                  // due to an error), reset the state.
                  if (mounted) {
                    setState(() => _isDeleting = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            elevation: 0,
            disabledBackgroundColor: AppColors.error.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: Text(
            _isDeleting ? 'Deleting...' : 'Permanently Delete My Account',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
