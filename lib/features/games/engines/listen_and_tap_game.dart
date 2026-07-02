import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../../core/widgets/mascot.dart';
import '../../curriculum/domain/lesson.dart';
import '../../gamification/reward_engine.dart';

/// A pre-reader activity with one spoken instruction and large visual targets.
/// Sessions are intentionally five rounds for a 3–5 minute attention window.
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

  int _index = 0;
  int _correct = 0;
  int _firstTry = 0;
  int? _selected;
  bool _missed = false;
  bool _locked = false;

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
      if (!_missed) {
        _missed = true;
        _struggled.add(_question.id);
      }
      AudioService.instance.playSfx(Sfx.wrong);
      AudioService.instance.speak('Try another picture!');
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (mounted) setState(() => _selected = null);
      return;
    }

    _locked = true;
    _correct++;
    if (!_missed) _firstTry++;
    AudioService.instance.playSfx(Sfx.correct);
    AudioService.instance.successHaptic();
    AudioService.instance.speak(PraiseLines.nextSuccess());
    _celebration.celebrate(sound: false);
    await Future<void>.delayed(const Duration(milliseconds: 800));
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
                            style: Theme.of(context).textTheme.titleLarge,
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
              child: Icon(Icons.close_rounded),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _total; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      i < _index
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: i < _index ? AppColors.star : Colors.white,
                      size: 30,
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
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1,
      ),
      itemCount: _question.options.length,
      itemBuilder: (context, index) {
        final option = _question.options[index];
        final selected = _selected == index;
        final correct = index == _question.correctIndex;
        final color = !selected
            ? Colors.white
            : correct
                ? AppColors.success
                : AppColors.error;
        Widget card = BouncyButton(
          onTap: () => _choose(index),
          borderRadius: AppSpacing.cardRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppSpacing.cardRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 82,
                  width: 150,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      option.emoji ?? option.label,
                      style: TextStyle(
                        fontSize: option.emoji == null ? 64 : 70,
                        color: selected ? Colors.white : AppColors.lightText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (option.emoji != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 20,
                      color: selected ? Colors.white : AppColors.lightText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
        if (selected && !correct) {
          card = card.animate().shake(
                hz: 5,
                offset: const Offset(10, 0),
                rotation: 0,
              );
        }
        return card;
      },
    );
  }
}
