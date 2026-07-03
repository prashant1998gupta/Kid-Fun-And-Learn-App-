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

/// Persists high scores for mini games via SharedPreferences.
class MiniGamesRepository {
  MiniGamesRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _prefix = 'mg_hs_';

  int highScore(String gameId) => _prefs.getInt('$_prefix$gameId') ?? 0;

  Future<bool> saveHighScore(String gameId, int score) async {
    final current = highScore(gameId);
    if (score <= current) return false;
    await _prefs.setInt('$_prefix$gameId', score);
    return true;
  }
}

final miniGamesRepositoryProvider = Provider<MiniGamesRepository>((ref) {
  return MiniGamesRepository(ref.watch(sharedPreferencesProvider));
});
