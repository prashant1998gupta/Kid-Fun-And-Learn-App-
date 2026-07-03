import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/mini_games_repository.dart';

/// Keeps catalog scores reactive while delegating persistence to the repository.
class MiniGamesController extends StateNotifier<Map<String, int>> {
  MiniGamesController(this._repository)
      : super({
          for (final game in kMiniGames)
            game.id: _repository.highScore(game.id),
        });

  final MiniGamesRepository _repository;

  Future<bool> recordScore(String gameId, int score) async {
    final saved = await _repository.saveHighScore(gameId, score);
    if (saved) state = {...state, gameId: score};
    return saved;
  }
}

final miniGamesControllerProvider =
    StateNotifierProvider<MiniGamesController, Map<String, int>>((ref) {
  return MiniGamesController(ref.watch(miniGamesRepositoryProvider));
});
