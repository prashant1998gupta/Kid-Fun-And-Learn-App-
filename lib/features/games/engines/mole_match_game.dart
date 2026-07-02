import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../curriculum/domain/lesson.dart';
import '../../gamification/reward_engine.dart';

/// Friendly whack-a-mole-style learning: characters pop from different holes
/// holding answer cards. There is no countdown or fail state.
class MoleMatchGame extends StatefulWidget {
  const MoleMatchGame({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  final Lesson lesson;
  final ValueChanged<LessonResult> onComplete;

  @override
  State<MoleMatchGame> createState() => _MoleMatchGameState();
}

class _MoleMatchGameState extends State<MoleMatchGame> {
  final _celebration = CelebrationController();
  final _stopwatch = Stopwatch()..start();
  final List<String> _struggled = [];
  Timer? _shuffleTimer;

  int _index = 0;
  int _tick = 0;
  int _correct = 0;
  int _firstTry = 0;
  int _combo = 0;
  int? _selected;
  bool _missed = false;
  bool _locked = false;

  Question get _question => widget.lesson.questions[_index];
  int get _total => widget.lesson.questions.length;

  @override
  void initState() {
    super.initState();
    _shuffleTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (mounted && !_locked) setState(() => _tick++);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    super.dispose();
  }

  void _speak() {
    AudioService.instance.speak(_question.speak ?? _question.prompt);
  }

  int? _optionAtHole(int hole) {
    for (var option = 0; option < _question.options.length; option++) {
      if ((option * 2 + _tick) % 6 == hole) return option;
    }
    return null;
  }

  Future<void> _choose(int option) async {
    if (_locked) return;
    final isCorrect = option == _question.correctIndex;
    setState(() => _selected = option);
    if (!isCorrect) {
      _combo = 0;
      if (!_missed) {
        _missed = true;
        _struggled.add(_question.id);
      }
      AudioService.instance.playSfx(Sfx.wrong);
      AudioService.instance.speak('Oops, find the right one!');
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) setState(() => _selected = null);
      return;
    }

    _locked = true;
    _correct++;
    _combo++;
    if (!_missed) _firstTry++;
    AudioService.instance.playSfx(Sfx.pop);
    AudioService.instance.successHaptic();
    AudioService.instance.speak(PraiseLines.nextSuccess());
    _celebration.celebrate(sound: false);
    await Future<void>.delayed(const Duration(milliseconds: 700));
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
      _tick++;
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
          theme: WorldTheme.jungle,
          particleCount: 10,
          child: SafeArea(
            child: Column(
              children: [
                _header(context),
                BouncyButton(
                  onTap: _speak,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_combo >= 2)
                  Text(
                    '🔥 $_combo combo!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate(key: ValueKey(_combo)).scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1, 1),
                      ),
                Expanded(child: _moleGrid(context)),
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
          const SizedBox(width: 14),
          Expanded(
            child: LinearProgressIndicator(
              value: (_index + 1) / _total,
              minHeight: 14,
              borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
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

  Widget _moleGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - 56) / 3;
        final cellHeight = (constraints.maxHeight - 44) / 2;
        final ratio = (cellWidth / cellHeight).clamp(0.65, 2.0).toDouble();
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: ratio,
          ),
          itemCount: 6,
          itemBuilder: (context, hole) {
            final option = _optionAtHole(hole);
            return _MoleHole(
              key: ValueKey('$_index-$_tick-$hole-$option'),
              option: option == null ? null : _question.options[option],
              selected: option != null && _selected == option,
              correct: option != null && option == _question.correctIndex,
              onTap: option == null ? null : () => _choose(option),
            );
          },
        );
      },
    );
  }
}

class _MoleHole extends StatelessWidget {
  const _MoleHole({
    super.key,
    required this.option,
    required this.selected,
    required this.correct,
    required this.onTap,
  });

  final AnswerOption? option;
  final bool selected;
  final bool correct;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: option != null,
      enabled: option != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 8,
              left: 4,
              right: 4,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF6D4C41),
                  borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            if (option != null)
              Positioned.fill(
                bottom: 18,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.65, end: 0),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  builder: (context, offset, child) => FractionalTranslation(
                    translation: Offset(0, offset),
                    child: child,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: selected
                          ? (correct ? AppColors.success : AppColors.error)
                          : const Color(0xFFFFD8A8),
                      borderRadius: AppSpacing.cardRadius,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🐹', style: TextStyle(fontSize: 38)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            option!.emoji ?? option!.label,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (option!.emoji != null)
                          Text(
                            option!.label,
                            maxLines: 1,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
