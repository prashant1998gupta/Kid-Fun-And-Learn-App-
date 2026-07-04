import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../settings/settings_controller.dart';
import '../logic/stack_merge_engine.dart';
import '../mini_games_controller.dart';
import '../widgets/game_tutorial.dart';
import '../widgets/mini_game_widgets.dart';

class StackMergeGame extends ConsumerStatefulWidget {
  const StackMergeGame({super.key});

  @override
  ConsumerState<StackMergeGame> createState() => _StackMergeGameState();
}

class _StackMergeGameState extends ConsumerState<StackMergeGame> {
  static const _columns = 5;
  late StackMergeEngine _engine;
  final MiniGameDifficulty _difficulty = MiniGameDifficulty.easy;
  MiniGamePlayMode _playMode = MiniGamePlayMode.solo;
  int _currentPlayer = 1;
  bool _resultRecorded = false;
  double _assistLevel = 0;
  int _activeValue = 2;
  int _dropColumn = 2;
  List<int> _preview = const [2, 4];
  bool _dropping = false;
  String _message = 'Match equal blocks to start a chain!';
  final _random = math.Random();
  final _celebration = CelebrationController();

  static const _valueColors = {
    2: Color(0xFFE74C3C),
    4: Color(0xFFF39C12),
    8: Color(0xFFF1C40F),
    16: Color(0xFF2ECC71),
    32: Color(0xFF3498DB),
    64: Color(0xFF9B59B6),
    128: Color(0xFFE91E63),
    256: Color(0xFF00CEC9),
    512: Color(0xFFFDCB6E),
    1024: Color(0xFF6C5CE7),
    2048: Color(0xFFE17055),
  };

