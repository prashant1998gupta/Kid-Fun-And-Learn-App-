import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/audio_service.dart';
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
    required this.learningLevels,
    required this.learningWorldItems,
    required this.adventureTrail,
  });

  final Map<String, int> highScores;
  final Set<String> achievements;
  final Set<String> playedGames;
  final DailyMiniGameChallenge dailyChallenge;
  final int petXp;
  final Map<String, int> learningLevels;
  final Set<String> learningWorldItems;
  final MiniGameAdventureTrail adventureTrail;

  MiniPet get pet => MiniPet.forXp(petXp);

  MiniGamesState copyWith({
    Map<String, int>? highScores,
    Set<String>? achievements,
    Set<String>? playedGames,
    DailyMiniGameChallenge? dailyChallenge,
    int? petXp,
    Map<String, int>? learningLevels,
    Set<String>? learningWorldItems,
    MiniGameAdventureTrail? adventureTrail,
  }) {
    return MiniGamesState(
      highScores: highScores ?? this.highScores,
      achievements: achievements ?? this.achievements,
      playedGames: playedGames ?? this.playedGames,
      dailyChallenge: dailyChallenge ?? this.dailyChallenge,
      petXp: petXp ?? this.petXp,
      learningLevels: learningLevels ?? this.learningLevels,
      learningWorldItems: learningWorldItems ?? this.learningWorldItems,
      adventureTrail: adventureTrail ?? this.adventureTrail,
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
    Iterable<String>? adventureGameIds,
  })  : _rewardPlayer = rewardPlayer,
        _syncCompanion = syncCompanion,
        _adventureGameIds = adventureGameIds?.toList(growable: false),
        super(
          MiniGamesState(
            highScores: {
              for (final game in kMiniGames)
                game.id: _repository.highScore(game.id),
            },
            achievements: _repository.achievements(),
            playedGames: _repository.playedGames(),
            dailyChallenge: _repository.dailyChallenge(null, adventureGameIds),
            petXp: initialCompanionXp > _repository.petXp()
                ? initialCompanionXp
                : _repository.petXp(),
            learningLevels: {
              for (final game in kMiniGames.where((game) => game.learning))
                game.id: _repository.learningLevel(game.id),
            },
            learningWorldItems: _repository.learningWorldItems(),
            adventureTrail: _repository.adventureTrail(null, adventureGameIds),
          ),
        );

  final MiniGamesRepository _repository;
  final Future<void> Function(RewardBundle reward)? _rewardPlayer;
  final Future<int> Function(int targetXp, String memory)? _syncCompanion;
  final List<String>? _adventureGameIds;

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
    int? completedLearningLevel,
    String? learningWorldItem,
  }) async {
    await _repository.recordPlay(gameId);
    await recordScore(gameId, score);

    final played = {...state.playedGames, gameId};
    final requested = <String>{'first_game', ...achievements};
    if (played.length == kMiniGames.length) requested.add('game_explorer');

    final daily = await _repository.recordDailyProgress(
      gameId,
      dailyProgress ?? score,
      null,
      _adventureGameIds,
    );
    if (daily.completed) requested.add('daily_challenge');

    final trailUpdate = await _repository.recordAdventureTrailGame(
      gameId,
      null,
      _adventureGameIds,
    );
    if (trailUpdate.chestUnlocked) {
      requested.addAll(const ['trail_blazer', 'story_hero']);
    }

    final newlyUnlocked = requested.difference(state.achievements);
    await _repository.unlockAchievements(newlyUnlocked);

    var learningLevels = state.learningLevels;
    if (completedLearningLevel != null) {
      final nextLevel = await _repository.completeLearningLevel(
        gameId,
        completedLearningLevel,
      );
      learningLevels = {...learningLevels, gameId: nextLevel};
    }
    var learningItems = state.learningWorldItems;
    if (learningWorldItem != null) {
      await _repository.unlockLearningWorldItem(learningWorldItem);
      learningItems = {...learningItems, learningWorldItem};
    }

    // Feed the pet — every game a child plays helps it grow.
    final earnedPetXp = MiniPet.xpForScore(score);
    var newPetXp = await _repository.addPetXp(earnedPetXp);
    final trail = trailUpdate.trail;
    final chapterIndex = trail.gameIds.indexOf(gameId);
    final storyMemory = chapterIndex < 0
        ? 'I loved playing ${_gameName(gameId)} with you!'
        : trailUpdate.chestUnlocked
            ? trail.storyWorld.finaleFor(trail.storyPath!)
            : trail.storyWorld.chapterLine(
                chapterIndex,
                _gameName(gameId),
                trail.storyPath!,
              );
    if (trailUpdate.chestUnlocked) {
      AudioService.instance.speak(storyMemory);
    }
    final sharedXp = await _syncCompanion?.call(newPetXp, storyMemory);
    if (sharedXp != null) newPetXp = sharedXp;

    // Mini games participate in the same visible economy as learning games.
    // Rewards are intentionally modest and always positive.
    final reward = RewardBundle(
      coins:
          3 + (score ~/ 100).clamp(0, 7) + (trailUpdate.chestUnlocked ? 15 : 0),
      xp: 5 + (score ~/ 50).clamp(0, 15) + (trailUpdate.chestUnlocked ? 20 : 0),
    );
    await _rewardPlayer?.call(reward);

    state = state.copyWith(
      playedGames: played,
      achievements: {...state.achievements, ...newlyUnlocked},
      dailyChallenge: daily,
      petXp: newPetXp,
      learningLevels: learningLevels,
      learningWorldItems: learningItems,
      adventureTrail: trailUpdate.trail,
    );
    return newlyUnlocked;
  }

  /// Whether feeding [score] would evolve the pet to a new stage (for a
  /// celebratory "your pet grew!" moment on the mini-games screen).
  bool wouldEvolve(int score) =>
      MiniPet.forXp(state.petXp + MiniPet.xpForScore(score)).stage >
      state.pet.stage;

  void syncPetXp(int xp) {
    if (xp != state.petXp) state = state.copyWith(petXp: xp);
  }

  Future<void> chooseStoryPath(String pathId) async {
    final trail = await _repository.chooseAdventureStoryPath(
      pathId,
      null,
      _adventureGameIds,
    );
    state = state.copyWith(adventureTrail: trail);
  }

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
  final controller = MiniGamesController(
    ref.watch(miniGamesRepositoryProvider),
    initialCompanionXp: child?.companionXp ?? 0,
    adventureGameIds: _adventureGameIdsForGrade(child?.grade.name),
    rewardPlayer: (reward) async {
      await ref.read(profilesControllerProvider.notifier).applyReward(reward);
    },
    syncCompanion: (xp, memory) => ref
        .read(profilesControllerProvider.notifier)
        .syncCompanionXp(xp, memory: memory),
  );
  ref.listen<int?>(
    activeChildProvider.select((active) => active?.companionXp),
    (_, xp) {
      if (xp != null) controller.syncPetXp(xp);
    },
  );
  return controller;
});

Iterable<String>? _adventureGameIdsForGrade(String? gradeName) {
  final gradeBand = switch (gradeName) {
    'lkg' || 'ukg' || 'kg' => null,
    'grade1' || 'grade2' => 'Class 1–2',
    'grade3' || 'grade4' => 'Class 3–4',
    'grade5' => 'Class 5',
    _ => 'all',
  };
  if (gradeBand == 'all') return null;
  return kMiniGames
      .where(
        (game) =>
            !game.learning ||
            (gradeBand == null
                ? game.gradeBand == null
                : game.gradeBand == gradeBand),
      )
      .map((game) => game.id);
}
