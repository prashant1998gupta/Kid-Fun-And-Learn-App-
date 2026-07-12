import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/feedback_timing.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../../core/widgets/currency_hud.dart';
import '../../../core/widgets/illustrated_object.dart';
import '../../../core/widgets/mascot.dart';
import '../../curriculum/domain/lesson.dart';
import '../../gamification/reward_engine.dart';
import '../learning_support.dart';

/// Pop-the-right-bubble. Options float as bobbing bubbles; the child pops the
/// one that answers the spoken prompt. Wrong pops fizzle (no penalty beyond the
/// first-try star). Same content schema as tap-choice, playful bubble feel.
class BubblePopGame extends StatefulWidget {
  const BubblePopGame({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  final Lesson lesson;
  final ValueChanged<LessonResult> onComplete;

  @override
  State<BubblePopGame> createState() => _BubblePopGameState();
}

class _BubblePopGameState extends State<BubblePopGame> {
  final _celebration = CelebrationController();
  int _index = 0;
  int _correct = 0;
  int _firstTry = 0;
  bool _erred = false;
  bool _locked = false;
  int? _wrong; // bubble briefly wobbling red after a wrong tap
  int _mistakes = 0;
  bool _rescue = false;
  final Set<int> _popped = {};
  final List<String> _struggled = [];
  final List<String> _rescued = [];
  final _stopwatch = Stopwatch()..start();

  Question get _q => widget.lesson.questions[_index];
  int get _total => widget.lesson.questions.length;

  static const _bubbleColors = [
    AppColors.sky,
    AppColors.bubblegum,
    AppColors.mint,
    AppColors.accent,
    AppColors.secondary,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  void _speak() => AudioService.instance.speak(_q.speak ?? _q.prompt);

  Future<void> _pop(int i) async {
    if (_locked || _popped.contains(i)) return;
    final correct = i == _q.correctIndex;
    if (correct) {
      _locked = true;
      setState(() => _popped.add(i));
      AudioService.instance.playSfx(Sfx.pop);
      AudioService.instance.successHaptic();
      _celebration.celebrate(sound: false);
      AudioService.instance.speak(PraiseLines.nextSuccess());
      _correct++;
      if (!_erred) _firstTry++;
      await Future<void>.delayed(FeedbackTiming.successBeat);
      if (!mounted) return;
      _advance();
    } else {
      _mistakes++;
      // A wrong bubble should wobble and stay — never disappear — so the child
      // can keep trying the others. (It used to pop and vanish, which read as a
      // reward.)
      AudioService.instance.playSfx(Sfx.wrong);
      if (!_erred) {
        _erred = true;
        _struggled.add(_q.id);
      }
      AudioService.instance.speak(PraiseLines.nextRetry());
      setState(() => _wrong = i);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _wrong = null);
      if (_mistakes >= 2 && !_rescue) {
        setState(() => _rescue = true);
        _rescued.add(_q.id);
        await showLearningRescue(context, _q);
      }
    }
  }

  void _advance() {
    if (_index + 1 >= _total) {
      _stopwatch.stop();
      widget.onComplete(
        LessonResult(
          lesson: widget.lesson,
          correct: _correct,
          total: _total,
          firstTryCorrect: _firstTry,
          struggledQuestionIds: _struggled,
          rescuedQuestionIds: _rescued,
          durationSeconds: _stopwatch.elapsed.inSeconds,
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _erred = false;
      _locked = false;
      _wrong = null;
      _popped.clear();
      _mistakes = 0;
      _rescue = false;
    });
    _speak();
  }

  @override
  Widget build(BuildContext context) {
    final optionIndexes = rescueOptionIndexes(
      _q,
      rescue: _rescue || LearningSupportScope.stageOf(context).guidedChoices,
    );
    return CelebrationOverlay(
      controller: _celebration,
      child: Scaffold(
        body: AnimatedBackground(
          theme: WorldTheme.ocean,
          child: SafeArea(
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 8),
                _prompt(context),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          for (final i in optionIndexes)
                            _bubble(i, constraints),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble(int i, BoxConstraints c) {
    final popped = _popped.contains(i);
    final isWrong = _wrong == i;
    // Distribute bubbles across the area deterministically.
    final col = i % 3;
    final row = i ~/ 3;
    final x =
        (c.maxWidth / 3) * col + (c.maxWidth / 6) - 55 + 20 * math.sin(i * 1.3);
    final y = 30.0 + row * 150 + 40 * math.cos(i * 0.7);
    final option = _q.options[i];
    final color =
        isWrong ? AppColors.error : _bubbleColors[i % _bubbleColors.length];

    Widget bubble = BouncyButton(
      onTap: () => _pop(i),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.95),
              color.withValues(alpha: 0.6)
            ],
            center: const Alignment(-0.3, -0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Glossy highlight — reads as a real, shiny, tappable bubble.
            Positioned(
              left: 24,
              top: 16,
              child: Container(
                width: 26,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (option.emoji != null)
                    IllustratedObjectView(
                      label: option.label,
                      emoji: option.emoji,
                      size: 42,
                      selected: true,
                    ),
                  Text(
                    option.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (popped) {
      bubble = bubble.animate().fadeOut(duration: 250.ms).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.4, 1.4),
            duration: 250.ms,
          );
    } else if (isWrong) {
      bubble = bubble.animate().shake(
            hz: 6,
            rotation: 0,
            offset: const Offset(8, 0),
            duration: 400.ms,
          );
    } else {
      bubble = bubble
          .animate(onPlay: (a) => a.repeat(reverse: true))
          .moveY(begin: -8, end: 8, duration: (1200 + i * 150).ms);
    }

    return Positioned(left: x, top: y, child: bubble);
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
              color: AppColors.sky,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_index + 1}/$_total',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _prompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: BouncyButton(
        onTap: _speak,
        borderRadius: AppSpacing.cardRadius,
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: AppSpacing.cardRadius,
          ),
          child: Row(
            children: [
              const MascotView(mascot: Mascot.penguin, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _q.prompt,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.lightText),
                ),
              ),
              const Icon(Icons.volume_up_rounded,
                  color: AppColors.primary, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
