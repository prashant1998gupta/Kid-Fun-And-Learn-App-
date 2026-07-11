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

enum LearningAdventureType {
  soundSafari,
  numberGarden,
  storyTrain,
  letterBakery,
  cleanRoom,
  mathMarket,
  wordWizard,
  sentenceTrain,
  clockAdventure,
  natureDetective,
  shapeBuilder,
  fractionCafe,
  multiplicationKingdom,
  grammarDetective,
  codeRobot,
  scienceLab,
  mapQuest,
}

extension LearningAdventureTypeData on LearningAdventureType {
  String get id => switch (this) {
        LearningAdventureType.soundSafari => 'sound-safari',
        LearningAdventureType.numberGarden => 'number-garden',
        LearningAdventureType.storyTrain => 'story-train',
        LearningAdventureType.letterBakery => 'letter-bakery',
        LearningAdventureType.cleanRoom => 'clean-room-helper',
        LearningAdventureType.mathMarket => 'math-market',
        LearningAdventureType.wordWizard => 'word-wizard-workshop',
        LearningAdventureType.sentenceTrain => 'sentence-train',
        LearningAdventureType.clockAdventure => 'clock-adventure',
        LearningAdventureType.natureDetective => 'nature-detective',
        LearningAdventureType.shapeBuilder => 'shape-builder',
        LearningAdventureType.fractionCafe => 'fraction-cafe',
        LearningAdventureType.multiplicationKingdom => 'multiplication-kingdom',
        LearningAdventureType.grammarDetective => 'grammar-detective',
        LearningAdventureType.codeRobot => 'code-the-robot',
        LearningAdventureType.scienceLab => 'science-machine-lab',
        LearningAdventureType.mapQuest => 'map-quest',
      };

  String get title => switch (this) {
        LearningAdventureType.soundSafari => 'Sound Safari',
        LearningAdventureType.numberGarden => 'Number Garden',
        LearningAdventureType.storyTrain => 'Story Train',
        LearningAdventureType.letterBakery => 'Letter Bakery',
        LearningAdventureType.cleanRoom => 'Clean Room Helper',
        LearningAdventureType.mathMarket => 'Math Market',
        LearningAdventureType.wordWizard => 'Word Wizard Workshop',
        LearningAdventureType.sentenceTrain => 'Sentence Train',
        LearningAdventureType.clockAdventure => 'Clock Adventure',
        LearningAdventureType.natureDetective => 'Nature Detective',
        LearningAdventureType.shapeBuilder => 'Shape Builder',
        LearningAdventureType.fractionCafe => 'Pizza Fraction Café',
        LearningAdventureType.multiplicationKingdom => 'Multiplication Kingdom',
        LearningAdventureType.grammarDetective => 'Grammar Detective',
        LearningAdventureType.codeRobot => 'Code the Robot',
        LearningAdventureType.scienceLab => 'Science Machine Lab',
        LearningAdventureType.mapQuest => 'Map Quest',
      };

  String get icon => switch (this) {
        LearningAdventureType.soundSafari => '🦁',
        LearningAdventureType.numberGarden => '🌻',
        LearningAdventureType.storyTrain => '🚂',
        LearningAdventureType.letterBakery => '🥐',
        LearningAdventureType.cleanRoom => '🧹',
        LearningAdventureType.mathMarket => '🛒',
        LearningAdventureType.wordWizard => '🧙',
        LearningAdventureType.sentenceTrain => '🚂',
        LearningAdventureType.clockAdventure => '⏰',
        LearningAdventureType.natureDetective => '🔎',
        LearningAdventureType.shapeBuilder => '🏗️',
        LearningAdventureType.fractionCafe => '🍕',
        LearningAdventureType.multiplicationKingdom => '🏰',
        LearningAdventureType.grammarDetective => '🕵️',
        LearningAdventureType.codeRobot => '🤖',
        LearningAdventureType.scienceLab => '🧪',
        LearningAdventureType.mapQuest => '🗺️',
      };

  String get mascot => switch (this) {
        LearningAdventureType.soundSafari => '🦉',
        LearningAdventureType.numberGarden => '🐝',
        LearningAdventureType.storyTrain => '🐼',
        LearningAdventureType.letterBakery => '🧑‍🍳',
        LearningAdventureType.cleanRoom => '🐧',
        LearningAdventureType.mathMarket => '🦊',
        LearningAdventureType.wordWizard => '🦉',
        LearningAdventureType.sentenceTrain => '🐼',
        LearningAdventureType.clockAdventure => '🐰',
        LearningAdventureType.natureDetective => '🐻',
        LearningAdventureType.shapeBuilder => '🦖',
        LearningAdventureType.fractionCafe => '🧑‍🍳',
        LearningAdventureType.multiplicationKingdom => '🐉',
        LearningAdventureType.grammarDetective => '🦉',
        LearningAdventureType.codeRobot => '🤖',
        LearningAdventureType.scienceLab => '🧑‍🔬',
        LearningAdventureType.mapQuest => '🦜',
      };

  String get achievementId => switch (this) {
        LearningAdventureType.soundSafari => 'sound_scout',
        LearningAdventureType.numberGarden => 'number_gardener',
        LearningAdventureType.storyTrain => 'story_conductor',
        LearningAdventureType.letterBakery => 'letter_baker',
        LearningAdventureType.cleanRoom => 'tidy_helper',
        LearningAdventureType.mathMarket => 'market_master',
        LearningAdventureType.wordWizard => 'word_wizard',
        LearningAdventureType.sentenceTrain => 'sentence_conductor',
        LearningAdventureType.clockAdventure => 'time_keeper',
        LearningAdventureType.natureDetective => 'nature_detective',
        LearningAdventureType.shapeBuilder => 'shape_architect',
        LearningAdventureType.fractionCafe => 'fraction_chef',
        LearningAdventureType.multiplicationKingdom => 'times_table_knight',
        LearningAdventureType.grammarDetective => 'grammar_sleuth',
        LearningAdventureType.codeRobot => 'robot_coder',
        LearningAdventureType.scienceLab => 'junior_scientist',
        LearningAdventureType.mapQuest => 'map_explorer',
      };

  WorldTheme get worldTheme => switch (this) {
        LearningAdventureType.soundSafari => WorldTheme.jungle,
        LearningAdventureType.numberGarden => WorldTheme.sunrise,
        LearningAdventureType.storyTrain => WorldTheme.ocean,
        LearningAdventureType.letterBakery => WorldTheme.candy,
        LearningAdventureType.cleanRoom => WorldTheme.aurora,
        LearningAdventureType.mathMarket => WorldTheme.sunrise,
        LearningAdventureType.wordWizard => WorldTheme.aurora,
        LearningAdventureType.sentenceTrain => WorldTheme.ocean,
        LearningAdventureType.clockAdventure => WorldTheme.candy,
        LearningAdventureType.natureDetective => WorldTheme.jungle,
        LearningAdventureType.shapeBuilder => WorldTheme.space,
        LearningAdventureType.fractionCafe => WorldTheme.candy,
        LearningAdventureType.multiplicationKingdom => WorldTheme.aurora,
        LearningAdventureType.grammarDetective => WorldTheme.night,
        LearningAdventureType.codeRobot => WorldTheme.space,
        LearningAdventureType.scienceLab => WorldTheme.ocean,
        LearningAdventureType.mapQuest => WorldTheme.jungle,
      };

  Color get accent => switch (this) {
        LearningAdventureType.soundSafari => const Color(0xFF00A878),
        LearningAdventureType.numberGarden => const Color(0xFFFFB000),
        LearningAdventureType.storyTrain => const Color(0xFF3D7EFF),
        LearningAdventureType.letterBakery => const Color(0xFFE84393),
        LearningAdventureType.cleanRoom => const Color(0xFF7C5CE7),
        LearningAdventureType.mathMarket => const Color(0xFFFF8F00),
        LearningAdventureType.wordWizard => const Color(0xFF6C5CE7),
        LearningAdventureType.sentenceTrain => const Color(0xFF1976D2),
        LearningAdventureType.clockAdventure => const Color(0xFFE91E63),
        LearningAdventureType.natureDetective => const Color(0xFF00897B),
        LearningAdventureType.shapeBuilder => const Color(0xFF5E35B1),
        LearningAdventureType.fractionCafe => const Color(0xFFFF7043),
        LearningAdventureType.multiplicationKingdom => const Color(0xFF7B1FA2),
        LearningAdventureType.grammarDetective => const Color(0xFF455A64),
        LearningAdventureType.codeRobot => const Color(0xFF1565C0),
        LearningAdventureType.scienceLab => const Color(0xFF00838F),
        LearningAdventureType.mapQuest => const Color(0xFF2E7D32),
      };

  String get tutorial => switch (this) {
        LearningAdventureType.soundSafari =>
          'Listen to the sound clue, then tap the matching picture.',
        LearningAdventureType.numberGarden =>
          'Count the garden objects, then tap the right number.',
        LearningAdventureType.storyTrain =>
          'Look at the story carriages, then choose what happens next.',
        LearningAdventureType.letterBakery =>
          'Look at the picture, then tap the letter its word starts with.',
        LearningAdventureType.cleanRoom =>
          'Look at the object, then tap the place where it belongs.',
        LearningAdventureType.mathMarket =>
          'Count the coins and prices, then tap the correct answer.',
        LearningAdventureType.wordWizard =>
          'Look at the picture and use the right letter or word.',
        LearningAdventureType.sentenceTrain =>
          'Read the sentence carriages and choose the word that completes them.',
        LearningAdventureType.clockAdventure =>
          'Look at the clock and choose the matching time or daily activity.',
        LearningAdventureType.natureDetective =>
          'Read or listen to the nature clue and choose the best answer.',
        LearningAdventureType.shapeBuilder =>
          'Study the shapes, sides, and patterns, then choose the right piece.',
        LearningAdventureType.fractionCafe =>
          'Look at the pizza parts, then choose the matching fraction.',
        LearningAdventureType.multiplicationKingdom =>
          'Count equal groups and solve the multiplication or division mission.',
        LearningAdventureType.grammarDetective =>
          'Inspect the sentence clue and choose the correct grammar evidence.',
        LearningAdventureType.codeRobot =>
          'Read the robot commands, predict the result, and fix silly bugs.',
        LearningAdventureType.scienceLab =>
          'Study the experiment clue and choose the scientific explanation.',
        LearningAdventureType.mapQuest =>
          'Use directions, coordinates, distance, and map symbols to find the answer.',
      };
}

