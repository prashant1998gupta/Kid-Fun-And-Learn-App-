import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'openmoji_view.dart';

/// Renders the illustration for a question answer/object. Preference order:
/// 1. A bundled OpenMoji image (consistent, kid-friendly real art) when the
///    answer's emoji is in our subset;
/// 2. a code-drawn preschool illustration for known objects;
/// 3. a big letter/number tile for short text answers.
/// This keeps the "just emoji" look out of core games while staying offline.
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
    final drawn = kind == _IllustrationKind.text
        ? _TextTile(label: label, size: size, foreground: fg)
        : SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _ObjectPainter(kind: kind, selected: selected),
            ),
          );
    // Real OpenMoji art wins for objects; letters/numbers keep their tile.
    // For object words that do not have an exact emoji, avoid misleading
    // generic cues. A drawn fruit is better than showing "Papaya" as a heart
    // or "Pomegranate" as a red dot.
    if (kind != _IllustrationKind.text &&
        !_preferDrawnArt(kind, emoji) &&
        OpenMojiView.has(emoji)) {
      return OpenMojiView(emoji: emoji!, size: size, fallback: drawn);
    }
    return drawn;
  }
}

bool _preferDrawnArt(_IllustrationKind kind, String? emoji) {
  if (emoji == null) return false;
  const genericCues = {
    '🔴',
    '🟠',
    '🟡',
    '🟢',
    '🔵',
    '🟣',
    '🟤',
    '⚪',
    '⚫',
    '⭐',
    '💚',
    '🧡',
    '💜',
    '🤍',
    '🐉',
  };
  const fruitFallbackKinds = {
    _IllustrationKind.fruit,
    _IllustrationKind.papaya,
    _IllustrationKind.pomegranate,
    _IllustrationKind.purpleFruit,
    _IllustrationKind.orangeFruit,
    _IllustrationKind.brownFruit,
    _IllustrationKind.lychee,
    _IllustrationKind.dragonFruit,
    _IllustrationKind.starFruit,
    _IllustrationKind.jackfruit,
  };
  return (fruitFallbackKinds.contains(kind) ||
          kind == _IllustrationKind.vegetable) &&
      genericCues.contains(emoji);
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
    // Show the FULL label. A single letter/number gets the big letter-tile
    // look; longer answers (words like "cell", decimals like "3.25", phrases
    // like "many years") scale down and wrap so the whole answer is always
    // readable — never truncated to its first character.
    final len = label.length;
    final fontSize = len <= 2
        ? size * 0.5
        : len <= 6
            ? size * 0.28
            : size * 0.2;
    final radius = size * 0.24;
    // Solid-white outer = the border; gradient is clipped inside. A stroked
    // border painted over a gradient leaves white fringes at the corners on
    // Flutter web, so we layer them instead.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.all(size * 0.08),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF1A6), Color(0xFFFFC048)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(radius - 3)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: foreground,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ),
      ),
    );
  }
}

enum _IllustrationKind {
  text,
  apple,
  banana,
  fruit,
  papaya,
  pomegranate,
  purpleFruit,
  orangeFruit,
  brownFruit,
  lychee,
  dragonFruit,
  starFruit,
  jackfruit,
  carrot,
  vegetable,
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
  if (value.contains('papaya')) return _IllustrationKind.papaya;
  if (value.contains('pomegranate')) return _IllustrationKind.pomegranate;
  if (value.contains('plum') || value.contains('fig')) {
    return _IllustrationKind.purpleFruit;
  }
  if (value.contains('apricot')) return _IllustrationKind.orangeFruit;
  if (value.contains('date')) return _IllustrationKind.brownFruit;
  if (value.contains('lychee')) return _IllustrationKind.lychee;
  if (value.contains('dragon fruit')) return _IllustrationKind.dragonFruit;
  if (value.contains('star fruit')) return _IllustrationKind.starFruit;
  if (value.contains('jackfruit')) return _IllustrationKind.jackfruit;
  if (_fruitWords.any(value.contains)) return _IllustrationKind.fruit;
  if (value.contains('carrot') || value.contains('veggie')) {
    return _IllustrationKind.carrot;
  }
  if (_vegetableWords.any(value.contains)) return _IllustrationKind.vegetable;
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

const _fruitWords = {
  'mango',
  'pear',
  'cherry',
  'coconut',
  'lemon',
  'kiwi',
  'papaya',
  'guava',
  'pomegranate',
  'plum',
  'apricot',
  'fig',
  'date',
  'lychee',
  'dragon fruit',
  'custard apple',
  'muskmelon',
  'star fruit',
  'jackfruit',
};

const _vegetableWords = {
  'tomato',
  'potato',
  'onion',
  'broccoli',
  'corn',
  'peas',
  'cucumber',
  'brinjal',
  'capsicum',
  'mushroom',
  'spinach',
  'pumpkin',
  'garlic',
  'sweet potato',
  'cabbage',
  'cauliflower',
  'radish',
  'beetroot',
  'okra',
  'beans',
  'ginger',
  'turnip',
  'gourd',
  'ladyfinger',
  'lettuce',
  'celery',
  'chilli',
  'coriander',
};

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
      case _IllustrationKind.fruit:
        _fruit(canvas, const Color(0xFFFFA726), leaf: true);
      case _IllustrationKind.papaya:
        _papaya(canvas);
      case _IllustrationKind.pomegranate:
        _pomegranate(canvas);
      case _IllustrationKind.purpleFruit:
        _ovalFruit(canvas, const Color(0xFF8E44AD));
      case _IllustrationKind.orangeFruit:
        _ovalFruit(canvas, const Color(0xFFFFA726));
      case _IllustrationKind.brownFruit:
        _ovalFruit(canvas, const Color(0xFF8D6E63), leaf: false);
      case _IllustrationKind.lychee:
        _lychee(canvas);
      case _IllustrationKind.dragonFruit:
        _dragonFruit(canvas);
      case _IllustrationKind.starFruit:
        _starFruit(canvas);
      case _IllustrationKind.jackfruit:
        _jackfruit(canvas);
      case _IllustrationKind.carrot:
        _carrot(canvas);
      case _IllustrationKind.vegetable:
        _leafyVegetable(canvas);
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

