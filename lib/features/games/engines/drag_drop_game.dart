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

/// Drag-and-drop sorting. For each question the child drags the prompt item
/// (an emoji) into one of the labeled baskets ([Question.options]); the correct
/// basket is [Question.correctIndex]. Same content schema as tap-choice, but a
/// tactile drag interaction — great for "sort into groups" lessons.
class DragDropGame extends StatefulWidget {
  const DragDropGame({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  final Lesson lesson;
  final ValueChanged<LessonResult> onComplete;

  @override
  State<DragDropGame> createState() => _DragDropGameState();
}

class _DragDropGameState extends State<DragDropGame> {
  final _celebration = CelebrationController();
  int _index = 0;
  int _correct = 0;
  int _firstTryCorrect = 0;
  bool _erred = false;
  int? _wrongBasket; // basket index flashing red
  bool _placed = false;
  final List<String> _struggled = [];
  final _stopwatch = Stopwatch()..start();

  Question get _q => widget.lesson.questions[_index];
  int get _total => widget.lesson.questions.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  void _speak() => AudioService.instance.speak(_q.speak ?? _q.prompt);

  Future<void> _drop(int basket) async {
    if (_placed) return;
    if (basket == _q.correctIndex) {
      setState(() => _placed = true);
      AudioService.instance.playSfx(Sfx.correct);
      AudioService.instance.successHaptic();
      _celebration.celebrate(sound: false);
      AudioService.instance.speak(PraiseLines.nextSuccess());
      _correct++;
      if (!_erred) _firstTryCorrect++;
      await Future<void>.delayed(FeedbackTiming.successBeat);
      if (!mounted) return;
      _advance();
    } else {
      AudioService.instance.playSfx(Sfx.wrong);
      if (!_erred) {
        _erred = true;
        _struggled.add(_q.id);
      }
      AudioService.instance.speak(PraiseLines.nextRetry());
      setState(() => _wrongBasket = basket);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _wrongBasket = null);
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
          firstTryCorrect: _firstTryCorrect,
          struggledQuestionIds: _struggled,
          durationSeconds: _stopwatch.elapsed.inSeconds,
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _placed = false;
      _erred = false;
      _wrongBasket = null;
    });
    _speak();
  }

  @override
  Widget build(BuildContext context) {
    return CelebrationOverlay(
      controller: _celebration,
      child: Scaffold(
        body: AnimatedBackground(
          theme: WorldTheme.jungle,
          child: SafeArea(
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 8),
                _prompt(context),
                const Spacer(),
                _draggable(context),
                const Spacer(),
                _baskets(context),
                const SizedBox(height: 24),
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
              color: AppColors.accent,
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
              const MascotView(mascot: Mascot.lion, size: 56),
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

  Widget _draggable(BuildContext context) {
    final item = _q.promptEmoji ?? '📦';
    if (_placed) {
      return const Icon(Icons.check_circle_rounded,
          color: AppColors.success, size: 90);
    }
    final chip = _ItemChip(label: item, artLabel: _q.prompt);
    return Draggable<int>(
      data: 1,
      feedback: _ItemChip(label: item, artLabel: _q.prompt, dragging: true),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: -6, end: 6, duration: 900.ms),
    );
  }

  Widget _baskets(BuildContext context) {
    final options = _q.options;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < options.length; i++)
            DragTarget<int>(
              onWillAcceptWithDetails: (_) => !_placed,
              onAcceptWithDetails: (_) => _drop(i),
              builder: (context, candidate, __) {
                final hover = candidate.isNotEmpty;
                final wrong = _wrongBasket == i;
                return _Basket(
                  option: options[i],
                  highlight: hover,
                  wrong: wrong,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({
    required this.label,
    required this.artLabel,
    this.dragging = false,
  });

  final String label;
  final String artLabel;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dragging ? 0.3 : 0.15),
              blurRadius: dragging ? 20 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: IllustratedObjectView(label: artLabel, emoji: label, size: 66),
      ),
    );
  }
}

class _Basket extends StatelessWidget {
  const _Basket({
    required this.option,
    required this.highlight,
    required this.wrong,
  });

  final AnswerOption option;
  final bool highlight;
  final bool wrong;

  @override
  Widget build(BuildContext context) {
    final color = wrong
        ? AppColors.error
        : highlight
            ? AppColors.success
            : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 110,
      height: 120,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: highlight ? AppColors.success : Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (option.emoji != null)
            IllustratedObjectView(
              label: option.label,
              emoji: option.emoji,
              size: 48,
              selected: highlight || wrong,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              option.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color:
                    (highlight || wrong) ? Colors.white : AppColors.lightText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
