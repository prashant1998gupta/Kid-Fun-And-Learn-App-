import 'dart:math' as math;

enum SwipeDirection { up, down, left, right }

/// Framework-independent 2048 rules, kept separate so merging is unit-testable.
class Classic2048Engine {
  Classic2048Engine({math.Random? random}) : _random = random ?? math.Random() {
    reset();
  }

  static const size = 4;
  final math.Random _random;
  late List<List<int>> grid;
  int score = 0;
  bool won = false;

  bool get gameOver => !hasMoves;

  void reset() {
    grid = List.generate(size, (_) => List.filled(size, 0));
    score = 0;
    won = false;
    addRandomTile();
    addRandomTile();
  }

  bool move(SwipeDirection direction, {bool addTile = true}) {
    var moved = false;
    for (var index = 0; index < size; index++) {
      final original = _readLine(index, direction);
      final result = _mergeLine(original);
      if (!_sameLine(original, result.values)) moved = true;
      score += result.points;
      if (result.values.contains(2048)) won = true;
      _writeLine(index, direction, result.values);
    }
    if (moved && addTile) addRandomTile();
    return moved;
  }

  bool get hasMoves {
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (grid[row][col] == 0) return true;
        if (col + 1 < size && grid[row][col] == grid[row][col + 1]) {
          return true;
        }
        if (row + 1 < size && grid[row][col] == grid[row + 1][col]) {
          return true;
        }
      }
    }
    return false;
  }

  void addRandomTile() {
    final empty = <({int row, int col})>[];
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (grid[row][col] == 0) {
          empty.add((row: row, col: col));
        }
      }
    }
    if (empty.isEmpty) return;
    final cell = empty[_random.nextInt(empty.length)];
    grid[cell.row][cell.col] = _random.nextDouble() < 0.9 ? 2 : 4;
  }

  List<int> _readLine(int index, SwipeDirection direction) {
    return switch (direction) {
      SwipeDirection.left => List.of(grid[index]),
      SwipeDirection.right => grid[index].reversed.toList(),
      SwipeDirection.up => [
          for (var row = 0; row < size; row++) grid[row][index]
        ],
      SwipeDirection.down => [
          for (var row = size - 1; row >= 0; row--) grid[row][index]
        ],
    };
  }

  void _writeLine(int index, SwipeDirection direction, List<int> values) {
    switch (direction) {
      case SwipeDirection.left:
        grid[index] = List.of(values);
      case SwipeDirection.right:
        grid[index] = values.reversed.toList();
      case SwipeDirection.up:
        for (var row = 0; row < size; row++) {
          grid[row][index] = values[row];
        }
      case SwipeDirection.down:
        for (var row = 0; row < size; row++) {
          grid[size - 1 - row][index] = values[row];
        }
    }
  }

  _LineResult _mergeLine(List<int> line) {
    final compact = line.where((value) => value != 0).toList();
    final merged = <int>[];
    var points = 0;
    for (var i = 0; i < compact.length; i++) {
      if (i + 1 < compact.length && compact[i] == compact[i + 1]) {
        final value = compact[i] * 2;
        merged.add(value);
        points += value;
        i++;
      } else {
        merged.add(compact[i]);
      }
    }
    return _LineResult(
      [...merged, ...List.filled(size - merged.length, 0)],
      points,
    );
  }

  bool _sameLine(List<int> a, List<int> b) {
    for (var i = 0; i < size; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _LineResult {
  const _LineResult(this.values, this.points);
  final List<int> values;
  final int points;
}
