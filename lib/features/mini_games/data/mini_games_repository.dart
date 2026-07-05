import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/settings_controller.dart';
import '../../profiles/profiles_controller.dart';

/// Data for a mini game definition.
class MiniGameDef {
  const MiniGameDef({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });

  final String id;
  final String name;
  final String icon;
  final int color;
  final String description;
}

class MiniGameAchievement {
  const MiniGameAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
}

class DailyMiniGameChallenge {
  const DailyMiniGameChallenge({
    required this.gameId,
    required this.title,
    required this.target,
    required this.progress,
  });

  final String gameId;
  final String title;
  final int target;
  final int progress;

  bool get completed => progress >= target;
}

/// All available mini games.
const List<MiniGameDef> kMiniGames = [
  MiniGameDef(
    id: 'infinity-loop',
    name: 'Flower Flow',
    icon: '🌸',
    color: 0xFF6C5CE7,
    description: 'Bring water to the thirsty flowers!',
  ),
  MiniGameDef(
    id: '368-chickens',
    name: 'Egg Rescue',
    icon: '🐔',
    color: 0xFFFF7675,
    description: 'Help Mama Chicken collect her eggs!',
  ),
  MiniGameDef(
    id: 'stack-merge',
    name: 'Rainbow Rescue',
    icon: '🌈',
    color: 0xFFFFC048,
    description: 'Build a rainbow tower to the moon!',
  ),
  MiniGameDef(
    id: '2048',
    name: 'Animal Family',
    icon: '🐣',
    color: 0xFF55EFC4,
    description: 'Grow the baby animals into a dragon!',
  ),
];

const List<MiniGameAchievement> kMiniGameAchievements = [
  MiniGameAchievement(
    id: 'first_game',
    title: 'First Play',
    description: 'Finish any mini game',
    icon: '🎮',
  ),
  MiniGameAchievement(
    id: 'game_explorer',
    title: 'Game Explorer',
    description: 'Play all four mini games',
    icon: '🗺️',
  ),
  MiniGameAchievement(
    id: 'chicken_combo_10',
    title: 'Chicken Hero',
    description: 'Build a 10-hit combo',
    icon: '🐔',
  ),
  MiniGameAchievement(
    id: 'loop_no_hint',
    title: 'Loop Wizard',
    description: 'Solve a loop without a hint',
    icon: '🔷',
  ),
  MiniGameAchievement(
    id: 'stack_128',
    title: 'Merge Master',
    description: 'Make a 128 tile in Stack Merge',
    icon: '🌈',
  ),
  MiniGameAchievement(
    id: '2048_256',
    title: 'Tile Tamer',
    description: 'Make a 256 tile in 2048',
    icon: '🧩',
  ),
  MiniGameAchievement(
    id: 'daily_challenge',
    title: 'Daily Star',
    description: 'Complete a daily mini-game challenge',
    icon: '⭐',
  ),
];

/// Persists high scores for mini games via SharedPreferences.
class MiniGamesRepository {
  MiniGamesRepository(
    this._prefs, {
    this.scope,
    this.fallbackToLegacy = true,
  });
  final SharedPreferences _prefs;
  final String? scope;
  final bool fallbackToLegacy;

  static const _prefix = 'mg_hs_';
  static const _playsPrefix = 'mg_plays_';
  static const _achievementsKey = 'mg_achievements';
  static const _dailyDateKey = 'mg_daily_date';
  static const _dailyProgressKey = 'mg_daily_progress';
  static const _petXpKey = 'mg_pet_xp';

  String _key(String base) => scope == null ? base : '$base@$scope';

  int? _readInt(String base) =>
      _prefs.getInt(_key(base)) ??
      (scope != null && fallbackToLegacy ? _prefs.getInt(base) : null);

  String? _readString(String base) =>
      _prefs.getString(_key(base)) ??
      (scope != null && fallbackToLegacy ? _prefs.getString(base) : null);

  List<String>? _readStringList(String base) =>
      _prefs.getStringList(_key(base)) ??
      (scope != null && fallbackToLegacy ? _prefs.getStringList(base) : null);

  int petXp() => _readInt(_petXpKey) ?? 0;

  /// Feeds the pet and returns its new total XP.
  Future<int> addPetXp(int amount) async {
    final next = petXp() + amount;
    await _prefs.setInt(_key(_petXpKey), next);
    return next;
  }

  int highScore(String gameId) => _readInt('$_prefix$gameId') ?? 0;

  Future<bool> saveHighScore(String gameId, int score) async {
    final current = highScore(gameId);
    if (score <= current) return false;
    await _prefs.setInt(_key('$_prefix$gameId'), score);
    return true;
  }

  Set<String> achievements() =>
      (_readStringList(_achievementsKey) ?? const <String>[]).toSet();

  Future<void> unlockAchievements(Iterable<String> ids) async {
    final updated = achievements()..addAll(ids);
    await _prefs.setStringList(
      _key(_achievementsKey),
      updated.toList()..sort(),
    );
  }

  Set<String> playedGames() {
    return {
      for (final game in kMiniGames)
        if ((_readInt('$_playsPrefix${game.id}') ?? 0) > 0) game.id,
    };
  }

  Future<void> recordPlay(String gameId) async {
    final key = '$_playsPrefix$gameId';
    await _prefs.setInt(_key(key), (_readInt(key) ?? 0) + 1);
  }

  DailyMiniGameChallenge dailyChallenge([DateTime? now]) {
    final date = now ?? DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final dayKey = _dayKey(day);
    final challengeIndex =
        day.difference(DateTime(2024)).inDays.abs() % kMiniGames.length;
    final gameId = kMiniGames[challengeIndex].id;
    final definition = switch (gameId) {
      'infinity-loop' => (title: 'Solve one loop', target: 1),
      '368-chickens' => (title: 'Score 40 in Chicken Tap', target: 40),
      'stack-merge' => (title: 'Score 128 in Stack Merge', target: 128),
      _ => (title: 'Score 256 in 2048', target: 256),
    };
    final storedDate = _readString(_dailyDateKey);
    final progress =
        storedDate == dayKey ? (_readInt(_dailyProgressKey) ?? 0) : 0;
    return DailyMiniGameChallenge(
      gameId: gameId,
      title: definition.title,
      target: definition.target,
      progress: progress,
    );
  }

  Future<DailyMiniGameChallenge> recordDailyProgress(
    String gameId,
    int progress, [
    DateTime? now,
  ]) async {
    final current = dailyChallenge(now);
    if (current.gameId != gameId) return current;
    final date = now ?? DateTime.now();
    final dayKey = _dayKey(DateTime(date.year, date.month, date.day));
    final next = progress > current.progress ? progress : current.progress;
    await _prefs.setString(_key(_dailyDateKey), dayKey);
    await _prefs.setInt(_key(_dailyProgressKey), next);
    return DailyMiniGameChallenge(
      gameId: current.gameId,
      title: current.title,
      target: current.target,
      progress: next,
    );
  }

  String _dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

final miniGamesRepositoryProvider = Provider<MiniGamesRepository>((ref) {
  final activeId = ref.watch(
    profilesControllerProvider.select((profiles) => profiles.activeId),
  );
  final firstId = ref.watch(
    profilesControllerProvider.select(
      (profiles) =>
          profiles.children.isEmpty ? null : profiles.children.first.id,
    ),
  );
  return MiniGamesRepository(
    ref.watch(sharedPreferencesProvider),
    scope: activeId,
    fallbackToLegacy: activeId != null && firstId == activeId,
  );
});
