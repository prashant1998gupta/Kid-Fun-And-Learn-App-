import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

/// "Pick the right answer" — the workhorse engine used by tapChoice, bubblePop,
/// count-catch, and spot-match lessons.
///
/// UX rules that make it feel great for a child:
/// - The prompt is spoken aloud automatically (minimal reading).
/// - Wrong taps wiggle red and let the child try again (no dead-ends, no score
///   punishment beyond losing the first-try star).
/// - Right taps turn green, celebrate, and auto-advance.
class TapChoiceGame extends StatefulWidget {
  const TapChoiceGame({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  final Lesson lesson;
  final ValueChanged<LessonResult> onComplete;

  @override
  State<TapChoiceGame> createState() => _TapChoiceGameState();
}

class _TapChoiceGameState extends State<TapChoiceGame> {
  final _celebration = CelebrationController();
  int _index = 0;
  int _correct = 0;
  int _firstTryCorrect = 0;
  bool _erredThisQuestion = false;
  int? _selected;
  bool _locked = false;
  final List<String> _struggled = [];
  final _stopwatch = Stopwatch()..start();

  Question get _q => widget.lesson.questions[_index];
  int get _total => widget.lesson.questions.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakPrompt());
  }

  void _speakPrompt() {
    final line = _q.speak ?? _q.prompt;
    AudioService.instance.speak(line);
  }

  Future<void> _choose(int i) async {
    if (_locked) return;
    final isCorrect = i == _q.correctIndex;
    setState(() => _selected = i);

    if (isCorrect) {
      _locked = true;
      AudioService.instance.playSfx(Sfx.correct);
      AudioService.instance.successHaptic();
      _correct++;
      if (!_erredThisQuestion) _firstTryCorrect++;
      _celebration.celebrate(sound: false);
      AudioService.instance.speak(PraiseLines.nextSuccess());
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      _advance();
    } else {
      AudioService.instance.playSfx(Sfx.wrong);
      if (!_erredThisQuestion) {
        _erredThisQuestion = true;
        _struggled.add(_q.id);
      }
      AudioService.instance.speak('Try again!');
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _selected = null);
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
      _selected = null;
      _locked = false;
      _erredThisQuestion = false;
    });
    _speakPrompt();
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
                const SizedBox(height: 12),
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
              color: AppColors.mint,
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
      child: Row(
        children: [
          const MascotView(mascot: Mascot.owl, size: 72),
          const SizedBox(width: 12),
          Expanded(
            child: BouncyButton(
              onTap: _speakPrompt,
              borderRadius: AppSpacing.cardRadius,
              child: Container(
                padding: AppSpacing.cardPadding,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.cardRadius,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _q.prompt,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Icon(
                      Icons.volume_up_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey(_index)).fadeIn().slideX(begin: 0.15, end: 0);
  }

  Widget _options(BuildContext context) {
    final options = _q.options;
    final wide = MediaQuery.of(context).size.width > 600;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GridView.count(
        crossAxisCount: wide ? options.length.clamp(1, 4) : 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.1,
        children: [
          for (int i = 0; i < options.length; i++)
            _OptionCard(
              key: ValueKey('$_index-$i'),
              option: options[i],
              state: _stateFor(i),
              onTap: () => _choose(i),
            ),
        ],
      ),
    );
  }

  _OptionState _stateFor(int i) {
    if (_selected == null) return _OptionState.idle;
    if (i == _selected && i == _q.correctIndex) return _OptionState.correct;
    if (i == _selected) return _OptionState.wrong;
    return _OptionState.idle;
  }
}

enum _OptionState { idle, correct, wrong }

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    super.key,
    required this.option,
    required this.state,
    required this.onTap,
  });

  final AnswerOption option;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _OptionState.correct => AppColors.success,
      _OptionState.wrong => AppColors.error,
      _OptionState.idle => Theme.of(context).colorScheme.surface,
    };
    final fg = state == _OptionState.idle
        ? Theme.of(context).colorScheme.onSurface
        : Colors.white;

    Widget card = BouncyButton(
      borderRadius: AppSpacing.cardRadius,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppSpacing.cardRadius,
          boxShadow: [
            BoxShadow(
              color: color == Theme.of(context).colorScheme.surface
                  ? Colors.black.withValues(alpha: 0.08)
                  : color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.emoji != null)
                Text(option.emoji!, style: const TextStyle(fontSize: 64)),
              if (option.emoji != null) const SizedBox(height: 8),
              Text(
                option.label,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );

    if (state == _OptionState.wrong) {
      card = card.animate().shake(
            hz: 6,
            rotation: 0,
            offset: const Offset(10, 0),
            duration: 400.ms,
          );
    } else if (state == _OptionState.correct) {
      card = card
          .animate()
          .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08))
          .then()
          .scale(begin: const Offset(1.08, 1.08), end: const Offset(1, 1));
    }
    return card;
  }
}
