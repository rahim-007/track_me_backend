import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Full-Screen 3D Flame Explosion Overlay ("ALL HABITS DONE!").
///
/// Triggers when the user completes the final habit of the day.
/// Displays a scaling 3D Flame (🔥), floating glowing ember particles, light rays,
/// and a 3D animated "ALL HABITS DONE!" victory banner.
class FlameExplosionOverlay {
  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _FlameExplosionWidget(
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _FlameExplosionWidget extends StatefulWidget {
  final VoidCallback onDismiss;
  const _FlameExplosionWidget({required this.onDismiss});

  @override
  State<_FlameExplosionWidget> createState() => _FlameExplosionWidgetState();
}

class _FlameExplosionWidgetState extends State<_FlameExplosionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();
  late List<_EmberData> _embers;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _embers = List.generate(24, (index) {
      final angle = _random.nextDouble() * math.pi * 2;
      final distance = 80.0 + _random.nextDouble() * 180.0;
      return _EmberData(
        targetX: math.cos(angle) * distance,
        targetY: math.sin(angle) * distance - (40.0 + _random.nextDouble() * 60.0),
        size: 10.0 + _random.nextDouble() * 14.0,
        speed: 0.7 + _random.nextDouble() * 0.5,
        color: _random.nextBool()
            ? const Color(0xFFFF6D00)
            : const Color(0xFFFFAB00),
      );
    });

    _controller.forward().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final backdropOpacity = (t < 0.2
                  ? (t / 0.2)
                  : (t > 0.8 ? (1.0 - t) / 0.2 : 1.0))
              .clamp(0.0, 0.85);

          // Flame scale curve with bounce
          final flameScale = t < 0.4
              ? Curves.elasticOut.transform(t / 0.4)
              : (1.0 + math.sin((t - 0.4) * math.pi * 3) * 0.05);

          return Material(
            color: Colors.black.withOpacity(backdropOpacity),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing Background Radial Light Wave
                Opacity(
                  opacity: (t < 0.5 ? t / 0.5 : (1.0 - t) / 0.5).clamp(0.0, 1.0),
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFF6D00).withOpacity(0.5),
                          const Color(0xFFFFAB00).withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Floating 3D Embers
                ..._embers.map((ember) {
                  final emberProgress =
                      (t * ember.speed).clamp(0.0, 1.0);
                  final posX = ember.targetX * emberProgress;
                  final posY = ember.targetY * emberProgress;
                  final emberOpacity = (1.0 - emberProgress).clamp(0.0, 1.0);

                  return Transform.translate(
                    offset: Offset(posX, posY),
                    child: Opacity(
                      opacity: emberOpacity,
                      child: Container(
                        width: ember.size,
                        height: ember.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ember.color,
                          boxShadow: [
                            BoxShadow(
                              color: ember.color.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Center 3D Flame Icon + 3D Victory Banner
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: flameScale,
                      child: Container(
                        width: 120,
                        height: 120,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF9100),
                              Color(0xFFFF3D00),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3D00).withOpacity(0.6),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Text(
                          '🔥',
                          style: TextStyle(fontSize: 64),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002) // 3D perspective
                        ..scale(flameScale.clamp(0.0, 1.2))
                        ..rotateX((1.0 - t.clamp(0.0, 1.0)) * 0.4),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF9100),
                              Color(0xFFFF3D00),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3D00).withOpacity(0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'ALL HABITS DONE!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black38,
                                    offset: Offset(1, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Day streak complete! 🔥',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmberData {
  final double targetX;
  final double targetY;
  final double size;
  final double speed;
  final Color color;

  _EmberData({
    required this.targetX,
    required this.targetY,
    required this.size,
    required this.speed,
    required this.color,
  });
}
