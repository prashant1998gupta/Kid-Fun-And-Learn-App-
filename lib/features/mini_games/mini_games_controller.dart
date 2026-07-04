import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/mini_games_repository.dart';
import 'data/mini_pet.dart';

class MiniGamesState {
  const MiniGamesState({
    required this.highScores,
    required this.achievements,
    required this.playedGames,
    required this.dailyChallenge,
    required this.petXp,
  });

  final Map<String, int> highScores;
  final Set<String> achievements;
  final Set<String> playedGames;
  final DailyMiniGameChallenge dailyChallenge;
  final int petXp;

  MiniPet get pet => MiniPet.forXp(petXp);

  MiniGamesState copyWith({
    Map<String, int>? highScores,
    Set<String>? achievements,
    Set<String>? playedGames,
    DailyMiniGameChallenge? dailyChallenge,
    int? petXp,
  }) {
    return MiniGamesState(
      highScores: highScores ?? this.highScores,
      achievements: achievements ?? this.achievements,
      playedGames: playedGames ?? this.playedGames,
      dailyChallenge: dailyChallenge ?? this.dailyChallenge,
      petXp: petXp ?? this.petXp,
    );
  }
}

/// Keeps scores, daily goals, and local badges reactive.
class MiniGamesController extends StateNotifier<MiniGamesState> {
  MiniGamesController(this._repository)
      : super(
          MiniGamesState(
            highScores: {
              for (final game in kMiniGames)
                game.id: _repository.highScore(game.id),
            },
            achievements: _repository.achievements(),
            playedGames: _repository.playedGames(),
            dailyChallenge: _repository.dailyChallenge(),
            petXp: _repository.petXp(),
          ),
        );

  final MiniGamesRepository _repository;

  Future<bool> recordScore(String gameId, int score) async {
    final saved = await _repository.saveHighScore(gameId, score);
    if (saved) {
      state = state.copyWith(highScores: {...state.highScores, gameId: score});
    }
    return saved;
  }

  Future<Set<String>> recordResult({
    required String gameId,
    required int score,
    int? dailyProgress,
    Iterable<String> achievements = const [],
  }) async {
    await _repository.recordPlay(gameId);
    await recordScore(gameId, score);

    final played = {...state.playedGames, gameId};
    final requested = <String>{'first_game', ...achievements};
    if (played.length == kMiniGames.length) requested.add('game_explorer');

    final daily = await _repository.recordDailyProgress(
      gameId,
      dailyProgress ?? score,
    );
    if (daily.completed) requested.add('daily_challenge');

    final newlyUnlocked = requested.difference(state.achievements);
    await _repository.unlockAchievements(newlyUnlocked);

    // Feed the pet — every game a child plays helps it grow.
    final newPetXp = await _repository.addPetXp(MiniPet.xpForScore(score));

    state = state.copyWith(
      playedGames: played,
      achievements: {...state.achievements, ...newlyUnlocked},
      dailyChallenge: daily,
      petXp: newPetXp,
    );
    return newlyUnlocked;
  }

  /// Whether feeding [score] would evolve the pet to a new stage (for a
  /// celebratory "your pet grew!" moment on the mini-games screen).
  bool wouldEvolve(int score) =>
      MiniPet.forXp(state.petXp + MiniPet.xpForScore(score)).stage >
      state.pet.stage;
}

final miniGamesControllerProvider =
    StateNotifierProvider<MiniGamesController, MiniGamesState>((ref) {
  return MiniGamesController(ref.watch(miniGamesRepositoryProvider));
});
