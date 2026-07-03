import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/mini_games/data/mini_games_repository.dart';
import 'package:kidverse/features/mini_games/games/chicken_tap_game.dart';
import 'package:kidverse/features/mini_games/games/classic_2048_game.dart';
import 'package:kidverse/features/mini_games/games/infinity_loop_game.dart';
import 'package:kidverse/features/mini_games/games/stack_merge_game.dart';
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

      expect(controller.state['368-chickens'], 25);
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
      expect(tester.takeException(), isNull);
    }

    await render(const MiniGamesScreen());
    await render(const InfinityLoopGame());
    await render(const ChickenTapGame());
    await render(const StackMergeGame());
    await render(const Classic2048Game());
  });
}
