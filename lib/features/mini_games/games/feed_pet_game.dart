import 'dart:async';
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
import '../data/mini_games_repository.dart';
import '../mini_games_controller.dart';
import '../widgets/game_tutorial.dart';
import '../widgets/mini_game_widgets.dart';
import '../../profiles/profiles_controller.dart';

/// Counting, quantity and food-recognition practice for preschool learners.
/// Children can hear every prompt and can never lose the round.
class FeedPetGame extends ConsumerStatefulWidget {
  const FeedPetGame({super.key});

  @override
  ConsumerState<FeedPetGame> createState() => _FeedPetGameState();
}

class _FeedPetGameState extends ConsumerState<FeedPetGame> {
  static const _gameId = 'feed-the-pet';
  final _celebration = CelebrationController();

  late int _level;
  late List<int> _roundSeeds;
  int _round = 0;
  int _fed = 0;
  int _score = 0;
  int _mistakes = 0;
  int _reaction = 0;
  bool _locked = false;
  bool _complete = false;
  String _message = 'A hungry friend is waiting!';
  LearningWorldItem? _reward;
  int _player = 1;

  bool get _coOp => ref.read(activeChildProvider)?.siblingCoopEnabled ?? false;

  static const _roundsPerLevel = 5;
  int get _maxCount => switch (_level) {
        <= 5 => 3,
        <= 15 => 5,
        <= 30 => 7,
        _ => 10,
      };
  int get _roundSeed =>
      _roundSeeds.isEmpty ? _round : _roundSeeds[_round % _roundSeeds.length];
  int get _wanted => _wantedForSeed(_roundSeed);
  _Food get _target => _targetForSeed(_roundSeed);
  bool get _teachPip => _round == 2 || _round == 4;

