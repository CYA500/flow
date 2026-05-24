import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'capsule_manager.dart';
import 'battery_capsule.dart';
import 'weather_capsule.dart';
import 'music_capsule.dart';
import 'match_capsule.dart';
import '../theme/nowbar_theme.dart';

class CapsuleRenderer extends StatelessWidget {
  final CapsuleData capsule;
  final VoidCallback onSwipeUp;
  final VoidCallback onSwipeDown;

  const CapsuleRenderer({
    super.key,
    required this.capsule,
    required this.onSwipeUp,
    required this.onSwipeDown,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -150) {
            onSwipeUp();
          } else if (details.primaryVelocity! > 150) {
            onSwipeDown();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              capsule.accentColor.withOpacity(0.25),
              capsule.accentColor.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: capsule.accentColor.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Capsule header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: capsule.accentColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        capsule.icon,
                        color: capsule.accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            capsule.title,
                            style: NowBarTheme.bodyStyle.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          if (capsule.subtitle != null)
                            Text(
                              capsule.subtitle!,
                              style: NowBarTheme.captionStyle,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Capsule content based on type
                _buildCapsuleContent(),
                const SizedBox(height: 12),
                // Subtle wave effect at bottom
                SizedBox(
                  height: 30,
                  child: AnimatedWave(
                    color: capsule.accentColor.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCapsuleContent() {
    switch (capsule.type) {
      case CapsuleType.battery:
        return BatteryCapsuleContent(data: capsule.data);
      case CapsuleType.weather:
        return WeatherCapsuleContent(data: capsule.data);
      case CapsuleType.music:
        return MusicCapsuleContent(data: capsule.data);
      case CapsuleType.match:
        return MatchCapsuleContent(data: capsule.data);
    }
  }
}

// Animated wave painter
class AnimatedWave extends StatefulWidget {
  final Color color;

  const AnimatedWave({
    super.key,
    required this.color,
  });

  @override
  State<AnimatedWave> createState() => _AnimatedWaveState();
}

class _AnimatedWaveState extends State<AnimatedWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: WavePainter(
            color: widget.color,
            animation: _controller.value,
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;
  final double animation;

  WavePainter({
    required this.color,
    this.animation = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(0, height / 2);

    for (double x = 0; x <= width; x++) {
      final y = height / 2 +
          math.sin((x / width) * math.pi * 4 + animation * math.pi * 2) *
              (height / 4);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Draw second wave offset
    final paint2 = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path2 = Path();
    path2.moveTo(0, height / 2);

    for (double x = 0; x <= width; x++) {
      final y = height / 2 +
          math.sin((x / width) * math.pi * 3 + animation * math.pi * 2 + 1) *
              (height / 5);
      path2.lineTo(x, y);
    }

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}