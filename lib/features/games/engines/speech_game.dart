import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/speech_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../../core/widgets/currency_hud.dart';
import '../../../core/widgets/mascot.dart';
import '../../curriculum/domain/lesson.dart';
import '../../gamification/reward_engine.dart';
import '../../speech/domain/pronunciation_scorer.dart';

/// "Say it!" — the child reads a word aloud and speech recognition checks it.
/// Uses [SpeechService]; when the mic isn't available (permission denied,
/// desktop/web, unsupported device) it falls back to a tap-to-continue button
/// so the lesson is always completable. Scoring is intentionally lenient
/// ([PronunciationScorer]) — this is confidence-building, not assessment.
class SpeechGame extends StatefulWidget {
  const SpeechGame({super.key, required this.lesson, required this.onComplete});

  final Lesson lesson;
  final ValueChanged<LessonResult> onComplete;

  @override
  State<SpeechGame> createState() => _SpeechGameState();
}

class _SpeechGameState extends State<SpeechGame> {
  final _celebration = CelebrationController();
  final _scorer = const PronunciationScorer();
  final _stopwatch = Stopwatch()..start();

  int _index = 0;
  int _correct = 0;
  int _firstTryCorrect = 0;
  int _attempts = 0; // attempts on the current word
  bool _listening = false;
  bool _resolved = false; // current word passed → showing celebration
  String _heard = '';
  bool _speechReady = false;

  Question get _q => widget.lesson.questions[_index];
  int get _total => widget.lesson.questions.length;
  String get _target => _q.answer ?? _q.prompt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ready = await SpeechService.instance.ensureReady();
      if (mounted) setState(() => _speechReady = ready);
      _sayPrompt();
    });
  }

  @override
  void dispose() {
    SpeechService.instance.stop();
    super.dispose();
  }

  void _sayPrompt() =>
      AudioService.instance.speak(_q.speak ?? 'Say the word: $_target');

  Future<void> _toggleListen() async {
    if (_resolved) return;
    if (_listening) {
      await SpeechService.instance.stop();
      return;
    }
    setState(() {
      _listening = true;
      _heard = '';
    });
    AudioService.instance.playSfx(Sfx.tap);
    await SpeechService.instance.listen(
      onResult: (words, isFinal) {
        if (mounted) setState(() => _heard = words);
      },
      onDone: () {
        if (mounted) _evaluate();
      },
    );
  }

  void _evaluate() {
    if (_resolved) return;
    setState(() => _listening = false);
    _attempts++;
    if (_scorer.passes(_target, _heard)) {
      _pass(firstTry: _attempts == 1);
    } else {
      AudioService.instance.playSfx(Sfx.wrong);
      AudioService.instance.speak('Almost! Try again.');
    }
  }

  /// Fallback path when speech isn't available: accept the attempt.
  void _tapPass() => _pass(firstTry: true);

  Future<void> _pass({required bool firstTry}) async {
    if (_resolved) return;
    setState(() => _resolved = true);
    _correct++;
    if (firstTry) _firstTryCorrect++;
    AudioService.instance.playSfx(Sfx.correct);
    AudioService.instance.successHaptic();
    _celebration.celebrate(sound: false);
    AudioService.instance.speak(PraiseLines.nextSuccess());
    await Future<void>.delayed(const Duration(milliseconds: 1100));
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
          firstTryCorrect: _firstTryCorrect,
          durationSeconds: _stopwatch.elapsed.inSeconds,
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _attempts = 0;
      _heard = '';
      _resolved = false;
      _listening = false;
    });
    _sayPrompt();
  }

  @override
  Widget build(BuildContext context) {
    return CelebrationOverlay(
      controller: _celebration,
      child: Scaffold(
        body: AnimatedBackground(
          theme: WorldTheme.ocean,
          child: SafeArea(
            child: Column(
              children: [
                _header(context),
                const Spacer(),
                Text(
                  'Say this word!',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                // Tap the word to hear it.
                BouncyButton(
                  onTap: () => AudioService.instance.speak(_target),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppSpacing.cardRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _target,
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.volume_up_rounded,
                            color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_heard.isNotEmpty)
                  Text(
                    '“$_heard”',
                    style: const TextStyle(color: Colors.white70, fontSize: 20),
                  ),
                const Spacer(),
                _controls(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    if (!_speechReady) {
      // No mic → tap-to-continue fallback keeps the lesson completable.
      return Column(
        children: [
          const Text('🎤 Mic not available',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          BouncyButton(
            onTap: _resolved ? null : _tapPass,
            child: _pill('I said it! ✅', AppColors.success),
          ),
        ],
      );
    }
    final mic = GestureDetector(
      onTap: _toggleListen,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _listening ? AppColors.error : AppColors.secondary,
          boxShadow: [
            BoxShadow(
              color: (_listening ? AppColors.error : AppColors.secondary)
                  .withValues(alpha: 0.5),
              blurRadius: 24,
              spreadRadius: _listening ? 6 : 2,
            ),
          ],
        ),
        child: Icon(
          _listening ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
    return Column(
      children: [
        Text(
          _listening ? 'Listening… tap to stop' : 'Tap the mic and say it!',
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 12),
        _listening
            ? mic.animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
                  begin: 1,
                  end: 1.12,
                  duration: 600.ms,
                  curve: Curves.easeInOut,
                )
            : mic,
      ],
    );
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

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
              color: AppColors.sky,
            ),
          ),
          const SizedBox(width: 12),
          const MascotView(mascot: Mascot.owl, size: 56),
        ],
      ),
    );
  }
}
