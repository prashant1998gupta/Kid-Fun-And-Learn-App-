import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/feedback_timing.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../curriculum/domain/lesson.dart';
import '../../gamification/reward_engine.dart';
import '../learning_support.dart';

/// A friendly end-of-unit challenge. Every correct answer removes one segment
/// of boss health; wrong answers cost a heart but never block completion.
class BossBattleGame extends StatefulWidget {
  const BossBattleGame({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  final Lesson lesson;
  final ValueChanged<LessonResult> onComplete;

  @override
  State<BossBattleGame> createState() => _BossBattleGameState();
}

class _BossBattleGameState extends State<BossBattleGame> {
  final _celebration = CelebrationController();
  final _stopwatch = Stopwatch()..start();
  final List<String> _struggled = [];
  final List<String> _rescued = [];

  int _index = 0;
  int _correct = 0;
  int _firstTryCorrect = 0;
  int _hearts = 3;
  int _attack = 0;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakPrompt());
  }

  void _speakPrompt() {
    AudioService.instance.speak(_question.speak ?? _question.prompt);
  }

  Future<void> _choose(int option) async {
    if (_locked) return;
    final correct = option == _question.correctIndex;
    setState(() => _selected = option);

    if (!correct) {
      _mistakes++;
      setState(() {
        _attack++;
        _hearts = (_hearts - 1).clamp(0, 3);
        if (!_missed) {
          _missed = true;
          _struggled.add(_question.id);
        }
      });
      AudioService.instance.playSfx(Sfx.wrong);
      AudioService.instance.speak('The boss blocked it. Try again!');
      await Future<void>.delayed(const Duration(milliseconds: 650));
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
    if (!_missed) _firstTryCorrect++;
    AudioService.instance.playSfx(Sfx.correct);
    AudioService.instance.successHaptic();
    _celebration.celebrate(sound: false);
    AudioService.instance.speak(PraiseLines.nextSuccess());
    await Future<void>.delayed(FeedbackTiming.successBeat);
    if (!mounted) return;
    _advance();
  }

  void _advance() {
    if (_index + 1 == _total) {
      _stopwatch.stop();
      _celebration.fireworks();
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
      _selected = null;
      _missed = false;
      _locked = false;
      _mistakes = 0;
      _rescue = false;
    });
    _speakPrompt();
  }

  @override
  Widget build(BuildContext context) {
    return CelebrationOverlay(
      controller: _celebration,
      child: Scaffold(
        body: AnimatedBackground(
          theme: WorldTheme.night,
          child: SafeArea(
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 8),
                Text(
                  '👾',
                  key: ValueKey(_attack),
                  style: const TextStyle(fontSize: 86),
                ).animate().shake(hz: 3, rotation: 0.08),
                Text(
                  'Knowledge Guardian',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 18),
                _prompt(context),
                const SizedBox(height: 18),
                Expanded(child: _options(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final remaining = _total - _correct;
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('BOSS',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w900)),
                    Text(List.filled(_hearts, '❤️').join(),
                        style: const TextStyle(fontSize: 19)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: remaining / _total,
                  minHeight: 14,
                  borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _prompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: BouncyButton(
        onTap: _speakPrompt,
        child: Container(
          width: double.infinity,
          padding: AppSpacing.cardPadding,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: AppSpacing.cardRadius,
          ),
          child: Text(
            _question.prompt,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.lightText),
          ),
        ),
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
        maxCrossAxisExtent: 260,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.7,
      ),
      itemCount: optionIndexes.length,
      itemBuilder: (context, index) {
        final originalIndex = optionIndexes[index];
        final isSelected = _selected == originalIndex;
        final isCorrect = originalIndex == _question.correctIndex;
        final color = !isSelected
            ? Colors.white
            : isCorrect
                ? AppColors.success
                : AppColors.error;
        return BouncyButton(
          onTap: () => _choose(originalIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppSpacing.cardRadius,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              _question.options[originalIndex].display,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isSelected ? Colors.white : AppColors.lightText,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        );
      },
    );
  }
}

extension on AnswerOption {
  String get display => emoji == null ? label : '$emoji\n$label';
}