class SoundSafariGame extends StatelessWidget {
  const SoundSafariGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.soundSafari,
      );
}

class NumberGardenGame extends StatelessWidget {
  const NumberGardenGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.numberGarden,
      );
}

class StoryTrainGame extends StatelessWidget {
  const StoryTrainGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.storyTrain,
      );
}

class LetterBakeryGame extends StatelessWidget {
  const LetterBakeryGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.letterBakery,
      );
}

class CleanRoomHelperGame extends StatelessWidget {
  const CleanRoomHelperGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.cleanRoom,
      );
}

class MathMarketGame extends StatelessWidget {
  const MathMarketGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.mathMarket,
      );
}

class WordWizardWorkshopGame extends StatelessWidget {
  const WordWizardWorkshopGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.wordWizard,
      );
}

class SentenceTrainGame extends StatelessWidget {
  const SentenceTrainGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.sentenceTrain,
      );
}

class ClockAdventureGame extends StatelessWidget {
  const ClockAdventureGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.clockAdventure,
      );
}

class NatureDetectiveGame extends StatelessWidget {
  const NatureDetectiveGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.natureDetective,
      );
}

class ShapeBuilderGame extends StatelessWidget {
  const ShapeBuilderGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.shapeBuilder,
      );
}

class FractionCafeGame extends StatelessWidget {
  const FractionCafeGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.fractionCafe,
      );
}

class MultiplicationKingdomGame extends StatelessWidget {
  const MultiplicationKingdomGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.multiplicationKingdom,
      );
}

class GrammarDetectiveGame extends StatelessWidget {
  const GrammarDetectiveGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.grammarDetective,
      );
}

class CodeTheRobotGame extends StatelessWidget {
  const CodeTheRobotGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.codeRobot,
      );
}

class ScienceMachineLabGame extends StatelessWidget {
  const ScienceMachineLabGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.scienceLab,
      );
}

class MapQuestGame extends StatelessWidget {
  const MapQuestGame({super.key});

  @override
  Widget build(BuildContext context) => const LearningAdventureGame(
        type: LearningAdventureType.mapQuest,
      );
}

/// Structural audit used by tests to exercise every generated learning round,
/// including levels that a short widget test cannot reasonably play through.
class LearningAdventureAudit {
  LearningAdventureAudit._();

  static List<String> validateAll() {
    final errors = <String>[];
    for (final type in LearningAdventureType.values) {
      for (var level = 1; level <= 50; level++) {
        for (var round = 0; round < 5; round++) {
          try {
            final question = _AdventureContent.question(type, level, round);
            final location = '${type.id} level $level round ${round + 1}';
            if (question.choices.length < 2 || question.choices.length > 3) {
              errors.add('$location has ${question.choices.length} choices');
            }
            if (question.correctIndex < 0 ||
                question.correctIndex >= question.choices.length) {
              errors.add('$location has an invalid correct answer');
            }
            final labels =
                question.choices.map((choice) => choice.label).toSet();
            if (labels.length != question.choices.length) {
              errors.add('$location has duplicate answer labels');
            }
            if (question.prompt.trim().isEmpty ||
                question.spokenPrompt.trim().isEmpty ||
                question.scene.isEmpty) {
              errors.add('$location has incomplete child-facing content');
            }
          } catch (error) {
            errors.add('${type.id} level $level round ${round + 1}: $error');
          }
        }
      }
    }
    return errors;
  }
}

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

class _AdventureRound {
  const _AdventureRound({
    required this.skill,
    required this.prompt,
    required this.spokenPrompt,
    required this.scene,
    required this.sceneLabel,
    required this.choices,
    required this.correctIndex,
    required this.hint,
    required this.explanation,
  });

  final String skill;
  final String prompt;
  final String spokenPrompt;
  final List<String> scene;
  final String sceneLabel;
  final List<_AdventureChoice> choices;
  final int correctIndex;
  final String hint;
  final String explanation;

  String get wrongGuess =>
      choices[correctIndex == 0 ? 1 : 0].label.toLowerCase();
}

class _AdventureChoice {
  const _AdventureChoice(this.label, [this.emoji]);

  final String label;
  final String? emoji;
}

class _AdventureContent {
  _AdventureContent._();

  static _AdventureRound question(
    LearningAdventureType type,
    int level,
    int round,
  ) =>
      switch (type) {
        LearningAdventureType.soundSafari => _sound(level, round),
        LearningAdventureType.numberGarden => _number(level, round),
        LearningAdventureType.storyTrain => _story(level, round),
        LearningAdventureType.letterBakery => _letter(level, round),
        LearningAdventureType.cleanRoom => _clean(level, round),
        LearningAdventureType.mathMarket => _market(level, round),
        LearningAdventureType.wordWizard => _wordWizard(level, round),
        LearningAdventureType.sentenceTrain => _sentence(level, round),
        LearningAdventureType.clockAdventure => _clock(level, round),
        LearningAdventureType.natureDetective => _nature(level, round),
        LearningAdventureType.shapeBuilder => _shape(level, round),
        LearningAdventureType.fractionCafe => _fraction(level, round),
        LearningAdventureType.multiplicationKingdom =>
          _multiplication(level, round),
        LearningAdventureType.grammarDetective => _grammar(level, round),
        LearningAdventureType.codeRobot => _code(level, round),
        LearningAdventureType.scienceLab => _science(level, round),
        LearningAdventureType.mapQuest => _map(level, round),
      };

  static _AdventureRound _sound(int level, int round) {
    final targetIndex = (level * 7 + round * 3) % _sounds.length;
    final target = _sounds[targetIndex];
    final reverse = level > 15 && (level + round).isEven;
    final candidates = _candidateIndexes(
      targetIndex,
      _sounds.length,
      level,
      round,
    );
    final choices = [
      for (final index in candidates)
        reverse
            ? _AdventureChoice(_sounds[index].sound.toUpperCase(), '🔊')
            : _AdventureChoice(_sounds[index].animal, _sounds[index].emoji),
    ];
    final correct = candidates.indexOf(targetIndex);
    return _AdventureRound(
      skill: reverse ? 'Match animal sounds' : 'Listen and identify',
      prompt: reverse
          ? 'What sound does the ${target.animal} make?'
          : 'Who says "${target.sound.toUpperCase()}"?',
      spokenPrompt: reverse
          ? 'What sound does the ${target.animal} make?'
          : 'Listen. ${target.sound}. Who makes that sound?',
      scene: reverse ? [target.emoji, '🔊'] : ['🎧', '🌿'],
      sceneLabel: reverse ? target.animal.toUpperCase() : 'LISTEN CAREFULLY',
      choices: choices,
      correctIndex: correct,
      hint: reverse
          ? 'Listen to the ${target.animal}: ${target.sound}.'
          : 'The ${target.animal} says ${target.sound}.',
      explanation: 'The ${target.animal} says ${target.sound}!',
    );
  }

  static _AdventureRound _number(int level, int round) {
    final max = level <= 8
        ? 3
        : level <= 18
            ? 5
            : 10;
    final addition = level > 30 && (level + round).isEven;
    final first = 1 + ((level * 2 + round) % (addition ? 5 : max));
    final second = addition ? 1 + ((level + round * 2) % 4) : 0;
    final answer = first + second;
    final values = <int>{answer};
    var step = 1;
    while (values.length < 3) {
      final candidate = (answer + (step.isOdd ? step : -step)).clamp(1, 10);
      values.add(candidate);
      step++;
    }
    final numbers = values.toList()..shuffle(math.Random(level * 101 + round));
    return _AdventureRound(
      skill: addition ? 'Early addition' : 'Count quantities',
      prompt: addition ? 'How many flowers altogether?' : 'How many flowers?',
      spokenPrompt: addition
          ? 'Count $first flowers and $second more. How many altogether?'
          : 'Count the flowers. How many can you see?',
      scene: [
        for (var i = 0; i < first; i++) '🌼',
        if (addition) '➕',
        for (var i = 0; i < second; i++) '🌻',
      ],
      sceneLabel: addition ? '$first AND $second MORE' : 'TOUCH AND COUNT',
      choices: [for (final value in numbers) _AdventureChoice('$value')],
      correctIndex: numbers.indexOf(answer),
      hint: addition
          ? 'Start at $first, then count $second more.'
          : 'Touch each flower once.',
      explanation: 'There ${answer == 1 ? 'is' : 'are'} $answer!',
    );
  }

  static _AdventureRound _story(int level, int round) {
    final index = (level * 3 + round * 2) % _stories.length;
    final story = _stories[index];
    final candidates = _candidateIndexes(index, _stories.length, level, round);
    final choices = [
      for (final candidate in candidates)
        _AdventureChoice(_stories[candidate].answer, _stories[candidate].third),
    ];
    return _AdventureRound(
      skill: 'Story order and prediction',
      prompt: 'What happens next?',
      spokenPrompt:
          '${story.firstLabel}. Then ${story.secondLabel}. What happens next?',
      scene: [story.first, '➡️', story.second, '➡️', '❓'],
      sceneLabel:
          '${story.firstLabel.toUpperCase()} • THEN ${story.secondLabel.toUpperCase()}',
      choices: choices,
      correctIndex: candidates.indexOf(index),
      hint: 'Think about what usually comes after ${story.secondLabel}.',
      explanation: 'Next, ${story.answer.toLowerCase()}!',
    );
  }

