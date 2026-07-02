import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Small code-drawn preschool illustrations used while production art assets
/// are being commissioned. This removes the "just emoji" look from core games
/// without adding network/image dependencies.
class IllustratedObjectView extends StatelessWidget {
  const IllustratedObjectView({
    super.key,
    required this.label,
    this.emoji,
    this.size = 76,
    this.selected = false,
  });

  final String label;
  final String? emoji;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final kind = _kindFor(label, emoji);
    final fg = selected ? Colors.white : AppColors.lightText;
    if (kind == _IllustrationKind.text) {
      return _TextTile(label: label, size: size, foreground: fg);
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ObjectPainter(kind: kind, selected: selected),
      ),
    );
  }
}

class _TextTile extends StatelessWidget {
  const _TextTile({
    required this.label,
    required this.size,
    required this.foreground,
  });

  final String label;
  final double size;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final compact = label.length <= 2;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1A6), Color(0xFFFFC048)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(size * 0.24)),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Text(
        compact ? label : label.characters.first.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: foreground,
          fontSize: compact ? size * 0.52 : size * 0.42,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

enum _IllustrationKind {
  text,
  apple,
  banana,
  carrot,
  strawberry,
  grapes,
  cookie,
  cat,
  dog,
  cow,
  pig,
  fish,
  lion,
  bird,
  bee,
  sun,
  moon,
  star,
  tree,
  flower,
  car,
  bus,
  ball,
  hat,
  book,
  box,
  umbrella,
  circle,
  square,
  triangle,
  rectangle,
  heart,
  water,
  land,
  generic,
}

_IllustrationKind _kindFor(String label, String? emoji) {
  final value = label.toLowerCase().trim();
  if (RegExp(r'^[a-z0-9]{1,2}$').hasMatch(value)) {
    return _IllustrationKind.text;
  }
  if (value.contains('apple')) return _IllustrationKind.apple;
  if (value.contains('banana')) return _IllustrationKind.banana;
  if (value.contains('carrot') || value.contains('veggie')) {
    return _IllustrationKind.carrot;
  }
  if (value.contains('berry') || value.contains('strawberry')) {
    return _IllustrationKind.strawberry;
  }
  if (value.contains('grape')) return _IllustrationKind.grapes;
  if (value.contains('cookie')) return _IllustrationKind.cookie;
  if (value.contains('cat')) return _IllustrationKind.cat;
  if (value.contains('dog') || value.contains('puppy')) {
    return _IllustrationKind.dog;
  }
  if (value.contains('cow')) return _IllustrationKind.cow;
  if (value.contains('pig')) return _IllustrationKind.pig;
  if (value.contains('fish') || value.contains('whale')) {
    return _IllustrationKind.fish;
  }
  if (value.contains('lion')) return _IllustrationKind.lion;
  if (value.contains('bird') ||
      value.contains('duck') ||
      value.contains('hen')) {
    return _IllustrationKind.bird;
  }
  if (value.contains('bee')) return _IllustrationKind.bee;
  if (value.contains('sun')) return _IllustrationKind.sun;
  if (value.contains('moon')) return _IllustrationKind.moon;
  if (value.contains('star')) return _IllustrationKind.star;
  if (value.contains('tree') || value.contains('plant')) {
    return _IllustrationKind.tree;
  }
  if (value.contains('flower')) return _IllustrationKind.flower;
  if (value.contains('car')) return _IllustrationKind.car;
  if (value.contains('bus')) return _IllustrationKind.bus;
  if (value.contains('ball') || value.contains('round')) {
    return _IllustrationKind.ball;
  }
  if (value.contains('hat')) return _IllustrationKind.hat;
  if (value.contains('book')) return _IllustrationKind.book;
  if (value.contains('box')) return _IllustrationKind.box;
  if (value.contains('umbrella')) return _IllustrationKind.umbrella;
  if (value.contains('circle')) return _IllustrationKind.circle;
  if (value.contains('square')) return _IllustrationKind.square;
  if (value.contains('triangle')) return _IllustrationKind.triangle;
  if (value.contains('rectangle')) return _IllustrationKind.rectangle;
  if (value.contains('heart')) return _IllustrationKind.heart;
  if (value.contains('water') || value.contains('pond')) {
    return _IllustrationKind.water;
  }
  if (value.contains('land')) return _IllustrationKind.land;
  return emoji == null ? _IllustrationKind.text : _IllustrationKind.generic;
}

class _ObjectPainter extends CustomPainter {
  const _ObjectPainter({required this.kind, required this.selected});

  final _IllustrationKind kind;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height);
    canvas.save();
    canvas.translate((size.width - scale) / 2, (size.height - scale) / 2);
    canvas.scale(scale / 100);

    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.10);
    canvas.drawOval(const Rect.fromLTWH(18, 82, 64, 10), shadow);

    switch (kind) {
      case _IllustrationKind.apple:
        _fruit(canvas, const Color(0xFFFF5E57), leaf: true);
      case _IllustrationKind.banana:
        _banana(canvas);
      case _IllustrationKind.carrot:
        _carrot(canvas);
      case _IllustrationKind.strawberry:
        _fruit(canvas, AppColors.bubblegum, seeds: true, leaf: true);
      case _IllustrationKind.grapes:
        _grapes(canvas);
      case _IllustrationKind.cookie:
        _cookie(canvas);
      case _IllustrationKind.cat:
        _animal(canvas, const Color(0xFFFFB45C), ears: true, whiskers: true);
      case _IllustrationKind.dog:
        _animal(canvas, const Color(0xFFB97A45), floppy: true);
      case _IllustrationKind.cow:
        _cow(canvas);
      case _IllustrationKind.pig:
        _animal(canvas, const Color(0xFFFF9EBB), pigNose: true);
      case _IllustrationKind.fish:
        _fish(canvas);
      case _IllustrationKind.lion:
        _lion(canvas);
      case _IllustrationKind.bird:
        _bird(canvas);
      case _IllustrationKind.bee:
        _bee(canvas);
      case _IllustrationKind.sun:
        _sun(canvas);
      case _IllustrationKind.moon:
        _moon(canvas);
      case _IllustrationKind.star:
        _star(canvas);
      case _IllustrationKind.tree:
        _tree(canvas);
      case _IllustrationKind.flower:
        _flower(canvas);
      case _IllustrationKind.car:
        _vehicle(canvas, bus: false);
      case _IllustrationKind.bus:
        _vehicle(canvas, bus: true);
      case _IllustrationKind.ball:
        _ball(canvas);
      case _IllustrationKind.hat:
        _hat(canvas);
      case _IllustrationKind.book:
        _book(canvas);
      case _IllustrationKind.box:
        _box(canvas);
      case _IllustrationKind.umbrella:
        _umbrella(canvas);
      case _IllustrationKind.circle:
        _shape(canvas, _IllustrationKind.circle);
      case _IllustrationKind.square:
        _shape(canvas, _IllustrationKind.square);
      case _IllustrationKind.triangle:
        _shape(canvas, _IllustrationKind.triangle);
      case _IllustrationKind.rectangle:
        _shape(canvas, _IllustrationKind.rectangle);
      case _IllustrationKind.heart:
        _heart(canvas);
      case _IllustrationKind.water:
        _water(canvas);
      case _IllustrationKind.land:
        _land(canvas);
      case _IllustrationKind.generic:
        _generic(canvas);
      case _IllustrationKind.text:
        break;
    }
    canvas.restore();
  }

  Paint _paint(Color color) =>
      Paint()..color = selected ? color.withValues(alpha: 0.9) : color;
  Paint _stroke(Color color, [double width = 4]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = width;

  void _eye(Canvas c, double x, double y) {
    c.drawCircle(Offset(x, y), 3.4, _paint(AppColors.lightText));
    c.drawCircle(Offset(x + 1, y - 1), 1.1, _paint(Colors.white));
  }

  void _smile(Canvas c) {
    c.drawArc(const Rect.fromLTWH(42, 50, 16, 12), 0, math.pi, false,
        _stroke(AppColors.lightText, 2.4));
  }

  void _fruit(Canvas c, Color color, {bool seeds = false, bool leaf = false}) {
    c.drawCircle(const Offset(50, 50), 28, _paint(color));
    c.drawCircle(
        const Offset(40, 42), 10, _paint(color.withValues(alpha: 0.95)));
    if (leaf) {
      c.drawOval(
          const Rect.fromLTWH(52, 17, 22, 12), _paint(AppColors.success));
      c.drawLine(const Offset(49, 25), const Offset(52, 15),
          _stroke(const Color(0xFF6D4C41), 4));
    }
    if (seeds) {
      for (final p in const [Offset(42, 45), Offset(55, 42), Offset(48, 57)]) {
        c.drawCircle(p, 1.8, _paint(Colors.white70));
      }
    }
    _eye(c, 42, 47);
    _eye(c, 58, 47);
    _smile(c);
  }

  void _banana(Canvas c) {
    final path = Path()
      ..moveTo(23, 34)
      ..quadraticBezierTo(55, 82, 82, 35)
      ..quadraticBezierTo(55, 61, 30, 27)
      ..close();
    c.drawPath(path, _paint(AppColors.accent));
    c.drawPath(path, _stroke(const Color(0xFFD99000), 3));
    _eye(c, 49, 47);
    _eye(c, 62, 49);
    _smile(c);
  }

  void _carrot(Canvas c) {
    final body = Path()
      ..moveTo(50, 84)
      ..lineTo(28, 30)
      ..quadraticBezierTo(50, 20, 72, 30)
      ..close();
    c.drawPath(body, _paint(const Color(0xFFFF8A3D)));
    c.drawPath(body, _stroke(const Color(0xFFD96B24), 3));
    c.drawOval(const Rect.fromLTWH(32, 12, 16, 24), _paint(AppColors.success));
    c.drawOval(const Rect.fromLTWH(48, 10, 16, 25), _paint(AppColors.mint));
    _eye(c, 45, 44);
    _eye(c, 56, 44);
    _smile(c);
  }

  void _grapes(Canvas c) {
    for (final p in const [
      Offset(42, 38),
      Offset(58, 38),
      Offset(34, 54),
      Offset(50, 54),
      Offset(66, 54),
      Offset(42, 70),
      Offset(58, 70),
    ]) {
      c.drawCircle(p, 11, _paint(const Color(0xFF9B59B6)));
    }
    c.drawOval(const Rect.fromLTWH(54, 18, 20, 10), _paint(AppColors.success));
    _eye(c, 44, 55);
    _eye(c, 56, 55);
    _smile(c);
  }

  void _cookie(Canvas c) {
    c.drawCircle(const Offset(50, 52), 30, _paint(const Color(0xFFD8A15D)));
    for (final p in const [
      Offset(39, 43),
      Offset(59, 40),
      Offset(50, 62),
      Offset(65, 58)
    ]) {
      c.drawCircle(p, 3, _paint(const Color(0xFF6D4C41)));
    }
    _eye(c, 41, 53);
    _eye(c, 59, 53);
    _smile(c);
  }

  void _animal(Canvas c, Color color,
      {bool ears = false,
      bool floppy = false,
      bool whiskers = false,
      bool pigNose = false}) {
    if (ears) {
      c.drawPath(
          Path()
            ..moveTo(26, 38)
            ..lineTo(32, 15)
            ..lineTo(44, 34)
            ..close(),
          _paint(color));
      c.drawPath(
          Path()
            ..moveTo(74, 38)
            ..lineTo(68, 15)
            ..lineTo(56, 34)
            ..close(),
          _paint(color));
    }
    if (floppy) {
      c.drawOval(const Rect.fromLTWH(17, 31, 22, 36),
          _paint(color.withValues(alpha: 0.9)));
      c.drawOval(const Rect.fromLTWH(61, 31, 22, 36),
          _paint(color.withValues(alpha: 0.9)));
    }
    c.drawCircle(const Offset(50, 49), 30, _paint(color));
    c.drawOval(const Rect.fromLTWH(37, 54, 26, 18),
        _paint(Colors.white.withValues(alpha: 0.45)));
    _eye(c, 40, 45);
    _eye(c, 60, 45);
    c.drawCircle(const Offset(50, 55), pigNose ? 8 : 4,
        _paint(pigNose ? const Color(0xFFE96D97) : AppColors.lightText));
    if (whiskers) {
      c.drawLine(const Offset(24, 54), const Offset(41, 56),
          _stroke(AppColors.lightText, 2));
      c.drawLine(const Offset(59, 56), const Offset(76, 54),
          _stroke(AppColors.lightText, 2));
    }
    _smile(c);
  }

  void _cow(Canvas c) {
    _animal(c, Colors.white, ears: true);
    c.drawCircle(const Offset(36, 36), 7, _paint(AppColors.lightText));
    c.drawOval(const Rect.fromLTWH(56, 55, 14, 9), _paint(AppColors.lightText));
  }

  void _fish(Canvas c) {
    c.drawOval(const Rect.fromLTWH(24, 34, 48, 34), _paint(AppColors.sky));
    c.drawPath(
        Path()
          ..moveTo(70, 51)
          ..lineTo(90, 34)
          ..lineTo(90, 68)
          ..close(),
        _paint(AppColors.primary));
    c.drawCircle(const Offset(39, 45), 3.4, _paint(AppColors.lightText));
    c.drawArc(const Rect.fromLTWH(34, 50, 14, 8), 0, math.pi, false,
        _stroke(AppColors.lightText, 2));
  }

  void _lion(Canvas c) {
    c.drawCircle(const Offset(50, 50), 34, _paint(const Color(0xFFD88924)));
    c.drawCircle(const Offset(50, 50), 25, _paint(AppColors.accent));
    _eye(c, 41, 46);
    _eye(c, 59, 46);
    c.drawCircle(const Offset(50, 54), 4, _paint(AppColors.lightText));
    _smile(c);
  }

  void _bird(Canvas c) {
    c.drawOval(const Rect.fromLTWH(27, 29, 46, 43), _paint(AppColors.sky));
    c.drawPath(
        Path()
          ..moveTo(70, 46)
          ..lineTo(88, 53)
          ..lineTo(70, 60)
          ..close(),
        _paint(AppColors.accent));
    c.drawOval(const Rect.fromLTWH(32, 48, 28, 15),
        _paint(AppColors.primary.withValues(alpha: 0.45)));
    _eye(c, 55, 42);
  }

  void _bee(Canvas c) {
    c.drawOval(const Rect.fromLTWH(28, 38, 44, 28), _paint(AppColors.accent));
    c.drawLine(const Offset(42, 39), const Offset(42, 66),
        _stroke(AppColors.lightText, 4));
    c.drawLine(const Offset(55, 39), const Offset(55, 66),
        _stroke(AppColors.lightText, 4));
    c.drawOval(const Rect.fromLTWH(28, 23, 20, 18),
        _paint(AppColors.sky.withValues(alpha: 0.55)));
    c.drawOval(const Rect.fromLTWH(52, 23, 20, 18),
        _paint(AppColors.sky.withValues(alpha: 0.55)));
    _eye(c, 63, 49);
  }

  void _sun(Canvas c) {
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi / 5;
      c.drawLine(
          Offset(50 + math.cos(a) * 32, 50 + math.sin(a) * 32),
          Offset(50 + math.cos(a) * 42, 50 + math.sin(a) * 42),
          _stroke(AppColors.accent, 5));
    }
    c.drawCircle(const Offset(50, 50), 25, _paint(AppColors.accent));
    _eye(c, 42, 47);
    _eye(c, 58, 47);
    _smile(c);
  }

  void _moon(Canvas c) {
    c.drawCircle(const Offset(48, 48), 30, _paint(const Color(0xFFFFF3B0)));
    c.drawCircle(const Offset(61, 39), 28, _paint(const Color(0xFF23243F)));
  }

  void _star(Canvas c) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? 34.0 : 15.0;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(50 + math.cos(a) * radius, 50 + math.sin(a) * radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    c.drawPath(path, _paint(AppColors.star));
  }

  void _tree(Canvas c) {
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(44, 54, 12, 28), AppSpacing.radiusMd),
        _paint(const Color(0xFF8D5524)));
    c.drawCircle(const Offset(38, 46), 18, _paint(AppColors.success));
    c.drawCircle(const Offset(58, 42), 20, _paint(AppColors.mint));
    c.drawCircle(const Offset(53, 58), 18, _paint(AppColors.success));
  }

  void _flower(Canvas c) {
    c.drawLine(const Offset(50, 55), const Offset(50, 84),
        _stroke(AppColors.success, 5));
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      c.drawCircle(Offset(50 + math.cos(a) * 17, 42 + math.sin(a) * 17), 11,
          _paint(AppColors.bubblegum));
    }
    c.drawCircle(const Offset(50, 42), 11, _paint(AppColors.accent));
  }

  void _vehicle(Canvas c, {required bool bus}) {
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(18, 36, 64, 32), AppSpacing.radiusMd),
        _paint(bus ? AppColors.accent : AppColors.secondary));
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(31, 27, 28, 18), AppSpacing.radiusMd),
        _paint(bus ? AppColors.sky : AppColors.secondary));
    c.drawCircle(const Offset(32, 70), 7, _paint(AppColors.lightText));
    c.drawCircle(const Offset(68, 70), 7, _paint(AppColors.lightText));
    c.drawCircle(const Offset(32, 70), 3, _paint(Colors.white));
    c.drawCircle(const Offset(68, 70), 3, _paint(Colors.white));
  }

  void _ball(Canvas c) {
    c.drawCircle(const Offset(50, 50), 30, _paint(AppColors.sky));
    c.drawArc(const Rect.fromLTWH(23, 23, 54, 54), -0.6, 1.2, false,
        _stroke(Colors.white, 5));
    c.drawLine(
        const Offset(50, 20), const Offset(50, 80), _stroke(Colors.white, 5));
  }

  void _hat(Canvas c) {
    c.drawPath(
        Path()
          ..moveTo(28, 60)
          ..lineTo(42, 28)
          ..lineTo(65, 28)
          ..lineTo(75, 60)
          ..close(),
        _paint(AppColors.primary));
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(20, 58, 62, 12), AppSpacing.radiusPill),
        _paint(AppColors.accent));
  }

  void _book(Canvas c) {
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(24, 27, 52, 50), AppSpacing.radiusMd),
        _paint(AppColors.secondary));
    c.drawLine(
        const Offset(50, 29), const Offset(50, 77), _stroke(Colors.white, 3));
    c.drawLine(
        const Offset(32, 42), const Offset(45, 42), _stroke(Colors.white70, 2));
  }

  void _box(Canvas c) {
    c.drawPath(
        Path()
          ..moveTo(22, 42)
          ..lineTo(50, 26)
          ..lineTo(78, 42)
          ..lineTo(50, 58)
          ..close(),
        _paint(const Color(0xFFD8A15D)));
    c.drawPath(
        Path()
          ..moveTo(22, 42)
          ..lineTo(50, 58)
          ..lineTo(50, 84)
          ..lineTo(22, 66)
          ..close(),
        _paint(const Color(0xFFC08A4A)));
    c.drawPath(
        Path()
          ..moveTo(78, 42)
          ..lineTo(50, 58)
          ..lineTo(50, 84)
          ..lineTo(78, 66)
          ..close(),
        _paint(const Color(0xFFE0AA6B)));
  }

  void _umbrella(Canvas c) {
    c.drawArc(const Rect.fromLTWH(20, 24, 60, 48), math.pi, math.pi, false,
        _stroke(AppColors.bubblegum, 27));
    c.drawLine(const Offset(50, 49), const Offset(50, 78),
        _stroke(AppColors.lightText, 4));
    c.drawArc(const Rect.fromLTWH(50, 68, 16, 16), 0, math.pi, false,
        _stroke(AppColors.lightText, 4));
  }

  void _shape(Canvas c, _IllustrationKind shape) {
    final paint = _paint(shape == _IllustrationKind.circle
        ? AppColors.sky
        : shape == _IllustrationKind.square
            ? AppColors.success
            : shape == _IllustrationKind.rectangle
                ? AppColors.secondary
                : AppColors.accent);
    switch (shape) {
      case _IllustrationKind.circle:
        c.drawCircle(const Offset(50, 50), 30, paint);
      case _IllustrationKind.square:
        c.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(24, 24, 52, 52), AppSpacing.radiusMd),
            paint);
      case _IllustrationKind.rectangle:
        c.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(16, 32, 68, 38), AppSpacing.radiusMd),
            paint);
      default:
        c.drawPath(
            Path()
              ..moveTo(50, 18)
              ..lineTo(82, 76)
              ..lineTo(18, 76)
              ..close(),
            paint);
    }
  }

  void _heart(Canvas c) {
    final path = Path()
      ..moveTo(50, 78)
      ..cubicTo(12, 50, 24, 22, 49, 36)
      ..cubicTo(76, 18, 88, 50, 50, 78)
      ..close();
    c.drawPath(path, _paint(AppColors.secondary));
  }

  void _water(Canvas c) {
    final path = Path()
      ..moveTo(18, 58)
      ..quadraticBezierTo(34, 44, 50, 58)
      ..quadraticBezierTo(66, 72, 82, 58)
      ..lineTo(82, 76)
      ..lineTo(18, 76)
      ..close();
    c.drawPath(path, _paint(AppColors.sky));
  }

  void _land(Canvas c) {
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(20, 52, 60, 26), AppSpacing.radiusPill),
        _paint(AppColors.success));
    c.drawCircle(const Offset(35, 45), 13, _paint(AppColors.mint));
    c.drawCircle(const Offset(60, 44), 14, _paint(AppColors.mint));
  }

  void _generic(Canvas c) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 22, 56, 56),
        AppSpacing.radiusLg,
      ),
      _paint(AppColors.mint),
    );
    c.drawCircle(const Offset(41, 44), 4, _paint(AppColors.lightText));
    c.drawCircle(const Offset(59, 44), 4, _paint(AppColors.lightText));
    _smile(c);
  }

  @override
  bool shouldRepaint(covariant _ObjectPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.selected != selected;
}
