import 'package:equatable/equatable.dart';

/// The child's economy state: soft currency (coins), premium-feel currency
/// (gems, earned not bought for kids), performance stars, XP and derived level,
/// plus the energy meter that gently paces play.
///
/// Level curve: each level needs `100 * level` XP (gentle, always-achievable).
class Wallet extends Equatable {
  const Wallet({
    this.coins = 0,
    this.gems = 0,
    this.stars = 0,
    this.xp = 0,
    this.energy = maxEnergy,
    this.streakDays = 0,
  });

  final int coins;
  final int gems;
  final int stars;
  final int xp;
  final int energy;
  final int streakDays;

  static const int maxEnergy = 30;

  int get level => _levelForXp(xp);

  /// XP into the current level and XP needed to finish it (for the HUD bar).
  int get xpIntoLevel => xp - _xpForLevel(level);
  int get xpForNextLevel => _xpForLevel(level + 1) - _xpForLevel(level);
  double get levelProgress =>
      xpForNextLevel == 0 ? 0 : xpIntoLevel / xpForNextLevel;

  static int _xpForLevel(int level) {
    // cumulative XP to REACH `level`: 0,100,300,600,1000,...  (n*(n-1)/2*100)
    return (level * (level - 1) ~/ 2) * 100;
  }

  static int _levelForXp(int xp) {
    var level = 1;
    while (_xpForLevel(level + 1) <= xp) {
      level++;
    }
    return level;
  }

  Wallet copyWith({
    int? coins,
    int? gems,
    int? stars,
    int? xp,
    int? energy,
    int? streakDays,
  }) {
    return Wallet(
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      stars: stars ?? this.stars,
      xp: xp ?? this.xp,
      energy: energy ?? this.energy,
      streakDays: streakDays ?? this.streakDays,
    );
  }

  Map<String, dynamic> toMap() => {
        'coins': coins,
        'gems': gems,
        'stars': stars,
        'xp': xp,
        'energy': energy,
        'streakDays': streakDays,
      };

  factory Wallet.fromMap(Map<String, dynamic> map) => Wallet(
        coins: (map['coins'] ?? 0) as int,
        gems: (map['gems'] ?? 0) as int,
        stars: (map['stars'] ?? 0) as int,
        xp: (map['xp'] ?? 0) as int,
        energy: (map['energy'] ?? maxEnergy) as int,
        streakDays: (map['streakDays'] ?? 0) as int,
      );

  @override
  List<Object?> get props => [coins, gems, stars, xp, energy, streakDays];
}

/// The reward granted when a child completes an activity. Kept as a value
/// object so the reward-reveal animation and the wallet update share one truth.
class RewardBundle extends Equatable {
  const RewardBundle({
    this.coins = 0,
    this.gems = 0,
    this.stars = 0,
    this.xp = 0,
  });

  final int coins;
  final int gems;
  final int stars;
  final int xp;

  bool get isEmpty => coins == 0 && gems == 0 && stars == 0 && xp == 0;

  @override
  List<Object?> get props => [coins, gems, stars, xp];
}