  static _AdventureRound _letter(int level, int round) {
    final index = (level * 5 + round * 3) % _words.length;
    final word = _words[index];
    final lowercase = level > 20 && (level + round).isEven;
    final correctLetter = lowercase ? word.letter.toLowerCase() : word.letter;
    final letters = <String>{correctLetter};
    var offset = 1;
    final code = word.letter.codeUnitAt(0) - 65;
    while (letters.length < 3) {
      final candidate = String.fromCharCode(65 + ((code + offset * 5) % 26));
      letters.add(lowercase ? candidate.toLowerCase() : candidate);
      offset++;
    }
    final choices = letters.toList()..shuffle(math.Random(level * 211 + round));
    return _AdventureRound(
      skill: lowercase ? 'Lowercase first sounds' : 'Letter sounds',
      prompt: 'Which letter starts ${word.word.toUpperCase()}?',
      spokenPrompt:
          '${word.word}. ${word.word}. Which letter makes the first sound?',
      scene: [word.emoji, '🥐'],
      sceneLabel: word.word.toUpperCase(),
      choices: [for (final letter in choices) _AdventureChoice(letter)],
      correctIndex: choices.indexOf(correctLetter),
      hint: '${word.word} starts with ${word.letter}.',
      explanation: '${word.letter} is for ${word.word}!',
    );
  }

  static _AdventureRound _clean(int level, int round) {
    final index = (level * 7 + round * 4) % _tidyItems.length;
    final target = _tidyItems[index];
    final availablePlaces = _places
        .where((place) =>
            place.id == target.place || level > 8 || place.id != 'books')
        .toList();
    final targetPlaceIndex =
        availablePlaces.indexWhere((p) => p.id == target.place);
    final candidates = _candidateIndexes(
      targetPlaceIndex,
      availablePlaces.length,
      level,
      round,
      count: level <= 8 ? 2 : 3,
    );
    final choices = [
      for (final candidate in candidates)
        _AdventureChoice(
          availablePlaces[candidate].label,
          availablePlaces[candidate].emoji,
        ),
    ];
    return _AdventureRound(
      skill: 'Everyday sorting',
      prompt: 'Where does the ${target.name} belong?',
      spokenPrompt: 'Help clean up. Where does the ${target.name} belong?',
      scene: [target.emoji, '✨'],
      sceneLabel: target.name.toUpperCase(),
      choices: choices,
      correctIndex: candidates.indexOf(targetPlaceIndex),
      hint:
          'We keep the ${target.name} in the ${_place(target.place).label.toLowerCase()}.',
      explanation:
          'The ${target.name} goes in the ${_place(target.place).label.toLowerCase()}!',
    );
  }

  static _AdventureRound _market(int level, int round) {
    final first = _marketItems[(level * 3 + round * 2) % _marketItems.length];
    final second =
        _marketItems[(level * 5 + round * 3 + 1) % _marketItems.length];
    final firstPrice = 1 + ((level + round * 2) % (level <= 15 ? 9 : 15));
    final secondPrice = 1 + ((level * 2 + round) % (level <= 15 ? 6 : 12));
    final changeQuestion = level > 15 && (level + round).isEven;
    final threeItems = level > 35 && !changeQuestion;
    final thirdPrice = threeItems ? 1 + ((level + round * 4) % 8) : 0;
    final answer = changeQuestion
        ? firstPrice + secondPrice
        : firstPrice + secondPrice + thirdPrice;
    final paid = changeQuestion ? answer + 2 + ((level + round) % 8) : 0;
    final finalAnswer = changeQuestion ? paid - answer : answer;
    final numbers = _nearbyNumbers(finalAnswer, level * 307 + round, max: 40);
    return _AdventureRound(
      skill: changeQuestion ? 'Subtraction and change' : 'Addition and money',
      prompt: changeQuestion
          ? 'You pay $paid coins. How much change?'
          : 'How many coins altogether?',
      spokenPrompt: changeQuestion
          ? 'The ${first.name} and ${second.name} cost $answer coins. You pay $paid coins. How many coins come back?'
          : 'The ${first.name} costs $firstPrice coins and the ${second.name} costs $secondPrice coins${threeItems ? ', with $thirdPrice more coins for another item' : ''}. How many coins altogether?',
      scene: [
        first.emoji,
        '$firstPrice',
        '🪙',
        second.emoji,
        '$secondPrice',
        '🪙',
        if (threeItems) ...['🎁', '$thirdPrice', '🪙'],
      ],
      sceneLabel:
          changeQuestion ? 'COST $answer • PAY $paid' : 'ADD THE PRICES',
      choices: [
        for (final number in numbers) _AdventureChoice('$number', '🪙'),
      ],
      correctIndex: numbers.indexOf(finalAnswer),
      hint: changeQuestion
          ? 'Count forward from $answer to $paid.'
          : 'Start with $firstPrice, then count on $secondPrice${threeItems ? ' and $thirdPrice' : ''}.',
      explanation: changeQuestion
          ? '$finalAnswer coins come back!'
          : 'The total is $finalAnswer coins!',
    );
  }

  static _AdventureRound _wordWizard(int level, int round) {
    final word = _words[(level * 7 + round * 5) % _words.length];
    final firstLetter = word.letter;
    final lastLetter = word.word[word.word.length - 1].toUpperCase();
    if (level <= 18) {
      final letters = _letterChoices(firstLetter, level * 401 + round);
      return _AdventureRound(
        skill: 'Beginning sounds and spelling',
        prompt: 'Which letter completes the word?',
        spokenPrompt:
            '${word.word}. Which letter starts the word ${word.word}?',
        scene: [word.emoji, '✨'],
        sceneLabel: '_${word.word.substring(1).toUpperCase()}',
        choices: [for (final letter in letters) _AdventureChoice(letter)],
        correctIndex: letters.indexOf(firstLetter),
        hint: '${word.word} begins with the sound $firstLetter.',
        explanation: '$firstLetter completes ${word.word}!',
      );
    }
    if (level <= 34) {
      final letters = _letterChoices(lastLetter, level * 409 + round);
      return _AdventureRound(
        skill: 'Ending sounds and spelling',
        prompt: 'Which letter finishes the word?',
        spokenPrompt:
            '${word.word}. Listen to the final sound. Which letter finishes ${word.word}?',
        scene: [word.emoji, '🪄'],
        sceneLabel:
            '${word.word.substring(0, word.word.length - 1).toUpperCase()}_',
        choices: [for (final letter in letters) _AdventureChoice(letter)],
        correctIndex: letters.indexOf(lastLetter),
        hint: '${word.word} ends with $lastLetter.',
        explanation: '$lastLetter finishes ${word.word}!',
      );
    }
    final correct = word.word.toUpperCase();
    final wrongFirst =
        '${String.fromCharCode(65 + ((firstLetter.codeUnitAt(0) - 64) % 26))}${correct.substring(1)}';
    final missing = correct.substring(0, correct.length - 1);
    final spellings = <String>{correct, wrongFirst, missing}.toList()
      ..shuffle(math.Random(level * 419 + round));
    return _AdventureRound(
      skill: 'Whole-word spelling',
      prompt: 'Which spelling is correct?',
      spokenPrompt: 'Choose the correct spelling of ${word.word}.',
      scene: [word.emoji, '🧙'],
      sceneLabel: 'SPELL ${word.word.toUpperCase()}',
      choices: [for (final spelling in spellings) _AdventureChoice(spelling)],
      correctIndex: spellings.indexOf(correct),
      hint: 'Say each sound slowly: ${word.word}.',
      explanation: '$correct is the correct spelling!',
    );
  }

  static _AdventureRound _sentence(int level, int round) {
    final item = _sentences[(level * 5 + round * 3) % _sentences.length];
    final punctuation = level > 30 && (level + round).isEven;
    if (punctuation) {
      final marks = <String>[item.mark, '.', '?']
        ..shuffle(math.Random(level * 433 + round));
      final uniqueMarks = marks.toSet().toList();
      while (uniqueMarks.length < 3) {
        uniqueMarks.add('!');
      }
      return _AdventureRound(
        skill: 'Sentence punctuation',
        prompt: 'Which mark completes the sentence?',
        spokenPrompt:
            '${item.completeSentence} Which punctuation mark belongs at the end?',
        scene: [item.emoji, '🚂'],
        sceneLabel: '${item.completeSentence.toUpperCase()} _',
        choices: [for (final mark in uniqueMarks) _AdventureChoice(mark)],
        correctIndex: uniqueMarks.indexOf(item.mark),
        hint: item.mark == '?'
            ? 'A question ends with a question mark.'
            : item.mark == '!'
                ? 'An excited sentence can end with an exclamation mark.'
                : 'A telling sentence ends with a full stop.',
        explanation: '${item.mark} completes the sentence!',
      );
    }
    final words = <String>[item.answer, item.distractorOne, item.distractorTwo]
      ..shuffle(math.Random(level * 431 + round));
    return _AdventureRound(
      skill: level <= 18 ? 'Build simple sentences' : 'Grammar and verb choice',
      prompt: 'Which word completes the sentence?',
      spokenPrompt:
          '${item.before}, blank, ${item.after}. Choose the best word.',
      scene: [item.emoji, '🚂', '❓'],
      sceneLabel:
          '${item.before.toUpperCase()} ___ ${item.after.toUpperCase()}',
      choices: [for (final word in words) _AdventureChoice(word.toUpperCase())],
      correctIndex: words.indexOf(item.answer),
      hint:
          'Read the whole sentence and listen for the word that sounds right.',
      explanation: '${item.answer} makes the sentence correct!',
    );
  }

