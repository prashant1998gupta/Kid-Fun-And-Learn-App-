import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The named worlds a background can render. Themes swap the gradient plus the
/// floating decorations so each subject/section feels like its own place.
enum WorldTheme {
  space(AppColors.gradientSpace, _Decor.stars),
  jungle(AppColors.gradientJungle, _Decor.leaves),
  ocean(AppColors.gradientOcean, _Decor.bubbles),
  candy(AppColors.gradientCandy, _Decor.sparkles),
  sunrise(AppColors.gradientSunrise, _Decor.clouds),
  night(AppColors.gradientNight, _Decor.stars);

  const WorldTheme(this.gradient, this._decor);
  final List<Color> gradient;
  final _Decor _decor;

  static WorldTheme fromId(String id) =>
      WorldTheme.values.firstWhere((t) => t.name == id,
          orElse: () => WorldTheme.sunrise);
}

enum _Decor { stars, leaves, bubbles, sparkles, clouds }

/// A full-screen animated gradient with gently drifting decorations
/// (clouds, stars, bubbles…). Pure CustomPainter — cheap enough to hold 60fps
/// on low-end tablets. Place it as the bottom of a [Stack].
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({
    super.key,
    this.theme = WorldTheme.sunrise,
    this.particleCount = 18,
    this.child,
  });

  final WorldTheme theme;
  final int particleCount;
  final Widget? child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  late final List<_Particle> _particles = _seed();

  List<_Particle> _seed() {
    final rnd = math.Random(42); // deterministic → stable across rebuilds
    return List.generate(widget.particleCount, (_) {
      return _Particle(
        x: rnd.nextDouble(),
        y: rnd.nextDouble(),
        size: 6 + rnd.nextDouble() * 22,
        speed: 0.2 + rnd.nextDouble() * 0.8,
        phase: rnd.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.theme.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _DecorPainter(
                _particles,
                _controller.value,
                widget.theme._decor,
              ),
              size: Size.infinite,
            );
          },
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });
  final double x, y, size, speed, phase;
}

class _DecorPainter extends CustomPainter {
  _DecorPainter(this.particles, this.t, this.decor);
  final List<_Particle> particles;
  final double t;
  final _Decor decor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (final p in particles) {
      final drift = math.sin((t * math.pi * 2 * p.speed) + p.phase);
      final dx = (p.x * size.width) + drift * 18;
      final dy = ((p.y - t * p.speed) % 1.0) * size.height;
      final center = Offset(dx, dy);
      switch (decor) {
        case _Decor.stars:
        case _Decor.sparkles:
          _drawStar(canvas, center, p.size / 2, paint);
        case _Decor.bubbles:
          canvas.drawCircle(
            center,
            p.size / 2,
            paint..color = Colors.white.withValues(alpha: 0.28),
          );
        case _Decor.clouds:
          _drawCloud(canvas, center, p.size, paint);
        case _Decor.leaves:
          canvas.drawCircle(
            center,
            p.size / 2.4,
            paint..color = Colors.white.withValues(alpha: 0.35),
          );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outer = i * 2 * math.pi / 5 - math.pi / 2;
      final inner = outer + math.pi / 5;
      final po = Offset(c.dx + math.cos(outer) * r, c.dy + math.sin(outer) * r);
      final pi_ = Offset(
          c.dx + math.cos(inner) * r / 2, c.dy + math.sin(inner) * r / 2);
      if (i == 0) {
        path.moveTo(po.dx, po.dy);
      } else {
        path.lineTo(po.dx, po.dy);
      }
      path.lineTo(pi_.dx, pi_.dy);
    }
    path.close();
    canvas.drawPath(path, paint..color = Colors.white.withValues(alpha: 0.7));
  }

  void _drawCloud(Canvas canvas, Offset c, double s, Paint paint) {
    paint.color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(c, s * 0.5, paint);
    canvas.drawCircle(c.translate(s * 0.5, s * 0.1), s * 0.4, paint);
    canvas.drawCircle(c.translate(-s * 0.5, s * 0.1), s * 0.35, paint);
  }

  @override
  bool shouldRepaint(_DecorPainter old) => old.t != t;
}
