enum ChickenTargetType { chicken, golden, egg, bomb, boss }

class ChickenTapRules {
  const ChickenTapRules._();

  static int points(ChickenTargetType type, int combo) {
    final base = switch (type) {
      ChickenTargetType.chicken => 1,
      ChickenTargetType.golden => 5,
      ChickenTargetType.egg => 2,
      ChickenTargetType.bomb => -5,
      ChickenTargetType.boss => 12,
    };
    if (base <= 0) return base;
    return base + (combo ~/ 5);
  }

  static bool countsAsMiss(ChickenTargetType type) =>
      type != ChickenTargetType.bomb && type != ChickenTargetType.egg;
}
