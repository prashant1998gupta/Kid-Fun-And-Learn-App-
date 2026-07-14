import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../mini_games_controller.dart';
import '../widgets/game_tutorial.dart';
import '../widgets/mini_game_widgets.dart';

class InfinityLoopGame extends ConsumerStatefulWidget {
  const InfinityLoopGame({super.key});

  @override
  ConsumerState<InfinityLoopGame> createState() => _InfinityLoopGameState();
}

class _InfinityLoopGameState extends ConsumerState<InfinityLoopGame> {
  late List<List<_HexTile>> _grid;
  int _adaptiveTier = 0;
  bool _strongFinish = false;
  MiniGamePlayMode _playMode = MiniGamePlayMode.solo;
  int _currentPlayer = 1;
  bool _won = false;
  bool _usedHint = false;
  int _moves = 0;
  int _level = 1;
  int _optimalMoves = 0;
  // Dynamic difficulty: once a child taps well past the ideal count without
  // solving it, the game quietly fixes a tile so they never get stuck.
  int _autoHelpThreshold = 9999;
  String _message = 'Rotate every path until the loop glows!';
  final _random = math.Random();
  final _celebration = CelebrationController();

  static const _directions = [
    (row: 0, col: 1),
    (row: 1, col: 0),
    (row: 1, col: -1),
    (row: 0, col: -1),
    (row: -1, col: 0),
    (row: -1, col: 1),
  ];

  int get _gridSize => switch (_adaptiveTier) {
        0 => 3,
        1 => 4,
        _ => 5,
      };

  int get _pathTileCount =>
      _grid.expand((row) => row).where((tile) => tile.solution != 0).length;

  int get _alignedCount => _grid
      .expand((row) => row)
      .where((tile) => tile.solution != 0 && tile.mask == tile.solution)
      .length;

  // How far tiles are scrambled from the solution. Fewer turns = a puzzle a
  // young child can finish in a handful of taps.
  int get _maxScramble => switch (_adaptiveTier) {
        0 => 2,
        1 => 3,
        _ => 4,
      };