  static _AdventureRound _clock(int level, int round) {
    final halfHour = level > 25 && (level + round).isEven;
    final hour = 1 + ((level * 3 + round * 2) % 12);
    final correctTime = halfHour ? '$hour:30' : '$hour:00';
    final times = <String>{correctTime};
    var offset = 1;
    while (times.length < 3) {
      final otherHour = 1 + ((hour - 1 + offset * 3) % 12);
      times.add(halfHour ? '$otherHour:30' : '$otherHour:00');
      offset++;
    }
    final choices = times.toList()..shuffle(math.Random(level * 443 + round));
    final activityMode = level > 38 && round.isOdd;
    final activity = _dailyTimes[(level + round) % _dailyTimes.length];
    if (activityMode) {
      final activityChoices = <_DailyTime>[activity];
      var cursor = (_dailyTimes.indexOf(activity) + 2) % _dailyTimes.length;
      while (activityChoices.length < 3) {
        final candidate = _dailyTimes[cursor % _dailyTimes.length];
        if (!activityChoices.contains(candidate)) {
          activityChoices.add(candidate);
        }
        cursor++;
      }
      activityChoices.shuffle(math.Random(level * 449 + round));
      return _AdventureRound(
        skill: 'Time and daily routines',
        prompt: 'What usually happens at ${activity.time}?',
        spokenPrompt:
            'It is ${activity.spokenTime}. What activity usually happens now?',
        scene: [activity.clock, '⏰'],
        sceneLabel: activity.time,
        choices: [
          for (final choice in activityChoices)
            _AdventureChoice(choice.activity, choice.emoji),
        ],
        correctIndex: activityChoices.indexOf(activity),
        hint: '${activity.activity} often happens at ${activity.time}.',
        explanation: '${activity.activity} matches ${activity.time}!',
      );
    }
    return _AdventureRound(
      skill: halfHour ? 'Read half-hour clocks' : 'Read hour clocks',
      prompt: 'What time does the clock show?',
      spokenPrompt: 'Look at the clock hands. What time is it?',
      scene: [_clockEmoji(hour, halfHour)],
      sceneLabel: halfHour ? 'HALF PAST $hour' : '$hour O\'CLOCK',
      choices: [for (final time in choices) _AdventureChoice(time)],
      correctIndex: choices.indexOf(correctTime),
      hint: halfHour
          ? 'The minute hand points to six, so it is half past.'
          : 'The minute hand points to twelve, so it is exactly on the hour.',
      explanation: 'The time is $correctTime!',
    );
  }

  static _AdventureRound _nature(int level, int round) {
    final index = (level * 7 + round * 5) % _natureItems.length;
    final target = _natureItems[index];
    final habitatMode = level > 22 && (level + round).isEven;
    if (habitatMode) {
      final habitats = <String>{target.habitat};
      var cursor = (index + 1) % _natureItems.length;
      while (habitats.length < 3) {
        habitats.add(_natureItems[cursor].habitat);
        cursor = (cursor + 1) % _natureItems.length;
      }
      final choices = habitats.toList()
        ..shuffle(math.Random(level * 457 + round));
      return _AdventureRound(
        skill: 'Habitats and adaptation',
        prompt: 'Where does the ${target.name} live?',
        spokenPrompt: 'Where would you find a ${target.name} in nature?',
        scene: [target.emoji, '🔎'],
        sceneLabel: target.clue.toUpperCase(),
        choices: [
          for (final habitat in choices)
            _AdventureChoice(habitat.toUpperCase(), _habitatEmoji(habitat)),
        ],
        correctIndex: choices.indexOf(target.habitat),
        hint: 'Think about the body and needs of the ${target.name}.',
        explanation: 'The ${target.name} lives in the ${target.habitat}!',
      );
    }
    final candidates =
        _candidateIndexes(index, _natureItems.length, level, round);
    return _AdventureRound(
      skill: 'Observe and infer from clues',
      prompt: 'Which living thing matches the clue?',
      spokenPrompt: '${target.clue}. Which living thing am I describing?',
      scene: ['🔎', '🌿', '❓'],
      sceneLabel: target.clue.toUpperCase(),
      choices: [
        for (final candidate in candidates)
          _AdventureChoice(
              _natureItems[candidate].name, _natureItems[candidate].emoji),
      ],
      correctIndex: candidates.indexOf(index),
      hint: 'Look for the important words in the clue.',
      explanation: 'It is the ${target.name}!',
    );
  }

  static _AdventureRound _shape(int level, int round) {
    final index = (level * 5 + round * 2) % _shapes.length;
    final target = _shapes[index];
    final patternMode = level > 30 && (level + round).isEven;
    final sidesMode = !patternMode && level > 15 && round.isOdd;
    if (patternMode) {
      final second = _shapes[(index + 2) % _shapes.length];
      final candidates = _candidateIndexes(index, _shapes.length, level, round);
      return _AdventureRound(
        skill: 'Shape patterns',
        prompt: 'Which shape comes next?',
        spokenPrompt:
            '${target.name}, ${second.name}, ${target.name}, ${second.name}. Which shape comes next?',
        scene: [target.emoji, second.emoji, target.emoji, second.emoji, '❓'],
        sceneLabel: 'FIND THE REPEATING PATTERN',
        choices: [
          for (final candidate in candidates)
            _AdventureChoice(_shapes[candidate].name, _shapes[candidate].emoji),
        ],
        correctIndex: candidates.indexOf(index),
        hint: 'The two shapes take turns.',
        explanation: 'The ${target.name} continues the pattern!',
      );
    }
    if (sidesMode) {
      final numbers =
          _nearbyNumbers(target.sides, level * 463 + round, max: 12);
      return _AdventureRound(
        skill: 'Shape properties and sides',
        prompt: 'How many straight sides?',
        spokenPrompt: 'How many straight sides does a ${target.name} have?',
        scene: [target.emoji, '📏'],
        sceneLabel: target.name.toUpperCase(),
        choices: [for (final number in numbers) _AdventureChoice('$number')],
        correctIndex: numbers.indexOf(target.sides),
        hint: 'Trace around the shape and count each straight edge.',
        explanation: 'A ${target.name} has ${target.sides} straight sides!',
      );
    }
    final candidates = _candidateIndexes(index, _shapes.length, level, round);
    return _AdventureRound(
      skill: 'Recognise 2D shapes',
      prompt: 'Find the ${target.name}.',
      spokenPrompt: 'Which picture is a ${target.name}?',
      scene: ['🏗️', '🧱'],
      sceneLabel: 'CHOOSE THE ${target.name.toUpperCase()}',
      choices: [
        for (final candidate in candidates)
          _AdventureChoice(_shapes[candidate].name, _shapes[candidate].emoji),
      ],
      correctIndex: candidates.indexOf(index),
      hint: target.description,
      explanation: 'That is the ${target.name}!',
    );
  }

  static _AdventureRound _fraction(int level, int round) {
    final denominators =
        level <= 12 ? const [2, 3, 4] : const [2, 3, 4, 5, 6, 8];
    final denominator = denominators[(level + round * 2) % denominators.length];
    final numerator = 1 + ((level * 3 + round) % (denominator - 1));
    final addition = level > 34 && (level + round).isEven;
    final equivalent = !addition && level > 18 && round.isOdd;
    if (addition) {
      final first = 1 + ((level + round) % math.max(1, denominator - 2));
      final second = 1 + ((level * 2 + round) % (denominator - first));
      final answerTop = first + second;
      final answer = '$answerTop/$denominator';
      final choices = <String>{
        answer,
        '${math.max(1, answerTop - 1)}/$denominator',
        '$answerTop/${denominator + 1}',
      }.toList()
        ..shuffle(math.Random(level * 503 + round));
      return _AdventureRound(
        skill: 'Add like fractions',
        prompt: 'How much pizza altogether?',
        spokenPrompt:
            'Add $first $denominator-ths and $second $denominator-ths. The pieces are the same size.',
        scene: [
          for (var i = 0; i < first; i++) '🍕',
          '➕',
          for (var i = 0; i < second; i++) '🍕',
        ],
        sceneLabel: '$first/$denominator + $second/$denominator',
        choices: [for (final value in choices) _AdventureChoice(value)],
        correctIndex: choices.indexOf(answer),
        hint: 'Keep the denominator $denominator and add the top numbers.',
        explanation: '$first/$denominator + $second/$denominator = $answer!',
      );
    }
    if (equivalent) {
      final doubled = '${numerator * 2}/${denominator * 2}';
      final choiceSet = <String>{
        doubled,
        '${numerator + 1}/${denominator * 2}',
        '${numerator * 2}/${denominator + 1}',
      };
      if (choiceSet.length < 3) {
        choiceSet.add('$numerator/${denominator * 2}');
      }
      final choices = choiceSet.toList()
        ..shuffle(math.Random(level * 509 + round));
      return _AdventureRound(
        skill: 'Equivalent fractions',
        prompt: 'Which fraction is equal?',
        spokenPrompt:
            'Which fraction has the same value as $numerator over $denominator?',
        scene: ['🍕', '⚖️', '🍕'],
        sceneLabel: '$numerator/$denominator = ?',
        choices: [for (final value in choices) _AdventureChoice(value)],
        correctIndex: choices.indexOf(doubled),
        hint: 'Multiply the top and bottom by the same number.',
        explanation: '$numerator/$denominator equals $doubled!',
      );
    }
    final answer = '$numerator/$denominator';
    final choices = <String>{
      answer,
      '${math.max(1, numerator - 1)}/$denominator',
      '$numerator/${denominator + 1}',
    }.toList();
    while (choices.length < 3) {
      choices.add('${numerator + 1}/$denominator');
    }
    choices.shuffle(math.Random(level * 499 + round));
    return _AdventureRound(
      skill: 'Read fractions of a whole',
      prompt: 'What fraction is served?',
      spokenPrompt:
          '$numerator of $denominator equal pizza pieces are served. What fraction is that?',
      scene: [
        for (var i = 0; i < numerator; i++) '🍕',
        for (var i = numerator; i < denominator; i++) '▫️',
      ],
      sceneLabel: '$numerator OF $denominator EQUAL PIECES',
      choices: [for (final value in choices) _AdventureChoice(value)],
      correctIndex: choices.indexOf(answer),
      hint:
          'The top number counts served pieces. The bottom counts all pieces.',
      explanation: '$numerator out of $denominator is $answer!',
    );
  }

