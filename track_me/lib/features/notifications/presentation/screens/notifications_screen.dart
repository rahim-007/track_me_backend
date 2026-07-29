// lib/features/notifications/presentation/screens/notifications_screen.dart
// Placeholder - Full implementation follows same pattern as other screens

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(
        child: Text('Notifications coming soon'),
      ),
    );
  }
}
