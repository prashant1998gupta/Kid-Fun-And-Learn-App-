import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kidverse/app/router.dart';
import 'package:kidverse/core/services/audio_service.dart';
import 'package:kidverse/core/theme/app_colors.dart';
import 'package:kidverse/core/theme/app_theme.dart';
import 'package:kidverse/features/curriculum/domain/lesson.dart';
import 'package:kidverse/features/curriculum/domain/subject.dart';
import 'package:kidverse/features/games/game_host_screen.dart';
import 'package:kidverse/features/home/home_screen.dart';
import 'package:kidverse/features/mini_games/games/chicken_tap_game.dart';
import 'package:kidverse/features/mini_games/games/classic_2048_game.dart';
import 'package:kidverse/features/mini_games/games/infinity_loop_game.dart';
import 'package:kidverse/features/mini_games/games/stack_merge_game.dart';
import 'package:kidverse/features/profiles/domain/child_profile.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';
import 'package:kidverse/features/profiles/profile_create_screen.dart';
import 'package:kidverse/features/profiles/profile_picker_screen.dart';
import 'package:kidverse/features/profiles/profiles_controller.dart';
import 'package:kidverse/features/settings/settings_controller.dart';
import 'package:kidverse/features/world/kid_world_screen.dart';
import 'package:kidverse/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (_) async => null,
    );
    AudioService.instance
      ..sfxEnabled = false
      ..musicEnabled = false
      ..voiceEnabled = false
      ..hapticsEnabled = false;
  });

  testWidgets('profile cards never overflow on a phone viewport',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final children = [
      _child('one', 'Gggg'),
      _child('two', 'Trigger'),
      _child('three', 'A very long child name'),
    ];
    final preferences = await _preferences(children);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(home: ProfilePickerScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Gggg'), findsOneWidget);
    expect(find.text('Trigger'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('profile creation stays readable in dark mode', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: const ProfileCreateScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final nameField = tester.widget<TextField>(find.byType(TextField));
    expect(nameField.style?.color, AppColors.lightText);
    final unselected = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .firstWhere(
            (chip) => chip.label is Text && (chip.label as Text).data == 'KG');
    expect(unselected.backgroundColor, const Color(0xFFF1EFFF));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Kid World keeps the companion fully inside its scene',
      (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final child = _child('world', 'Sdf Sdf').copyWith(
      companionXp: 12,
      ownedRoomItems: const ['room_rocket'],
      placedRoomItems: const ['room_rocket'],
    );
    final preferences = await _preferences([child]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: const KidWorldScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    final scene =
        tester.getRect(find.byKey(const ValueKey('living-world-scene')));
    final label = tester
        .getRect(find.byKey(const ValueKey('living-world-companion-label')));
    expect(scene.contains(label.topLeft), isTrue);
    expect(scene.contains(label.bottomRight), isTrue);
    expect(find.text('🐣'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Home renders cleanly in the screenshot-sized dark viewport',
      (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferences = await _preferences([_child('home', 'Sdf Sdf')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Hi Sdf Sdf'), findsOneWidget);
    expect(find.text('Enter My World'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Math'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('lesson mission completes, persists reward, and continues safely',
      (tester) async {
    final preferences = await _preferences([_child('player', 'Mia')]);
    const lesson = Lesson(
      id: 'stable-math-1',
      title: 'Moon Numbers',
      subject: Subject.math,
      grade: GradeLevel.kg,
      gameType: GameType.tapChoice,
      questions: [
        Question(
          id: 'q1',
          prompt: 'Two plus two?',
          correctIndex: 1,
          options: [AnswerOption(label: '3'), AnswerOption(label: '4')],
        ),
      ],
    );
    final router = GoRouter(
      initialLocation: AppRoutes.game,
      routes: [
        GoRoute(
          path: AppRoutes.game,
          builder: (_, __) => const GameHostScreen(lesson: lesson),
        ),
        GoRoute(
          path: AppRoutes.learningMap,
          builder: (_, __) => const Scaffold(body: Text('MAP-SAFE')),
        ),
        GoRoute(
          path: AppRoutes.kidWorld,
          builder: (_, __) => const Scaffold(body: Text('WORLD-SAFE')),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const Scaffold(body: Text('HOME-SAFE')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    expect(find.text('Repair the Moon Bridge'), findsOneWidget);

    await tester.ensureVisible(find.text('Show me first! 👀'));
    await tester.pump();
    await tester.tap(find.text('Show me first! 👀'));
    await tester.pump();
    expect(find.text('👀 Watch Spark first'), findsOneWidget);
    await tester.tap(find.text('Now let’s do it together'));
    await tester.pump();
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1650));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Great Job!'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameHostScreen)),
    );
    final child = container.read(activeChildProvider)!;
    expect(child.completedAdventures, 1);
    expect(
      child.ownedRoomItems.isNotEmpty ||
          child.ownedCollectibles.contains('st_star') ||
          child.companionXp > 0,
      isTrue,
    );

    await tester.tap(find.text('Continue Adventure 🚀'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
        router.routeInformationProvider.value.uri.path, AppRoutes.learningMap);
    expect(find.text('MAP-SAFE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all mini-games render on a compact phone without layout errors',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'mg_tutorial_infinity-loop': true,
      'mg_tutorial_368-chickens': true,
      'mg_tutorial_stack-merge': true,
      'mg_tutorial_2048': true,
    });
    final preferences = await SharedPreferences.getInstance();

    Future<void> render(Widget game) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.2),
              ),
              child: child!,
            ),
            home: game,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull,
          reason: game.runtimeType.toString());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    await render(const InfinityLoopGame());
    await render(const ChickenTapGame());
    await render(const StackMergeGame());
    await render(const Classic2048Game());

    tester.view.physicalSize = const Size(568, 320);
    await render(const InfinityLoopGame());
    await render(const ChickenTapGame());
    await render(const StackMergeGame());
    await render(const Classic2048Game());
  });

  testWidgets('rapid mini-game input, restart, and disposal stay safe',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'mg_tutorial_infinity-loop': true,
      'mg_tutorial_368-chickens': true,
      'mg_tutorial_stack-merge': true,
      'mg_tutorial_2048': true,
    });
    final preferences = await SharedPreferences.getInstance();

    Future<void> show(Widget game) => tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(preferences),
            ],
            child: MaterialApp(home: game),
          ),
        );

    await show(const StackMergeGame());
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_downward_rounded));
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);

    await show(const Classic2048Game());
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.tap(find.byIcon(Icons.arrow_downward_rounded));
    }
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);

    await show(const ChickenTapGame());
    await tester.pump();
    await tester.tap(find.text('▶ START'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}

ChildProfile _child(String id, String name) => ChildProfile(
      id: id,
      name: name,
      grade: GradeLevel.kg,
      avatar: const AvatarConfig(),
    );

Future<SharedPreferences> _preferences(List<ChildProfile> children) async {
  SharedPreferences.setMockInitialValues({
    'child_profiles':
        jsonEncode(children.map((child) => child.toMap()).toList()),
    'active_child_id': children.first.id,
  });
  return SharedPreferences.getInstance();
}
