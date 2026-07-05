import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/mini_games/data/mini_games_repository.dart';
import 'package:kidverse/features/mini_games/data/mini_pet.dart';
import 'package:kidverse/features/mini_games/games/chicken_tap_game.dart';
import 'package:kidverse/features/mini_games/games/classic_2048_game.dart';
import 'package:kidverse/features/mini_games/games/infinity_loop_game.dart';
import 'package:kidverse/features/mini_games/games/stack_merge_game.dart';
import 'package:kidverse/features/mini_games/logic/chicken_tap_rules.dart';
import 'package:kidverse/features/mini_games/logic/classic_2048_engine.dart';
import 'package:kidverse/features/mini_games/logic/stack_merge_engine.dart';
import 'package:kidverse/features/mini_games/mini_games_controller.dart';
import 'package:kidverse/features/mini_games/mini_games_screen.dart';
import 'package:kidverse/features/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MiniGamesRepository', () {
    test('only replaces a high score with a larger value', () async {
      SharedPreferences.setMockInitialValues({'mg_hs_2048': 100});
      final preferences = await SharedPreferences.getInstance();
      final repository = MiniGamesRepository(preferences);

      expect(await repository.saveHighScore('2048', 80), isFalse);
      expect(repository.highScore('2048'), 100);
      expect(await repository.saveHighScore('2048', 140), isTrue);
      expect(repository.highScore('2048'), 140);
    });

    test('controller exposes a newly saved score immediately', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final controller = MiniGamesController(MiniGamesRepository(preferences));

      await controller.recordScore('368-chickens', 25);

      expect(controller.state.highScores['368-chickens'], 25);
    });

    test('daily challenge progress resets on a new date', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = MiniGamesRepository(preferences);
      final dayOne = DateTime(2026, 7, 3);
      final challenge = repository.dailyChallenge(dayOne);

      await repository.recordDailyProgress(
        challenge.gameId,
        challenge.target,
        dayOne,
      );

      expect(repository.dailyChallenge(dayOne).completed, isTrue);
      expect(
          repository
              .dailyChallenge(dayOne.add(const Duration(days: 1)))
              .progress,
          0);
    });

    test('result unlocks local badges without curriculum rewards', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final controller = MiniGamesController(MiniGamesRepository(preferences));

      final unlocked = await controller.recordResult(
        gameId: '368-chickens',
        score: 50,
        achievements: const ['chicken_combo_10'],
      );

      expect(unlocked, containsAll(['first_game', 'chicken_combo_10']));
      expect(controller.state.playedGames, contains('368-chickens'));
      expect(controller.state.petXp, greaterThan(0));
    });

    test('pet XP persists and evolves through play', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = MiniGamesRepository(preferences);
      final controller = MiniGamesController(repository);

      for (var i = 0; i < 5; i++) {
        await controller.recordResult(gameId: '2048', score: 25);
      }

      expect(controller.state.pet.stage, greaterThan(0));
      expect(repository.petXp(), controller.state.petXp);
      expect(MiniPet.forXp(repository.petXp()).emoji, '🐣');
    });

    test('legacy pet XP migrates forward into the shared companion', () async {
      SharedPreferences.setMockInitialValues({'mg_pet_xp': 100});
      final preferences = await SharedPreferences.getInstance();
      var syncedXp = 0;
      final controller = MiniGamesController(
        MiniGamesRepository(preferences),
        syncCompanion: (targetXp, _) async {
          syncedXp = targetXp;
          return targetXp;
        },
      );

      await controller.recordResult(gameId: '2048', score: 25);

      expect(syncedXp, greaterThan(100));
      expect(controller.state.petXp, syncedXp);
    });

    test('mini-game results grant coins and XP through the shared wallet hook',
        () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      var coins = 0;
      var xp = 0;
      final controller = MiniGamesController(
        MiniGamesRepository(preferences),
        rewardPlayer: (reward) async {
          coins += reward.coins;
          xp += reward.xp;
        },
      );

      await controller.recordResult(gameId: '2048', score: 250);

      expect(coins, 5);
      expect(xp, 10);
    });
  });

  group('Classic2048Engine', () {
    test('merges each tile at most once per move', () {
      final engine = Classic2048Engine(random: math.Random(1));
      engine.grid = [
        [2, 2, 4, 4],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];

      expect(engine.move(SwipeDirection.left, addTile: false), isTrue);

      expect(engine.grid.first, [4, 8, 0, 0]);
      expect(engine.score, 12);
    });

    test('detects a full board with no legal move', () {
      final engine = Classic2048Engine(random: math.Random(1));
      engine.grid = [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ];

      expect(engine.hasMoves, isFalse);
      expect(engine.gameOver, isTrue);
    });

    test('supports variable board sizes and one-step undo', () {
      final engine = Classic2048Engine(size: 3, random: math.Random(2));
      engine.grid = [
        [2, 2, 0],
        [0, 0, 0],
        [0, 0, 0],
      ];

      expect(engine.move(SwipeDirection.left, addTile: false), isTrue);
      expect(engine.grid.first, [4, 0, 0]);
      expect(engine.canUndo, isTrue);
      expect(engine.undo(), isTrue);
      expect(engine.grid.first, [2, 2, 0]);
      expect(engine.score, 0);
    });

    test('friendly rescue makes room without wiping progress', () {
      final engine = Classic2048Engine(random: math.Random(1));
      engine.grid = [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ];

      expect(engine.rescue(count: 3), 3);
      expect(engine.hasMoves, isTrue);
      expect(engine.grid.expand((row) => row).where((v) => v == 0), isNotEmpty);
    });
  });

  group('StackMergeEngine', () {
    test('resolves consecutive chain merges and adds their points', () {
      final engine = StackMergeEngine();

      engine.drop(0, 2);
      expect(engine.drop(0, 2), 4);
      expect(engine.drop(0, 4), 8);

      expect(engine.columns[0], [8]);
      expect(engine.score, 12);
    });

    test('ends when a column reaches the row limit', () {
      final engine = StackMergeEngine(columnCount: 1, maxRows: 3);

      engine.drop(0, 2);
      engine.drop(0, 4);
      engine.drop(0, 2);

      expect(engine.gameOver, isTrue);
    });

    test('rainbow doubles the top tile and can trigger a chain', () {
      final engine = StackMergeEngine();
      engine.columns[0].addAll([16, 8]);

      final result = engine.dropWithResult(0, StackMergeEngine.rainbow);

      expect(result.value, 32);
      expect(result.mergeCount, 2);
      expect(engine.columns[0], [32]);
    });

    test('rainbow rescue clears the bottom of the tallest tower', () {
      final engine = StackMergeEngine(columnCount: 2, maxRows: 3);
      engine.columns[0].addAll([2, 4, 8]);
      engine.columns[1].add(2);

      expect(engine.rescueTallest(remove: 2), 2);
      expect(engine.columns[0], [8]);
      expect(engine.gameOver, isFalse);
    });
  });

  group('ChickenTapRules', () {
    test('special targets have distinct scores and miss behavior', () {
      expect(ChickenTapRules.points(ChickenTargetType.golden, 1), 5);
      expect(ChickenTapRules.points(ChickenTargetType.bomb, 10), -5);
      expect(ChickenTapRules.countsAsMiss(ChickenTargetType.bomb), isFalse);
      expect(ChickenTapRules.countsAsMiss(ChickenTargetType.chicken), isTrue);
    });
  });

  testWidgets('catalog and all four game screens render on a phone viewport',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> render(Widget screen) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: MaterialApp(home: screen),
        ),
      );
      await tester.pump();
      final tutorialButton = find.text("Let's Play! 🎉");
      if (tutorialButton.evaluate().isNotEmpty) {
        await tester.tap(tutorialButton);
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(tester.takeException(), isNull);
    }

    await render(const MiniGamesScreen());
    await render(const InfinityLoopGame());
    await tester.tap(find.text('Together'));
    await tester.pump();
    expect(find.textContaining('Player 1'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await render(const ChickenTapGame());
    await tester.tap(find.text('▶ START'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);

    await render(const StackMergeGame());
    await tester.tap(find.byIcon(Icons.arrow_downward_rounded));
    await tester.pump(const Duration(milliseconds: 1600));
    expect(tester.takeException(), isNull);

    await render(const Classic2048Game());
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