  static _AdventureRound _multiplication(int level, int round) {
    final maxFactor = level <= 12
        ? 5
        : level <= 28
            ? 10
            : 12;
    final first = 2 + ((level + round * 3) % (maxFactor - 1));
    final second = 2 + ((level * 2 + round) % (maxFactor - 1));
    final product = first * second;
    final division = level > 18 && (level + round).isEven;
    final missingFactor = level > 35 && !division && round.isOdd;
    final answer = division
        ? second
        : missingFactor
            ? first
            : product;
    final numbers = _nearbyNumbers(answer, level * 521 + round, max: 144);
    return _AdventureRound(
      skill: division
          ? 'Division as equal sharing'
          : missingFactor
              ? 'Find a missing factor'
              : 'Multiplication facts',
      prompt: division
          ? '$product ÷ $first = ?'
          : missingFactor
              ? '? × $second = $product'
              : '$first × $second = ?',
      spokenPrompt: division
          ? 'Share $product objects into $first equal groups. How many are in each group?'
          : missingFactor
              ? 'What number times $second makes $product?'
              : 'There are $first equal groups of $second. How many altogether?',
      scene: [
        for (var i = 0; i < math.min(first, 8); i++) '🛡️',
        '×',
        '$second',
      ],
      sceneLabel: division
          ? '$product SHARED INTO $first GROUPS'
          : '$first GROUPS OF $second',
      choices: [for (final value in numbers) _AdventureChoice('$value')],
      correctIndex: numbers.indexOf(answer),
      hint: division
          ? 'Use the multiplication fact $first × $second = $product.'
          : 'Skip-count by $second, $first times.',
      explanation: division
          ? '$product ÷ $first = $answer!'
          : '$first × $second = $product!',
    );
  }

  static _AdventureRound _grammar(int level, int round) {
    final question =
        _grammarQuestions[(level * 7 + round * 3) % _grammarQuestions.length];
    final choices = <String>[
      question.answer,
      question.distractorOne,
      question.distractorTwo,
    ]..shuffle(math.Random(level * 523 + round));
    return _AdventureRound(
      skill: question.skill,
      prompt: question.prompt,
      spokenPrompt: question.spokenPrompt,
      scene: [question.emoji, '🔎', '📖'],
      sceneLabel: question.sentence.toUpperCase(),
      choices: [for (final choice in choices) _AdventureChoice(choice)],
      correctIndex: choices.indexOf(question.answer),
      hint: question.hint,
      explanation: question.explanation,
    );
  }

  static _AdventureRound _code(int level, int round) {
    final loopMode = level > 18 && (level + round).isEven;
    final debugMode = level > 35 && !loopMode && round.isOdd;
    if (loopMode) {
      final repeats = 2 + ((level + round) % 4);
      final moves = 1 + ((level * 2 + round) % 3);
      final answer = repeats * moves;
      final numbers = _nearbyNumbers(answer, level * 541 + round, max: 20);
      return _AdventureRound(
        skill: 'Loops and repeated commands',
        prompt: 'Where does the robot finish?',
        spokenPrompt:
            'Repeat move $moves steps, $repeats times. How many steps altogether?',
        scene: ['🤖', '🔁', '$repeats', '➡️', '$moves', '⭐'],
        sceneLabel: 'REPEAT $repeats [ MOVE $moves ]',
        choices: [for (final number in numbers) _AdventureChoice('$number')],
        correctIndex: numbers.indexOf(answer),
        hint: 'Add $moves once for every repeat.',
        explanation: 'The robot moves $answer steps!',
      );
    }
    final target = 3 + ((level * 3 + round) % 7);
    if (debugMode) {
      final actual = target + ((level + round).isEven ? 1 : -1);
      final answer = actual > target ? 'REMOVE 1' : 'ADD 1';
      final choices = <String>{answer, 'TURN LEFT', 'REPEAT AGAIN'}.toList()
        ..shuffle(math.Random(level * 547 + round));
      return _AdventureRound(
        skill: 'Debug an algorithm',
        prompt: 'Which fix reaches the star?',
        spokenPrompt:
            'The star is $target steps away, but the code moves $actual steps. Which fix works?',
        scene: ['🤖', '➡️', '$actual', '🐛', '⭐'],
        sceneLabel: 'TARGET $target • CODE MOVES $actual',
        choices: [for (final choice in choices) _AdventureChoice(choice)],
        correctIndex: choices.indexOf(answer),
        hint: 'Compare the target distance with the coded distance.',
        explanation: '$answer fixes the code!',
      );
    }
    final commands = <String>{
      'MOVE $target',
      'MOVE ${target + 1}',
      'MOVE ${target - 1}'
    }.toList()
      ..shuffle(math.Random(level * 539 + round));
    return _AdventureRound(
      skill: 'Sequence movement commands',
      prompt: 'Which command reaches the star?',
      spokenPrompt:
          'The star is $target spaces ahead. Choose the exact move command.',
      scene: ['🤖', for (var i = 0; i < math.min(target, 7); i++) '▫️', '⭐'],
      sceneLabel: '$target SPACES FORWARD',
      choices: [for (final command in commands) _AdventureChoice(command)],
      correctIndex: commands.indexOf('MOVE $target'),
      hint: 'Count every space between the robot and star.',
      explanation: 'MOVE $target reaches the star exactly!',
    );
  }

  static _AdventureRound _science(int level, int round) {
    final question =
        _scienceQuestions[(level * 5 + round * 7) % _scienceQuestions.length];
    final choices = <String>[
      question.answer,
      question.distractorOne,
      question.distractorTwo,
    ]..shuffle(math.Random(level * 557 + round));
    return _AdventureRound(
      skill: question.skill,
      prompt: question.prompt,
      spokenPrompt: question.spokenPrompt,
      scene: [question.emoji, '🧪', '💡'],
      sceneLabel: question.sceneLabel.toUpperCase(),
      choices: [for (final choice in choices) _AdventureChoice(choice)],
      correctIndex: choices.indexOf(question.answer),
      hint: question.hint,
      explanation: question.explanation,
    );
  }

  static _AdventureRound _map(int level, int round) {
    final coordinateMode = level > 18 && (level + round).isEven;
    final distanceMode = level > 35 && !coordinateMode && round.isOdd;
    if (distanceMode) {
      final first = 2 + ((level + round) % 7);
      final second = 2 + ((level * 2 + round) % 7);
      final answer = first + second;
      final numbers = _nearbyNumbers(answer, level * 577 + round, max: 20);
      return _AdventureRound(
        skill: 'Map distance and scale',
        prompt: 'How far is the full journey?',
        spokenPrompt:
            'Walk $first kilometres to the bridge, then $second kilometres to the camp. How far altogether?',
        scene: ['🏕️', '━', '$first km', '🌉', '━', '$second km', '🏕️'],
        sceneLabel: '$first km + $second km',
        choices: [for (final value in numbers) _AdventureChoice('$value km')],
        correctIndex: numbers.indexOf(answer),
        hint: 'Add both parts of the route.',
        explanation: 'The journey is $answer kilometres!',
      );
    }
    if (coordinateMode) {
      final row = 1 + ((level * 2 + round) % 3);
      final east = (level + round).isEven;
      final column = east ? (level + round) % 2 : 1 + ((level + round) % 2);
      final nextColumn = column + (east ? 1 : -1);
      final answer = '${String.fromCharCode(65 + nextColumn)}$row';
      final choices = <String>{
        answer,
        '${String.fromCharCode(65 + column)}${row == 3 ? 2 : row + 1}',
        '${String.fromCharCode(65 + ((nextColumn + 1) % 3))}$row',
      }.toList();
      while (choices.length < 3) {
        choices.add('${String.fromCharCode(65 + column)}${row == 1 ? 3 : 1}');
      }
      choices.shuffle(math.Random(level * 571 + round));
      return _AdventureRound(
        skill: 'Grid coordinates',
        prompt: 'Which square do you reach?',
        spokenPrompt:
            'Start at ${String.fromCharCode(65 + column)}$row and move one square ${east ? 'east' : 'west'}. Where do you land?',
        scene: ['🗺️', east ? '➡️' : '⬅️', '🎯'],
        sceneLabel:
            'START ${String.fromCharCode(65 + column)}$row • MOVE ${east ? 'EAST' : 'WEST'}',
        choices: [for (final value in choices) _AdventureChoice(value)],
        correctIndex: choices.indexOf(answer),
        hint: 'Letters move left and right; numbers stay on the same row.',
        explanation: 'You arrive at $answer!',
      );
    }
    final directionIndex = (level * 3 + round) % _directions.length;
    final direction = _directions[directionIndex];
    final candidates = _candidateIndexes(
      directionIndex,
      _directions.length,
      level,
      round,
    );
    return _AdventureRound(
      skill: 'Compass directions',
      prompt: 'Which direction does the arrow point?',
      spokenPrompt: 'Use the compass. Which direction does this arrow show?',
      scene: ['🧭', direction.arrow, '🗺️'],
      sceneLabel: 'NORTH IS AT THE TOP',
      choices: [
        for (final candidate in candidates)
          _AdventureChoice(
              _directions[candidate].name, _directions[candidate].arrow),
      ],
      correctIndex: candidates.indexOf(directionIndex),
      hint: 'North is up, south is down, east is right, and west is left.',
      explanation: 'The arrow points ${direction.name.toLowerCase()}!',
    );
  }

  static List<int> _nearbyNumbers(int answer, int seed, {required int max}) {
    final values = <int>{answer};
    var offset = 1;
    while (values.length < 3) {
      values.add((answer + (offset.isOdd ? offset : -offset)).clamp(0, max));
      offset++;
    }
    return values.toList()..shuffle(math.Random(seed));
  }

  static List<String> _letterChoices(String answer, int seed) {
    final values = <String>{answer};
    final base = answer.codeUnitAt(0) - 65;
    var offset = 1;
    while (values.length < 3) {
      values.add(String.fromCharCode(65 + ((base + offset * 7) % 26)));
      offset++;
    }
    return values.toList()..shuffle(math.Random(seed));
  }

  static String _clockEmoji(int hour, bool halfHour) {
    final index = (hour - 1) % 12;
    return halfHour ? _halfHourClocks[index] : _hourClocks[index];
  }

