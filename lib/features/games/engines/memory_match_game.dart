import 'package:flutter/material.dart';

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

/// Flip-and-match memory game. The board is built from the first question's
/// [AnswerOption]s: each option becomes a matching pair of cards. Mastery
/// reflects efficiency — fewer mismatches → more first-try pairs → more stars.
class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  final Lesson lesson;
  final ValueChanged<LessonResult> onComplete;

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _Card {
  _Card(this.pairId, this.label, this.emoji);
  final int pairId;
  final String label;
  final String? emoji;
  bool matched = false;
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  final _celebration = CelebrationController();
  late final List<_Card> _cards = _buildBoard();

  int? _firstIndex; // first card flipped this turn
  int? _secondIndex; // second card flipped this turn (during evaluation)
  bool _locked = false;
  int _matchedPairs = 0;
  int _mismatches = 0;
  int _pairs = 0;
  final _stopwatch = Stopwatch()..start();

  List<_Card> _buildBoard() {
    final q = widget.lesson.questions.isNotEmpty
        ? widget.lesson.questions.first
        : null;
    final faces = <AnswerOption>[];
    if (q != null) {
      for (final o in q.options) {
        faces.add(o);
      }
    }
    if (faces.isEmpty) {
      faces.addAll(const [
        AnswerOption(label: 'Apple'),
        AnswerOption(label: 'Star'),
        AnswerOption(label: 'Panda'),
        AnswerOption(label: 'Ball'),
      ]);
    }
    final chosen = faces.take(6).toList();
    _pairs = chosen.length;

    final cards = <_Card>[];
    for (var i = 0; i < chosen.length; i++) {
      cards
        ..add(_Card(i, chosen[i].label, chosen[i].emoji))
        ..add(_Card(i, chosen[i].label, chosen[i].emoji));
    }
    // Deterministic scramble (avoids Math.random, stable across rebuilds).
    for (var i = 0; i < cards.length; i++) {
      final j = (i * 7 + 3) % cards.length;
      final tmp = cards[i];
      cards[i] = cards[j];
      cards[j] = tmp;
    }
    return cards;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => AudioService.instance.speak(
        widget.lesson.instruction.isNotEmpty
            ? widget.lesson.instruction
            : 'Find the matching pairs!',
      ),
    );
  }

  bool _faceUp(int index) {
    final c = _cards[index];
    return c.matched || index == _firstIndex || index == _secondIndex;
  }

  Future<void> _onTap(int index) async {
    if (_locked) return;
    final card = _cards[index];
    if (card.matched || index == _firstIndex) return;

    AudioService.instance.playSfx(Sfx.tap);

    if (_firstIndex == null) {
      setState(() => _firstIndex = index);
      return;
    }

    // Second flip → lock and evaluate.
    setState(() {
      _secondIndex = index;
      _locked = true;
    });

    final match = _cards[_firstIndex!].pairId == card.pairId;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    if (match) {
      AudioService.instance.playSfx(Sfx.correct);
      AudioService.instance.successHaptic();
      _celebration.celebrate(sound: false);
      setState(() {
        _cards[_firstIndex!].matched = true;
        _cards[_secondIndex!].matched = true;
        _matchedPairs++;
        _firstIndex = null;
        _secondIndex = null;
        _locked = false;
      });
      if (_matchedPairs >= _pairs) _finish();
    } else {
      AudioService.instance.playSfx(Sfx.wrong);
      _mismatches++;
      setState(() {
        _firstIndex = null;
        _secondIndex = null;
        _locked = false;
      });
    }
  }

  void _finish() {
    _stopwatch.stop();
    final firstTry = (_pairs - _mismatches).clamp(0, _pairs);
    widget.onComplete(
      LessonResult(
        lesson: widget.lesson,
        correct: _pairs,
        total: _pairs,
        firstTryCorrect: firstTry,
        durationSeconds: _stopwatch.elapsed.inSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 600;
    return CelebrationOverlay(
      controller: _celebration,
      child: Scaffold(
        body: AnimatedBackground(
          theme: WorldTheme.ocean,
          child: SafeArea(
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: wide ? 6 : 4,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                      ),
                      itemCount: _cards.length,
                      itemBuilder: (context, i) => _CardTile(
                        label: _cards[i].label,
                        emoji: _cards[i].emoji,
                        faceUp: _faceUp(i),
                        matched: _cards[i].matched,
                        onTap: () => _onTap(i),
                      ),
                    ),
                  ),
                ),
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
              progress: _pairs == 0 ? 0 : _matchedPairs / _pairs,
              color: AppColors.mint,
            ),
          ),
          const SizedBox(width: 12),
          const MascotView(mascot: Mascot.penguin, size: 56),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.label,
    required this.emoji,
    required this.faceUp,
    required this.matched,
    required this.onTap,
  });

  final String label;
  final String? emoji;
  final bool faceUp;
  final bool matched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      borderRadius: AppSpacing.cardRadius,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: faceUp
                ? [Colors.white, const Color(0xFFF0F4FF)]
                : [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: AppSpacing.cardRadius,
          border:
              matched ? Border.all(color: AppColors.success, width: 4) : null,
        ),
        child: Center(
          child: faceUp
              ? IllustratedObjectView(label: label, emoji: emoji, size: 58)
              : const Icon(
                  Icons.question_mark_rounded,
                  color: Colors.white,
                  size: 34,
                ),
        ),
      ),
    );
  }
}
