import 'package:flutter/material.dart';

import '../../../core/constants/feedback_timing.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../../core/widgets/mascot.dart';
import '../../../core/widgets/play_option_card.dart';
import '../../curriculum/domain/lesson.dart';
import '../../gamification/reward_engine.dart';
import '../learning_support.dart';

/// A pre-reader activity with one spoken instruction and large visual targets.
/// The child can replay the spoken prompt at any time; large targets keep
/// longer curriculum sessions accessible to developing motor skills.
class ListenAndTapGame extends StatefulWidget {
  const ListenAndTapGame({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  final Lesson lesson;
  final ValueChanged<LessonResult> onComplete;

  @override
  State<ListenAndTapGame> createState() => _ListenAndTapGameState();
}

class _ListenAndTapGameState extends State<ListenAndTapGame> {
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
      await Future<void>.delayed(const Duration(milliseconds: 550));
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
    AudioService.instance.playSfx(Sfx.correct);
    AudioService.instance.successHaptic();
    AudioService.instance.speak(PraiseLines.nextSuccess());
    _celebration.celebrate(sound: false);
    await Future<void>.delayed(FeedbackTiming.successBeat);
    if (mounted) _advance();
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
          theme: WorldTheme.candy,
          particleCount: 12,
          child: SafeArea(
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 8),
                const MascotView(mascot: Mascot.panda, size: 82),
                const SizedBox(height: 8),
                BouncyButton(
                  onTap: _speak,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(AppSpacing.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.volume_up_rounded,
                          size: 34,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
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
                ),
                const SizedBox(height: 16),
                Expanded(child: _options(context)),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_index + 1) / _total,
                  minHeight: 14,
                  borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.star),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_index + 1} / $_total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _options(BuildContext context) {
    final optionIndexes = rescueOptionIndexes(
      _question,
      rescue: _rescue || LearningSupportScope.stageOf(context).guidedChoices,
    );
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1,
      ),
      itemCount: optionIndexes.length,
      itemBuilder: (context, index) {
        final originalIndex = optionIndexes[index];
        final option = _question.options[originalIndex];
        return PlayOptionCard(
          key: ValueKey('$_index-$originalIndex'),
          index: originalIndex,
          label: option.label,
          emoji: option.emoji,
          artSize: 86,
          state: _stateFor(originalIndex),
          onTap: () => _choose(originalIndex),
        );
      },
    );
  }

  PlayCardState _stateFor(int index) {
    if (_selected != index) return PlayCardState.idle;
    return index == _question.correctIndex
        ? PlayCardState.correct
        : PlayCardState.wrong;
  }
}