  @override
  void initState() {
    super.initState();
    _engine = StackMergeEngine(columnCount: _columns);
    _restart();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showFirstPlayTutorial(
          context,
          ref,
          gameId: 'stack-merge',
          instruction: 'Tap a column to drop your block. Drop two of the same '
              'to join them!',
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  int get _maxRows => switch (_difficulty) {
        MiniGameDifficulty.easy => 9,
        MiniGameDifficulty.normal => 8,
        MiniGameDifficulty.challenge => 7,
      };

  int get _bestColumn {
    if (_activeValue != StackMergeEngine.rainbow) {
      for (var i = 0; i < _engine.columns.length; i++) {
        final column = _engine.columns[i];
        if (column.isNotEmpty && column.last == _activeValue) return i;
      }
    }
    var best = 0;
    for (var i = 1; i < _engine.columns.length; i++) {
      if (_engine.columns[i].length < _engine.columns[best].length) best = i;
    }
    return best;
  }

  int _nextRandomValue() {
    if (_assistLevel >= 0.55) {
      final helpful = _engine.columns
          .where((column) => column.isNotEmpty)
          .map((column) => column.last)
          .where((value) => value > 0)
          .toList();
      if (helpful.isNotEmpty) return helpful[_random.nextInt(helpful.length)];
    }
    // Rainbow helper appears more often on Easy (it's a rescue, not a puzzle).
    final rainbowChance = _difficulty == MiniGameDifficulty.easy ? 12 : 22;
    if (_random.nextInt(rainbowChance) == 0) return StackMergeEngine.rainbow;
    if (_difficulty == MiniGameDifficulty.challenge &&
        _random.nextInt(5) == 0) {
      return 8;
    }
    return _random.nextBool() ? 2 : 4;
  }

  void _restart() {
    setState(() {
      _engine = StackMergeEngine(columnCount: _columns, maxRows: _maxRows);
      _activeValue = _nextRandomValue();
      _preview = [_nextRandomValue(), _nextRandomValue()];
      _dropColumn = 2;
      _dropping = false;
      _message = 'Tap a column to drop your block!';
      _currentPlayer = 1;
      _resultRecorded = false;
      _assistLevel = 0;
      // Start with a clean board on Easy so kids aren't handed a mess; a small
      // head start on harder modes keeps them interesting.
      if (_difficulty != MiniGameDifficulty.easy) {
        for (var i = 0; i < 3; i++) {
          _engine.drop(_random.nextInt(_columns), _random.nextBool() ? 2 : 4);
        }
      }
    });
  }

  void _move(int delta) {
    if (_dropping) return;
    setState(() {
      _dropColumn = (_dropColumn + delta).clamp(0, _columns - 1);
    });
  }

  /// Tap a column to aim there and drop in one gesture — the most natural
  /// control for a young child (no cursor-nudging required).
  Future<void> _dropAt(int column) async {
    if (_dropping) return;
    setState(() => _dropColumn = column.clamp(0, _columns - 1));
    await _drop();
  }

  Future<void> _drop() async {
    if (_dropping) return;
    if (_engine.gameOver) _rescueTower();
    setState(() => _dropping = true);
    final reducedMotion = ref.read(reducedMotionProvider);
    if (!reducedMotion) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
    }

    final result = _engine.dropWithResult(_dropColumn, _activeValue);
    setState(() {
      _activeValue = _preview.first;
      _preview = [_preview.last, _nextRandomValue()];
      _dropping = false;
      if (result.mergeCount >= 2) {
        _message = result.mergeCount >= 3
            ? 'Firework chain x${result.mergeCount}! The rainbow is free!'
            : 'Rainbow puff! Chain x${result.mergeCount}!';
      } else if (result.mergeCount == 1) {
        _message = 'Pop! You made ${result.value}.';
      } else {
        _message = 'Set up two matching blocks.';
      }
      _assistLevel = result.mergeCount == 0
          ? (_assistLevel + 0.18).clamp(0, 1)
          : (_assistLevel - 0.3).clamp(0, 1);
    });

    if (result.mergeCount > 0) {
      AudioService.instance.playSfx(
        result.mergeCount >= 2 ? Sfx.celebration : Sfx.correct,
      );
      AudioService.instance.successHaptic();
      if (result.mergeCount >= 3) {
        _celebration.fireworks();
      } else {
        _celebration.celebrate(sound: false);
      }
    } else {
      AudioService.instance.playSfx(Sfx.tap);
    }
    if (_playMode == MiniGamePlayMode.together) {
      setState(() => _currentPlayer = _currentPlayer == 1 ? 2 : 1);
    }
    if (_engine.gameOver) _rescueTower();
    if (!_resultRecorded && _engine.highestTile >= 128) _recordResult();
  }

  void _recordResult() {
    if (_resultRecorded) return;
    _resultRecorded = true;
    showMiniGameReward(context, _engine.score);
    ref.read(miniGamesControllerProvider.notifier).recordResult(
      gameId: 'stack-merge',
      score: _engine.score,
      achievements: [
        if (_engine.highestTile >= 128) 'stack_128',
      ],
    );
  }

  void _rescueTower() {
    _recordResult();
    final cleared = _engine.rescueTallest(remove: 3);
    setState(() {
      _dropping = false;
      _message = _playMode == MiniGamePlayMode.creative
          ? 'Whoosh! More room to create!'
          : 'Rainbow rescue cleared $cleared blocks. Keep building!';
    });
    _celebration.celebrate(sound: false);
    AudioService.instance.playSfx(Sfx.magic);
    AudioService.instance.speak("Let's keep building to the moon!");
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
                MascotMessage(message: _message, icon: '🤖'),
                StoryGoalCard(
                  emoji: '🏗️🚀🌙',
                  goal: _playMode == MiniGamePlayMode.creative
                      ? 'Build anything—nothing can fail!'
                      : 'Free the rainbow and reach the moon!',
                  progress: (_engine.highestTile / 512).clamp(0, 1),
                  progressColor: const Color(0xFF00CEC9),
                ),
                const SizedBox(height: 5),
                Expanded(child: _gameArea()),
                _controls(),
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
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '🌈 Rainbow Rescue',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          Text(
            '⭐ ${_engine.score}',
            style: const TextStyle(
              color: Colors.yellow,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 6),
          GameCircleButton(
            icon: Icons.help_outline_rounded,
            tooltip: 'How to play',
            onTap: () => showMiniGameHelp(
              context,
              title: 'How to play Stack Merge',
              steps: const [
                'Tap a column to drop your block there.',
                'Drop two of the same to join them into a bigger one!',
                'Long chains give bigger scores and celebrations.',
                'A rainbow ★ block doubles the top block in its column.',
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardHeight = (constraints.maxHeight - 110).clamp(260.0, 430.0);
        final cellHeight = (boardHeight - 8) / _maxRows;
        return SingleChildScrollView(
          child: Column(
            children: [
              PlayModePicker(
                value: _playMode,
                showCreative: true,
                onChanged: (value) => setState(() {
                  _playMode = value;
                  _currentPlayer = 1;
                }),
              ),
              if (_playMode == MiniGamePlayMode.together) ...[
                const SizedBox(height: 5),
                PlayerTurnBadge(player: _currentPlayer),
              ],
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Next:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  for (final value in _preview)
                    Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: _tile(value, size: 34),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _dropAt((d.localPosition.dx / 52).floor()),
                child: Container(
                  width: 260,
                  height: boardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Stack(
                    children: [
                      for (var column = 0;
                          column < _engine.columns.length;
                          column++)
                        for (var row = 0;
                            row < _engine.columns[column].length;
                            row++)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 180),
                            left: column * 52.0 + 5,
                            bottom: row * cellHeight + 4,
                            child: _tile(
                              _engine.columns[column][row],
                              size: math.min(44, cellHeight - 3),
                            ),
                          ),
                      AnimatedPositioned(
                        duration: Duration(
                          milliseconds: _dropping ? 220 : 120,
                        ),
                        curve: Curves.easeIn,
                        left: _dropColumn * 52.0 + 5,
                        top: _dropping
                            ? boardHeight -
                                ((_engine.columns[_dropColumn].length + 1) *
                                    cellHeight)
                            : 7,
                        child: _tile(
                          _activeValue,
                          size: math.min(44, cellHeight - 3),
                        ),
                      ),
                      Positioned(
                        left: _bestColumn * 52.0 + 14,
                        top: 50,
                        child: IgnorePointer(
                          child: Text(
                            '👇',
                            style: TextStyle(
                              fontSize: 25,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(int value, {required double size}) {
    final rainbow = value == StackMergeEngine.rainbow;
    final colorBlind = ref.watch(settingsControllerProvider).colorBlindMode;
    const shapes = ['●', '■', '▲', '◆', '⬟', '✚', '✦'];
    final shape = value > 0
        ? shapes[((math.log(value) / math.ln2).round() - 1) % shapes.length]
        : '★';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: rainbow
            ? const LinearGradient(
                colors: [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                ],
              )
            : null,
        color: rainbow ? null : (_valueColors[value] ?? Colors.purple),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          rainbow ? '★' : (colorBlind ? '$shape\n$value' : '$value'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.37,
            shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _control(Icons.arrow_back_rounded, () => _move(-1)),
          const SizedBox(width: 20),
          _control(Icons.arrow_downward_rounded, _drop, emphasized: true),
          const SizedBox(width: 20),
          _control(Icons.arrow_forward_rounded, () => _move(1)),
          const SizedBox(width: 10),
          GameCircleButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Restart',
            onTap: _restart,
          ),
        ],
      ),
    );
  }

  Widget _control(
    IconData icon,
    VoidCallback onTap, {
    bool emphasized = false,
  }) {
    return BouncyButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: emphasized ? 28 : 22,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: emphasized ? const Color(0xFFFFD93D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppColors.primary, size: 28),
      ),
    );
  }
}
