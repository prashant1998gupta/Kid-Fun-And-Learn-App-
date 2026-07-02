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

/// Finger-tracing of a glyph ([Question.answer] — a letter, number or shape
/// character). Coverage is measured over a grid: when the child has drawn over
/// enough of the glyph area, the stroke "locks in" and we advance. Deliberately
/// lenient — the goal is joyful motor practice, not handwriting grading.
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
  static const int _cols = 6;
  static const int _rows = 6;
  static const double _threshold = 0.5; // fraction of central cells to cover

  int _index = 0;
  final List<Offset> _points = [];
  final Set<int> _covered = {};
  bool _done = false;
  Size _canvas = Size.zero;
  final _stopwatch = Stopwatch()..start();

  Question get _q => widget.lesson.questions[_index];
  int get _total => widget.lesson.questions.length;
  String get _glyph => _q.answer ?? _q.prompt;

  // Central band of the grid = where the glyph roughly lives.
  Set<int> get _targetCells {
    final cells = <int>{};
    for (var r = 1; r < _rows - 1; r++) {
      for (var c = 1; c < _cols - 1; c++) {
        cells.add(r * _cols + c);
      }
    }
    return cells;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  void _speak() => AudioService.instance
      .speak(_q.speak ?? 'Trace the ${_glyph.toUpperCase()}');

  void _add(Offset local) {
    if (_done || _canvas == Size.zero) return;
    final c = (local.dx / _canvas.width * _cols).floor().clamp(0, _cols - 1);
    final r = (local.dy / _canvas.height * _rows).floor().clamp(0, _rows - 1);
    setState(() {
      _points.add(local);
      _covered.add(r * _cols + c);
    });
  }

  void _checkComplete() {
    if (_done) return;
    final target = _targetCells;
    final hit = _covered.where(target.contains).length;
    if (hit / target.length >= _threshold) _complete();
  }

  Future<void> _complete() async {
    setState(() => _done = true);
    AudioService.instance.playSfx(Sfx.correct);
    AudioService.instance.successHaptic();
    _celebration.celebrate(sound: false);
    AudioService.instance.speak(PraiseLines.nextSuccess());
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    _advance();
  }

  void _advance() {
    if (_index + 1 >= _total) {
      _stopwatch.stop();
      widget.onComplete(
        LessonResult(
          lesson: widget.lesson,
          correct: _total,
          total: _total,
          firstTryCorrect:
              _total, // tracing completion = mastery for young kids
          durationSeconds: _stopwatch.elapsed.inSeconds,
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _points.clear();
      _covered.clear();
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
                const SizedBox(height: 8),
                Text(
                  'Trace it!',
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
                        return GestureDetector(
                          onPanStart: (d) => _add(d.localPosition),
                          onPanUpdate: (d) => _add(d.localPosition),
                          onPanEnd: (_) => _checkComplete(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: AppSpacing.cardRadius,
                            ),
                            child: CustomPaint(
                              painter: _TracePainter(
                                glyph: _glyph,
                                points: _points,
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
                    onTap: () => setState(() {
                      _points.clear();
                      _covered.clear();
                    }),
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
              child: const Icon(Icons.close_rounded, size: 26),
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
    required this.points,
    required this.done,
  });

  final String glyph;
  final List<Offset> points;
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    // Faded guide glyph behind the trace.
    final tp = TextPainter(
      text: TextSpan(
        text: glyph.toUpperCase(),
        style: TextStyle(
          fontSize: size.height * 0.7,
          fontWeight: FontWeight.w900,
          color: (done ? AppColors.success : AppColors.primary)
              .withValues(alpha: 0.22),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );

    // The child's stroke.
    if (points.length > 1) {
      final paint = Paint()
        ..color = done ? AppColors.success : AppColors.secondary
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_TracePainter old) =>
      old.points.length != points.length || old.done != done;
}
