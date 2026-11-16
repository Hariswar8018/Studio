import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _twinkleController;
  late final AnimationController _shimmerController;
  late final AnimationController _bounceController;

  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  Timer? _navigationTimer;

  // Star particles data for twinkling floating stars background
  final List<_StarParticle> _stars = List.generate(28, (index) {
    final rand = math.Random(index * 7);
    return _StarParticle(
      relX: rand.nextDouble(),
      relY: rand.nextDouble(),
      baseSize: 6.0 + rand.nextDouble() * 12.0,
      phaseOffset: rand.nextDouble() * math.pi * 2,
      speed: 0.8 + rand.nextDouble() * 1.2,
      color: [
        const Color(0xFFF59E0B), // Amber
        const Color(0xFFEC4899), // Pink
        const Color(0xFF3B82F6), // Blue
        const Color(0xFF8B5CF6), // Purple
        const Color(0xFF06B6D4), // Cyan
      ][index % 5],
    );
  });

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation (scale + fade)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // 2. Continuous Twinkle controller for stars
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // 3. Continuous Shimmer controller for light sweep
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // 4. Continuous Bounce controller for image float
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _entranceController.forward();

    // Navigate to AuthGate smoothly after 3.2 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthGate(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _entranceController.dispose();
    _twinkleController.dispose();
    _shimmerController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Animated Twinkling & Floating Stars Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _twinkleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _TwinklingStarsPainter(
                    stars: _stars,
                    progress: _twinkleController.value,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),

          // 2. Center Content with Scale, Opacity, Shimmer, and Floating Bounce
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _entranceController,
                _bounceController,
                _shimmerController,
              ]),
              builder: (context, child) {
                final floatOffset = math.sin(_bounceController.value * math.pi) * 8;
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, floatOffset),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: math.min(size.width * 0.78, 320.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset(
                                'assets/splash.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 220,
                                  color: const Color(0xFFEFF6FF),
                                  child: const Center(
                                    child: Icon(
                                      Icons.school_rounded,
                                      color: Color(0xFF6366F1),
                                      size: 80,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STAR PARTICLE DATA MODEL & CUSTOM PAINTER
// -----------------------------------------------------------------------------
class _StarParticle {
  final double relX;
  final double relY;
  final double baseSize;
  final double phaseOffset;
  final double speed;
  final Color color;

  _StarParticle({
    required this.relX,
    required this.relY,
    required this.baseSize,
    required this.phaseOffset,
    required this.speed,
    required this.color,
  });
}

class _TwinklingStarsPainter extends CustomPainter {
  final List<_StarParticle> stars;
  final double progress;
  final bool isDark;

  _TwinklingStarsPainter({
    required this.stars,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final time = progress * math.pi * 2 * star.speed + star.phaseOffset;
      final opacity = (0.2 + 0.8 * (0.5 + 0.5 * math.sin(time))).clamp(0.0, 1.0);
      final sizePulse = star.baseSize * (0.8 + 0.3 * math.sin(time * 1.5));

      final dx = star.relX * size.width + math.sin(time) * 4.0;
      final dy = star.relY * size.height + math.cos(time) * 4.0;
      final center = Offset(dx, dy);

      final paint = Paint()
        ..color = star.color.withValues(alpha: isDark ? opacity : opacity * 0.75)
        ..style = PaintingStyle.fill;

      final path = _createSparkleStarPath(center, sizePulse);
      canvas.drawPath(path, paint);
    }
  }

  Path _createSparkleStarPath(Offset center, double size) {
    final path = Path();
    final half = size / 2;

    path.moveTo(center.dx, center.dy - half);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + half, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + half);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - half, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - half);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant _TwinklingStarsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
