import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../../core/widgets/openmoji_view.dart';
import '../data/learning_world_item.dart';
import '../mini_games_controller.dart';
import '../widgets/game_tutorial.dart';
import '../widgets/mini_game_widgets.dart';

part 'learning_adventure_types.dart';
part 'learning_adventure_routes.dart';
part 'learning_adventure_audit.dart';
part 'learning_adventure_content.dart';

/// Shared no-fail engine for preschool and early-primary learning adventures.
class LearningAdventureGame extends ConsumerStatefulWidget {
  const LearningAdventureGame({required this.type, super.key});

  final LearningAdventureType type;

  @override
  ConsumerState<LearningAdventureGame> createState() =>
      _LearningAdventureGameState();
}

class _LearningAdventureGameState extends ConsumerState<LearningAdventureGame> {
  static const _roundsPerLevel = 5;
  final _celebration = CelebrationController();

  late int _level;
  int _round = 0;
  int _score = 0;
  int _mistakes = 0;
  int _reaction = 0;
  bool _locked = false;
  bool _complete = false;
  String _message = 'A new learning adventure is ready!';
  LearningWorldItem? _reward;

  _AdventureRound get _question =>
      _AdventureContent.question(widget.type, _level, _round);
  bool get _teachPip => _round == 2 || _round == 4;

