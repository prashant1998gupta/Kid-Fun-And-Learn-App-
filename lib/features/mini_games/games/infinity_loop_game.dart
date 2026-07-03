import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../mini_games_controller.dart';

/// Infinity Loop Hex — rotate hex tiles to form a closed loop.
class InfinityLoopGame extends ConsumerStatefulWidget {
  const InfinityLoopGame({super.key});

  @override
  ConsumerState<InfinityLoopGame> createState() => _InfinityLoopGameState();
}

class _InfinityLoopGameState extends ConsumerState<InfinityLoopGame> {
  static const _gridSize = 4;
  late List<List<_HexTile>> _grid;
  bool _won = false;
  int _moves = 0;
  final _rnd = math.Random();

  static const _directions = [
    (row: 0, col: 1),
    (row: 1, col: 0),
    (row: 1, col: -1),
    (row: 0, col: -1),
    (row: -1, col: 0),
    (row: -1, col: 1),
  ];

  @override
  void initState() {
    super.initState();
    _initGrid();
  }

  void _initGrid() {
    final masks = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));
    const loop = [
      (row: 0, col: 0),
      (row: 0, col: 1),
      (row: 0, col: 2),
      (row: 0, col: 3),
      (row: 1, col: 3),
      (row: 2, col: 3),
      (row: 3, col: 3),
      (row: 3, col: 2),
      (row: 3, col: 1),
      (row: 3, col: 0),
      (row: 2, col: 0),
      (row: 1, col: 0),
    ];
    for (var i = 0; i < loop.length; i++) {
      final from = loop[i];
      final to = loop[(i + 1) % loop.length];
      final direction = _directionBetween(from, to);
      masks[from.row][from.col] |= 1 << direction;
      masks[to.row][to.col] |= 1 << ((direction + 3) % 6);
    }
    _grid = List.generate(_gridSize, (row) {
      return List.generate(_gridSize, (col) {
        var mask = masks[row][col];
        if (mask != 0) {
          final turns = _rnd.nextInt(6);
          for (var i = 0; i < turns; i++) {
            mask = _rotateMask(mask);
          }
        }
        return _HexTile(mask: mask);
      });
    });
    _won = false;
    _moves = 0;
    if (_isSolved()) {
      _grid[0][0].mask = _rotateMask(_grid[0][0].mask);
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

  void _newGame() => setState(_initGrid);

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

  void _tapTile(int r, int c) {
    if (_won) return;
    setState(() {
      final tile = _grid[r][c];
      if (tile.mask == 0) return;
      tile.mask = _rotateMask(tile.mask);
      _moves++;
      if (_isSolved()) {
        _won = true;
        ref.read(miniGamesControllerProvider.notifier).recordScore(
              'infinity-loop',
              1,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.space,
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              if (_won) _winScreen() else _gridArea(),
            ],
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
          BouncyButton(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.primary, size: 22),
              )),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '🔷 Infinity Loop',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
          ),
          BouncyButton(
              onTap: _newGame,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.refresh_rounded,
                    color: AppColors.primary, size: 22),
              )),
        ],
      ),
    );
  }

  Widget _gridArea() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tap each tile to rotate',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            Text('Moves: $_moves',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              width: 266,
              height: 178,
              child: Stack(
                children: [
                  for (var row = 0; row < _gridSize; row++)
                    for (var col = 0; col < _gridSize; col++)
                      Positioned(
                        left: col * 48 + row * 24,
                        top: row * 42,
                        child: _hexTile(row, col),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hexTile(int r, int c) {
    final tile = _grid[r][c];
    return GestureDetector(
      onTap: () => _tapTile(r, c),
      child: SizedBox(
        width: 50,
        height: 50,
        child: CustomPaint(
          painter: _HexPipePainter(tile.mask, AppColors.primary),
        ),
      ),
    );
  }

  Widget _winScreen() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const Text('Perfect Loop!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900)),
            Text('Completed in $_moves moves',
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 24),
            BouncyButton(
                onTap: _newGame,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30)),
                  child: const Text('🔄 New Game',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary)),
                )),
          ],
        ),
      ),
    );
  }
}

class _HexTile {
  _HexTile({required this.mask});
  int mask;
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
    canvas.drawPath(hex, Paint()..color = Colors.white.withValues(alpha: 0.92));
    canvas.drawPath(
      hex,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var direction = 0; direction < 6; direction++) {
      if (mask & (1 << direction) == 0) continue;
      final angle = direction * math.pi / 3;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(center, end, paint);
    }
    if (mask != 0) canvas.drawCircle(center, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HexPipePainter old) =>
      old.mask != mask || old.color != color;
}