  static String _habitatEmoji(String habitat) => switch (habitat) {
        'ocean' => '🌊',
        'pond' => '🌿',
        'forest' => '🌲',
        'desert' => '🏜️',
        'farm' => '🐄',
        'garden' => '🌻',
        'polar ice' => '🧳',
        _ => '🌍',
      };

  static List<int> _candidateIndexes(
    int target,
    int length,
    int level,
    int round, {
    int count = 3,
  }) {
    final values = <int>{target};
    var cursor = (target + level + round + 1) % length;
    while (values.length < math.min(count, length)) {
      values.add(cursor);
      cursor = (cursor + 1) % length;
    }
    final result = values.toList()
      ..shuffle(math.Random(level * 997 + round * 37 + target));
    return result;
  }

  static _Place _place(String id) =>
      _places.firstWhere((place) => place.id == id);
}

class _SoundItem {
  const _SoundItem(this.emoji, this.animal, this.sound);
  final String emoji;
  final String animal;
  final String sound;
}

const _sounds = <_SoundItem>[
  _SoundItem('🐄', 'cow', 'moo'),
  _SoundItem('🐶', 'dog', 'woof'),
  _SoundItem('🐱', 'cat', 'meow'),
  _SoundItem('🦁', 'lion', 'roar'),
  _SoundItem('🐑', 'sheep', 'baa'),
  _SoundItem('🐷', 'pig', 'oink'),
  _SoundItem('🐸', 'frog', 'ribbit'),
  _SoundItem('🐔', 'chicken', 'cluck'),
  _SoundItem('🦆', 'duck', 'quack'),
  _SoundItem('🐍', 'snake', 'hiss'),
  _SoundItem('🐝', 'bee', 'buzz'),
  _SoundItem('🦉', 'owl', 'hoot'),
  _SoundItem('🐴', 'horse', 'neigh'),
  _SoundItem('🐒', 'monkey', 'chatter'),
  _SoundItem('🐦', 'bird', 'tweet'),
];

class _StoryItem {
  const _StoryItem(
    this.first,
    this.firstLabel,
    this.second,
    this.secondLabel,
    this.third,
    this.answer,
  );
  final String first;
  final String firstLabel;
  final String second;
  final String secondLabel;
  final String third;
  final String answer;
}

const _stories = <_StoryItem>[
  _StoryItem('🌱', 'plant a seed', '💧', 'water it', '🌻', 'A flower grows'),
  _StoryItem(
      '🥚', 'an egg rests', '🐣', 'a chick hatches', '🐔', 'The chicken grows'),
  _StoryItem('🌧️', 'rain falls', '☂️', 'we use an umbrella', '🌈',
      'A rainbow appears'),
  _StoryItem('🛌', 'wake up', '🪥', 'brush teeth', '🏫', 'Go to school'),
  _StoryItem(
      '🥣', 'mix ingredients', '🔥', 'bake them', '🎂', 'The cake is ready'),
  _StoryItem('🧼', 'wash hands', '🧻', 'dry hands', '🍽️', 'Eat the meal'),
  _StoryItem(
      '📖', 'open a book', '👀', 'read the story', '💡', 'Learn an idea'),
  _StoryItem(
      '🌙', 'night arrives', '👕', 'put on pajamas', '😴', 'Go to sleep'),
  _StoryItem('🎨', 'dip the brush', '🖼️', 'paint a picture', '😊',
      'Share the artwork'),
  _StoryItem(
      '🧸', 'play with toys', '🧺', 'put toys away', '✨', 'The room is tidy'),
];

class _WordItem {
  const _WordItem(this.emoji, this.word, this.letter);
  final String emoji;
  final String word;
  final String letter;
}

const _words = <_WordItem>[
  _WordItem('🍎', 'apple', 'A'),
  _WordItem('🍌', 'banana', 'B'),
  _WordItem('🐱', 'cat', 'C'),
  _WordItem('🐶', 'dog', 'D'),
  _WordItem('🐘', 'elephant', 'E'),
  _WordItem('🐟', 'fish', 'F'),
  _WordItem('🍇', 'grape', 'G'),
  _WordItem('🏠', 'house', 'H'),
  _WordItem('🍨', 'ice cream', 'I'),
  _WordItem('🥤', 'juice', 'J'),
  _WordItem('🪁', 'kite', 'K'),
  _WordItem('🦁', 'lion', 'L'),
  _WordItem('🌕', 'moon', 'M'),
  _WordItem('🪆', 'nest', 'N'),
  _WordItem('🍊', 'orange', 'O'),
  _WordItem('🐧', 'penguin', 'P'),
  _WordItem('👸', 'queen', 'Q'),
  _WordItem('🌈', 'rainbow', 'R'),
  _WordItem('⭐', 'star', 'S'),
  _WordItem('🌳', 'tree', 'T'),
  _WordItem('☔', 'umbrella', 'U'),
  _WordItem('🎻', 'violin', 'V'),
  _WordItem('🐋', 'whale', 'W'),
  _WordItem('🪇', 'xylophone', 'X'),
  _WordItem('🪀', 'yo-yo', 'Y'),
  _WordItem('🦓', 'zebra', 'Z'),
];

class _Place {
  const _Place(this.id, this.label, this.emoji);
  final String id;
  final String label;
  final String emoji;
}

const _places = <_Place>[
  _Place('toybox', 'TOY BOX', '🧺'),
  _Place('wardrobe', 'WARDROBE', '👕'),
  _Place('kitchen', 'KITCHEN', '🍳'),
  _Place('bathroom', 'BATHROOM', '🚿'),
  _Place('books', 'BOOKSHELF', '📚'),
];

class _TidyItem {
  const _TidyItem(this.emoji, this.name, this.place);
  final String emoji;
  final String name;
  final String place;
}

const _tidyItems = <_TidyItem>[
  _TidyItem('⚽', 'ball', 'toybox'),
  _TidyItem('🧸', 'teddy', 'toybox'),
  _TidyItem('🧩', 'puzzle', 'toybox'),
  _TidyItem('🧱', 'blocks', 'toybox'),
  _TidyItem('👕', 'shirt', 'wardrobe'),
  _TidyItem('🧦', 'socks', 'wardrobe'),
  _TidyItem('👗', 'dress', 'wardrobe'),
  _TidyItem('🧢', 'cap', 'wardrobe'),
  _TidyItem('🥄', 'spoon', 'kitchen'),
  _TidyItem('🍽️', 'plate', 'kitchen'),
  _TidyItem('🥛', 'cup', 'kitchen'),
  _TidyItem('🥣', 'bowl', 'kitchen'),
  _TidyItem('🪥', 'toothbrush', 'bathroom'),
  _TidyItem('🧼', 'soap', 'bathroom'),
  _TidyItem('🧻', 'towel', 'bathroom'),
  _TidyItem('🧴', 'shampoo', 'bathroom'),
  _TidyItem('📕', 'story book', 'books'),
  _TidyItem('📘', 'blue book', 'books'),
  _TidyItem('📗', 'green book', 'books'),
  _TidyItem('📙', 'orange book', 'books'),
];

class _MarketItem {
  const _MarketItem(this.emoji, this.name);
  final String emoji;
  final String name;
}

const _marketItems = <_MarketItem>[
  _MarketItem('🍎', 'apple'),
  _MarketItem('🍌', 'banana'),
  _MarketItem('🥕', 'carrot'),
  _MarketItem('🧸', 'teddy'),
  _MarketItem('⚽', 'ball'),
  _MarketItem('✏️', 'pencil'),
  _MarketItem('📕', 'book'),
  _MarketItem('🪁', 'kite'),
  _MarketItem('🥪', 'sandwich'),
  _MarketItem('🍹', 'juice'),
  _MarketItem('🍪', 'cookie'),
  _MarketItem('🧩', 'puzzle'),
];

class _SentenceItem {
  const _SentenceItem(
    this.emoji,
    this.before,
    this.answer,
    this.after,
    this.distractorOne,
    this.distractorTwo,
    this.mark,
  );
  final String emoji;
  final String before;
  final String answer;
  final String after;
  final String distractorOne;
  final String distractorTwo;
  final String mark;

  String get completeSentence => '$before $answer $after';
}

const _sentences = <_SentenceItem>[
  _SentenceItem('🐱', 'The cat', 'sits', 'on the mat', 'sit', 'sleep', '.'),
  _SentenceItem('🐶', 'The dog', 'runs', 'in the park', 'run', 'reads', '.'),
  _SentenceItem('🐦', 'A bird', 'flies', 'in the sky', 'fly', 'swims', '.'),
  _SentenceItem('🐟', 'The fish', 'swims', 'in water', 'swim', 'walks', '.'),
  _SentenceItem('🌙', 'The moon', 'shines', 'at night', 'shine', 'eats', '.'),
  _SentenceItem('👧', 'Mia', 'reads', 'a story', 'read', 'jumps', '.'),
  _SentenceItem('👦', 'Sam', 'kicks', 'the ball', 'kick', 'drinks', '.'),
  _SentenceItem(
      '🐝', 'The bees', 'buzz', 'near flowers', 'buzzes', 'roar', '.'),
  _SentenceItem('🌧️', 'Why is it', 'raining', 'today', 'rain', 'yellow', '?'),
  _SentenceItem('🎂', 'What a', 'wonderful', 'cake', 'wonder', 'slowly', '!'),
  _SentenceItem('🚲', 'Can you', 'ride', 'a bicycle', 'rides', 'blue', '?'),
  _SentenceItem(
      '🌈', 'Look at the', 'bright', 'rainbow', 'brightness', 'swim', '!'),
  _SentenceItem('👫', 'The children', 'play', 'together', 'plays', 'red', '.'),
  _SentenceItem('🌱', 'A seed', 'grows', 'into a plant', 'grow', 'sings', '.'),
  _SentenceItem(
      '🐘', 'The elephant', 'has', 'a long trunk', 'have', 'are', '.'),
];