  @override
  void initState() {
    super.initState();
    _level =
        ref.read(miniGamesControllerProvider).learningLevels[widget.type.id] ??
            1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showFirstPlayTutorial(
        context,
        ref,
        gameId: widget.type.id,
        instruction: widget.type.tutorial,
        emoji: widget.type.icon,
      );
      _speakPrompt();
    });
  }

  void _speakPrompt() {
    if (!mounted || _complete) return;
    final spoken = _teachPip
        ? 'Pip chose ${_question.wrongGuess}. Is Pip right? ${_question.spokenPrompt}'
        : _question.spokenPrompt;
    AudioService.instance.speak(spoken);
  }

  void _choose(int index) {
    if (_locked || _complete) return;
    if (index != _question.correctIndex) {
      setState(() {
        _mistakes++;
        _reaction++;
        _message = PraiseLines.nextRetry();
      });
      AudioService.instance.playSfx(Sfx.wrong);
      AudioService.instance.lightHaptic();
      AudioService.instance.speak(
        '$_message ${_question.hint}',
      );
      return;
    }

    _locked = true;
    setState(() {
      _score += _mistakes == 0 ? 10 : 7;
      _reaction++;
      _message = _teachPip
          ? 'You taught Pip! ${_question.explanation}'
          : '${PraiseLines.nextSuccess()} ${_question.explanation}';
    });
    _celebration.celebrate(sound: false);
    AudioService.instance.playSfx(Sfx.correct);
    AudioService.instance.successHaptic();
    AudioService.instance.speak(_message);

    Future<void>.delayed(const Duration(milliseconds: 780), () {
      if (!mounted) return;
      if (_round + 1 >= _roundsPerLevel) {
        _finishLevel();
      } else {
        setState(() {
          _round++;
          _mistakes = 0;
          _locked = false;
          _message = _teachPip
              ? 'Pip made a funny guess. Can you help?'
              : 'Here comes the next learning challenge!';
        });
        _speakPrompt();
      }
    });
  }

  Future<void> _finishLevel() async {
    final reward = LearningWorldCatalog.rewardFor(widget.type.id, _level);
    setState(() {
      _complete = true;
      _reward = reward;
      _message = 'Level complete! Your world has a new surprise!';
    });
    _celebration.fireworks();
    AudioService.instance.speak(
      'Wonderful learning! You earned a ${reward.name} for Kid World.',
    );
    showMiniGameReward(context, _score);
    await ref.read(miniGamesControllerProvider.notifier).recordResult(
      gameId: widget.type.id,
      score: _score + _level,
      dailyProgress: _roundsPerLevel,
      completedLearningLevel: _level,
      learningWorldItem: reward.id,
      achievements: [widget.type.achievementId],
    );
  }

  void _nextLevel() {
    setState(() {
      if (_level < 50) _level++;
      _round = 0;
      _score = 0;
      _mistakes = 0;
      _locked = false;
      _complete = false;
      _reward = null;
      _message = 'Level $_level is ready!';
    });
    _speakPrompt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CelebrationOverlay(
        controller: _celebration,
        child: AnimatedBackground(
          theme: widget.type.worldTheme,
          child: SafeArea(
            child: Column(
              children: [
                _topBar(),
                MascotMessage(
                  message: _message,
                  icon: widget.type.mascot,
                ),
                const SizedBox(height: 6),
                StoryGoalCard(
                  emoji: widget.type.icon,
                  goal: 'Level $_level/50 • ${_question.skill}',
                  progress: _complete ? 1 : _round / _roundsPerLevel,
                  progressColor: widget.type.accent,
                ),
                const SizedBox(height: 8),
                Expanded(child: _complete ? _completionCard() : _playArea()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          GameCircleButton(
            icon: Icons.close_rounded,
            tooltip: 'Close game',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${widget.type.icon} ${widget.type.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '⭐ $_score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          GameCircleButton(
            icon: Icons.volume_up_rounded,
            tooltip: 'Hear the question',
            onTap: _speakPrompt,
          ),
        ],
      ),
    );
  }

  Widget _playArea() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_teachPip) _pipGuess(),
              Text(
                _question.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Color(0x55000000), blurRadius: 4)],
                ),
              ),
              _sceneCard(),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _question.choices.length,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.9,
                ),
                itemCount: _question.choices.length,
                itemBuilder: (_, index) => _choiceCard(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pipGuess() {
    return Container(
      key: ValueKey('teach-pip-$_round'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '🐧 Pip chose "${_question.wrongGuess}". Teach Pip!',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF5D4037),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _sceneCard() {
    return Container(
      key: ValueKey('scene-${widget.type.id}-$_level-$_round-$_reaction'),
      constraints: const BoxConstraints(minHeight: 118),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: widget.type.accent, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 5,
            runSpacing: 2,
            children: [
              for (final emoji in _question.scene)
                Text(emoji, style: const TextStyle(fontSize: 38)),
            ],
          ),
          if (_question.sceneLabel.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              _question.sceneLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.lightText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).scale(
          begin: const Offset(0.94, 0.94),
          end: const Offset(1, 1),
        );
  }

  Widget _choiceCard(int index) {
    final choice = _question.choices[index];
    final selectedCorrect = _locked && index == _question.correctIndex;
    return Semantics(
      button: true,
      label: choice.label,
      child: InkWell(
        key: ValueKey('answer-${widget.type.id}-$index'),
        borderRadius: BorderRadius.circular(22),
        onTap: () => _choose(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: selectedCorrect ? AppColors.success : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selectedCorrect ? Colors.white : widget.type.accent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.type.accent.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (choice.emoji != null)
                OpenMojiView(
                  emoji: choice.emoji!,
                  size: 48,
                  fallback: Text(
                    choice.emoji!,
                    style: const TextStyle(fontSize: 42),
                  ),
                ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  choice.label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selectedCorrect ? Colors.white : AppColors.lightText,
                    fontSize: choice.emoji == null ? 29 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _completionCard() {
    final reward = _reward!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 48)),
              Text(
                '${widget.type.title} reward!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.lightText,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              OpenMojiView(
                emoji: reward.emoji,
                size: 82,
                fallback: Text(
                  reward.emoji,
                  style: const TextStyle(fontSize: 70),
                ),
              ),
              Text(
                '${reward.name} is now in Kid World!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.lightText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: ValueKey('${widget.type.id}-next-level'),
                onPressed: _nextLevel,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _level >= 50 ? 'Play again' : 'Level ${_level + 1}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
