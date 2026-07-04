import 'dart:math' as math;

class StackDropResult {
  const StackDropResult({
    required this.value,
    required this.mergeCount,
    required this.points,
  });

  final int value;
  final int mergeCount;
  final int points;
}

/// Framework-independent column merge rules. A value of -1 is a rainbow tile.
class StackMergeEngine {
  StackMergeEngine({this.columnCount = 5, this.maxRows = 8})
      : columns = List.generate(columnCount, (_) => <int>[]);

  static const rainbow = -1;
  final int columnCount;
  final int maxRows;
  final List<List<int>> columns;
  int score = 0;

  bool get gameOver => columns.any((column) => column.length >= maxRows);
  int get highestTile => columns
      .expand((column) => column)
      .where((value) => value > 0)
      .fold(0, math.max);

  StackDropResult dropWithResult(int column, int value) {
    if (gameOver || column < 0 || column >= columnCount) {
      return StackDropResult(value: value, mergeCount: 0, points: 0);
    }
    final target = columns[column];
    var resolvedValue = value;
    var merges = 0;
    var points = 0;

    if (resolvedValue == rainbow) {
      resolvedValue = target.isEmpty ? 2 : target.removeLast() * 2;
      merges++;
      points += resolvedValue;
    }
    target.add(resolvedValue);
    while (target.length >= 2 && target.last == target[target.length - 2]) {
      final merged = target.removeLast() * 2;
      target[target.length - 1] = merged;
      merges++;
      points += merged;
    }
    score += points;
    return StackDropResult(
      value: target.last,
      mergeCount: merges,
      points: points,
    );
  }

  int drop(int column, int value) => dropWithResult(column, value).value;

  void reset() {
    for (final column in columns) {
      column.clear();
    }
    score = 0;
  }

  /// Makes room while preserving the tower. Used by kid and creative modes so
  /// a full column becomes a cheerful rescue moment instead of game over.
  int rescueTallest({int remove = 2}) {
    var tallest = 0;
    for (var i = 1; i < columns.length; i++) {
      if (columns[i].length > columns[tallest].length) tallest = i;
    }
    final count = math.min(remove, columns[tallest].length);
    if (count > 0) columns[tallest].removeRange(0, count);
    return count;
  }
}
