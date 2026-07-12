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

/// A preschool-friendly toy loop: feed a cute pet the correct food/object.
/// It keeps the same question schema as tap-choice, but wraps answers in a
/// pretend-play goal so it feels like care-taking rather than a quiz.
class FeedPetGame extends StatefulWidget {
  const FeedPetGame({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  final Lesson lesson;
  final ValueChanged<LessonResult> onComplete;

  @override
  State<FeedPetGame> createState() => _FeedPetGameState();
}

class _FeedPetGameState extends State<FeedPetGame> {
  final _celebration = CelebrationController();
  final _stopwatch = Stopwatch()..start();
  final List<String> _struggled = [];
  final List<String> _rescued = [];

  int _index = 0;
  int _correct = 0;
  int _firstTry = 0;
  int? _selected;
  bool _missed = false;
  bool _locked = false;
  bool _petHappy = false;
  int _mistakes = 0;
  bool _rescue = false;

  Question get _question => widget.lesson.questions[_index];
  int get _total => widget.lesson.questions.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  void _speak() {
    AudioService.instance.speak(_question.speak ?? _question.prompt);
  }

  Future<void> _choose(int index) async {
    if (_locked) return;
    final isCorrect = index == _question.correctIndex;
    setState(() => _selected = index);

    if (!isCorrect) {
      _mistakes++;
      if (!_missed) {
        _missed = true;
        _struggled.add(_question.id);
      }
      AudioService.instance.playSfx(Sfx.wrong);
      AudioService.instance.speak(PraiseLines.nextRetry());
      await Future<void>.delayed(const Duration(milliseconds: 520));
      if (!mounted) return;
      setState(() => _selected = null);
      if (_mistakes >= 2 && !_rescue) {
        setState(() => _rescue = true);
        _rescued.add(_question.id);
        await showLearningRescue(context, _question);
      }
      return;
    }

    _locked = true;
    _correct++;
    if (!_missed) _firstTry++;
    setState(() => _petHappy = true);
    AudioService.instance.playSfx(Sfx.reward);
    AudioService.instance.successHaptic();
    AudioService.instance.speak(PraiseLines.nextRescue());
    _celebration.celebrate(sound: false);
    await Future<void>.delayed(FeedbackTiming.successBeat);
    if (!mounted) return;
    _advance();
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
      _selected = null;
      _missed = false;
      _locked = false;
      _petHappy = false;
      _mistakes = 0;
      _rescue = false;
    });
    _speak();
  }

  @override
  Widget build(BuildContext context) {
    return CelebrationOverlay(
      controller: _celebration,
      child: Scaffold(
        body: AnimatedBackground(
          theme: WorldTheme.sunrise,
          particleCount: 14,
          child: SafeArea(
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 8),
                _prompt(context),
                const SizedBox(height: 10),
                _PetStage(happy: _petHappy),
                const SizedBox(height: 8),
                Expanded(child: _foodTray(context)),
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
            child: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.close_rounded, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ProgressBarKid(
              progress: (_index + 1) / _total,
              color: AppColors.mint,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${_index + 1}/$_total',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _prompt(BuildContext context) {
    return BouncyButton(
      onTap: _speak,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(AppSpacing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.volume_up_rounded,
                color: AppColors.primary, size: 30),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _question.prompt,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _foodTray(BuildContext context) {
    final optionIndexes = rescueOptionIndexes(_question, rescue: _rescue);
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.95,
      ),
      itemCount: optionIndexes.length,
      itemBuilder: (context, index) {
        final originalIndex = optionIndexes[index];
        final option = _question.options[originalIndex];
        final selected = _selected == originalIndex;
        final correct = originalIndex == _question.correctIndex;
        final bg = !selected
            ? Colors.white
            : correct
                ? AppColors.success
                : AppColors.error;
        Widget card = BouncyButton(
          key: ValueKey('feed-$originalIndex'),
          borderRadius: AppSpacing.cardRadius,
          onTap: () => _choose(originalIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppSpacing.cardRadius,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IllustratedObjectView(
                  label: option.label,
                  emoji: option.emoji,
                  size: 82,
                  selected: selected,
                ),
                const SizedBox(height: 8),
                Text(
                  option.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.lightText,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        );
        if (selected && !correct) {
          card = card.animate().shake(
                hz: 6,
                offset: const Offset(12, 0),
                rotation: 0.05,
                duration: 450.ms,
              );
        }
        return card;
      },
    );
  }
}

class _PetStage extends StatelessWidget {
  const _PetStage({required this.happy});

  final bool happy;

  @override
  Widget build(BuildContext context) {
    final pet = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 190,
          height: 116,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: AppSpacing.cardRadius,
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
        Positioned(
          top: -18,
          child: IllustratedObjectView(
            label: happy ? 'Happy puppy' : 'Puppy',
            size: 108,
          ),
        ),
        Positioned(
          bottom: 10,
          child: Container(
            width: 78,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
        if (happy)
          const Positioned(
            right: 18,
            top: 8,
            child: Text('❤', style: TextStyle(fontSize: 34)),
          ).animate().scale(curve: Curves.elasticOut).moveY(begin: 8, end: -4),
      ],
    );
    return Column(
      children: [
        const MascotView(mascot: Mascot.panda, size: 64),
        const SizedBox(height: 4),
        happy
            ? pet.animate(key: const ValueKey('happy_pet')).shake(
                  hz: 3,
                  rotation: 0.04,
                  duration: 500.ms,
                )
            : pet,
      ],
    );
  }
}
