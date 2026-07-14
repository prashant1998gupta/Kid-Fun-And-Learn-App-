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
  int? _landedBasket; // basket the item correctly settled into
  bool _placed = false;
  int _mistakes = 0;
  bool _rescue = false;
  final List<String> _struggled = [];
  final List<String> _rescued = [];
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
      setState(() {
        _placed = true;
        _landedBasket = basket;
      });
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
      _mistakes++;
      AudioService.instance.playSfx(Sfx.wrong);
      if (!_erred) {
        _erred = true;
        _struggled.add(_q.id);
      }
      AudioService.instance.speak(PraiseLines.nextRetry());
      setState(() => _wrongBasket = basket);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _wrongBasket = null);
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
          firstTryCorrect: _firstTryCorrect,
          struggledQuestionIds: _struggled,
          rescuedQuestionIds: _rescued,
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
      _landedBasket = null;
      _mistakes = 0;
      _rescue = false;
    });
    _speak();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.width < 360 ||
        media.size.height < 620 ||
        media.textScaler.scale(1) > 1.2;

    return CelebrationOverlay(
      controller: _celebration,
      child: Scaffold(
        body: AnimatedBackground(
          theme: WorldTheme.jungle,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      children: [
                        _header(context),
                        SizedBox(height: compact ? 4 : 8),
                        _prompt(context, compact: compact),
                        SizedBox(height: compact ? 14 : 36),
                        _draggable(context),
                        SizedBox(height: compact ? 16 : 36),
                        _baskets(context),
                        SizedBox(height: compact ? 14 : 24),
                      ],
                    ),
                  ),
                );
              },
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

  Widget _prompt(BuildContext context, {required bool compact}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.md : AppSpacing.lg,
      ),
      child: BouncyButton(
        onTap: _speak,
        borderRadius: AppSpacing.cardRadius,
        child: Container(
          padding: EdgeInsets.all(compact ? 14 : AppSpacing.lg),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: AppSpacing.cardRadius,
          ),
          child: Row(
            children: [
              MascotView(mascot: Mascot.lion, size: compact ? 42 : 56),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Text(
                  _q.prompt,
                  maxLines: compact ? 3 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.lightText,
                        fontSize: compact ? 18 : null,
                        height: 1.15,
                      ),
                ),
              ),
              Icon(Icons.volume_up_rounded,
                  color: AppColors.primary, size: compact ? 24 : 28),
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
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
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
                  highlight: hover || (_rescue && i == _q.correctIndex),
                  wrong: wrong,
                  landed: _landedBasket == i,
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
    final compact = MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final size = compact ? 78.0 : 96.0;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: size,
        height: size,
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
        child: IllustratedObjectView(
          label: artLabel,
          emoji: label,
          size: compact ? 52 : 66,
        ),
      ),
    );
  }
}

class _Basket extends StatelessWidget {
  const _Basket({
    required this.option,
    required this.highlight,
    required this.wrong,
    required this.landed,
  });

  final AnswerOption option;
  final bool highlight;
  final bool wrong;
  final bool landed;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final active = highlight || landed;
    final gradient = wrong
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.error, AppColors.error.withValues(alpha: 0.82)],
          )
        : active
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.success, AppColors.mint],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFF2EFFF)],
              );
    final glow = wrong
        ? AppColors.error.withValues(alpha: 0.4)
        : active
            ? AppColors.success.withValues(alpha: 0.45)
            : AppColors.primary.withValues(alpha: 0.14);

    Widget basket = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: compact ? 92 : 110,
      height: compact ? 100 : 120,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.8),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.emoji != null)
                IllustratedObjectView(
                  label: option.label,
                  emoji: option.emoji,
                  size: compact ? 38 : 48,
                  selected: active || wrong,
                ),
              SizedBox(
                width: compact ? 76 : 92,
                child: Text(
                  option.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 13 : 15,
                    height: 1.05,
                    color:
                        (active || wrong) ? Colors.white : AppColors.lightText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (landed) {
      basket = basket
          .animate()
          .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
          .then()
          .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1));
    }
    return basket;
  }
}