class _DailyTime {
  const _DailyTime(
    this.clock,
    this.time,
    this.spokenTime,
    this.emoji,
    this.activity,
  );
  final String clock;
  final String time;
  final String spokenTime;
  final String emoji;
  final String activity;
}

const _dailyTimes = <_DailyTime>[
  _DailyTime('🕡', '6:30', 'half past six', '🌅', 'WAKE UP'),
  _DailyTime('🕢', '7:30', 'half past seven', '🥣', 'BREAKFAST'),
  _DailyTime('🕘', '9:00', 'nine o clock', '🏫', 'SCHOOL'),
  _DailyTime('🕛', '12:00', 'twelve o clock', '🍛', 'LUNCH'),
  _DailyTime('🕞', '3:00', 'three o clock', '⚽', 'PLAY TIME'),
  _DailyTime('🕡', '6:00', 'six o clock', '🍽️', 'DINNER'),
  _DailyTime('🕣', '8:30', 'half past eight', '🛌', 'BEDTIME'),
];

const _hourClocks = <String>[
  '🕐',
  '🕑',
  '🕒',
  '🕓',
  '🕔',
  '🕕',
  '🕖',
  '🕗',
  '🕘',
  '🕙',
  '🕚',
  '🕛',
];

const _halfHourClocks = <String>[
  '🕜',
  '🕝',
  '🕞',
  '🕟',
  '🕠',
  '🕡',
  '🕢',
  '🕣',
  '🕤',
  '🕥',
  '🕦',
  '🕧',
];

class _NatureItem {
  const _NatureItem(
    this.emoji,
    this.name,
    this.clue,
    this.habitat,
  );
  final String emoji;
  final String name;
  final String clue;
  final String habitat;
}

const _natureItems = <_NatureItem>[
  _NatureItem(
      '🐫', 'camel', 'I store fat in my hump and need little water', 'desert'),
  _NatureItem('🐋', 'whale', 'I am a huge mammal that breathes air', 'ocean'),
  _NatureItem('🐸', 'frog', 'I have moist skin and can hop and swim', 'pond'),
  _NatureItem('🦉', 'owl', 'I hunt at night and have large eyes', 'forest'),
  _NatureItem('🐄', 'cow', 'I eat grass and give milk', 'farm'),
  _NatureItem(
      '🐝', 'bee', 'I collect nectar and help flowers make seeds', 'garden'),
  _NatureItem(
      '🐧', 'penguin', 'I am a bird that swims but cannot fly', 'polar ice'),
  _NatureItem('🐠', 'fish', 'I breathe with gills and have fins', 'ocean'),
  _NatureItem('🦋', 'butterfly', 'I begin life as a caterpillar', 'garden'),
  _NatureItem('🐒', 'monkey', 'I climb trees and use my hands', 'forest'),
  _NatureItem(
      '🦆', 'duck', 'I have webbed feet and waterproof feathers', 'pond'),
  _NatureItem('🐔', 'chicken', 'I have feathers and lay eggs', 'farm'),
  _NatureItem('🌵', 'cactus', 'My thick stem stores water', 'desert'),
  _NatureItem(
      '🌻', 'sunflower', 'I turn toward sunlight and make seeds', 'garden'),
];

class _ShapeItem {
  const _ShapeItem(this.emoji, this.name, this.sides, this.description);
  final String emoji;
  final String name;
  final int sides;
  final String description;
}

const _shapes = <_ShapeItem>[
  _ShapeItem('🔴', 'circle', 0, 'A circle is round and has no straight sides.'),
  _ShapeItem('🟦', 'square', 4, 'A square has four equal straight sides.'),
  _ShapeItem('🔺', 'triangle', 3, 'A triangle has three straight sides.'),
  _ShapeItem('🟩', 'rectangle', 4,
      'A rectangle has four sides and opposite sides match.'),
  _ShapeItem('⭐', 'star', 10, 'A five-point star has ten outside edges.'),
  _ShapeItem('🔷', 'diamond', 4, 'A diamond looks like a tilted square.'),
  _ShapeItem('⬡', 'hexagon', 6, 'A hexagon has six straight sides.'),
  _ShapeItem('🫥', 'oval', 0, 'An oval is round but stretched longer.'),
];

class _GrammarQuestion {
  const _GrammarQuestion({
    required this.emoji,
    required this.skill,
    required this.sentence,
    required this.prompt,
    required this.spokenPrompt,
    required this.answer,
    required this.distractorOne,
    required this.distractorTwo,
    required this.hint,
    required this.explanation,
  });
  final String emoji;
  final String skill;
  final String sentence;
  final String prompt;
  final String spokenPrompt;
  final String answer;
  final String distractorOne;
  final String distractorTwo;
  final String hint;
  final String explanation;
}

const _grammarQuestions = <_GrammarQuestion>[
  _GrammarQuestion(
      emoji: '🐶',
      skill: 'Parts of speech',
      sentence: 'The playful dog barked',
      prompt: 'Which word is the noun?',
      spokenPrompt:
          'In the sentence, the playful dog barked, which word names an animal?',
      answer: 'DOG',
      distractorOne: 'PLAYFUL',
      distractorTwo: 'BARKED',
      hint: 'A noun names a person, place, animal, or thing.',
      explanation: 'Dog is the noun.'),
  _GrammarQuestion(
      emoji: '🏃',
      skill: 'Parts of speech',
      sentence: 'Mia runs quickly',
      prompt: 'Which word is the verb?',
      spokenPrompt: 'In Mia runs quickly, which word shows the action?',
      answer: 'RUNS',
      distractorOne: 'MIA',
      distractorTwo: 'QUICKLY',
      hint: 'A verb shows an action or state.',
      explanation: 'Runs is the action verb.'),
  _GrammarQuestion(
      emoji: '🌺',
      skill: 'Adjectives',
      sentence: 'The red flower bloomed',
      prompt: 'Which word describes the flower?',
      spokenPrompt: 'Which word tells us more about the flower?',
      answer: 'RED',
      distractorOne: 'FLOWER',
      distractorTwo: 'BLOOMED',
      hint: 'An adjective describes a noun.',
      explanation: 'Red is the describing adjective.'),
  _GrammarQuestion(
      emoji: '🐢',
      skill: 'Adverbs',
      sentence: 'The turtle walked slowly',
      prompt: 'Which word tells how it walked?',
      spokenPrompt: 'Which word tells how the turtle walked?',
      answer: 'SLOWLY',
      distractorOne: 'TURTLE',
      distractorTwo: 'WALKED',
      hint: 'Many adverbs tell how an action happens.',
      explanation: 'Slowly tells how it walked.'),
  _GrammarQuestion(
      emoji: '👧',
      skill: 'Pronouns',
      sentence: 'Mia has a book. She reads it.',
      prompt: 'Which word replaces Mia?',
      spokenPrompt: 'Which pronoun replaces the name Mia?',
      answer: 'SHE',
      distractorOne: 'BOOK',
      distractorTwo: 'IT',
      hint: 'Use a pronoun instead of repeating a name.',
      explanation: 'She replaces Mia.'),
  _GrammarQuestion(
      emoji: '👦',
      skill: 'Subject-verb agreement',
      sentence: 'Sam ___ to school',
      prompt: 'Choose the correct verb.',
      spokenPrompt: 'Sam, blank, to school. Which verb agrees with Sam?',
      answer: 'WALKS',
      distractorOne: 'WALK',
      distractorTwo: 'WALKING',
      hint: 'A single person often takes a verb ending in s.',
      explanation: 'Sam walks to school.'),
  _GrammarQuestion(
      emoji: '👫',
      skill: 'Subject-verb agreement',
      sentence: 'The children ___ outside',
      prompt: 'Choose the correct verb.',
      spokenPrompt:
          'The children, blank, outside. Which verb agrees with children?',
      answer: 'PLAY',
      distractorOne: 'PLAYS',
      distractorTwo: 'PLAYING',
      hint: 'A plural subject uses play, without s.',
      explanation: 'The children play outside.'),
  _GrammarQuestion(
      emoji: '⏪',
      skill: 'Past tense',
      sentence: 'Yesterday we ___ football',
      prompt: 'Choose the past-tense verb.',
      spokenPrompt: 'Yesterday we blank football. Which word shows the past?',
      answer: 'PLAYED',
      distractorOne: 'PLAY',
      distractorTwo: 'WILL PLAY',
      hint: 'Yesterday tells us the action already happened.',
      explanation: 'Played is past tense.'),
  _GrammarQuestion(
      emoji: '⏩',
      skill: 'Future tense',
      sentence: 'Tomorrow I ___ my aunt',
      prompt: 'Choose the future-tense verb.',
      spokenPrompt: 'Tomorrow I blank my aunt. Which phrase shows the future?',
      answer: 'WILL VISIT',
      distractorOne: 'VISITED',
      distractorTwo: 'VISIT',
      hint: 'Will can show an action that has not happened yet.',
      explanation: 'Will visit is future tense.'),
  _GrammarQuestion(
      emoji: '❓',
      skill: 'Sentence types',
      sentence: 'Where is my pencil',
      prompt: 'Which punctuation mark belongs?',
      spokenPrompt: 'Where is my pencil? Which ending mark belongs?',
      answer: '?',
      distractorOne: '.',
      distractorTwo: '!',
      hint: 'A direct question ends with a question mark.',
      explanation: 'The sentence needs a question mark.'),
  _GrammarQuestion(
      emoji: '🎉',
      skill: 'Sentence types',
      sentence: 'What an amazing surprise',
      prompt: 'Which punctuation mark belongs?',
      spokenPrompt:
          'What an amazing surprise! Which ending mark shows excitement?',
      answer: '!',
      distractorOne: '.',
      distractorTwo: '?',
      hint: 'Strong excitement can end with an exclamation mark.',
      explanation: 'The sentence needs an exclamation mark.'),
  _GrammarQuestion(
      emoji: '📍',
      skill: 'Prepositions',
      sentence: 'The ball is under the table',
      prompt: 'Which word shows position?',
      spokenPrompt: 'Which word tells where the ball is?',
      answer: 'UNDER',
      distractorOne: 'BALL',
      distractorTwo: 'TABLE',
      hint: 'A preposition can show position.',
      explanation: 'Under shows the position.'),
  _GrammarQuestion(
      emoji: '🔗',
      skill: 'Conjunctions',
      sentence: 'I like apples ___ bananas',
      prompt: 'Which joining word fits?',
      spokenPrompt: 'I like apples, blank, bananas. Choose the joining word.',
      answer: 'AND',
      distractorOne: 'BUT',
      distractorTwo: 'BECAUSE',
      hint: 'Use and to join two things you like.',
      explanation: 'And joins apples and bananas.'),
  _GrammarQuestion(
      emoji: '🌧️',
      skill: 'Conjunctions',
      sentence: 'I took an umbrella ___ it was raining',
      prompt: 'Which joining word explains why?',
      spokenPrompt:
          'I took an umbrella, blank, it was raining. Which word gives the reason?',
      answer: 'BECAUSE',
      distractorOne: 'AND',
      distractorTwo: 'OR',
      hint: 'Because introduces a reason.',
      explanation: 'Because explains the reason.'),
  _GrammarQuestion(
      emoji: '📚',
      skill: 'Plural nouns',
      sentence: 'One story, two ___',
      prompt: 'Choose the correct plural.',
      spokenPrompt: 'One story, two what? Choose the plural form.',
      answer: 'STORIES',
      distractorOne: 'STORYS',
      distractorTwo: 'STORY',
      hint: 'Change consonant y to ies.',
      explanation: 'The plural of story is stories.'),
];

