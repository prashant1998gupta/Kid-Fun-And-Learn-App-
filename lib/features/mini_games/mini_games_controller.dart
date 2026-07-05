import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamification/domain/wallet.dart';
import '../profiles/profiles_controller.dart';
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
  MiniGamesController(
    this._repository, {
    Future<void> Function(RewardBundle reward)? rewardPlayer,
    Future<int> Function(int targetXp, String memory)? syncCompanion,
    int initialCompanionXp = 0,
  })  : _rewardPlayer = rewardPlayer,
        _syncCompanion = syncCompanion,
        super(
          MiniGamesState(
            highScores: {
              for (final game in kMiniGames)
                game.id: _repository.highScore(game.id),
            },
            achievements: _repository.achievements(),
            playedGames: _repository.playedGames(),
            dailyChallenge: _repository.dailyChallenge(),
            petXp: initialCompanionXp > _repository.petXp()
                ? initialCompanionXp
                : _repository.petXp(),
          ),
        );

  final MiniGamesRepository _repository;
  final Future<void> Function(RewardBundle reward)? _rewardPlayer;
  final Future<int> Function(int targetXp, String memory)? _syncCompanion;

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
    final earnedPetXp = MiniPet.xpForScore(score);
    var newPetXp = await _repository.addPetXp(earnedPetXp);
    final sharedXp = await _syncCompanion?.call(
      newPetXp,
      'I loved playing ${_gameName(gameId)} with you!',
    );
    if (sharedXp != null) newPetXp = sharedXp;

    // Mini games participate in the same visible economy as learning games.
    // Rewards are intentionally modest and always positive.
    final reward = RewardBundle(
      coins: 3 + (score ~/ 100).clamp(0, 7),
      xp: 5 + (score ~/ 50).clamp(0, 15),
    );
    await _rewardPlayer?.call(reward);

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

  String _gameName(String id) {
    for (final game in kMiniGames) {
      if (game.id == id) return game.name;
    }
    return 'that game';
  }
}

final miniGamesControllerProvider =
    StateNotifierProvider<MiniGamesController, MiniGamesState>((ref) {
  final child = ref.read(activeChildProvider);
  return MiniGamesController(
    ref.watch(miniGamesRepositoryProvider),
    initialCompanionXp: child?.companionXp ?? 0,
    rewardPlayer: (reward) async {
      await ref.read(profilesControllerProvider.notifier).applyReward(reward);
    },
    syncCompanion: (xp, memory) => ref
        .read(profilesControllerProvider.notifier)
        .syncCompanionXp(xp, memory: memory),
  );
});
