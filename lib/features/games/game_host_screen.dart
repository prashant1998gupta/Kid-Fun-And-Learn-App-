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
import '../progress/progress_controller.dart';
import 'engines/bubble_pop_game.dart';
import 'engines/drag_drop_game.dart';
import 'engines/memory_match_game.dart';
import 'engines/sequence_game.dart';
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
  int _newLevel = 1;
  List<Achievement> _newBadges = const [];

  Future<void> _onComplete(LessonResult result) async {
    final profiles = ref.read(profilesControllerProvider.notifier);
    final child = ref.read(activeChildProvider);
    if (child == null) return;

    final before = child.wallet;
    final reward = _engine.compute(result);
    var after = await profiles.applyReward(reward);

    await ref
        .read(adaptiveControllerProvider.notifier)
        .record(child.id, result);

    // Persist the best-ever star score for the Learning Map / reports.
    await ref
        .read(progressControllerProvider.notifier)
        .recordStars(result.lesson.id, result.stars);

    // Evaluate achievements against the fresh state and grant their coins.
    final progress = ref.read(progressControllerProvider);
    final newBadges = await ref.read(achievementsControllerProvider.notifier).evaluate(
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

    final check = LevelUpCheck(before, after);
    if (!mounted) return;
    setState(() {
      _result = result;
      _reward = reward;
      _leveledUp = check.leveledUp;
      _newLevel = check.newLevel;
      _newBadges = newBadges;
    });
  }

  void _replay() => setState(() => _result = null);

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return GameResultScreen(
        result: _result!,
        reward: _reward,
        leveledUp: _leveledUp,
        newLevel: _newLevel,
        newBadges: _newBadges,
        onReplay: _replay,
        onHome: () => context.go(AppRoutes.home),
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
      case GameType.wordBuilder:
        // Engine under construction — fall back to tapChoice so every lesson
        // is playable. Replace with the real engine as it lands.
        return TapChoiceGame(lesson: lesson, onComplete: _onComplete);
    }
  }
}