class _ScienceQuestion {
  const _ScienceQuestion({
    required this.emoji,
    required this.skill,
    required this.sceneLabel,
    required this.prompt,
    required this.spokenPrompt,
    required this.answer,
    required this.distractorOne,
    required this.distractorTwo,
    required this.hint,
    required this.explanation,
  });
  final String emoji;
  final String skill;
  final String sceneLabel;
  final String prompt;
  final String spokenPrompt;
  final String answer;
  final String distractorOne;
  final String distractorTwo;
  final String hint;
  final String explanation;
}

const _scienceQuestions = <_ScienceQuestion>[
  _ScienceQuestion(
      emoji: '🧊',
      skill: 'States of matter',
      sceneLabel: 'Ice warms in the sun',
      prompt: 'What change happens?',
      spokenPrompt: 'Ice warms in the sun. What happens to it?',
      answer: 'IT MELTS',
      distractorOne: 'IT FREEZES',
      distractorTwo: 'IT GROWS',
      hint: 'Heating changes solid ice into liquid water.',
      explanation: 'The ice melts into water.'),
  _ScienceQuestion(
      emoji: '💧',
      skill: 'States of matter',
      sceneLabel: 'Water goes into a freezer',
      prompt: 'What change happens?',
      spokenPrompt: 'Liquid water is placed in a freezer. What happens?',
      answer: 'IT FREEZES',
      distractorOne: 'IT MELTS',
      distractorTwo: 'IT BURNS',
      hint: 'Cooling water enough makes it solid.',
      explanation: 'The water freezes into ice.'),
  _ScienceQuestion(
      emoji: '💨',
      skill: 'States of matter',
      sceneLabel: 'Steam spreads through the air',
      prompt: 'Which state is steam?',
      spokenPrompt:
          'Steam spreads and fills space. Which state of matter is it?',
      answer: 'GAS',
      distractorOne: 'SOLID',
      distractorTwo: 'LIQUID',
      hint: 'A gas spreads to fill its container.',
      explanation: 'Steam is water vapour, a gas.'),
  _ScienceQuestion(
      emoji: '🧲',
      skill: 'Forces and magnets',
      sceneLabel: 'A magnet nears an iron nail',
      prompt: 'What will happen?',
      spokenPrompt: 'A magnet moves close to an iron nail. What will happen?',
      answer: 'THE NAIL IS ATTRACTED',
      distractorOne: 'THE NAIL MELTS',
      distractorTwo: 'NOTHING CAN MOVE',
      hint: 'Iron is attracted to a magnet.',
      explanation: 'The magnet attracts the iron nail.'),
  _ScienceQuestion(
      emoji: '🛤️',
      skill: 'Forces and motion',
      sceneLabel: 'A ball rolls down a slope',
      prompt: 'Which force pulls it downward?',
      spokenPrompt: 'Which force pulls the rolling ball toward Earth?',
      answer: 'GRAVITY',
      distractorOne: 'MAGNETISM',
      distractorTwo: 'ELECTRICITY',
      hint: 'This force pulls objects toward Earth.',
      explanation: 'Gravity pulls the ball downward.'),
  _ScienceQuestion(
      emoji: '💡',
      skill: 'Electric circuits',
      sceneLabel: 'Battery, wires and bulb form a closed loop',
      prompt: 'Why does the bulb light?',
      spokenPrompt: 'Why does a bulb light in a complete circuit?',
      answer: 'THE CIRCUIT IS CLOSED',
      distractorOne: 'THE WIRE IS CUT',
      distractorTwo: 'THERE IS NO BATTERY',
      hint: 'Electric current needs an unbroken path.',
      explanation: 'A closed circuit lets current flow.'),
  _ScienceQuestion(
      emoji: '🪝',
      skill: 'Simple machines',
      sceneLabel: 'A ramp helps load a heavy box',
      prompt: 'What simple machine is the ramp?',
      spokenPrompt: 'A ramp makes lifting easier. What simple machine is it?',
      answer: 'INCLINED PLANE',
      distractorOne: 'PULLEY',
      distractorTwo: 'LEVER',
      hint: 'It is a flat surface set at an angle.',
      explanation: 'A ramp is an inclined plane.'),
  _ScienceQuestion(
      emoji: '⚖️',
      skill: 'Simple machines',
      sceneLabel: 'A seesaw turns around a middle point',
      prompt: 'What simple machine is it?',
      spokenPrompt: 'A seesaw moves around a fixed middle point. What is it?',
      answer: 'LEVER',
      distractorOne: 'WHEEL',
      distractorTwo: 'SCREW',
      hint: 'A lever pivots around a fulcrum.',
      explanation: 'A seesaw is a lever.'),
  _ScienceQuestion(
      emoji: '🌱',
      skill: 'Plant science',
      sceneLabel: 'A plant stands near a sunny window',
      prompt: 'Why does it need light?',
      spokenPrompt: 'Why does a green plant need sunlight?',
      answer: 'TO MAKE FOOD',
      distractorOne: 'TO MAKE NOISE',
      distractorTwo: 'TO GROW METAL',
      hint: 'Plants use light during photosynthesis.',
      explanation: 'Plants use sunlight to make food.'),
  _ScienceQuestion(
      emoji: '🫗',
      skill: 'Human body',
      sceneLabel: 'We breathe in and out',
      prompt: 'Which organs help us breathe?',
      spokenPrompt: 'Which organs take oxygen from the air?',
      answer: 'LUNGS',
      distractorOne: 'BONES',
      distractorTwo: 'TEETH',
      hint: 'These organs are inside the chest.',
      explanation: 'Our lungs help us breathe.'),
  _ScienceQuestion(
      emoji: '🦴',
      skill: 'Human body',
      sceneLabel: 'The skeleton supports the body',
      prompt: 'What protects the brain?',
      spokenPrompt: 'Which bone structure protects the brain?',
      answer: 'SKULL',
      distractorOne: 'RIBS',
      distractorTwo: 'SPINE',
      hint: 'It is the hard case around the head.',
      explanation: 'The skull protects the brain.'),
  _ScienceQuestion(
      emoji: '🌑',
      skill: 'Earth and space',
      sceneLabel: 'The Moon seems bright at night',
      prompt: 'Where does moonlight come from?',
      spokenPrompt: 'The Moon does not make its own light. Why can we see it?',
      answer: 'IT REFLECTS SUNLIGHT',
      distractorOne: 'IT IS ON FIRE',
      distractorTwo: 'STARS LIGHT IT',
      hint: 'Light from the Sun bounces off the Moon.',
      explanation: 'The Moon reflects sunlight.'),
  _ScienceQuestion(
      emoji: '🌍',
      skill: 'Earth and space',
      sceneLabel: 'Day changes into night',
      prompt: 'What causes day and night?',
      spokenPrompt: 'What movement of Earth causes day and night?',
      answer: 'EARTH ROTATES',
      distractorOne: 'EARTH STOPS',
      distractorTwo: 'THE MOON MELTS',
      hint: 'Earth spins once about every twenty-four hours.',
      explanation: 'Earth rotating causes day and night.'),
  _ScienceQuestion(
      emoji: '🧽',
      skill: 'Materials',
      sceneLabel: 'A raincoat must keep water out',
      prompt: 'Which material property helps?',
      spokenPrompt: 'Which property should raincoat material have?',
      answer: 'WATERPROOF',
      distractorOne: 'ABSORBENT',
      distractorTwo: 'MAGNETIC',
      hint: 'Water should not pass through it.',
      explanation: 'A raincoat needs waterproof material.'),
  _ScienceQuestion(
      emoji: '🌊',
      skill: 'Environment',
      sceneLabel: 'Plastic floats in the ocean',
      prompt: 'What is the safest action?',
      spokenPrompt: 'What should we do to reduce plastic pollution?',
      answer: 'REUSE AND RECYCLE',
      distractorOne: 'THROW MORE AWAY',
      distractorTwo: 'BURN IT OUTSIDE',
      hint: 'Reduce waste and keep it out of nature.',
      explanation: 'Reusing and recycling reduces plastic waste.'),
];

class _DirectionItem {
  const _DirectionItem(this.name, this.arrow);
  final String name;
  final String arrow;
}

const _directions = <_DirectionItem>[
  _DirectionItem('NORTH', '⬆️'),
  _DirectionItem('EAST', '➡️'),
  _DirectionItem('SOUTH', '⬇️'),
  _DirectionItem('WEST', '⬅️'),
];
