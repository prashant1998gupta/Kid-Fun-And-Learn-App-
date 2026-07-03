import 'package:flutter/material.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../../core/widgets/currency_hud.dart';
import '../../../core/widgets/mascot.dart';
import '../../curriculum/domain/lesson.dart';
import '../../gamification/reward_engine.dart';

/// Finger-tracing of a glyph ([Question.answer] — a letter, number or shape).
///
/// Made kid-friendly and smooth:
///  - **Multi-stroke**: lifting the finger starts a new stroke, so no ugly
///    connecting line jumps across the letter (needed for A, E, T, 4…).
///  - **Smooth ink**: strokes are drawn as quadratic-bezier curves through
///    point midpoints, with a soft glow — no jagged straight segments.
///  - **Clear guide**: the letter shows as a big dashed-style *outline* with a
///    green "start here" dot, not a faded fill.
///  - **Fair completion**: the grid is mapped to the glyph's bounding box
///    (the central ~60% of the canvas) rather than the whole canvas, so
///    narrow letters like "I" or "1" complete properly. Threshold is lenient;
///    this is motor practice, not handwriting grading.
class TracingGame extends StatefulWidget {
  const TracingGame({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  final Lesson lesson;
  final ValueChanged<LessonResult> onComplete;

  @override
  State<TracingGame> createState() => _TracingGameState();
}

class _TracingGameState extends State<TracingGame> {
  final _celebration = CelebrationController();

  // Coverage grid mapped to the glyph bounding box (central 60% of canvas).
  static const int _cols = 10;
  static const int _rows = 10;
  static const double _threshold = 0.30; // fraction of glyph cells to cover
  static const int _minInkPoints = 20; // guard against a single tap completing

  int _index = 0;
  final List<List<Offset>> _strokes = []; // each finger-down starts a stroke
  final Set<int> _covered = {};
  int _inkPoints = 0;
  bool _done = false;
  Size _canvas = Size.zero;
  Rect _glyphRect = Rect.zero; // bounding box of the rendered glyph
  final _stopwatch = Stopwatch()..start();

  Question get _q => widget.lesson.questions[_index];
  int get _total => widget.lesson.questions.length;
  String get _glyph => _q.answer ?? _q.prompt;

  /// Scale factor from canvas coords to glyph-bounding-box coords.
  double get _glyphLeft => _glyphRect.left;
  double get _glyphTop => _glyphRect.top;
  double get _glyphW => _glyphRect.width;
  double get _glyphH => _glyphRect.height;

  /// Cells that make up the glyph's writing area — all interior cells.
  Set<int> get _targetCells {
    final cells = <int>{};
    for (var r = 1; r < _rows - 1; r++) {
      for (var c = 1; c < _cols - 1; c++) {
        cells.add(r * _cols + c);
      }
    }
    return cells;
  }

  /// Maps a finger position to a grid cell within the glyph bounding box.
  /// Returns -1 if the position is outside the glyph area entirely.
  int _cellAt(Offset local) {
    if (_glyphW <= 0 || _glyphH <= 0) return -1;
    final dx = (local.dx - _glyphLeft) / _glyphW * _cols;
    final dy = (local.dy - _glyphTop) / _glyphH * _rows;
    final c = dx.floor();
    final r = dy.floor();
    if (c < 0 || c >= _cols || r < 0 || r >= _rows) return -1;
    return r * _cols + c;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  void _speak() => AudioService.instance
      .speak(_q.speak ?? 'Trace the ${_glyph.toUpperCase()}');

  void _startStroke(Offset local) {
    if (_done) return;
    setState(() => _strokes.add(<Offset>[]));
    _extend(local);
  }

  void _extend(Offset local) {
    if (_done || _canvas == Size.zero || _strokes.isEmpty) return;
    final cell = _cellAt(local);
    setState(() {
      _strokes.last.add(local);
      if (cell >= 0) _covered.add(cell);
      _inkPoints++;
    });
  }

  void _checkComplete() {
    if (_done) return;
    final target = _targetCells;
    final hit = _covered.where(target.contains).length;
    if (_inkPoints >= _minInkPoints && hit / target.length >= _threshold) {
      _complete();
    }
  }

  Future<void> _complete() async {
    setState(() => _done = true);
    AudioService.instance.playSfx(Sfx.correct);
    AudioService.instance.successHaptic();
    _celebration.celebrate(sound: false);
    AudioService.instance.speak(PraiseLines.nextSuccess());
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _advance();
  }

  void _clear() => setState(() {
        _strokes.clear();
        _covered.clear();
        _inkPoints = 0;
      });

  void _advance() {
    if (_index + 1 >= _total) {
      _stopwatch.stop();
      widget.onComplete(
        LessonResult(
          lesson: widget.lesson,
          correct: _total,
          total: _total,
          firstTryCorrect: _total,
          durationSeconds: _stopwatch.elapsed.inSeconds,
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _strokes.clear();
      _covered.clear();
      _inkPoints = 0;
      _done = false;
    });
    _speak();
  }

  @override
  Widget build(BuildContext context) {
    return CelebrationOverlay(
      controller: _celebration,
      child: Scaffold(
        body: AnimatedBackground(
          theme: WorldTheme.candy,
          child: SafeArea(
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 4),
                Text(
                  'Trace the ${_glyph.toUpperCase()}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _canvas =
                            Size(constraints.maxWidth, constraints.maxHeight);
                        // Compute the glyph bounding box for hit-testing.
                        final tp = TextPainter(
                          text: TextSpan(
                            text: _glyph.toUpperCase(),
                            style: TextStyle(
                              fontSize: _canvas.height * 0.72,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          textDirection: TextDirection.ltr,
                        )..layout();
                        _glyphRect = Rect.fromLTWH(
                          (_canvas.width - tp.width) / 2,
                          (_canvas.height - tp.height) / 2,
                          tp.width,
                          tp.height,
                        );
                        return GestureDetector(
                          onPanStart: (d) => _startStroke(d.localPosition),
                          onPanUpdate: (d) => _extend(d.localPosition),
                          onPanEnd: (_) => _checkComplete(),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: AppSpacing.cardRadius,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              painter: _TracePainter(
                                glyph: _glyph,
                                strokes: _strokes,
                                revision: _inkPoints,
                                done: _done,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: BouncyButton(
                    onTap: _clear,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(AppSpacing.radiusPill),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('Clear',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.lightText,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          BouncyButton(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ProgressBarKid(
              progress: (_index + 1) / _total,
              color: AppColors.bubblegum,
            ),
          ),
          const SizedBox(width: 12),
          const MascotView(mascot: Mascot.unicorn, size: 56),
        ],
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter({
    required this.glyph,
    required this.strokes,
    required this.revision,
    required this.done,
  });

  final String glyph;
  final List<List<Offset>> strokes;

  /// Increments on every added ink point; drives repaints because [strokes] is
  /// mutated in place (same list reference across builds).
  final int revision;
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    final fontSize = size.height * 0.72;
    final text = glyph.toUpperCase();

    // 1) Faint fill of the glyph (soft target area).
    _drawGlyph(
      canvas,
      size,
      text,
      fontSize,
      Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.primary.withValues(alpha: 0.08),
    );
    // 2) Dashed-look outline the child follows.
    _drawGlyph(
      canvas,
      size,
      text,
      fontSize,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = (done ? AppColors.success : AppColors.primary)
            .withValues(alpha: 0.55),
    );

    // 3) "Start here" green dot (top-left of the glyph box) — only before done.
    if (!done && strokes.isEmpty) {
      final start = Offset(size.width * 0.40, size.height * 0.24);
      canvas.drawCircle(start, 11, Paint()..color = AppColors.success);
      canvas.drawCircle(
          start,
          11,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.white);
    }

    // 4) The child's smooth ink.
    final glow = Paint()
      ..color = (done ? AppColors.success : AppColors.secondary)
          .withValues(alpha: 0.25)
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final ink = Paint()
      ..color = done ? AppColors.success : AppColors.secondary
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      final path = _smoothPath(stroke);
      if (path == null) {
        if (stroke.isNotEmpty) {
          canvas.drawCircle(stroke.first, 7, ink);
        }
        continue;
      }
      canvas.drawPath(path, glow);
      canvas.drawPath(path, ink);
    }
  }

  void _drawGlyph(
      Canvas canvas, Size size, String text, double fontSize, Paint paint) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          foreground: paint,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
  }

  /// Smooths a stroke into curves through point midpoints.
  Path? _smoothPath(List<Offset> pts) {
    if (pts.length < 2) return null;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final mid = Offset(
        (pts[i].dx + pts[i + 1].dx) / 2,
        (pts[i].dy + pts[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(_TracePainter old) =>
      old.done != done ||
      old.revision != revision ||
      old.strokes.length != strokes.length;
}
