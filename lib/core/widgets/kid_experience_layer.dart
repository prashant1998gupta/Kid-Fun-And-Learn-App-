import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// App-wide "Wonder Touch" feedback.
///
/// A small, silent burst follows each intentional pointer-down so the whole
/// world acknowledges the child's touch, including screens that do not use a
/// [Material] ink response. It is deliberately visual-only because buttons
/// already own their sound and haptic feedback. Bursts are bounded, short, and
/// completely disabled when reduced motion is requested.
class KidExperienceLayer extends StatefulWidget {
  const KidExperienceLayer({
    required this.child,
    required this.reducedMotion,
    this.energyLevel = 1,
    super.key,
  });

  final Widget child;
  final bool reducedMotion;
  final int energyLevel;

  @override
  State<KidExperienceLayer> createState() => _KidExperienceLayerState();
}

class _KidExperienceLayerState extends State<KidExperienceLayer> {
  final List<_TouchBurst> _bursts = [];
  int _nextId = 0;

  void _respond(PointerDownEvent event) {
    if (widget.reducedMotion) return;
    setState(() {
      final maxBursts = switch (widget.energyLevel) { 0 => 4, 2 => 8, _ => 6 };
      if (_bursts.length >= maxBursts) _bursts.removeAt(0);
      _bursts.add(_TouchBurst(_nextId++, event.localPosition));
    });
  }

  void _remove(int id) {
    if (!mounted) return;
    setState(() => _bursts.removeWhere((burst) => burst.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _respond,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          for (final burst in _bursts)
            Positioned(
              key: ValueKey('wonder-touch-${burst.id}'),
              left: burst.position.dx - 42,
              top: burst.position.dy - 42,
              width: 84,
              height: 84,
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(
                    milliseconds: switch (widget.energyLevel) {
                      0 => 560,
                      2 => 400,
                      _ => 480,
                    },
                  ),
                  curve: Curves.easeOutCubic,
                  onEnd: () => _remove(burst.id),
                  builder: (_, progress, __) => CustomPaint(
                    key: const ValueKey('kid-wonder-touch-burst'),
                    painter: _WonderTouchPainter(
                      progress: progress,
                      colorOffset: burst.id,
                      energyLevel: widget.energyLevel,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TouchBurst {
  const _TouchBurst(this.id, this.position);

  final int id;
  final Offset position;
}

class _WonderTouchPainter extends CustomPainter {
  const _WonderTouchPainter({
    required this.progress,
    required this.colorOffset,
    required this.energyLevel,
  });

  final double progress;
  final int colorOffset;
  final int energyLevel;

  static const _colors = [
    AppColors.star,
    AppColors.bubblegum,
    AppColors.mint,
    AppColors.sky,
    AppColors.secondary,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final fade = (1 - progress).clamp(0.0, 1.0);
    final halo = Paint()
      ..color =
          _colors[colorOffset % _colors.length].withValues(alpha: 0.24 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 8 + 23 * progress, halo);

    final starCount = switch (energyLevel) { 0 => 3, 2 => 7, _ => 5 };
    for (var index = 0; index < starCount; index++) {
      final angle = -math.pi / 2 + (math.pi * 2 * index / starCount);
      final distance = 8 + 27 * progress;
      final point = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );
      final radius = (5.5 - 2.5 * progress).clamp(2.0, 5.5);
      final paint = Paint()
        ..color = _colors[(colorOffset + index) % _colors.length]
            .withValues(alpha: fade);
      canvas.drawPath(_star(point, radius), paint);
    }
  }

  Path _star(Offset center, double radius) {
    final path = Path();
    for (var point = 0; point < 10; point++) {
      final angle = -math.pi / 2 + point * math.pi / 5;
      final length = point.isEven ? radius : radius * 0.45;
      final x = center.dx + math.cos(angle) * length;
      final y = center.dy + math.sin(angle) * length;
      if (point == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _WonderTouchPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.colorOffset != colorOffset ||
      oldDelegate.energyLevel != energyLevel;
}
