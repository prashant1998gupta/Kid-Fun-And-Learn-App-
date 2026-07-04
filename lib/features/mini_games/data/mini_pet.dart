/// A friendly pet that grows as the child plays mini games — one emotional
/// through-line that ties four separate puzzles into a world worth returning to.
/// Every win feeds it XP; enough XP evolves it to the next stage.
class MiniPet {
  const MiniPet({
    required this.stage,
    required this.emoji,
    required this.name,
    required this.xp,
    required this.stageStart,
    required this.stageEnd,
  });

  final int stage;
  final String emoji;
  final String name;
  final int xp;
  final int stageStart;
  final int stageEnd;

  /// Progress through the current stage, 0..1.
  double get progress => stageEnd <= stageStart
      ? 1
      : ((xp - stageStart) / (stageEnd - stageStart)).clamp(0.0, 1.0);

  bool get isMax => stageEnd >= _maxSentinel;
  int get xpToNext => isMax ? 0 : (stageEnd - xp).clamp(0, stageEnd);

  static const _maxSentinel = 1 << 30;

  // (xpThreshold, emoji, name) — ordered.
  static const List<(int, String, String)> _stages = [
    (0, '🥚', 'Mystery Egg'),
    (30, '🐣', 'Hatchling'),
    (90, '🐥', 'Fluffy Chick'),
    (180, '🐤', 'Happy Bird'),
    (300, '🐔', 'Proud Chicken'),
    (460, '🦚', 'Royal Peacock'),
  ];

  static MiniPet forXp(int xp) {
    var idx = 0;
    for (var i = 0; i < _stages.length; i++) {
      if (xp >= _stages[i].$1) idx = i;
    }
    final start = _stages[idx].$1;
    final end = idx + 1 < _stages.length ? _stages[idx + 1].$1 : _maxSentinel;
    return MiniPet(
      stage: idx,
      emoji: _stages[idx].$2,
      name: _stages[idx].$3,
      xp: xp,
      stageStart: start,
      stageEnd: end,
    );
  }

  /// XP earned from a single mini-game result.
  static int xpForScore(int score) => 6 + (score ~/ 25).clamp(0, 14);
}
