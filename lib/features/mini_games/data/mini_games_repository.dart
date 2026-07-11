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
    this.learning = false,
    this.gradeBand,
  });

  final String id;
  final String name;
  final String icon;
  final int color;
  final String description;
  final bool learning;
  final String? gradeBand;
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
    id: 'toy-sort',
    name: 'Toy Sort',
    icon: '🧸',
    color: 0xFFFF8A65,
    description: 'Teach Pip colors, shapes, sizes and groups!',
    learning: true,
  ),
  MiniGameDef(
    id: 'feed-the-pet',
    name: 'Feed the Pet',
    icon: '🥣',
    color: 0xFF26A69A,
    description: 'Count tasty food for a hungry friend!',
    learning: true,
  ),
  MiniGameDef(
    id: 'sound-safari',
    name: 'Sound Safari',
    icon: '🦁',
    color: 0xFF00A878,
    description: 'Listen and discover who makes each sound!',
    learning: true,
  ),
  MiniGameDef(
    id: 'number-garden',
    name: 'Number Garden',
    icon: '🌻',
    color: 0xFFFFB000,
    description: 'Count flowers and grow a number garden!',
    learning: true,
  ),
  MiniGameDef(
    id: 'story-train',
    name: 'Story Train',
    icon: '🚂',
    color: 0xFF3D7EFF,
    description: 'Put events in order and predict what comes next!',
    learning: true,
  ),
  MiniGameDef(
    id: 'letter-bakery',
    name: 'Letter Bakery',
    icon: '🥐',
    color: 0xFFE84393,
    description: 'Bake words by matching their first letters!',
    learning: true,
  ),
  MiniGameDef(
    id: 'clean-room-helper',
    name: 'Clean Room Helper',
    icon: '🧹',
    color: 0xFF7C5CE7,
    description: 'Help Pip put everyday things in their places!',
    learning: true,
  ),
  MiniGameDef(
    id: 'math-market',
    name: 'Math Market',
    icon: '🛒',
    color: 0xFFFF8F00,
    description: 'Shop with coins and catch silly change mistakes!',
    learning: true,
    gradeBand: 'Class 1–2',
  ),
  MiniGameDef(
    id: 'word-wizard-workshop',
    name: 'Word Wizard',
    icon: '🧙',
    color: 0xFF6C5CE7,
    description: 'Repair words with beginning, ending and spelling magic!',
    learning: true,
    gradeBand: 'Class 1–2',
  ),
  MiniGameDef(
    id: 'sentence-train',
    name: 'Sentence Train',
    icon: '🚂',
    color: 0xFF1976D2,
    description: 'Complete grammar carriages and punctuation tracks!',
    learning: true,
    gradeBand: 'Class 1–2',
  ),
  MiniGameDef(
    id: 'clock-adventure',
    name: 'Clock Adventure',
    icon: '⏰',
    color: 0xFFE91E63,
    description: 'Read clocks and match times to everyday routines!',
    learning: true,
    gradeBand: 'Class 1–2',
  ),
  MiniGameDef(
    id: 'nature-detective',
    name: 'Nature Detective',
    icon: '🔎',
    color: 0xFF00897B,
    description: 'Solve animal, plant and habitat mysteries!',
    learning: true,
    gradeBand: 'Class 1–2',
  ),
  MiniGameDef(
    id: 'shape-builder',
    name: 'Shape Builder',
    icon: '🏗️',
    color: 0xFF5E35B1,
    description: 'Build with shapes, sides and repeating patterns!',
    learning: true,
    gradeBand: 'Class 1–2',
  ),
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
    id: 'toy_teacher',
    title: 'Toy Teacher',
    description: 'Teach Pip to sort a full level',
    icon: '🧸',
  ),
  MiniGameAchievement(
    id: 'pet_feeder',
    title: 'Pet Chef',
    description: 'Count every snack in a full level',
    icon: '🥣',
  ),
  MiniGameAchievement(
    id: 'sound_scout',
    title: 'Sound Scout',
    description: 'Finish a Sound Safari level',
    icon: '🦉',
  ),
  MiniGameAchievement(
    id: 'number_gardener',
    title: 'Number Gardener',
    description: 'Finish a Number Garden level',
    icon: '🌻',
  ),
  MiniGameAchievement(
    id: 'story_conductor',
    title: 'Story Conductor',
    description: 'Finish a Story Train level',
    icon: '🚂',
  ),
  MiniGameAchievement(
    id: 'letter_baker',
    title: 'Letter Baker',
    description: 'Finish a Letter Bakery level',
    icon: '🥐',
  ),
  MiniGameAchievement(
    id: 'tidy_helper',
    title: 'Tidy Helper',
    description: 'Finish a Clean Room Helper level',
    icon: '🧹',
  ),
  MiniGameAchievement(
    id: 'market_master',
    title: 'Market Master',
    description: 'Finish a Math Market level',
    icon: '🛒',
  ),
  MiniGameAchievement(
    id: 'word_wizard',
    title: 'Word Wizard',
    description: 'Finish a Word Wizard level',
    icon: '🧙',
  ),
  MiniGameAchievement(
    id: 'sentence_conductor',
    title: 'Sentence Conductor',
    description: 'Finish a Sentence Train level',
    icon: '🚂',
  ),
  MiniGameAchievement(
    id: 'time_keeper',
    title: 'Time Keeper',
    description: 'Finish a Clock Adventure level',
    icon: '⏰',
  ),
  MiniGameAchievement(
    id: 'nature_detective',
    title: 'Nature Detective',
    description: 'Finish a Nature Detective level',
    icon: '🔎',
  ),
  MiniGameAchievement(
    id: 'shape_architect',
    title: 'Shape Architect',
    description: 'Finish a Shape Builder level',
    icon: '🏗️',
  ),
  MiniGameAchievement(
    id: 'game_explorer',
    title: 'Game Explorer',
    description: 'Play every mini game',
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
  static const _learningLevelPrefix = 'mg_learning_level_';
  static const _learningItemsKey = 'mg_learning_world_items';

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

  int learningLevel(String gameId) =>
      (_readInt('$_learningLevelPrefix$gameId') ?? 1).clamp(1, 50);

  Set<String> learningWorldItems() =>
      (_readStringList(_learningItemsKey) ?? const <String>[]).toSet();

  Future<int> completeLearningLevel(String gameId, int completedLevel) async {
    final next = (completedLevel + 1).clamp(1, 50);
    final unlocked = learningLevel(gameId);
    final value = next > unlocked ? next : unlocked;
    await _prefs.setInt(_key('$_learningLevelPrefix$gameId'), value);
    return value;
  }

  Future<void> unlockLearningWorldItem(String id) async {
    final updated = learningWorldItems()..add(id);
    await _prefs.setStringList(
      _key(_learningItemsKey),
      updated.toList()..sort(),
    );
  }

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
      'toy-sort' => (title: 'Sort 5 toys', target: 5),
      'feed-the-pet' => (title: 'Count 5 pet snacks', target: 5),
      'sound-safari' => (title: 'Solve 5 sound clues', target: 5),
      'number-garden' => (title: 'Count 5 garden groups', target: 5),
      'story-train' => (title: 'Finish 5 story steps', target: 5),
      'letter-bakery' => (title: 'Bake 5 starting letters', target: 5),
      'clean-room-helper' => (title: 'Put away 5 objects', target: 5),
      'math-market' => (title: 'Solve 5 market totals', target: 5),
      'word-wizard-workshop' => (title: 'Repair 5 words', target: 5),
      'sentence-train' => (title: 'Complete 5 sentences', target: 5),
      'clock-adventure' => (title: 'Read 5 clocks', target: 5),
      'nature-detective' => (title: 'Solve 5 nature clues', target: 5),
      'shape-builder' => (title: 'Solve 5 shape puzzles', target: 5),
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
