/// Framework-independent rules for the column-based Stack Merge game.
class StackMergeEngine {
  StackMergeEngine({this.columnCount = 5, this.maxRows = 8})
      : columns = List.generate(columnCount, (_) => <int>[]);

  final int columnCount;
  final int maxRows;
  final List<List<int>> columns;
  int score = 0;

  bool get gameOver => columns.any((column) => column.length >= maxRows);

  /// Drops [value] and resolves all consecutive top-of-column chain merges.
  int drop(int column, int value) {
    if (gameOver || column < 0 || column >= columnCount) return value;
    final target = columns[column]..add(value);
    while (target.length >= 2 && target.last == target[target.length - 2]) {
      final merged = target.removeLast() * 2;
      target[target.length - 1] = merged;
      score += merged;
    }
    return target.last;
  }

  void reset() {
    for (final column in columns) {
      column.clear();
    }
    score = 0;
  }
}
