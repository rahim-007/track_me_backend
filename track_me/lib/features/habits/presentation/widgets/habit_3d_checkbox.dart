import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D Tactile Checkbox Wrapper with 3D Z-Axis matrix squishy press
/// and 3D liquid energy wave ripple effect.
class Habit3dCheckbox extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool enabled;
  final Color accentColor;

  const Habit3dCheckbox({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    required this.accentColor,
  });

  @override
  State<Habit3dCheckbox> createState() => _Habit3dCheckboxState();
}

class _Habit3dCheckboxState extends State<Habit3dCheckbox>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled) {
      widget.onTap();
      return;
    }

    _pressController.forward(from: 0.0).then((_) {
      _pressController.reverse();
    });
    _waveController.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return GestureDetector(
        onTap: widget.onTap,
        child: widget.child,
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 3D Liquid Energy Wave Ripple
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final waveValue = _waveController.value;
              if (waveValue == 0 || waveValue == 1.0) {
                return const SizedBox.shrink();
              }

              final waveSize = 36.0 + (waveValue * 48.0);
              final waveOpacity = (1.0 - waveValue).clamp(0.0, 1.0);

              return Container(
                width: waveSize,
                height: waveSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.accentColor.withOpacity(0.4 * waveOpacity),
                      widget.accentColor.withOpacity(0.1 * waveOpacity),
                      Colors.transparent,
                    ],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                  border: Border.all(
                    color: widget.accentColor.withOpacity(0.6 * waveOpacity),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),

          // 3D Matrix Z-Axis Squishy Button Press Transform
          AnimatedBuilder(
            animation: _pressController,
            builder: (context, child) {
              final pressVal = math.sin(_pressController.value * math.pi);
              final scale = 1.0 - (pressVal * 0.15); // 3D scale compression
              final pitch = -pressVal * 0.15; // 3D pitch depression

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002) // 3D Perspective Depth
                  ..scale(scale)
                  ..rotateX(pitch), // Z-axis matrix depression
                alignment: Alignment.center,
                child: widget.child,
              );
            },
          ),
        ],
      ),
    );
  }
}
