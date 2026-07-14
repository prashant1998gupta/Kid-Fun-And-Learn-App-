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

/// A gentle, no-fail LEARNING mode. The child taps through big friendly cards —
/// a letter (A → Apple 🍎), a number (5 → five), or a times-table fact
/// (2 × 3 = 6) — hearing each one spoken. There are no wrong answers; finishing
/// the deck always earns full stars. Perfect for A–Z, 1–100 and tables.
class FlashcardGame extends StatefulWidget {
  const FlashcardGame({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  final Lesson lesson;
  final ValueChanged<LessonResult> onComplete;

  @override
  State<FlashcardGame> createState() => _FlashcardGameState();
}

class _FlashcardGameState extends State<FlashcardGame> {
  final _celebration = CelebrationController();
  int _index = 0;
  bool _finishing = false;
  final _stopwatch = Stopwatch()..start();

  Question get _card => widget.lesson.questions[_index];
  int get _total => widget.lesson.questions.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _say());
  }

  void _say() {
    AudioService.instance.speak(_card.speak ?? _card.prompt);
    AudioService.instance.playSfx(Sfx.pop);
  }

  Future<void> _next() async {
    if (_finishing) return;
    AudioService.instance.successHaptic();
    if (_index + 1 >= _total) {
      setState(() => _finishing = true);
      _stopwatch.stop();
      _celebration.fireworks();
      AudioService.instance.speak(PraiseLines.nextSuccess());
      await Future<void>.delayed(FeedbackTiming.successBeat);
      if (!mounted) return;
      // Learning is always a win — full marks for finishing the deck.
      widget.onComplete(
        LessonResult(
          lesson: widget.lesson,
          correct: _total,
          total: _total,
          firstTryCorrect: _total,
          durationSeconds: _stopwatch.elapsed.inSeconds,
        ),
      );
      return;
    }
    setState(() => _index++);
    _say();
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    return CelebrationOverlay(
      controller: _celebration,
      child: Scaffold(
        body: AnimatedBackground(
          theme: WorldTheme.candy,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final compact = constraints.maxWidth < 360 ||
                    constraints.maxHeight < 620 ||
                    textScale > 1.2;
                final cardWidth = (constraints.maxWidth - AppSpacing.lg * 2)
                    .clamp(220.0, 300.0)
                    .toDouble();
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      children: [
                        _header(context),
                        SizedBox(height: compact ? 12 : 36),
                        // The big tappable learning card.
                        BouncyButton(
                          onTap: _say,
                          borderRadius: AppSpacing.cardRadius,
                          child: Container(
                            key: ValueKey(_index),
                            width: cardWidth,
                            padding: EdgeInsets.symmetric(
                              vertical: compact ? AppSpacing.lg : AppSpacing.xl,
                              horizontal:
                                  compact ? AppSpacing.md : AppSpacing.lg,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppSpacing.cardRadius,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    card.prompt,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: compact ? 54 : 72,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      compact ? AppSpacing.sm : AppSpacing.md,
                                ),
                                if (card.promptEmoji != null)
                                  IllustratedObjectView(
                                    label: card.answer ?? '',
                                    emoji: card.promptEmoji,
                                    size: compact ? 76 : 96,
                                  ),
                                if (card.answer != null) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      card.answer!,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: compact ? 24 : 30,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.lightText,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.sm),
                                Icon(
                                  Icons.volume_up_rounded,
                                  color: AppColors.primary,
                                  size: compact ? 26 : 30,
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate(key: ValueKey('card$_index'))
                            .fadeIn(duration: 250.ms)
                            .scale(
                              begin: const Offset(0.85, 0.85),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutBack,
                            ),
                        SizedBox(height: compact ? 16 : 36),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: BouncyButton(
                            onTap: _next,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                vertical: compact ? 15 : 18,
                              ),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  AppColors.success,
                                  AppColors.mint
                                ]),
                                borderRadius:
                                    BorderRadius.all(AppSpacing.radiusPill),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _index + 1 >= _total
                                      ? 'Finish! 🎉'
                                      : 'Next ➜',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 19 : 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
                  color: Colors.white, shape: BoxShape.circle),
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
              color: AppColors.bubblegum,
            ),
          ),
          const SizedBox(width: 12),
          const MascotView(mascot: Mascot.owl, size: 52),
        ],
      ),
    );
  }
}
