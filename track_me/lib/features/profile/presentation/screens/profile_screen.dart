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
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_card.dart';
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
    return '1.0.0';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: profileAsync.when(
                    data: (user) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: buildAvatarWidget(
                              user?.avatarUrl,
                              name: user?.name ?? 'User',
                              fontSize: 32,
                              iconColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user?.name ?? 'User',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showEditProfileDialog(context, ref, user),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Row
                Builder(
                  builder: (context) {
                    final stats = ref.watch(userProfileStatsProvider);
                    return Row(
                      children: [
                        _StatCard(
                          label: 'Current\nStreak',
                          value: '${stats.currentStreak}',
                          emoji: '🔥',
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Habits\nCompleted',
                          value: '${stats.totalCompletedHabits}',
                          emoji: '✅',
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Goals\nActive',
                          value: '${stats.activeGoals}',
                          emoji: '🎯',
                          color: AppColors.primary,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Achievements
                Text(
                  '🏆 Achievements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 96,
                  child: Builder(
                    builder: (context) {
                      final stats = ref.watch(userProfileStatsProvider);
                      final streakCount = stats.longestStreak > stats.currentStreak ? stats.longestStreak : stats.currentStreak;
                      final completedCount = stats.totalCompletedHabits;
                      final habitsCount = stats.totalHabits;
                      final goalsCount = stats.totalGoals;

                      return ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _AchievementBadge(
                            emoji: '🔥',
                            label: '7-Day Streak',
                            isUnlocked: streakCount >= 7,
                          ),
                          const SizedBox(width: 12),
                          _AchievementBadge(
                            emoji: '⭐',
                            label: 'First Habit',
                            isUnlocked: habitsCount >= 1,
                          ),
                          const SizedBox(width: 12),
                          _AchievementBadge(
                            emoji: '🎯',
                            label: 'Goal Setter',
                            isUnlocked: goalsCount >= 1,
                          ),
                          const SizedBox(width: 12),
                          _AchievementBadge(
                            emoji: '💪',
                            label: 'Consistent',
                            isUnlocked: completedCount >= 10,
                          ),
                          const SizedBox(width: 12),
                          _AchievementBadge(
                            emoji: '🧘',
                            label: 'Mindful',
                            isUnlocked: completedCount >= 5,
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Settings
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _SettingsList(
                  items: [
                    _SettingsItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profile',
                      subtitle: 'Update your name and photo',
                      onTap: () {
                        final user = profileAsync.value;
                        _showEditProfileDialog(context, ref, user);
                      },
                    ),
                    _SettingsItem(
                      icon: Icons.notifications_rounded,
                      title: 'Notifications',
                      subtitle: 'Manage reminders',
                      onTap: () {},
                    ),
                    _SettingsItem(
                      icon: Icons.lock_outline_rounded,
                      title: 'Privacy & Security',
                      subtitle: 'Password and data',
                      onTap: () {},
                    ),
                    _SettingsItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      subtitle: 'FAQ and contact',
                      onTap: () {},
                    ),
                    _SettingsItem(
                      icon: Icons.info_outline_rounded,
                      title: 'About',
                      subtitle: 'Version ${ref.watch(appVersionProvider).value ?? '1.0.0'}',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Detailed Statistics
                Text(
                  '📊 Detailed Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final stats = ref.watch(userProfileStatsProvider);
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Join Date',
                            value: profileAsync.value?.createdAt != null
                                ? DateFormat('MMMM dd, yyyy').format(profileAsync.value!.createdAt!)
                                : 'Loading...',
                          ),
                          const Divider(height: 1),
                          _DetailRow(
                            icon: Icons.track_changes_rounded,
                            label: 'Total Habits',
                            value: '${stats.totalHabits}',
                          ),
                          const Divider(height: 1),
                          _DetailRow(
                            icon: Icons.done_all_rounded,
                            label: 'Completed Habits',
                            value: '${stats.totalCompletedHabits}',
                          ),
                          const Divider(height: 1),
                          _DetailRow(
                            icon: Icons.percent_rounded,
                            label: 'Completion Rate',
                            value: '${stats.totalHabits > 0 ? ((stats.totalCompletedHabits / (stats.totalHabits * 7.0)) * 100.0).clamp(0.0, 100.0).toStringAsFixed(1) : '0.0'}%',
                          ),
                          const Divider(height: 1),
                          _DetailRow(
                            icon: Icons.star_rounded,
                            label: 'Longest Streak',
                            value: '${stats.longestStreak} days',
                          ),
                          const Divider(height: 1),
                          _DetailRow(
                            icon: Icons.emoji_events_rounded,
                            label: 'Goals Achieved',
                            value: '${stats.goalsAchieved}',
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Logout
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
                  icon: Icon(Icons.logout_rounded, color: AppColors.error),
                  label: Text(
                    'Log Out',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

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
        final mimeType =
            pickedFile.path.endsWith('.png') ? 'image/png' : 'image/jpeg';
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  child: Icon(Icons.photo_library_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Select a photo from your gallery'),
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
                  child: Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Take a Photo',
                    style: TextStyle(fontWeight: FontWeight.w700)),
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
          const SnackBar(content: Text('✅ Profile updated successfully!')),
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: AppColors.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Avatar preview with camera tap target
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.primary, width: 2.5),
                        ),
                        child: ClipOval(
                          child: buildAvatarWidget(
                            _selectedAvatarUrl,
                            name: _nameController.text,
                            fontSize: 36,
                            iconColor: AppColors.primary,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showImageSourceSheet(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Gallery / Camera Button Bar
                Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded, size: 16),
                        label: const Text(
                          'Choose Photo',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded, size: 16),
                        label: const Text(
                          'Camera',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Predefined Avatars Grid
                const Text(
                  'Or Select Avatar Preset',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 56,
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
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Name',
                  hint: 'Enter your name',
                  controller: _nameController,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name is required'
                      : null,
                  prefixIcon: Icons.person_outline_rounded,
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Custom Avatar URL (Optional)',
                  hint: 'Enter image URL',
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
                  label: 'Save Changes',
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isUnlocked;

  const _AchievementBadge({
    required this.emoji,
    required this.label,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.45,
      child: Container(
        width: 86,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnlocked ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                if (!isUnlocked)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.w500,
                    color: isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsList extends ConsumerWidget {
  final List<_SettingsItem> items;
  const _SettingsList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            return Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  onTap: item.onTap,
                ),
                const Divider(height: 1, indent: 66),
              ],
            );
          }),
          // Dark Mode Switch
          SwitchListTile.adaptive(
            value: isDarkMode,
            onChanged: (value) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
            secondary: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.dark_mode_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            title: const Text(
              'Dark Mode',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Enable dark theme',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
