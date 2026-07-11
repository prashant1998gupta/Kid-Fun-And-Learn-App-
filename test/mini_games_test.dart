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
import 'package:kidverse/features/mini_games/games/toy_sort_game.dart';
import 'package:kidverse/features/mini_games/games/feed_pet_game.dart';
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

    test('scores and badges are isolated between child profiles', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final childA = MiniGamesRepository(
        preferences,
        scope: 'child-a',
        fallbackToLegacy: false,
      );
      final childB = MiniGamesRepository(
        preferences,
        scope: 'child-b',
        fallbackToLegacy: false,
      );

      await childA.saveHighScore('2048', 512);
      await childA.unlockAchievements(const ['first_game']);

      expect(childA.highScore('2048'), 512);
      expect(childB.highScore('2048'), 0);
      expect(childA.achievements(), contains('first_game'));
      expect(childB.achievements(), isEmpty);
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
      expect(MiniPet.forXp(repository.petXp()).emoji, '🐥');
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

    test('learning levels and Kid World items persist per child', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final childA = MiniGamesRepository(
        preferences,
        scope: 'learner-a',
        fallbackToLegacy: false,
      );
      final childB = MiniGamesRepository(
        preferences,
        scope: 'learner-b',
        fallbackToLegacy: false,
      );

      expect(await childA.completeLearningLevel('toy-sort', 1), 2);
      await childA.unlockLearningWorldItem('learning_ball');

      expect(childA.learningLevel('toy-sort'), 2);
      expect(childA.learningWorldItems(), contains('learning_ball'));
      expect(childB.learningLevel('toy-sort'), 1);
      expect(childB.learningWorldItems(), isEmpty);
    });

    test('learning level is capped at 50', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = MiniGamesRepository(preferences);

      expect(await repository.completeLearningLevel('feed-the-pet', 50), 50);
      expect(repository.learningLevel('feed-the-pet'), 50);
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

  testWidgets('catalog and all six game screens render on a phone viewport',
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

    await render(const ToySortGame());
    expect(find.textContaining('Level 1/50'), findsOneWidget);
    expect(find.text('RED'), findsOneWidget);
    expect(find.text('YELLOW'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await render(const FeedPetGame());
    expect(find.textContaining('Level 1/50'), findsOneWidget);
    expect(find.byKey(const ValueKey('food-grape')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Toy Sort always advances after a correct basket choice',
      (tester) async {
    SharedPreferences.setMockInitialValues({'mg_tutorial_toy-sort': true});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(home: ToySortGame()),
      ),
    );
    await tester.pump();

    for (var round = 0; round < 5; round++) {
      await tester.tap(find.text('RED'));
      await tester.tap(find.text('YELLOW'));
      await tester.pump(const Duration(milliseconds: 850));
    }

    expect(find.text('World reward!'), findsOneWidget);
    expect(find.byKey(const ValueKey('toy-sort-next-level')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Feed the Pet completes five counting prompts', (tester) async {
    SharedPreferences.setMockInitialValues({'mg_tutorial_feed-the-pet': true});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(home: FeedPetGame()),
      ),
    );
    await tester.pump();

    const rounds = <(String, int)>[
      ('grape', 1),
      ('watermelon', 3),
      ('pear', 2),
      ('carrot', 1),
      ('grape', 3),
    ];
    for (final round in rounds) {
      for (var tap = 0; tap < round.$2; tap++) {
        await tester.tap(find.byKey(ValueKey('food-${round.$1}')));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 950));
    }

    expect(find.text('Counting reward!'), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-pet-next-level')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
  });
}
