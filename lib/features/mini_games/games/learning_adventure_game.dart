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
}

extension LearningAdventureTypeData on LearningAdventureType {
  String get id => switch (this) {
        LearningAdventureType.soundSafari => 'sound-safari',
        LearningAdventureType.numberGarden => 'number-garden',
        LearningAdventureType.storyTrain => 'story-train',
        LearningAdventureType.letterBakery => 'letter-bakery',
        LearningAdventureType.cleanRoom => 'clean-room-helper',
      };

  String get title => switch (this) {
        LearningAdventureType.soundSafari => 'Sound Safari',
        LearningAdventureType.numberGarden => 'Number Garden',
        LearningAdventureType.storyTrain => 'Story Train',
        LearningAdventureType.letterBakery => 'Letter Bakery',
        LearningAdventureType.cleanRoom => 'Clean Room Helper',
      };

  String get icon => switch (this) {
        LearningAdventureType.soundSafari => '🦁',
        LearningAdventureType.numberGarden => '🌻',
        LearningAdventureType.storyTrain => '🚂',
        LearningAdventureType.letterBakery => '🥐',
        LearningAdventureType.cleanRoom => '🧹',
      };

  String get mascot => switch (this) {
        LearningAdventureType.soundSafari => '🦉',
        LearningAdventureType.numberGarden => '🐝',
        LearningAdventureType.storyTrain => '🐼',
        LearningAdventureType.letterBakery => '🧑‍🍳',
        LearningAdventureType.cleanRoom => '🐧',
      };

  String get achievementId => switch (this) {
        LearningAdventureType.soundSafari => 'sound_scout',
        LearningAdventureType.numberGarden => 'number_gardener',
        LearningAdventureType.storyTrain => 'story_conductor',
        LearningAdventureType.letterBakery => 'letter_baker',
        LearningAdventureType.cleanRoom => 'tidy_helper',
      };

  WorldTheme get worldTheme => switch (this) {
        LearningAdventureType.soundSafari => WorldTheme.jungle,
        LearningAdventureType.numberGarden => WorldTheme.sunrise,
        LearningAdventureType.storyTrain => WorldTheme.ocean,
        LearningAdventureType.letterBakery => WorldTheme.candy,
        LearningAdventureType.cleanRoom => WorldTheme.aurora,
      };

  Color get accent => switch (this) {
        LearningAdventureType.soundSafari => const Color(0xFF00A878),
        LearningAdventureType.numberGarden => const Color(0xFFFFB000),
        LearningAdventureType.storyTrain => const Color(0xFF3D7EFF),
        LearningAdventureType.letterBakery => const Color(0xFFE84393),
        LearningAdventureType.cleanRoom => const Color(0xFF7C5CE7),
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

/// Shared no-fail engine for five preschool learning adventures.
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
