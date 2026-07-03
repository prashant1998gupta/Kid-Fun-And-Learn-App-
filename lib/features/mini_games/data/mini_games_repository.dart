import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/settings_controller.dart';

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
    name: 'Infinity Loop',
    icon: '🔷',
    color: 0xFF6C5CE7,
    description: 'Rotate hex tiles to form a loop!',
  ),
  MiniGameDef(
    id: '368-chickens',
    name: 'Chicken Tap',
    icon: '🐔',
    color: 0xFFFF7675,
    description: 'Tap the chickens before they run away!',
  ),
  MiniGameDef(
    id: 'stack-merge',
    name: 'Stack Merge',
    icon: '🔢',
    color: 0xFFFFC048,
    description: 'Drop numbers, merge them bigger!',
  ),
  MiniGameDef(
    id: '2048',
    name: '2048',
    icon: '🧩',
    color: 0xFF55EFC4,
    description: 'Swipe tiles to reach 2048!',
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
  MiniGamesRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _prefix = 'mg_hs_';
  static const _playsPrefix = 'mg_plays_';
  static const _achievementsKey = 'mg_achievements';
  static const _dailyDateKey = 'mg_daily_date';
  static const _dailyProgressKey = 'mg_daily_progress';

  int highScore(String gameId) => _prefs.getInt('$_prefix$gameId') ?? 0;

  Future<bool> saveHighScore(String gameId, int score) async {
    final current = highScore(gameId);
    if (score <= current) return false;
    await _prefs.setInt('$_prefix$gameId', score);
    return true;
  }

  Set<String> achievements() =>
      (_prefs.getStringList(_achievementsKey) ?? const <String>[]).toSet();

  Future<void> unlockAchievements(Iterable<String> ids) async {
    final updated = achievements()..addAll(ids);
    await _prefs.setStringList(_achievementsKey, updated.toList()..sort());
  }

  Set<String> playedGames() {
    return {
      for (final game in kMiniGames)
        if ((_prefs.getInt('$_playsPrefix${game.id}') ?? 0) > 0) game.id,
    };
  }

  Future<void> recordPlay(String gameId) async {
    final key = '$_playsPrefix$gameId';
    await _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
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
    final storedDate = _prefs.getString(_dailyDateKey);
    final progress =
        storedDate == dayKey ? (_prefs.getInt(_dailyProgressKey) ?? 0) : 0;
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
    await _prefs.setString(_dailyDateKey, dayKey);
    await _prefs.setInt(_dailyProgressKey, next);
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
  return MiniGamesRepository(ref.watch(sharedPreferencesProvider));
});
