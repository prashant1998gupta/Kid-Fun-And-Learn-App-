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

/// A pre-reader-friendly classification game. Every level contains several
/// short questions, and there are 50 progressively richer levels.
class ToySortGame extends ConsumerStatefulWidget {
  const ToySortGame({super.key});

  @override
  ConsumerState<ToySortGame> createState() => _ToySortGameState();
}

class _ToySortGameState extends ConsumerState<ToySortGame> {
  static const _gameId = 'toy-sort';
  final _celebration = CelebrationController();

  late int _level;
  late _SortPack _pack;
  late List<_SortItem> _deck;
  int _round = 0;
  int _score = 0;
  int _tries = 0;
  bool _locked = false;
  bool _complete = false;
  int _reaction = 0;
  String _message = 'Pip needs a sorting teacher!';
  LearningWorldItem? _reward;
  int _player = 1;

  bool get _coOp => ref.read(activeChildProvider)?.siblingCoopEnabled ?? false;

  int get _goal => 5 + ((_level - 1) ~/ 10).clamp(0, 4);
  _SortItem get _item => _deck[_round % _deck.length];
  bool get _teachPip => _round > 0 && _round % 3 == 2;

  @override
  void initState() {
    super.initState();
    _level = ref.read(miniGamesControllerProvider).learningLevels[_gameId] ?? 1;
    _loadLevel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showFirstPlayTutorial(
        context,
        ref,
        gameId: _gameId,
        instruction: 'Tap a basket, or drag the toy into the matching basket.',
        emoji: '🧸',
      );
      _speakPrompt();
    });
  }

  void _loadLevel() {
    _pack = _packs[(_level - 1) % _packs.length];
    final availableGroups = _level <= 8
        ? _pack.groups.take(2).map((group) => group.id).toSet()
        : _pack.groups.map((group) => group.id).toSet();
    _deck = _pack.items
        .where((item) => availableGroups.contains(item.group))
        .toList()
      ..shuffle(math.Random(_level * 7919));
    final recent = ref.read(miniGamesRepositoryProvider).recentQuestionIds(
          _gameId,
        );
    if (recent.isNotEmpty) {
      final recentSet = recent.toSet();
      _deck = [
        for (final item in _deck)
          if (!recentSet.contains(item.id)) item,
        for (final item in _deck)
          if (recentSet.contains(item.id)) item,
      ];
    }
    _round = 0;
    _score = 0;
    _tries = 0;
    _locked = false;
    _complete = false;
    _reward = null;
    _player = 1;
    _message = 'Look carefully. Where does it belong?';
  }

  void _speakPrompt() {
    if (_complete || !mounted) return;
    unawaited(
      ref.read(miniGamesRepositoryProvider).recordQuestionSeen(
            _gameId,
            _item.id,
          ),
    );
    final text = _teachPip
        ? 'Pip made a silly guess. Teach Pip where the ${_item.spokenName} belongs.'
        : 'Put the ${_item.spokenName} in the ${_group(_item.group).label} basket.';
    AudioService.instance.speak(text);
  }

  _SortGroup _group(String id) =>
      _pack.groups.firstWhere((group) => group.id == id);

  void _choose(String groupId) {
    if (_locked || _complete) return;
    if (groupId != _item.group) {
      setState(() {
        _tries++;
        _reaction++;
        _message = PraiseLines.nextRetry();
      });
      AudioService.instance.playSfx(Sfx.wrong);
      AudioService.instance.lightHaptic();
      AudioService.instance.speak(_message);
      return;
    }

    _locked = true;
    final taught = _teachPip;
    setState(() {
      _score += _tries == 0 ? 10 : 6;
      _reaction++;
      _message = taught
          ? 'You taught Pip! Pip knows it now!'
          : PraiseLines.nextSuccess();
    });
    _celebration.celebrate(sound: false);
    AudioService.instance.playSfx(Sfx.correct);
    AudioService.instance.successHaptic();
    AudioService.instance.speak(_message);

    Future<void>.delayed(const Duration(milliseconds: 720), () {
      if (!mounted) return;
      if (_round + 1 >= _goal) {
        _finishLevel();
      } else {
        setState(() {
          _round++;
          if (_coOp) _player = _player == 1 ? 2 : 1;
          _tries = 0;
          _locked = false;
          _message = _teachPip
              ? 'Pip has a silly answer. Can you teach Pip?'
              : 'Next toy! Find its basket.';
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
      _message = 'Sorting level complete! You are Pip\'s teacher!';
    });
    _celebration.fireworks();
    AudioService.instance.speak(
      'Wonderful sorting! You earned a ${reward.name} for Kid World.',
    );
    showMiniGameReward(context, _score);
    await ref.read(miniGamesControllerProvider.notifier).recordResult(
      gameId: _gameId,
      score: _score + _level,
      dailyProgress: _goal,
      completedLearningLevel: _level,
      learningWorldItem: reward.id,
      achievements: const ['toy_teacher'],
    );
  }

  void _nextLevel() {
    setState(() {
      if (_level < 50) _level++;
      _loadLevel();
    });
    _speakPrompt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CelebrationOverlay(
        controller: _celebration,
        child: AnimatedBackground(
          theme: WorldTheme.candy,
          child: SafeArea(
            child: Column(
              children: [
                _topBar(),
                MascotMessage(message: _message, icon: '🐧'),
                const SizedBox(height: 6),
                StoryGoalCard(
                  emoji: '🧸',
                  goal: 'Level $_level/50 • ${_pack.title}',
                  progress: _complete ? 1 : _round / _goal,
                  progressColor: const Color(0xFFFF7043),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _complete ? _completionCard() : _playArea(),
                ),
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
            child: Text('🧸 Toy Sort',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
          ),
          if (_coOp)
            Container(
              key: const ValueKey('toy-sort-coop-turn'),
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
    final groups = _level <= 8 ? _pack.groups.take(2).toList() : _pack.groups;
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
                  key: ValueKey('teach-$_round'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '🐧 Pip says: "Maybe ${_wrongGuess().label}?"  Teach Pip!',
                    style: const TextStyle(
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                _item.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Color(0x55000000), blurRadius: 4)],
                ),
              ),
              const SizedBox(height: 6),
              Draggable<String>(
                data: _item.id,
                feedback: Material(
                  color: Colors.transparent,
                  child: _toyCard(_item, size: 112),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: _toyCard(_item, size: 112),
                ),
                child: _toyCard(_item, size: 112),
              )
                  .animate(key: ValueKey('toy-${_item.id}-$_round-$_reaction'))
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 260.ms,
                  ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < groups.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _basket(groups[i])),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap a basket or drag the toy',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _SortGroup _wrongGuess() => _pack.groups.firstWhere(
        (group) => group.id != _item.group,
      );

  Widget _toyCard(_SortItem item, {required double size}) {
    final artSize = 68 * item.scale;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 5)),
        ],
      ),
      child: OpenMojiView(
        emoji: item.emoji,
        size: artSize,
        fallback: Text(item.emoji, style: TextStyle(fontSize: artSize * 0.8)),
      ),
    );
  }

  Widget _basket(_SortGroup group) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data == _item.id,
      onAcceptWithDetails: (_) => _choose(group.id),
      builder: (context, candidates, rejects) {
        final hovering = candidates.isNotEmpty;
        return Semantics(
          button: true,
          label: '${group.label} basket',
          child: GestureDetector(
            onTap: () => _choose(group.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 116,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hovering
                    ? group.color
                    : Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: group.color, width: hovering ? 5 : 3),
                boxShadow: [
                  BoxShadow(
                    color: group.color.withValues(alpha: 0.3),
                    blurRadius: hovering ? 18 : 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(group.emoji, style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 4),
                  FittedBox(
                    child: Text(
                      group.label,
                      style: const TextStyle(
                        color: AppColors.lightText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                'World reward!',
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
                key: const ValueKey('toy-sort-next-level'),
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

class _SortPack {
  const _SortPack({
    required this.title,
    required this.groups,
    required this.items,
  });
  final String title;
  final List<_SortGroup> groups;
  final List<_SortItem> items;
}

class _SortGroup {
  const _SortGroup(this.id, this.label, this.emoji, this.color);
  final String id;
  final String label;
  final String emoji;
  final Color color;
}

class _SortItem {
  const _SortItem(
    this.id,
    this.emoji,
    this.spokenName,
    this.group, {
    this.scale = 1,
  });
  final String id;
  final String emoji;
  final String spokenName;
  final String group;
  final double scale;
  String get prompt => 'Where does the $spokenName go?';
}

const _packs = <_SortPack>[
  _SortPack(
    title: 'Sort by color',
    groups: [
      _SortGroup('red', 'RED', '🔴', Color(0xFFE74C3C)),
      _SortGroup('yellow', 'YELLOW', '🟡', Color(0xFFF1C40F)),
      _SortGroup('green', 'GREEN', '🟢', Color(0xFF27AE60)),
    ],
    items: [
      _SortItem('red-apple', '🍎', 'red apple', 'red'),
      _SortItem('red-strawberry', '🍓', 'red strawberry', 'red'),
      _SortItem('red-ladybird', '🐞', 'red ladybird', 'red'),
      _SortItem('yellow-banana', '🍌', 'yellow banana', 'yellow'),
      _SortItem('yellow-chick', '🐥', 'yellow chick', 'yellow'),
      _SortItem('yellow-star', '⭐', 'yellow star', 'yellow'),
      _SortItem('green-frog', '🐸', 'green frog', 'green'),
      _SortItem('green-leaf', '🍃', 'green leaf', 'green'),
      _SortItem('green-broccoli', '🥦', 'green broccoli', 'green'),
    ],
  ),
  _SortPack(
    title: 'Sort into groups',
    groups: [
      _SortGroup('animal', 'ANIMALS', '🐾', Color(0xFF8E44AD)),
      _SortGroup('food', 'FOOD', '🍎', Color(0xFFE67E22)),
      _SortGroup('toy', 'TOYS', '🧸', Color(0xFF2980B9)),
    ],
    items: [
      _SortItem('animal-dog', '🐶', 'dog', 'animal'),
      _SortItem('animal-cat', '🐱', 'cat', 'animal'),
      _SortItem('animal-lion', '🦁', 'lion', 'animal'),
      _SortItem('food-apple', '🍎', 'apple', 'food'),
      _SortItem('food-carrot', '🥕', 'carrot', 'food'),
      _SortItem('food-banana', '🍌', 'banana', 'food'),
      _SortItem('toy-ball', '⚽', 'ball', 'toy'),
      _SortItem('toy-kite', '🪁', 'kite', 'toy'),
      _SortItem('toy-teddy', '🧸', 'teddy', 'toy'),
    ],
  ),
  _SortPack(
    title: 'Where do they live?',
    groups: [
      _SortGroup('land', 'LAND', '🌳', Color(0xFF27AE60)),
      _SortGroup('water', 'WATER', '🌊', Color(0xFF3498DB)),
      _SortGroup('sky', 'SKY', '☁️', Color(0xFF7F8CFF)),
    ],
    items: [
      _SortItem('land-dog', '🐶', 'dog', 'land'),
      _SortItem('land-elephant', '🐘', 'elephant', 'land'),
      _SortItem('land-lion', '🦁', 'lion', 'land'),
      _SortItem('water-fish', '🐟', 'fish', 'water'),
      _SortItem('water-whale', '🐋', 'whale', 'water'),
      _SortItem('water-octopus', '🐙', 'octopus', 'water'),
      _SortItem('sky-bird', '🐦', 'bird', 'sky'),
      _SortItem('sky-butterfly', '🦋', 'butterfly', 'sky'),
      _SortItem('sky-bee', '🐝', 'bee', 'sky'),
    ],
  ),
  _SortPack(
    title: 'Sort by size',
    groups: [
      _SortGroup('small', 'SMALL', '🐜', Color(0xFF00A896)),
      _SortGroup('big', 'BIG', '🐘', Color(0xFFFF6B6B)),
      _SortGroup('medium', 'MEDIUM', '🐶', Color(0xFFFFB703)),
    ],
    items: [
      _SortItem('small-ball', '⚽', 'small ball', 'small', scale: 0.62),
      _SortItem('small-apple', '🍎', 'small apple', 'small', scale: 0.62),
      _SortItem('small-fish', '🐟', 'small fish', 'small', scale: 0.62),
      _SortItem('big-ball', '⚽', 'big ball', 'big', scale: 1.15),
      _SortItem('big-apple', '🍎', 'big apple', 'big', scale: 1.15),
      _SortItem('big-fish', '🐟', 'big fish', 'big', scale: 1.15),
      _SortItem('medium-ball', '⚽', 'medium ball', 'medium'),
      _SortItem('medium-apple', '🍎', 'medium apple', 'medium'),
      _SortItem('medium-fish', '🐟', 'medium fish', 'medium'),
    ],
  ),
  _SortPack(
    title: 'Sort the shapes',
    groups: [
      _SortGroup('round', 'ROUND', '⚪', Color(0xFF9B59B6)),
      _SortGroup('pointy', 'POINTY', '⭐', Color(0xFFF39C12)),
      _SortGroup('long', 'LONG', '📏', Color(0xFF16A085)),
    ],
    items: [
      _SortItem('round-ball', '⚽', 'round ball', 'round'),
      _SortItem('round-orange', '🍊', 'round orange', 'round'),
      _SortItem('round-moon', '🌕', 'round moon', 'round'),
      _SortItem('pointy-star', '⭐', 'pointy star', 'pointy'),
      _SortItem('pointy-tree', '🎄', 'pointy tree', 'pointy'),
      _SortItem('pointy-kite', '🪁', 'pointy kite', 'pointy'),
      _SortItem('long-pencil', '✏️', 'long pencil', 'long'),
      _SortItem('long-banana', '🍌', 'long banana', 'long'),
      _SortItem('long-carrot', '🥕', 'long carrot', 'long'),
    ],
  ),
];
