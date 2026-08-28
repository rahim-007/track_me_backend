import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Quote card with motivational text — clay hero surface
class QuoteCard extends StatelessWidget {
  final String quote;
  final String? author;
  final VoidCallback? onRefresh;
  final Gradient? gradient;

  const QuoteCard({
    super.key,
    required this.quote,
    this.author,
    this.onRefresh,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const Spacer(),
              if (onRefresh != null)
                GestureDetector(
                  onTap: onRefresh,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$quote"',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (author != null) ...[
            const SizedBox(height: 8),
            Text(
              '— $author',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.70),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Circular progress ring with clay palette
class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? color;
  final Widget? centerWidget;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 8,
    this.color,
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    final trackColor = (color ?? AppColors.primary).withOpacity(0.12);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.primary,
            ),
            strokeCap: StrokeCap.round,
          ),
          if (centerWidget != null) centerWidget!,
        ],
      ),
    );
  }
}

/// Empty state widget with clay styling
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  boxShadow: AppShadows.raised,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading overlay
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.background.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shimmer loading placeholder with clay surface color
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
