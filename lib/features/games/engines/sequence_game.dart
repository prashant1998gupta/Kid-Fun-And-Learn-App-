import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

/// Put-it-in-order. [Question.options] are authored in the correct sequence and
/// shown scrambled; the child taps them in order (1 → 2 → 3…). Great for
/// counting order, story sequence, life cycles, and pattern completion.
class SequenceGame extends StatefulWidget {
  const SequenceGame({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  final Lesson lesson;
  final ValueChanged<LessonResult> onComplete;

  @override
  State<SequenceGame> createState() => _SequenceGameState();
}

class _SequenceGameState extends State<SequenceGame> {
  final _celebration = CelebrationController();
  int _index = 0;
  int _correct = 0;
  int _firstTry = 0;
  bool _erred = false;
  int _nextExpected = 0; // original index we expect next
  int? _wrongTile;
  late List<int> _order; // scrambled display order (original indices)
  final List<String> _struggled = [];
  final _stopwatch = Stopwatch()..start();

  Question get _q => widget.lesson.questions[_index];
  int get _total => widget.lesson.questions.length;

  @override
  void initState() {
    super.initState();
    _order = _scramble(_q.options.length);
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  void _speak() => AudioService.instance.speak(_q.speak ?? _q.prompt);

  /// Deterministic scramble (stable, no RNG). Reverses then rotates.
  List<int> _scramble(int n) {
    final base = List.generate(n, (i) => i);
    final rotated = [...base.reversed];
    final k = n > 2 ? 1 : 0;
    return [...rotated.sublist(k), ...rotated.sublist(0, k)];
  }

  Future<void> _tap(int originalIndex) async {
    if (originalIndex < _nextExpected) return; // already placed
    if (originalIndex == _nextExpected) {
      AudioService.instance.playSfx(Sfx.correct);
      AudioService.instance.lightHaptic();
      setState(() => _nextExpected++);
      if (_nextExpected >= _q.options.length) {
        AudioService.instance.successHaptic();
        _celebration.celebrate(sound: false);
        AudioService.instance.speak(PraiseLines.nextSuccess());
        _correct++;
        if (!_erred) _firstTry++;
        await Future<void>.delayed(const Duration(milliseconds: 900));
        _advance();
      }
    } else {
      AudioService.instance.playSfx(Sfx.wrong);
      if (!_erred) {
        _erred = true;
        _struggled.add(_q.id);
      }
      AudioService.instance.speak('Which one comes next?');
      setState(() => _wrongTile = originalIndex);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) setState(() => _wrongTile = null);
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
          durationSeconds: _stopwatch.elapsed.inSeconds,
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _nextExpected = 0;
      _erred = false;
      _wrongTile = null;
      _order = _scramble(_q.options.length);
    });
    _speak();
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
                _prompt(context),
                const SizedBox(height: 8),
                _slots(context),
                const Spacer(),
                _tiles(context),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The ordered "answer" row that fills in as the child taps correctly.
  Widget _slots(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        for (int pos = 0; pos < _q.options.length; pos++)
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pos < _nextExpected
                  ? AppColors.success
                  : Colors.white.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.all(AppSpacing.radiusMd),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: pos < _nextExpected
                ? Text(_optionShort(_q.options[pos]),
                    style: const TextStyle(fontSize: 24))
                : Text('${pos + 1}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 20)),
          ),
      ],
    );
  }

  String _optionShort(AnswerOption o) => o.emoji ?? o.label;

  Widget _tiles(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final original in _order)
          _Tile(
            option: _q.options[original],
            placed: original < _nextExpected,
            wrong: original == _wrongTile,
            onTap: () => _tap(original),
          ),
      ],
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
              color: AppColors.primary,
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
              const MascotView(mascot: Mascot.robot, size: 56),
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.option,
    required this.placed,
    required this.wrong,
    required this.onTap,
  });

  final AnswerOption option;
  final bool placed;
  final bool wrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget tile = BouncyButton(
      onTap: placed ? null : onTap,
      borderRadius: AppSpacing.cardRadius,
      child: AnimatedOpacity(
        opacity: placed ? 0.35 : 1,
        duration: const Duration(milliseconds: 250),
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: wrong ? AppColors.error : Colors.white,
            borderRadius: AppSpacing.cardRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (option.emoji != null)
                  IllustratedObjectView(
                    label: option.label,
                    emoji: option.emoji,
                    size: 42,
                    selected: wrong,
                  ),
                Text(
                  option.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: wrong ? Colors.white : AppColors.lightText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (wrong) tile = tile.animate().shake(hz: 6, duration: 400.ms);
    return tile;
  }
}