  void _ovalFruit(Canvas c, Color color, {bool leaf = true}) {
    c.drawOval(const Rect.fromLTWH(28, 28, 44, 54), _paint(color));
    c.drawOval(const Rect.fromLTWH(38, 34, 14, 20), _paint(Colors.white24));
    if (leaf) {
      c.drawOval(const Rect.fromLTWH(54, 17, 18, 10), _paint(AppColors.mint));
      c.drawLine(const Offset(51, 28), const Offset(56, 18),
          _stroke(const Color(0xFF6D4C41), 3));
    }
    _eye(c, 43, 52);
    _eye(c, 57, 52);
    _smile(c);
  }

  void _papaya(Canvas c) {
    c.drawOval(
        const Rect.fromLTWH(25, 27, 50, 56), _paint(const Color(0xFFFFA726)));
    c.drawOval(
        const Rect.fromLTWH(37, 35, 26, 38), _paint(const Color(0xFFFFE082)));
    for (final p in const [Offset(47, 48), Offset(54, 54), Offset(49, 61)]) {
      c.drawCircle(p, 2.2, _paint(const Color(0xFF5D4037)));
    }
    c.drawOval(const Rect.fromLTWH(55, 16, 18, 10), _paint(AppColors.mint));
    _eye(c, 38, 55);
    _eye(c, 62, 55);
    _smile(c);
  }

  void _pomegranate(Canvas c) {
    _fruit(c, const Color(0xFFE53935), leaf: true);
    for (final p in const [
      Offset(43, 40),
      Offset(54, 43),
      Offset(47, 54),
      Offset(59, 58),
    ]) {
      c.drawCircle(p, 2.4, _paint(const Color(0xFFFFCDD2)));
    }
  }

  void _lychee(Canvas c) {
    _fruit(c, const Color(0xFFFF6F91), leaf: true);
    for (final p in const [
      Offset(39, 39),
      Offset(54, 36),
      Offset(64, 49),
      Offset(44, 64),
    ]) {
      c.drawCircle(p, 1.8, _paint(Colors.white70));
    }
  }

  void _dragonFruit(Canvas c) {
    c.drawOval(
        const Rect.fromLTWH(26, 25, 48, 58), _paint(const Color(0xFFE91E63)));
    for (final p in const [
      Offset(30, 36),
      Offset(70, 39),
      Offset(32, 62),
      Offset(68, 66),
    ]) {
      c.drawPath(
        Path()
          ..moveTo(p.dx, p.dy)
          ..lineTo(p.dx + (p.dx < 50 ? -10 : 10), p.dy + 6)
          ..lineTo(p.dx + (p.dx < 50 ? 2 : -2), p.dy + 14)
          ..close(),
        _paint(AppColors.mint),
      );
    }
    c.drawOval(const Rect.fromLTWH(38, 36, 24, 34), _paint(Colors.white));
    _eye(c, 44, 52);
    _eye(c, 56, 52);
    _smile(c);
  }

  void _starFruit(Canvas c) {
    _star(c);
    c.drawPath(
      Path()
        ..moveTo(50, 22)
        ..lineTo(55, 45)
        ..lineTo(78, 44)
        ..lineTo(58, 56)
        ..lineTo(66, 78)
        ..lineTo(50, 63)
        ..lineTo(34, 78)
        ..lineTo(42, 56)
        ..lineTo(22, 44)
        ..lineTo(45, 45)
        ..close(),
      _stroke(const Color(0xFFD99000), 2.5),
    );
  }

  void _jackfruit(Canvas c) {
    c.drawOval(
        const Rect.fromLTWH(25, 28, 50, 54), _paint(const Color(0xFF9CCC65)));
    for (final p in const [
      Offset(38, 41),
      Offset(51, 38),
      Offset(63, 45),
      Offset(43, 56),
      Offset(58, 61),
      Offset(48, 71),
    ]) {
      c.drawCircle(p, 1.8, _paint(const Color(0xFF558B2F)));
    }
    c.drawOval(const Rect.fromLTWH(55, 18, 18, 10), _paint(AppColors.mint));
    _eye(c, 43, 53);
    _eye(c, 57, 53);
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

  void _leafyVegetable(Canvas c) {
    c.drawOval(
        const Rect.fromLTWH(24, 42, 28, 34), _paint(const Color(0xFF66BB6A)));
    c.drawOval(
        const Rect.fromLTWH(48, 42, 28, 34), _paint(const Color(0xFF43A047)));
    c.drawOval(
        const Rect.fromLTWH(34, 26, 32, 42), _paint(const Color(0xFF81C784)));
    c.drawPath(
      Path()
        ..moveTo(50, 32)
        ..quadraticBezierTo(44, 50, 42, 74)
        ..moveTo(50, 32)
        ..quadraticBezierTo(56, 50, 58, 74),
      _stroke(const Color(0xFF2E7D32), 2.4),
    );
    _eye(c, 43, 54);
    _eye(c, 57, 54);
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