  @override
  void initState() {
    super.initState();
    _initGrid();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showFirstPlayTutorial(
          context,
          ref,
          gameId: 'infinity-loop',
          instruction: 'Tap the pieces to spin them. Connect them all so the '
              'loop lights up!',
          emoji: '🔄',
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initGrid() {
    final size = _gridSize;
    final solved = List.generate(size, (_) => List.filled(size, 0));
    final loop = <({int row, int col})>[
      for (var col = 0; col < size; col++) (row: 0, col: col),
      for (var row = 1; row < size; row++) (row: row, col: size - 1),
      for (var col = size - 2; col >= 0; col--) (row: size - 1, col: col),
      for (var row = size - 2; row > 0; row--) (row: row, col: 0),
    ];
    for (var i = 0; i < loop.length; i++) {
      final from = loop[i];
      final to = loop[(i + 1) % loop.length];
      final direction = _directionBetween(from, to);
      solved[from.row][from.col] |= 1 << direction;
      solved[to.row][to.col] |= 1 << ((direction + 3) % 6);
    }

    _optimalMoves = 0;
    _grid = List.generate(size, (row) {
      return List.generate(size, (col) {
        final solution = solved[row][col];
        var mask = solution;
        var turns = 0;
        if (mask != 0) {
          turns = 1 + _random.nextInt(_maxScramble);
          for (var i = 0; i < turns; i++) {
            mask = _rotateMask(mask);
          }
          _optimalMoves += (6 - turns) % 6;
        }
        return _HexTile(mask: mask, solution: solution);
      });
    });
    _won = false;
    _usedHint = false;
    _moves = 0;
    _autoHelpThreshold = _optimalMoves * 2 + 8;
    _message = 'Level $_level: connect the glowing loop!';
    _currentPlayer = 1;
    if (_isSolved()) {
      final tile = _grid.first.first;
      tile.mask = _rotateMask(tile.mask);
      _optimalMoves++;
    }
  }

  int _directionBetween(
    ({int row, int col}) from,
    ({int row, int col}) to,
  ) {
    final row = to.row - from.row;
    final col = to.col - from.col;
    return _directions
        .indexWhere((delta) => delta.row == row && delta.col == col);
  }

  int _rotateMask(int mask) => ((mask << 1) & 0x3f) | ((mask >> 5) & 1);

  void _newGame({bool nextLevel = false}) {
    setState(() {
      if (nextLevel) {
        _level++;
        if (_strongFinish) {
          _adaptiveTier = math.min(2, _adaptiveTier + 1);
        } else if (_usedHint) {
          _adaptiveTier = math.max(0, _adaptiveTier - 1);
        }
      }
      _initGrid();
      _strongFinish = false;
    });
  }

  void _hint() {
    if (_won) return;
    for (final row in _grid) {
      for (final tile in row) {
        if (tile.mask != tile.solution) {
          setState(() {
            tile.mask = tile.solution;
            tile.bloomPulse++;
            _usedHint = true;
            _message = 'Pip fixed one tile. Finish the rest!';
          });
          AudioService.instance.playSfx(Sfx.magic);
          if (_isSolved()) _complete();
          return;
        }
      }
    }
  }

  bool _isSolved() {
    final connected = <(int, int)>[];
    for (var row = 0; row < _gridSize; row++) {
      for (var col = 0; col < _gridSize; col++) {
        final mask = _grid[row][col].mask;
        if (mask == 0) continue;
        if (_bitCount(mask) != 2) return false;
        connected.add((row, col));
        for (var direction = 0; direction < 6; direction++) {
          if (mask & (1 << direction) == 0) continue;
          final delta = _directions[direction];
          final nextRow = row + delta.row;
          final nextCol = col + delta.col;
          if (nextRow < 0 ||
              nextRow >= _gridSize ||
              nextCol < 0 ||
              nextCol >= _gridSize) {
            return false;
          }
          final opposite = (direction + 3) % 6;
          if (_grid[nextRow][nextCol].mask & (1 << opposite) == 0) {
            return false;
          }
        }
      }
    }
    if (connected.isEmpty) return false;
    final visited = <(int, int)>{};
    final pending = <(int, int)>[connected.first];
    while (pending.isNotEmpty) {
      final cell = pending.removeLast();
      if (!visited.add(cell)) continue;
      final mask = _grid[cell.$1][cell.$2].mask;
      for (var direction = 0; direction < 6; direction++) {
        if (mask & (1 << direction) == 0) continue;
        final delta = _directions[direction];
        pending.add((cell.$1 + delta.row, cell.$2 + delta.col));
      }
    }
    return visited.length == connected.length;
  }

  int _bitCount(int value) {
    var count = 0;
    while (value != 0) {
      count += value & 1;
      value >>= 1;
    }
    return count;
  }

  void _tapTile(int row, int col) {
    if (_won) return;
    final tile = _grid[row][col];
    if (tile.mask == 0) return;
    setState(() {
      tile.mask = _rotateMask(tile.mask);
      if (tile.mask == tile.solution) tile.bloomPulse++;
      _moves++;
      _message = tile.mask == tile.solution
          ? 'Click! That tile is connected.'
          : 'Keep turning — watch both ends.';
    });
    AudioService.instance.playSfx(
      tile.mask == tile.solution
          ? ((row + col).isEven ? Sfx.correct : Sfx.star)
          : Sfx.tap,
    );
    if (tile.mask == tile.solution) AudioService.instance.lightHaptic();
    if (_playMode == MiniGamePlayMode.together) {
      setState(() {
        _currentPlayer = _currentPlayer == 1 ? 2 : 1;
        _message = 'The water glows! Player $_currentPlayer, your turn.';
      });
    }
    if (_isSolved()) {
      _complete();
      return;
    }
    // Struggling? Quietly lend a hand so a child never hits a wall.
    if (_moves >= _autoHelpThreshold) {
      _autoHelpThreshold = _moves + 10;
      _autoHelp();
    }
  }

  void _autoHelp() {
    for (final row in _grid) {
      for (final tile in row) {
        if (tile.mask != tile.solution) {
          setState(() {
            tile.mask = tile.solution;
            tile.bloomPulse++;
            _usedHint = true;
            _message = 'Here is a little help! 💫';
          });
          AudioService.instance.playSfx(Sfx.magic);
          AudioService.instance.speak('Here is a little help!');
          if (_isSolved()) _complete();
          return;
        }
      }
    }
  }

  void _complete() {
    final stars = _starCount;
    setState(() {
      _won = true;
      _strongFinish = stars == 3 && _moves <= _optimalMoves + 2;
      _message = stars == 3
          ? 'Water flows! Every flower is blooming!'
          : 'The thirsty flowers are blooming!';
    });
    _celebration.fireworks();
    AudioService.instance.speak(
      'Splish splash! The flowers bloom. La la la! You earned $stars stars.',
    );
    showMiniGameReward(context, (_gridSize * 250) - (_moves * 5));
    ref.read(miniGamesControllerProvider.notifier).recordResult(
      gameId: 'infinity-loop',
      score: (_gridSize * 250) - (_moves * 5).clamp(0, _gridSize * 100),
      dailyProgress: 1,
      achievements: [
        if (!_usedHint) 'loop_no_hint',
      ],
    );
  }

  int get _starCount {
    if (_usedHint) return 1;
    if (_moves <= _optimalMoves + 2) return 3;
    if (_moves <= _optimalMoves + _gridSize) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CelebrationOverlay(
        controller: _celebration,
        child: AnimatedBackground(
          theme: WorldTheme.space,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxHeight < 620 || constraints.maxWidth < 340;
                return Column(
                  children: [
                    _topBar(compact: compact),
                    if (compact)
                      _compactGoal()
                    else ...[
                      MascotMessage(message: _message),
                      StoryGoalCard(
                        emoji: '💧🌸',
                        goal: 'Fix the water path so the flowers bloom!',
                        progress: _pathTileCount == 0
                            ? 0
                            : _alignedCount / _pathTileCount,
                        progressColor: const Color(0xFF00CEC9),
                      ),
                    ],
                    SizedBox(height: compact ? 3 : 6),
                    if (_won)
                      _winScreen(compact: compact)
                    else
                      _gridArea(compact: compact),
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
              '🌸 Flower Flow',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          GameCircleButton(
            icon: Icons.lightbulb_rounded,
            tooltip: 'Hint',
            onTap: _hint,
          ),
          const SizedBox(width: 5),
          GameCircleButton(
            icon: Icons.help_outline_rounded,
            tooltip: 'How to play',
            onTap: () => showMiniGameHelp(
              context,
              title: 'How to play Infinity Loop',
              steps: const [
                'Tap a hexagon to rotate its path.',
                'Every path end must meet another path end.',
                'The whole board must form one closed loop.',
                'Use a hint if you are stuck, or solve alone for 3 stars.',
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactGoal() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('💧', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Fix the path so flowers bloom!',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.lightText,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: LinearProgressIndicator(
              value: _pathTileCount == 0 ? 0 : _alignedCount / _pathTileCount,
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

  Widget _gridArea({required bool compact}) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth - 20;
          final tileSize = math.min(
            compact ? 45.0 : 54.0,
            availableWidth / (_gridSize * 1.5 - 0.5),
          );
          final boardWidth = tileSize * (_gridSize * 1.5 - 0.5);
          final boardHeight = tileSize * (1 + ((_gridSize - 1) * 0.86));
          return SingleChildScrollView(
            child: Column(
              children: [
                PlayModePicker(
                  value: _playMode,
                  onChanged: (value) => setState(() {
                    _playMode = value;
                    _currentPlayer = 1;
                  }),
                ),
                if (_playMode == MiniGamePlayMode.together) ...[
                  const SizedBox(height: 6),
                  PlayerTurnBadge(player: _currentPlayer),
                ],
                SizedBox(height: compact ? 4 : 8),
                Text(
                  'Level $_level  •  Moves $_moves  •  Best path $_optimalMoves',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: compact ? 6 : 10),
                SizedBox(
                  width: boardWidth,
                  height: boardHeight,
                  child: Stack(
                    children: [
                      for (var row = 0; row < _gridSize; row++)
                        for (var col = 0; col < _gridSize; col++)
                          Positioned(
                            left: col * tileSize + row * tileSize * 0.5,
                            top: row * tileSize * 0.86,
                            child: _hexTile(row, col, tileSize),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _hexTile(int row, int col, double size) {
    final tile = _grid[row][col];
    final aligned = tile.mask == tile.solution && tile.mask != 0;
    return Semantics(
      button: tile.mask != 0,
      label: aligned ? 'Connected path tile' : 'Path tile to rotate',
      child: GestureDetector(
        onTap: () => _tapTile(row, col),
        onPanEnd: (_) => _tapTile(row, col),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HexPipePainter(
                    tile.mask,
                    aligned ? const Color(0xFF00B894) : AppColors.primary,
                  ),
                ),
              ),
              if (aligned)
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(tile.bloomPulse),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) => Opacity(
                      opacity: (1 - t).clamp(0, 1),
                      child: Transform.scale(
                        scale: 0.7 + t * 0.9,
                        child: child,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00CEC9),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              if (aligned)
                const Align(
                  alignment: Alignment.topRight,
                  child: Text('🌸', style: TextStyle(fontSize: 14)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _winScreen({required bool compact}) {
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⭐' * _starCount,
                  style: TextStyle(fontSize: compact ? 36 : 48)),
              Text(
                'Perfect Loop!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 23 : 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Level $_level completed in $_moves moves',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _newGame(nextLevel: true),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Next loop'),
              ),
              TextButton(
                onPressed: _newGame,
                child: const Text(
                  'Replay level',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HexTile {
  _HexTile({required this.mask, required this.solution});
  int mask;
  final int solution;
  int bloomPulse = 0;
}

class _HexPipePainter extends CustomPainter {
  _HexPipePainter(this.mask, this.color);
  final int mask;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        hex.moveTo(point.dx, point.dy);
      } else {
        hex.lineTo(point.dx, point.dy);
      }
    }
    hex.close();
    canvas.drawPath(hex, Paint()..color = Colors.white.withValues(alpha: 0.94));
    canvas.drawPath(
      hex,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(3, size.width * 0.11)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var direction = 0; direction < 6; direction++) {
      if (mask & (1 << direction) == 0) continue;
      final angle = direction * math.pi / 3;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(center, end, paint);
    }
    if (mask != 0) {
      canvas.drawCircle(
          center, math.max(2, size.width * 0.07), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_HexPipePainter oldDelegate) =>
      oldDelegate.mask != mask || oldDelegate.color != color;
}
