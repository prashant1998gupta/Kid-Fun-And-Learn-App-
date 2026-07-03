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
import '../widgets/mini_game_widgets.dart';

class StackMergeGame extends ConsumerStatefulWidget {
  const StackMergeGame({super.key});

  @override
  ConsumerState<StackMergeGame> createState() => _StackMergeGameState();
}

class _StackMergeGameState extends ConsumerState<StackMergeGame> {
  static const _columns = 5;
  late StackMergeEngine _engine;
  MiniGameDifficulty _difficulty = MiniGameDifficulty.normal;
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

  int _nextRandomValue() {
    if (_random.nextInt(20) == 0) return StackMergeEngine.rainbow;
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
      _message = 'Aim, drop, and build a giant merge!';
      for (var i = 0; i < 3; i++) {
        _engine.drop(_random.nextInt(_columns), _random.nextBool() ? 2 : 4);
      }
    });
  }

  void _changeDifficulty(MiniGameDifficulty value) {
    _difficulty = value;
    _restart();
  }

  void _move(int delta) {
    if (_dropping || _engine.gameOver) return;
    setState(() {
      _dropColumn = (_dropColumn + delta).clamp(0, _columns - 1);
    });
  }

  Future<void> _drop() async {
    if (_dropping || _engine.gameOver) return;
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
        _message = 'Chain x${result.mergeCount}! Huge merge!';
      } else if (result.mergeCount == 1) {
        _message = 'Pop! You made ${result.value}.';
      } else {
        _message = 'Set up two matching blocks.';
      }
    });

    if (result.mergeCount > 0) {
      AudioService.instance.playSfx(
        result.mergeCount >= 2 ? Sfx.celebration : Sfx.correct,
      );
      AudioService.instance.successHaptic();
      if (result.mergeCount >= 2) _celebration.celebrate(sound: false);
    } else {
      AudioService.instance.playSfx(Sfx.tap);
    }
    if (_engine.gameOver) _endGame();
  }

  void _endGame() {
    AudioService.instance
        .speak('Great stacking! Your score is ${_engine.score}.');
    ref.read(miniGamesControllerProvider.notifier).recordResult(
      gameId: 'stack-merge',
      score: _engine.score,
      achievements: [
        if (_engine.highestTile >= 128) 'stack_128',
      ],
    );
    setState(() => _message = 'The tower is full. Great stacking!');
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
              '🔢 Stack Merge',
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
                'Move the falling block above a column.',
                'Drop equal numbers together to merge them.',
                'Chain merges give bigger scores and celebrations.',
                'A rainbow block doubles the top block in its column.',
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
              DifficultyPicker(
                value: _difficulty,
                onChanged: _changeDifficulty,
              ),
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
              if (_engine.gameOver)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: FilledButton.icon(
                    onPressed: _restart,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Play again'),
                  ),
                ),
              Container(
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
                  ],
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
          rainbow ? '★' : '$value',
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