  @override
  void initState() {
    super.initState();
    _level = ref.read(miniGamesControllerProvider).learningLevels[_gameId] ?? 1;
    _prepareRoundSeeds();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showFirstPlayTutorial(
        context,
        ref,
        gameId: _gameId,
        instruction:
            'Listen, then tap the right food the right number of times.',
        emoji: '👆',
      );
      _speakPrompt();
    });
  }

  List<_Food> get _choices {
    final result = <_Food>[_target];
    var cursor =
        (_foods.indexOf(_target) + _level + _roundSeed + 1) % _foods.length;
    while (result.length < 3) {
      final candidate = _foods[cursor % _foods.length];
      if (!result.contains(candidate)) result.add(candidate);
      cursor++;
    }
    result.shuffle(math.Random(_level * 1009 + _roundSeed));
    return result;
  }

  int _wantedForSeed(int seed) => 1 + ((_level * 3 + seed * 2) % _maxCount);

  _Food _targetForSeed(int seed) =>
      _foods[(_level * 5 + seed * 3) % _foods.length];

  String _questionIdForSeed(int seed) =>
      '${_targetForSeed(seed).name}|${_wantedForSeed(seed)}';

  void _prepareRoundSeeds() {
    _roundSeeds = ref.read(miniGamesRepositoryProvider).freshQuestionSeeds(
          gameId: _gameId,
          count: _roundsPerLevel,
          questionIdForSeed: _questionIdForSeed,
        );
  }

  String get _prompt => _level >= 11
      ? 'Feed $_wanted ${_target.color} ${_plural(_target.name, _wanted)}'
      : 'Feed $_wanted ${_plural(_target.name, _wanted)}';

  String _plural(String name, int count) {
    if (count == 1) return name;
    if (name.endsWith('y')) return '${name.substring(0, name.length - 1)}ies';
    return '${name}s';
  }

  void _speakPrompt() {
    if (_complete || !mounted) return;
    unawaited(
      ref.read(miniGamesRepositoryProvider).recordQuestionSeen(
            _gameId,
            _questionIdForSeed(_roundSeed),
          ),
    );
    final countLine = [for (var i = 1; i <= _wanted; i++) '$i'].join(', ');
    final text = _teachPip
        ? 'Pip counted ${_pipGuess()}. Pip is being silly! Please feed $_wanted ${_plural(_target.name, _wanted)}.'
        : 'Please feed $_wanted ${_plural(_target.name, _wanted)}. Count $countLine.';
    AudioService.instance.speak(text);
  }

  int _pipGuess() =>
      _wanted == _maxCount ? math.max(1, _wanted - 1) : _wanted + 1;

  void _tapFood(_Food food) {
    if (_locked || _complete) return;
    if (food != _target) {
      setState(() {
        _mistakes++;
        _reaction++;
        _message = 'Oops! The pet asked for ${_plural(_target.name, 2)}.';
      });
      AudioService.instance.playSfx(Sfx.wrong);
      AudioService.instance.lightHaptic();
      AudioService.instance.speak(_message);
      return;
    }

    setState(() {
      _fed++;
      _reaction++;
      _message = _fed < _wanted
          ? '$_fed! Keep counting…'
          : 'Yum! You counted $_wanted!';
    });
    AudioService.instance.playSfx(Sfx.pop);
    AudioService.instance.lightHaptic();
    if (_fed == _wanted) _correctRound();
  }

  void _removeOne() {
    if (_locked || _fed == 0) return;
    setState(() => _fed--);
  }

  void _correctRound() {
    _locked = true;
    setState(() {
      _score += _mistakes == 0 ? 10 : 7;
      _message = _teachPip
          ? 'You fixed Pip\'s counting! Brilliant teacher!'
          : PraiseLines.nextRescue();
    });
    _celebration.celebrate(sound: false);
    AudioService.instance.playSfx(Sfx.correct);
    AudioService.instance.successHaptic();
    AudioService.instance.speak(_message);

    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      if (_round + 1 >= _roundsPerLevel) {
        _finishLevel();
      } else {
        setState(() {
          _round++;
          if (_coOp) _player = _player == 1 ? 2 : 1;
          _fed = 0;
          _mistakes = 0;
          _locked = false;
          _message = _teachPip
              ? 'Pip needs your counting help!'
              : 'The pet would like another snack!';
        });
        _speakPrompt();
      }
    });
  }

  Future<void> _finishLevel() async {
    final reward = LearningWorldCatalog.rewardFor(_gameId, _level);
    setState(() {
      _complete = true;
      _reward = reward;
      _message = 'Full tummy and five smart counting rounds!';
    });
    _celebration.fireworks();
    AudioService.instance.speak(
      'Amazing counting! You earned a ${reward.name} for Kid World.',
    );
    showMiniGameReward(context, _score);
    await ref.read(miniGamesControllerProvider.notifier).recordResult(
      gameId: _gameId,
      score: _score + _level,
      dailyProgress: _roundsPerLevel,
      completedLearningLevel: _level,
      learningWorldItem: reward.id,
      achievements: const ['pet_feeder'],
    );
  }

  void _nextLevel() {
    setState(() {
      if (_level < 50) _level++;
      _prepareRoundSeeds();
      _round = 0;
      _fed = 0;
      _score = 0;
      _mistakes = 0;
      _locked = false;
      _complete = false;
      _reward = null;
      _message = 'A new counting picnic begins!';
      _player = 1;
    });
    _speakPrompt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CelebrationOverlay(
        controller: _celebration,
        child: AnimatedBackground(
          theme: WorldTheme.jungle,
          child: SafeArea(
            child: Column(
              children: [
                _topBar(),
                MascotMessage(message: _message, icon: '🐶'),
                const SizedBox(height: 6),
                StoryGoalCard(
                  emoji: '🥣',
                  goal: 'Level $_level/50 • Count 1 to $_maxCount',
                  progress: _complete ? 1 : _round / _roundsPerLevel,
                  progressColor: const Color(0xFF00B894),
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
          const Expanded(
            child: Text(
              '🥣 Feed the Pet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (_coOp)
            Container(
              key: const ValueKey('feed-pet-coop-turn'),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text('P$_player 👋',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w900)),
            ),
          if (_coOp) const SizedBox(width: 6),
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
    final choices = _choices;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_teachPip)
                Container(
                  key: ValueKey('pip-count-$_round'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '🐧 Pip says "${_pipGuess()}". Is Pip right?',
                    style: const TextStyle(
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              Text(
                _prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Color(0x55000000), blurRadius: 4)],
                ),
              ),
              _petAndBowl(),
              Row(
                children: [
                  for (var i = 0; i < choices.length; i++) ...[
                    if (i > 0) const SizedBox(width: 9),
                    Expanded(child: _foodButton(choices[i])),
                  ],
                ],
              ),
              const Text(
                'Tap the food to count it into the bowl',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _petAndBowl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OpenMojiView(
          key: ValueKey('pet-$_reaction'),
          emoji: '🐶',
          size: 90,
          fallback: const Text('🐶', style: TextStyle(fontSize: 76)),
        ).animate(key: ValueKey('pet-bounce-$_reaction')).scaleXY(
            begin: 0.88, end: 1, duration: 260.ms, curve: Curves.elasticOut),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _removeOne,
          child: Container(
            width: 150,
            constraints: const BoxConstraints(minHeight: 104),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF00B894), width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🥣', style: TextStyle(fontSize: 34)),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 1,
                  runSpacing: 1,
                  children: [
                    for (var i = 0; i < _fed; i++)
                      Text(_target.emoji, style: const TextStyle(fontSize: 20)),
                  ],
                ),
                Text(
                  '$_fed / $_wanted',
                  style: const TextStyle(
                    color: AppColors.lightText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _foodButton(_Food food) {
    final target = food == _target;
    return Semantics(
      button: true,
      label: food.name,
      child: InkWell(
        key: ValueKey('food-${food.name}'),
        borderRadius: BorderRadius.circular(24),
        onTap: () => _tapFood(food),
        child: Container(
          height: 112,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 9,
                  offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OpenMojiView(
                emoji: food.emoji,
                size: 58,
                fallback:
                    Text(food.emoji, style: const TextStyle(fontSize: 48)),
              ),
              Text(
                food.name.toUpperCase(),
                maxLines: 1,
                style: TextStyle(
                  color: target && _fed > 0
                      ? const Color(0xFF00796B)
                      : AppColors.lightText,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
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
              const Text(
                'Counting reward!',
                style: TextStyle(
                  color: AppColors.lightText,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              OpenMojiView(
                emoji: reward.emoji,
                size: 82,
                fallback:
                    Text(reward.emoji, style: const TextStyle(fontSize: 70)),
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
                key: const ValueKey('feed-pet-next-level'),
                onPressed: _nextLevel,
                icon: const Icon(Icons.arrow_forward_rounded),
                label:
                    Text(_level >= 50 ? 'Play again' : 'Level ${_level + 1}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Food {
  const _Food(this.emoji, this.name, this.color);
  final String emoji;
  final String name;
  final String color;
}

const _foods = <_Food>[
  _Food('🍎', 'apple', 'red'),
  _Food('🍌', 'banana', 'yellow'),
  _Food('🥕', 'carrot', 'orange'),
  _Food('🍓', 'strawberry', 'red'),
  _Food('🫐', 'blueberry', 'blue'),
  _Food('🍇', 'grape', 'purple'),
  _Food('🍊', 'orange', 'orange'),
  _Food('🥦', 'broccoli', 'green'),
  _Food('🍉', 'watermelon', 'green'),
  _Food('🥝', 'kiwi', 'green'),
  _Food('🫛', 'pea', 'green'),
  _Food('🍐', 'pear', 'green'),
];
