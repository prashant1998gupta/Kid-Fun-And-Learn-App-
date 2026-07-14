import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/feedback_timing.dart';
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
  int _boardSession = 0;
  double _assistLevel = 0;
  int _activeValue = 2;
  int _dropColumn = 2;
  List<int> _preview = const [2, 4];
  bool _dropping = false;
  int _dropPulse = 0;
  int _mergePulse = 0;
  int _lastDropColumn = 2;
  int _lastDropRow = 0;
  int _lastMergeCount = 0;
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
      _boardSession++;
      _engine = StackMergeEngine(columnCount: _columns, maxRows: _maxRows);
      _activeValue = _nextRandomValue();
      _preview = [_nextRandomValue(), _nextRandomValue()];
      _dropColumn = 2;
      _dropping = false;
      _dropPulse = 0;
      _mergePulse = 0;
      _lastDropColumn = 2;
      _lastDropRow = 0;
      _lastMergeCount = 0;
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
    final session = _boardSession;
    setState(() => _dropping = true);
    final reducedMotion = ref.read(reducedMotionProvider);
    if (!reducedMotion) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted || session != _boardSession) return;
    }

    final droppedColumn = _dropColumn;
    final result = _engine.dropWithResult(droppedColumn, _activeValue);
    setState(() {
      _lastDropColumn = droppedColumn;
      _lastDropRow = math.max(0, _engine.columns[droppedColumn].length - 1);
      _lastMergeCount = result.mergeCount;
      _dropPulse++;
      if (result.mergeCount > 0) _mergePulse++;
      _activeValue = _preview.first;
      _preview = [_preview.last, _nextRandomValue()];
      _dropping = result.mergeCount > 0;
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
      await Future<void>.delayed(FeedbackTiming.successBeat);
      if (!mounted || session != _boardSession) return;
      setState(() => _dropping = false);
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxHeight < 620 || constraints.maxWidth < 340;
                final goal = _playMode == MiniGamePlayMode.creative
                    ? 'Build anything—nothing can fail!'
                    : 'Free the rainbow and reach the moon!';
                return Column(
                  children: [
                    _topBar(compact: compact),
                    if (compact)
                      _compactGoal(goal)
                    else ...[
                      MascotMessage(message: _message, icon: '🤖'),
                      StoryGoalCard(
                        emoji: '🏗️🚀🌙',
                        goal: goal,
                        progress: (_engine.highestTile / 512).clamp(0, 1),
                        progressColor: const Color(0xFF00CEC9),
                      ),
                    ],
                    SizedBox(height: compact ? 3 : 5),
                    Expanded(child: _gameArea(compact: compact)),
                    _controls(compact: compact),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar({required bool compact}) {
    return Padding(
      padding: EdgeInsets.all(compact ? 6 : AppSpacing.sm),
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

  Widget _compactGoal(String goal) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🏗️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              goal,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.lightText,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: LinearProgressIndicator(
              value: (_engine.highestTile / 512).clamp(0, 1),
              minHeight: 5,
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF00CEC9),
              backgroundColor: Colors.black.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameArea({required bool compact}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final reserved = compact ? 78.0 : 110.0;
        final minBoard = compact ? 150.0 : 260.0;
        final boardHeight =
            (constraints.maxHeight - reserved).clamp(minBoard, 430.0);
        final cellHeight = (boardHeight - 8) / _maxRows;
        final availableWidth = math.max(0.0, constraints.maxWidth - 24);
        final boardWidth = math.min(260.0, availableWidth);
        final columnWidth = boardWidth / _columns;
        final tileSize =
            math.max(16.0, math.min(columnWidth - 8, cellHeight - 3));
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
                onTapDown: (d) =>
                    _dropAt((d.localPosition.dx / columnWidth).floor()),
                child: Container(
                  width: boardWidth,
                  height: boardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        _columnGlow(columnWidth),
                        _landingShadow(cellHeight, columnWidth),
                        for (var column = 0;
                            column < _engine.columns.length;
                            column++)
                          for (var row = 0;
                              row < _engine.columns[column].length;
                              row++)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 180),
                              left: column * columnWidth +
                                  (columnWidth - tileSize) / 2,
                              bottom: row * cellHeight + 4,
                              child: _tile(
                                _engine.columns[column][row],
                                size: tileSize,
                                bounceKey: column == _lastDropColumn &&
                                        row == _lastDropRow
                                    ? _dropPulse
                                    : null,
                              ),
                            ),
                        _mergeBurst(cellHeight, columnWidth, tileSize),
                        AnimatedPositioned(
                          duration: Duration(
                            milliseconds: _dropping ? 260 : 140,
                          ),
                          curve: _dropping
                              ? Curves.easeInCubic
                              : Curves.easeOutBack,
                          left: _dropColumn * columnWidth +
                              (columnWidth - tileSize) / 2,
                          top: _activeTop(boardHeight, cellHeight, tileSize),
                          child: _tile(
                            _activeValue,
                            size: tileSize,
                            floating: true,
                          ),
                        ),
                        Positioned(
                          left: _bestColumn * columnWidth +
                              (columnWidth / 2) -
                              12,
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
              ),
            ],
          ),
        );
      },
    );
  }

  double _activeTop(double boardHeight, double cellHeight, double tileSize) {
    if (!_dropping) return 7;
    final targetTop =
        boardHeight - ((_engine.columns[_dropColumn].length + 1) * cellHeight);
    return targetTop.clamp(7.0, boardHeight - tileSize - 4);
  }

  Widget _columnGlow(double columnWidth) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 150),
      left: _dropColumn * columnWidth + 2,
      top: 0,
      bottom: 0,
      width: math.max(24, columnWidth - 4),
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.22),
                const Color(0xFFFFD93D).withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _landingShadow(double cellHeight, double columnWidth) {
    final stackHeight = _engine.columns[_dropColumn].length;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 160),
      left: _dropColumn * columnWidth + columnWidth * 0.25,
      bottom: stackHeight * cellHeight + 5,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: math.max(18, columnWidth * (_dropping ? 0.6 : 0.5)),
          height: _dropping ? 10 : 7,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: _dropping ? 0.24 : 0.14),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }

  Widget _mergeBurst(double cellHeight, double columnWidth, double tileSize) {
    if (_lastMergeCount == 0) return const SizedBox.shrink();
    final tileLeft = _lastDropColumn * columnWidth +
        (columnWidth - tileSize) / 2 +
        tileSize / 2;
    return Positioned(
      key: ValueKey(_mergePulse),
      left: tileLeft - 42,
      bottom: _lastDropRow * cellHeight + 4 + tileSize / 2 - 42,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 620),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) {
            return Opacity(
              opacity: (1 - t).clamp(0, 1),
              child: Transform.scale(
                scale: 0.45 + t * 1.3,
                child: child,
              ),
            );
          },
          child: SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD93D),
                      width: 4,
                    ),
                  ),
                ),
                for (var i = 0; i < 8; i++)
                  Transform.translate(
                    offset: Offset(
                      math.cos(i * math.pi / 4) * 30,
                      math.sin(i * math.pi / 4) * 30,
                    ),
                    child: const Text('✨', style: TextStyle(fontSize: 14)),
                  ),
                Text(
                  _lastMergeCount >= 2 ? 'x$_lastMergeCount' : 'POP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(
    int value, {
    required double size,
    int? bounceKey,
    bool floating = false,
  }) {
    final rainbow = value == StackMergeEngine.rainbow;
    final colorBlind = ref.watch(settingsControllerProvider).colorBlindMode;
    const shapes = ['●', '■', '▲', '◆', '⬟', '✚', '✦'];
    final shape = value > 0
        ? shapes[((math.log(value) / math.ln2).round() - 1) % shapes.length]
        : '★';
    final tile = Container(
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
        border: floating
            ? Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: floating ? 0.32 : 0.2),
            blurRadius: floating ? 10 : 4,
            offset: Offset(0, floating ? 5 : 2),
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
    if (bounceKey == null) return tile;
    return TweenAnimationBuilder<double>(
      key: ValueKey('stack-bounce-$bounceKey-$value'),
      tween: Tween(begin: 1.18, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: tile,
    );
  }

  Widget _controls({required bool compact}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, compact ? 3 : 6, 12, compact ? 8 : 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _control(Icons.arrow_back_rounded, () => _move(-1), compact: compact),
          SizedBox(width: compact ? 6 : 8),
          _control(Icons.arrow_downward_rounded, _drop,
              emphasized: true, compact: compact),
          SizedBox(width: compact ? 6 : 8),
          _control(Icons.arrow_forward_rounded, () => _move(1),
              compact: compact),
          SizedBox(width: compact ? 6 : 8),
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
    required bool compact,
  }) {
    return BouncyButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? (emphasized ? 16 : 13) : (emphasized ? 20 : 16),
          vertical: compact ? 10 : 13,
        ),
        decoration: BoxDecoration(
          color: emphasized ? const Color(0xFFFFD93D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppColors.primary, size: compact ? 24 : 28),
      ),
    );
  }
}
