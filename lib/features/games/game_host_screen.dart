import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../curriculum/domain/lesson.dart';
import '../gamification/domain/wallet.dart';
import '../gamification/reward_engine.dart';
import '../achievements/achievements_controller.dart';
import '../achievements/domain/achievement.dart';
import '../ai/adaptive_engine.dart';
import '../profiles/profiles_controller.dart';
import '../progress/activity_log.dart';
import '../progress/progress_controller.dart';
import '../season/season_controller.dart';
import '../world/domain/world_prize.dart';
import 'adventure_intro.dart';
import 'engines/bubble_pop_game.dart';
import 'engines/boss_battle_game.dart';
import 'engines/drag_drop_game.dart';
import 'engines/feed_pet_game.dart';
import 'engines/flashcard_game.dart';
import 'engines/memory_match_game.dart';
import 'engines/listen_and_tap_game.dart';
import 'engines/mole_match_game.dart';
import 'engines/sequence_game.dart';
import 'engines/speech_game.dart';
import 'engines/tap_choice_game.dart';
import 'engines/tracing_game.dart';
import 'game_result_screen.dart';

/// Hosts one lesson end-to-end:
/// 1. Pick the engine widget for the lesson's [GameType].
/// 2. Collect the [LessonResult] the engine reports.
/// 3. Compute rewards, apply to the wallet, update the adaptive model.
/// 4. Show the celebration/result screen with replay/home.
///
/// Adding a new game type = add one case + one engine widget. Nothing else in
/// the app changes.
class GameHostScreen extends ConsumerStatefulWidget {
  const GameHostScreen({super.key, required this.lesson});
  final Lesson lesson;

  @override
  ConsumerState<GameHostScreen> createState() => _GameHostScreenState();
}

class _GameHostScreenState extends ConsumerState<GameHostScreen> {
  static const _engine = RewardEngine();
  LessonResult? _result;
  RewardBundle _reward = const RewardBundle();
  bool _leveledUp = false;
  bool _completing = false;
  int _newLevel = 1;
  List<Achievement> _newBadges = const [];
  bool _missionStarted = false;
  late final WorldPrize _worldPrize =
      WorldPrizeCatalog.forLesson(widget.lesson.id);
  bool _prizeWasNew = false;

  Future<void> _onComplete(LessonResult result) async {
    if (_completing) return;
    setState(() => _completing = true);
    final profiles = ref.read(profilesControllerProvider.notifier);
    final child = ref.read(activeChildProvider);
    final reward = _engine.compute(result);
    if (child == null) {
      if (mounted) {
        setState(() {
          _result = result;
          _reward = reward;
          _completing = false;
        });
      }
      return;
    }

    final before = child.wallet;
    var after = before;
    var newBadges = <Achievement>[];
    try {
      after = await profiles.applyReward(reward);
      await ref
          .read(adaptiveControllerProvider.notifier)
          .record(child.id, result);
      await ref
          .read(progressControllerProvider.notifier)
          .recordStars(result.lesson.id, result.stars);
      await ref
          .read(activityControllerProvider.notifier)
          .record(child.id, stars: result.stars, xp: reward.xp);
      await ref
          .read(seasonControllerProvider.notifier)
          .recordLesson(child.id, result.stars);
      await profiles.rememberAdventure(
        neededHelp: result.struggledQuestionIds.isNotEmpty,
      );
      _prizeWasNew = switch (_worldPrize.kind) {
        WorldPrizeKind.decoration =>
          await profiles.grantRoomItem(_worldPrize.id),
        WorldPrizeKind.sticker => await profiles.grantCollectible('st_star'),
        WorldPrizeKind.snack => true,
      };
      if (_worldPrize.kind == WorldPrizeKind.snack) {
        await profiles.addCompanionXp(12,
            memory: 'That crunchy snack made me sparkle! Thank you!');
      } else if (!_prizeWasNew) {
        await profiles.addCompanionXp(4,
            memory: 'We found another ${_worldPrize.title}! What a lucky day!');
      }

      final progress = ref.read(progressControllerProvider);
      newBadges =
          await ref.read(achievementsControllerProvider.notifier).evaluate(
                AchievementContext(
                  wallet: after,
                  completedLessons: progress.completedCount(child.id),
                  totalStars: progress.totalStars(child.id),
                  lastResultStars: result.stars,
                ),
              );
      if (newBadges.isNotEmpty) {
        final bonus = newBadges.fold(0, (sum, b) => sum + b.coinReward);
        after = await profiles.applyReward(RewardBundle(coins: bonus));
      }
    } catch (error, stackTrace) {
      debugPrint('Lesson completion persistence failed: $error\n$stackTrace');
    } finally {
      final check = LevelUpCheck(before, after);
      if (mounted) {
        setState(() {
          _result = result;
          _reward = reward;
          _leveledUp = check.leveledUp;
          _newLevel = check.newLevel;
          _newBadges = newBadges;
          _completing = false;
        });
      }
    }
  }

