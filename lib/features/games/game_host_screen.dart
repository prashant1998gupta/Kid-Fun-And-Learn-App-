import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../curriculum/domain/lesson.dart';
import '../gamification/domain/wallet.dart';
import '../gamification/reward_engine.dart';
import '../ai/adaptive_engine.dart';
import '../profiles/profiles_controller.dart';
import 'engines/tap_choice_game.dart';
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

  Future<void> _onComplete(LessonResult result) async {
    final profiles = ref.read(profilesControllerProvider.notifier);
    final child = ref.read(activeChildProvider);
    if (child == null) return;

    final before = child.wallet;
    final reward = _engine.compute(result);
    final after = await profiles.applyReward(reward);

    await ref
        .read(adaptiveControllerProvider.notifier)
        .record(child.id, result);

    final check = LevelUpCheck(before, after);
    if (!mounted) return;
    setState(() {
      _result = result;
      _reward = reward;
      _leveledUp = check.leveledUp;
      _newLevel = check.newLevel;
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
        onReplay: _replay,
        onHome: () => context.go(AppRoutes.home),
      );
    }
    return _engineFor(widget.lesson);
  }

  Widget _engineFor(Lesson lesson) {
    switch (lesson.gameType) {
      case GameType.tapChoice:
      case GameType.bubblePop:
      case GameType.countCatch:
      case GameType.spotMatch:
        // These all share the "pick the right option" interaction for now;
        // dedicated engines can be swapped in per type without touching hosts.
        return TapChoiceGame(lesson: lesson, onComplete: _onComplete);
      case GameType.memoryMatch:
      case GameType.dragDrop:
      case GameType.tracing:
      case GameType.sorting:
      case GameType.sequence:
      case GameType.wordBuilder:
        // Engines under construction — fall back to tapChoice so every lesson
        // is playable. Replace with the real engine as it lands.
        return TapChoiceGame(lesson: lesson, onComplete: _onComplete);
    }
  }
}