  void _replay() => setState(() {
        _result = null;
        _missionStarted = true;
      });

  @override
  Widget build(BuildContext context) {
    if (_completing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Saving your stars…'),
            ],
          ),
        ),
      );
    }
    if (_result != null) {
      return GameResultScreen(
        result: _result!,
        reward: _reward,
        leveledUp: _leveledUp,
        newLevel: _newLevel,
        newBadges: _newBadges,
        prize: _worldPrize,
        prizeWasNew: _prizeWasNew,
        onReplay: _replay,
        onContinue: () => context.go(
          AppRoutes.learningMap,
          extra: widget.lesson.subject,
        ),
        onVisitWorld: () => context.go(AppRoutes.kidWorld),
        onHome: () => context.go(AppRoutes.home),
      );
    }
    if (!_missionStarted) {
      final child = ref.watch(activeChildProvider);
      return AdventureIntro(
        mission: AdventureMission.forLesson(
          widget.lesson,
          heroName: child?.heroName,
        ),
        lessonTitle: widget.lesson.title,
        onStart: () => setState(() => _missionStarted = true),
      );
    }
    return _engineFor(widget.lesson);
  }

  Widget _engineFor(Lesson lesson) {
    switch (lesson.gameType) {
      case GameType.tapChoice:
      case GameType.countCatch:
      case GameType.spotMatch:
        // Share the "pick the right option" interaction; dedicated engines can
        // be swapped in per type without touching the host.
        return TapChoiceGame(lesson: lesson, onComplete: _onComplete);
      case GameType.bubblePop:
        return BubblePopGame(lesson: lesson, onComplete: _onComplete);
      case GameType.memoryMatch:
        return MemoryMatchGame(lesson: lesson, onComplete: _onComplete);
      case GameType.dragDrop:
      case GameType.sorting:
        // Sorting is drag-into-basket — same engine, different content.
        return DragDropGame(lesson: lesson, onComplete: _onComplete);
      case GameType.tracing:
        return TracingGame(lesson: lesson, onComplete: _onComplete);
      case GameType.sequence:
        return SequenceGame(lesson: lesson, onComplete: _onComplete);
      case GameType.speak:
        return SpeechGame(lesson: lesson, onComplete: _onComplete);
      case GameType.bossBattle:
        return BossBattleGame(lesson: lesson, onComplete: _onComplete);
      case GameType.listenAndTap:
        return ListenAndTapGame(lesson: lesson, onComplete: _onComplete);
      case GameType.moleMatch:
        return MoleMatchGame(lesson: lesson, onComplete: _onComplete);
      case GameType.feedPet:
        return FeedPetGame(lesson: lesson, onComplete: _onComplete);
      case GameType.flashcard:
        return FlashcardGame(lesson: lesson, onComplete: _onComplete);
      case GameType.wordBuilder:
        // Engine under construction — fall back to tapChoice so every lesson
        // is playable. Replace with the real engine as it lands.
        return TapChoiceGame(lesson: lesson, onComplete: _onComplete);
    }
  }
}
