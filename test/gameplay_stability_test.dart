import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kidverse/app/router.dart';
import 'package:kidverse/core/constants/feedback_timing.dart';
import 'package:kidverse/core/services/audio_service.dart';
import 'package:kidverse/core/theme/app_colors.dart';
import 'package:kidverse/core/theme/app_theme.dart';
import 'package:kidverse/features/achievements/achievements_screen.dart';
import 'package:kidverse/features/ai/adaptive_engine.dart';
import 'package:kidverse/features/art_studio/art_studio_screen.dart';
import 'package:kidverse/features/auth/sign_in_screen.dart';
import 'package:kidverse/features/certificates/certificate_screen.dart';
import 'package:kidverse/features/collections/collection_screen.dart';
import 'package:kidverse/features/curriculum/domain/lesson.dart';
import 'package:kidverse/features/curriculum/domain/subject.dart';
import 'package:kidverse/features/gamification/domain/wallet.dart';
import 'package:kidverse/features/gamification/reward_engine.dart';
import 'package:kidverse/features/games/adventure_intro.dart';
import 'package:kidverse/features/games/engines/flashcard_game.dart';
import 'package:kidverse/features/games/engines/bubble_pop_game.dart';
import 'package:kidverse/features/games/engines/boss_battle_game.dart';
import 'package:kidverse/features/games/engines/drag_drop_game.dart';
import 'package:kidverse/features/games/engines/feed_pet_game.dart';
import 'package:kidverse/features/games/engines/listen_and_tap_game.dart';
import 'package:kidverse/features/games/engines/memory_match_game.dart';
import 'package:kidverse/features/games/engines/mole_match_game.dart';
import 'package:kidverse/features/games/engines/sequence_game.dart';
import 'package:kidverse/features/games/engines/speech_game.dart';
import 'package:kidverse/features/games/engines/tap_choice_game.dart';
import 'package:kidverse/features/games/engines/tracing_game.dart';
import 'package:kidverse/features/games/game_host_screen.dart';
import 'package:kidverse/features/games/game_result_screen.dart';
import 'package:kidverse/features/games/learning_support.dart';
import 'package:kidverse/features/home/home_screen.dart';
import 'package:kidverse/features/leaderboard/leaderboard_screen.dart';
import 'package:kidverse/features/learning_map/learning_map_screen.dart';
import 'package:kidverse/features/mini_games/games/chicken_tap_game.dart';
import 'package:kidverse/features/mini_games/games/classic_2048_game.dart';
import 'package:kidverse/features/mini_games/games/infinity_loop_game.dart';
import 'package:kidverse/features/mini_games/games/stack_merge_game.dart';
import 'package:kidverse/features/mini_games/mini_games_screen.dart';
import 'package:kidverse/features/mini_games/widgets/game_tutorial.dart';
import 'package:kidverse/features/mini_games/widgets/mini_game_widgets.dart';
import 'package:kidverse/features/onboarding/onboarding_screen.dart';
import 'package:kidverse/features/onboarding/splash_screen.dart';
import 'package:kidverse/features/parent/parent_gate.dart';
import 'package:kidverse/features/parent/parent_dashboard_screen.dart';
import 'package:kidverse/features/preschool_library/preschool_practice_screen.dart';
import 'package:kidverse/features/profiles/domain/child_profile.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';
import 'package:kidverse/features/profiles/profile_create_screen.dart';
import 'package:kidverse/features/profiles/profile_picker_screen.dart';
import 'package:kidverse/features/profiles/profiles_controller.dart';
import 'package:kidverse/features/rewards/daily_reward_sheet.dart';
import 'package:kidverse/features/settings/about_screen.dart';
import 'package:kidverse/features/settings/settings_controller.dart';
import 'package:kidverse/features/settings/settings_screen.dart';
import 'package:kidverse/features/season/season_pass_screen.dart';
import 'package:kidverse/features/shop/shop_screen.dart';
import 'package:kidverse/features/spin/lucky_spin_screen.dart';
import 'package:kidverse/features/story_maker/story_maker_screen.dart';
import 'package:kidverse/features/world/kid_world_screen.dart';
import 'package:kidverse/features/world/domain/world_prize.dart';
import 'package:kidverse/features/world/physical_mission_screen.dart';
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

  testWidgets('profile flow survives tiny phones with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final children = [
      _child('tiny-one', 'A very very long child name'),
      _child('tiny-two', 'Mia'),
    ];
    final preferences = await _preferences(children);

    Widget wrap(Widget child) => ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: child,
          ),
        );

    await tester.pumpWidget(wrap(const ProfilePickerScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Parents'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(wrap(const ProfileCreateScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Create Your Character'), findsOneWidget);
    expect(find.text("Let's Play!"), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  testWidgets('Home top sections survive tiny phones with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final child = _child(
      'tiny-home',
      'A very very long learner name',
    ).copyWith(
      wallet: const Wallet(coins: 123456, gems: 999, xp: 2200, streakDays: 21),
    );
    final preferences = await _preferences([child]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Hi A very very long'), findsOneWidget);
    expect(find.text('123456'), findsOneWidget);
    expect(find.text('999'), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('🌞'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('How do you feel today?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Calm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'shop, badge, and collection grids survive tiny phones with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final child = _child('tiny-shop', 'Mia').copyWith(
      wallet: const Wallet(coins: 987654, gems: 321),
      ownedCollectibles: const ['pet_puppy', 'pet_kitten', 'st_star'],
      activePetId: 'pet_puppy',
    );
    final preferences = await _preferences([child]);

    Future<void> render(Widget screen) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: screen,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull,
          reason: screen.runtimeType.toString());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    await render(const ShopScreen());
    await render(const AchievementsScreen());
    await render(const CollectionScreen());
  });

  testWidgets('Mini Games hub survives tiny phones with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final child = _child('tiny-mini-hub', 'A very long player name').copyWith(
      grade: GradeLevel.lkg,
      siblingCoopEnabled: true,
    );
    final preferences = await _preferences([child]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const MiniGamesScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('🎮 Mini Games'), findsOneWidget);
    expect(find.text('Choose your power:'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('💖 Kind'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('💖 Kind ending'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithText(ChoiceChip, 'My Learning'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Toy Sort'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('reward and map hubs survive tiny phones with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final child = _child('tiny-rewards', 'A very long player name').copyWith(
      wallet: const Wallet(coins: 987654, gems: 321, xp: 4321),
    );
    final preferences = await _preferences([child]);

    Future<void> render(Widget screen) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: screen,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull,
          reason: screen.runtimeType.toString());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    await render(const SeasonPassScreen());
    await render(const LuckySpinScreen());
    await render(const LeaderboardScreen());
    await render(const LearningMapScreen(subject: Subject.math));
  });

  testWidgets(
      'creative and parent screens survive tiny phones with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final child = _child(
      'tiny-creative-parent',
      'A very very long creative learner name',
    ).copyWith(
      wallet: const Wallet(coins: 987654, gems: 321, xp: 4321, streakDays: 99),
    );
    final preferences = await _preferences([child]);

    Future<void> render(Widget screen) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: screen,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull,
          reason: screen.runtimeType.toString());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    await render(const ArtStudioScreen());
    await render(const StoryMakerScreen());
    await render(const ParentDashboardScreen());
  });

  testWidgets('edge utility screens survive tiny phones with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final child = _child(
      'tiny-edge',
      'A very very long certificate learner name',
    ).copyWith(
      wallet: const Wallet(coins: 987654, gems: 321, xp: 4321, streakDays: 99),
    );
    final preferences = await _preferences([child]);
    const resultLesson = Lesson(
      id: 'edge-result',
      title: 'Tiny Result Mission',
      subject: Subject.math,
      grade: GradeLevel.kg,
      gameType: GameType.tapChoice,
      questions: [
        Question(
          id: 'q1',
          prompt: 'One plus one?',
          correctIndex: 1,
          options: [AnswerOption(label: '1'), AnswerOption(label: '2')],
        ),
      ],
    );

    Future<void> render(Widget screen) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: screen,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull,
          reason: screen.runtimeType.toString());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    await render(const OnboardingScreen());
    await render(const SignInScreen());
    await render(const CertificateScreen());
    await render(const PhysicalMissionScreen());
    await render(
      GameResultScreen(
        result: const LessonResult(
          lesson: resultLesson,
          correct: 1,
          total: 1,
          firstTryCorrect: 1,
        ),
        reward: const RewardBundle(coins: 123456, xp: 9999, gems: 3, stars: 3),
        leveledUp: true,
        newLevel: 123,
        onReplay: () {},
        onContinue: () {},
        onVisitWorld: () {},
        onHome: () {},
        prize: WorldPrizeCatalog.all.first,
        prizeWasNew: true,
      ),
    );
  });

  testWidgets('settings, splash, and preschool hub survive tiny phones',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final child = _child(
      'tiny-final',
      'A very very long preschool learner name',
    ).copyWith(grade: GradeLevel.lkg);
    final preferences = await _preferences([child]);

    Future<void> render(Widget screen) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: screen,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull,
          reason: screen.runtimeType.toString());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    await render(const SplashScreen());
    await render(const SettingsScreen());
    await render(const AboutScreen());
    await render(const PreschoolPracticeScreen());
  });

  testWidgets('shared gates, sheets, and intros survive tiny large-text phones',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferences = await _preferences([_child('tiny-shared', 'Mia')]);

    Widget app(Widget screen) => ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: screen,
          ),
        );

    Future<void> render(Widget screen) async {
      await tester.pumpWidget(app(screen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull,
          reason: screen.runtimeType.toString());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    await render(
      AdventureIntro(
        mission: const AdventureMission(
          '🌙',
          'Repair the Moon Bridge',
          'The number stones have floated away! Help your team solve the '
              'puzzles and rebuild the bridge.',
        ),
        lessonTitle: 'A very long lesson title that still needs to fit',
        skillName: 'early number sense',
        teachingTip:
            'Watch first, then try with Spark, then do one by yourself.',
        isNewSkill: true,
        supportStage: LearningSupportStage.watch,
        foundationNote: 'Tiny reminder: count slowly and tap gently.',
        onStart: () {},
      ),
    );
    await render(const DailyRewardSheet());
    await render(const ParentGateScreen());
  });

  testWidgets('text input screens survive tiny phones with keyboard open',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final preferences = await _preferences([
      _child('keyboard-child', 'Keyboard Kid'),
    ]);

    Future<void> render(Widget screen) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.4),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: screen,
          ),
        ),
      );
      await tester.pump();
      var field = find.byType(TextField);
      for (var attempt = 0;
          attempt < 5 && field.evaluate().isEmpty;
          attempt++) {
        final scrollable = find.byType(Scrollable);
        expect(scrollable, findsWidgets, reason: screen.runtimeType.toString());
        await tester.drag(scrollable.first, const Offset(0, -180));
        await tester.pump();
        field = find.byType(TextField);
      }
      expect(field, findsWidgets, reason: screen.runtimeType.toString());
      await tester.ensureVisible(field.first);
      await tester.pump();
      await tester.tap(field.first);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull,
          reason: screen.runtimeType.toString());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    await render(const ProfileCreateScreen());
    await render(const SignInScreen());
  });

  testWidgets('play dialogs survive tiny phones with accessibility text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferences = await _preferences([_child('dialog-child', 'Mia')]);
    const longQuestion = Question(
      id: 'dialog-q',
      prompt: 'Which friendly animal is making the sound?',
      correctIndex: 0,
      options: [
        AnswerOption(label: 'A very cheerful elephant', emoji: '🐘'),
        AnswerOption(label: 'A sleepy tiny turtle', emoji: '🐢'),
      ],
      teachingTip:
          'Listen first, look at the pictures, and choose the animal that matches.',
      rescueTip:
          'Slow down and look for the animal with the long trunk. That is the elephant.',
    );

    Future<void> pumpHarness(
      Future<void> Function(BuildContext context) action,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.8),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: FilledButton(
                    onPressed: () => action(context),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    await pumpHarness(
      (context) => showMiniGameHelp(
        context,
        title: 'How to play this wonderfully silly game',
        steps: const [
          'Listen to Spark and look for the biggest friendly clue.',
          'Tap the matching picture when you feel ready.',
          'If it feels tricky, take your time and try again with a smile.',
          'Celebrate every small win because practice grows your brain.',
        ],
      ),
    );
    await pumpHarness(
      (context) => showTutorialAgain(
        context,
        instruction:
            'Tap the glowing card, listen to the helper voice, and try one small step.',
        emoji: '👆',
      ),
    );
    await pumpHarness(
      (context) => showWatchDemonstration(context, longQuestion),
    );
    await pumpHarness(
      (context) => showLearningRescue(context, longQuestion),
    );
  });

  testWidgets('major screens survive short landscape phones with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final child = _child(
      'landscape-child',
      'A very long landscape learner name',
    ).copyWith(
      grade: GradeLevel.lkg,
      wallet: const Wallet(coins: 987654, gems: 321, xp: 4321, streakDays: 99),
      ownedCollectibles: const ['pet_puppy', 'pet_kitten', 'st_star'],
      activePetId: 'pet_puppy',
      siblingCoopEnabled: true,
    );
    final preferences = await _preferences([child]);
    const resultLesson = Lesson(
      id: 'landscape-result',
      title: 'Landscape Result Mission',
      subject: Subject.math,
      grade: GradeLevel.kg,
      gameType: GameType.tapChoice,
      questions: [
        Question(
          id: 'landscape-q1',
          prompt: 'One plus one?',
          correctIndex: 1,
          options: [AnswerOption(label: '1'), AnswerOption(label: '2')],
        ),
      ],
    );

    Future<void> render(Widget screen) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.2),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: screen,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull,
          reason: screen.runtimeType.toString());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    await render(const ProfilePickerScreen());
    await render(const ProfileCreateScreen());
    await render(const HomeScreen());
    await render(const KidWorldScreen());
    await render(const MiniGamesScreen());
    await render(const PreschoolPracticeScreen());
    await render(const ShopScreen());
    await render(const AchievementsScreen());
    await render(const CollectionScreen());
    await render(const SeasonPassScreen());
    await render(const LuckySpinScreen());
    await render(const LeaderboardScreen());
    await render(const LearningMapScreen(subject: Subject.math));
    await render(const ArtStudioScreen());
    await render(const StoryMakerScreen());
    await render(const ParentDashboardScreen());
    await render(const SettingsScreen());
    await render(const AboutScreen());
    await render(const OnboardingScreen());
    await render(const SplashScreen());
    await render(
      GameResultScreen(
        result: const LessonResult(
          lesson: resultLesson,
          correct: 1,
          total: 1,
          firstTryCorrect: 1,
        ),
        reward: const RewardBundle(coins: 123456, xp: 9999, gems: 3, stars: 3),
        leveledUp: true,
        newLevel: 123,
        onReplay: () {},
        onContinue: () {},
        onVisitWorld: () {},
        onHome: () {},
        prize: WorldPrizeCatalog.all.first,
        prizeWasNew: true,
      ),
    );
  });

  testWidgets('real app routes survive tiny phone navigation with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'child_profiles': jsonEncode([
        _child('route-child', 'A very long route learner name')
            .copyWith(
              grade: GradeLevel.lkg,
              wallet: const Wallet(
                  coins: 987654, gems: 321, xp: 4321, streakDays: 99),
              ownedCollectibles: const ['pet_puppy', 'pet_kitten', 'st_star'],
              activePetId: 'pet_puppy',
              siblingCoopEnabled: true,
            )
            .toMap(),
      ]),
      'active_child_id': 'route-child',
      'mg_tutorial_infinity-loop': true,
      'mg_tutorial_368-chickens': true,
      'mg_tutorial_stack-merge': true,
      'mg_tutorial_2048': true,
      'mg_tutorial_toy-sort': true,
      'mg_tutorial_feed-the-pet': true,
      'mg_tutorial_sound-safari': true,
      'mg_tutorial_number-garden': true,
      'mg_tutorial_story-train': true,
      'mg_tutorial_letter-bakery': true,
      'mg_tutorial_clean-room-helper': true,
      'mg_tutorial_math-market': true,
      'mg_tutorial_word-wizard-workshop': true,
      'mg_tutorial_sentence-train': true,
      'mg_tutorial_clock-adventure': true,
      'mg_tutorial_nature-detective': true,
      'mg_tutorial_shape-builder': true,
      'mg_tutorial_fraction-cafe': true,
      'mg_tutorial_multiplication-kingdom': true,
      'mg_tutorial_grammar-detective': true,
      'mg_tutorial_code-the-robot': true,
      'mg_tutorial_science-machine-lab': true,
      'mg_tutorial_map-quest': true,
      'mg_tutorial_eco-city-builder': true,
      'mg_tutorial_space-mission-control': true,
      'mg_tutorial_business-bazaar': true,
      'mg_tutorial_mystery-science-lab': true,
      'mg_tutorial_news-detective': true,
      'mg_tutorial_algorithm-quest': true,
    });
    final preferences = await SharedPreferences.getInstance();
    GoRouter? appRouter;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: Consumer(
          builder: (context, ref, _) {
            appRouter ??= ref.watch(routerProvider);
            return MaterialApp.router(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: appRouter!,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.35),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    Future<void> go(String route, Finder visibleText) async {
      appRouter!.go(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 850));
      expect(visibleText, findsWidgets, reason: route);
      expect(tester.takeException(), isNull, reason: route);
    }

    await go(AppRoutes.home, find.byType(HomeScreen));
    await go(AppRoutes.miniGames, find.byType(MiniGamesScreen));
    await go(AppRoutes.preschoolPractice, find.byType(PreschoolPracticeScreen));
    await go(AppRoutes.kidWorld, find.byType(KidWorldScreen));
    await go(AppRoutes.shop, find.byType(ShopScreen));
    await go(AppRoutes.collection, find.byType(CollectionScreen));
    await go(AppRoutes.settings, find.byType(SettingsScreen));
    await go(AppRoutes.artStudio, find.byType(ArtStudioScreen));
    await go(AppRoutes.storyMaker, find.byType(StoryMakerScreen));
    await go(AppRoutes.parentGate, find.byType(ParentGateScreen));
    await go(AppRoutes.infinityLoop, find.byType(InfinityLoopGame));
    await go(AppRoutes.stackMerge, find.byType(StackMergeGame));
    await go(AppRoutes.classic2048, find.byType(Classic2048Game));
    await go(AppRoutes.chickenTap, find.byType(ChickenTapGame));
  });

  testWidgets('all real mini-game routes survive tiny phones with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'child_profiles': jsonEncode([
        _child('route-mini-child', 'A very long mini route learner name')
            .copyWith(
              grade: GradeLevel.lkg,
              wallet: const Wallet(
                  coins: 987654, gems: 321, xp: 4321, streakDays: 99),
              siblingCoopEnabled: true,
            )
            .toMap(),
      ]),
      'active_child_id': 'route-mini-child',
      'mg_tutorial_infinity-loop': true,
      'mg_tutorial_368-chickens': true,
      'mg_tutorial_stack-merge': true,
      'mg_tutorial_2048': true,
      'mg_tutorial_toy-sort': true,
      'mg_tutorial_feed-the-pet': true,
      'mg_tutorial_sound-safari': true,
      'mg_tutorial_number-garden': true,
      'mg_tutorial_story-train': true,
      'mg_tutorial_letter-bakery': true,
      'mg_tutorial_clean-room-helper': true,
      'mg_tutorial_math-market': true,
      'mg_tutorial_word-wizard-workshop': true,
      'mg_tutorial_sentence-train': true,
      'mg_tutorial_clock-adventure': true,
      'mg_tutorial_nature-detective': true,
      'mg_tutorial_shape-builder': true,
      'mg_tutorial_fraction-cafe': true,
      'mg_tutorial_multiplication-kingdom': true,
      'mg_tutorial_grammar-detective': true,
      'mg_tutorial_code-the-robot': true,
      'mg_tutorial_science-machine-lab': true,
      'mg_tutorial_map-quest': true,
      'mg_tutorial_eco-city-builder': true,
      'mg_tutorial_space-mission-control': true,
      'mg_tutorial_business-bazaar': true,
      'mg_tutorial_mystery-science-lab': true,
      'mg_tutorial_news-detective': true,
      'mg_tutorial_algorithm-quest': true,
    });
    final preferences = await SharedPreferences.getInstance();
    GoRouter? appRouter;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: Consumer(
          builder: (context, ref, _) {
            appRouter ??= ref.watch(routerProvider);
            return MaterialApp.router(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: appRouter!,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.35),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    const routes = [
      AppRoutes.toySort,
      AppRoutes.feedThePet,
      AppRoutes.soundSafari,
      AppRoutes.numberGarden,
      AppRoutes.storyTrain,
      AppRoutes.letterBakery,
      AppRoutes.cleanRoomHelper,
      AppRoutes.mathMarket,
      AppRoutes.wordWizard,
      AppRoutes.sentenceTrain,
      AppRoutes.clockAdventure,
      AppRoutes.natureDetective,
      AppRoutes.shapeBuilder,
      AppRoutes.fractionCafe,
      AppRoutes.multiplicationKingdom,
      AppRoutes.grammarDetective,
      AppRoutes.codeTheRobot,
      AppRoutes.scienceMachineLab,
      AppRoutes.mapQuest,
      AppRoutes.ecoCityBuilder,
      AppRoutes.spaceMissionControl,
      AppRoutes.businessBazaar,
      AppRoutes.mysteryScienceLab,
      AppRoutes.newsDetective,
      AppRoutes.algorithmQuest,
      AppRoutes.infinityLoop,
      AppRoutes.chickenTap,
      AppRoutes.stackMerge,
      AppRoutes.classic2048,
    ];

    for (final route in routes) {
      appRouter!.go(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 850));
      expect(appRouter!.routeInformationProvider.value.uri.path, route);
      final exception = tester.takeException();
      if (exception != null) {
        final details = exception is FlutterError
            ? exception.toStringDeep()
            : exception.toString();
        fail('$route\n$details');
      }
    }
  });

  testWidgets('all real app routes survive tiny phones with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'child_profiles': jsonEncode([
        _child('route-app-child', 'A very long app route learner name')
            .copyWith(
              grade: GradeLevel.lkg,
              wallet: const Wallet(
                  coins: 987654, gems: 321, xp: 4321, streakDays: 99),
              ownedCollectibles: const ['pet_puppy', 'pet_kitten', 'st_star'],
              activePetId: 'pet_puppy',
              siblingCoopEnabled: true,
            )
            .toMap(),
      ]),
      'active_child_id': 'route-app-child',
    });
    final preferences = await SharedPreferences.getInstance();
    GoRouter? appRouter;
    const lesson = Lesson(
      id: 'route-game-lesson',
      title: 'Tiny Route Lesson With A Long Name',
      subject: Subject.math,
      grade: GradeLevel.lkg,
      gameType: GameType.tapChoice,
      questions: [
        Question(
          id: 'route-q',
          prompt: 'Which fruit is red?',
          correctIndex: 0,
          options: [
            AnswerOption(label: 'Apple', emoji: '🍎'),
            AnswerOption(label: 'Banana', emoji: '🍌'),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: Consumer(
          builder: (context, ref, _) {
            appRouter ??= ref.watch(routerProvider);
            return MaterialApp.router(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: appRouter!,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.35),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    Future<void> go(String route, {Object? extra}) async {
      appRouter!.go(route, extra: extra);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 850));
      expect(appRouter!.routeInformationProvider.value.uri.path, route);
      final exception = tester.takeException();
      if (exception != null) {
        final details = exception is FlutterError
            ? exception.toStringDeep()
            : exception.toString();
        fail('$route\n$details');
      }
    }

    await go(AppRoutes.onboarding);
    await go(AppRoutes.profilePicker);
    await go(AppRoutes.profileCreate);
    await go(AppRoutes.home);
    await go(AppRoutes.learningMap, extra: Subject.math);
    await go(AppRoutes.preschoolPractice);
    await go(AppRoutes.achievements);
    await go(AppRoutes.shop);
    await go(AppRoutes.collection);
    await go(AppRoutes.spin);
    await go(AppRoutes.game, extra: lesson);
    await go(AppRoutes.settings);
    await go(AppRoutes.about);
    await go(AppRoutes.artStudio);
    await go(AppRoutes.storyMaker);
    await go(AppRoutes.miniGames);
    await go(AppRoutes.kidWorld);
    await go(AppRoutes.physicalMission);
    await go(AppRoutes.parentGate);
    await go(AppRoutes.parentDashboard);
    await go(AppRoutes.signIn);
    await go(AppRoutes.leaderboard);
    await go(AppRoutes.certificate);
    await go(AppRoutes.season);
  });

  testWidgets('core flows survive accessibility text scaling', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final child = _child(
      'access-child',
      'A very long accessibility learner name',
    ).copyWith(
      grade: GradeLevel.lkg,
      wallet: const Wallet(coins: 987654, gems: 321, xp: 4321, streakDays: 99),
      siblingCoopEnabled: true,
    );
    final preferences = await _preferences([child]);
    const resultLesson = Lesson(
      id: 'access-result',
      title: 'Accessibility Result Mission',
      subject: Subject.english,
      grade: GradeLevel.lkg,
      gameType: GameType.tapChoice,
      questions: [
        Question(
          id: 'access-q1',
          prompt: 'Which one is apple?',
          correctIndex: 0,
          options: [
            AnswerOption(label: 'Apple', emoji: '🍎'),
            AnswerOption(label: 'Ball', emoji: '⚽'),
          ],
        ),
      ],
    );

    Future<void> render(Widget screen) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.8),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: screen,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull,
          reason: screen.runtimeType.toString());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    await render(const ProfilePickerScreen());
    await render(const ProfileCreateScreen());
    await render(const HomeScreen());
    await render(const PreschoolPracticeScreen());
    await render(const MiniGamesScreen());
    await render(const SettingsScreen());
    await render(const DailyRewardSheet());
    await render(
      GameResultScreen(
        result: const LessonResult(
          lesson: resultLesson,
          correct: 1,
          total: 1,
          firstTryCorrect: 1,
        ),
        reward: const RewardBundle(coins: 123456, xp: 9999, gems: 3, stars: 3),
        leveledUp: true,
        newLevel: 123,
        onReplay: () {},
        onContinue: () {},
        onVisitWorld: () {},
        onHome: () {},
        prize: WorldPrizeCatalog.all.first,
        prizeWasNew: true,
      ),
    );
    await render(
      TapChoiceGame(
        lesson: resultLesson,
        onComplete: (_) {},
      ),
    );
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

  testWidgets('flashcard lessons survive tiny phones with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const lesson = Lesson(
      id: 'tiny-flashcard',
      title: 'Tiny Flashcards',
      subject: Subject.english,
      grade: GradeLevel.lkg,
      gameType: GameType.flashcard,
      questions: [
        Question(
          id: 'flash-a',
          prompt: 'Aa',
          promptEmoji: '🍎',
          answer: 'Apple with a very long helper word',
          speak: 'A for apple',
        ),
      ],
    );
    LessonResult? result;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.3),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        home: FlashcardGame(
          lesson: lesson,
          onComplete: (value) => result = value,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Aa'), findsOneWidget);
    expect(find.textContaining('Apple with'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Finish! 🎉'));
    await tester.tap(find.text('Finish! 🎉'));
    await tester.pump(FeedbackTiming.successBeat);
    expect(result?.correct, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all lesson engines render on tiny phones with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const choiceQuestions = [
      Question(
        id: 'tiny-q1',
        prompt: 'Choose the friendly answer with a long prompt',
        correctIndex: 1,
        options: [
          AnswerOption(label: 'Tiny apple', emoji: '🍎'),
          AnswerOption(label: 'Bright banana', emoji: '🍌'),
          AnswerOption(label: 'Curious coconut', emoji: '🥥'),
        ],
      ),
      Question(
        id: 'tiny-q2',
        prompt: 'Choose the second friendly answer',
        correctIndex: 0,
        options: [
          AnswerOption(label: 'Happy mango', emoji: '🥭'),
          AnswerOption(label: 'Round grape', emoji: '🍇'),
        ],
      ),
    ];
    const orderQuestions = [
      Question(
        id: 'tiny-order',
        prompt: 'Put the morning routine in order',
        options: [
          AnswerOption(label: 'Wake up', emoji: '☀️'),
          AnswerOption(label: 'Brush', emoji: '🪥'),
          AnswerOption(label: 'Eat', emoji: '🥣'),
        ],
      ),
    ];
    const traceQuestions = [
      Question(id: 'tiny-trace', prompt: 'Trace A', answer: 'A'),
    ];
    const speechQuestions = [
      Question(
        id: 'tiny-speech',
        prompt: 'elephant',
        answer: 'elephant',
        speak: 'Say elephant',
      ),
    ];

    final engines = <String, Widget Function(ValueChanged<LessonResult>)>{
      'tap choice': (onComplete) => TapChoiceGame(
            lesson: _lesson(
              id: 'tiny-tap',
              type: GameType.tapChoice,
              questions: choiceQuestions,
            ),
            onComplete: onComplete,
          ),
      'listen and tap': (onComplete) => ListenAndTapGame(
            lesson: _lesson(
              id: 'tiny-listen',
              type: GameType.listenAndTap,
              questions: choiceQuestions,
            ),
            onComplete: onComplete,
          ),
      'bubble pop': (onComplete) => BubblePopGame(
            lesson: _lesson(
              id: 'tiny-bubble',
              type: GameType.bubblePop,
              questions: choiceQuestions,
            ),
            onComplete: onComplete,
          ),
      'boss battle': (onComplete) => BossBattleGame(
            lesson: _lesson(
              id: 'tiny-boss',
              type: GameType.bossBattle,
              questions: choiceQuestions,
              grade: GradeLevel.grade5,
            ),
            onComplete: onComplete,
          ),
      'mole match': (onComplete) => MoleMatchGame(
            lesson: _lesson(
              id: 'tiny-mole',
              type: GameType.moleMatch,
              questions: choiceQuestions,
            ),
            onComplete: onComplete,
          ),
      'feed pet': (onComplete) => FeedPetGame(
            lesson: _lesson(
              id: 'tiny-feed',
              type: GameType.feedPet,
              questions: choiceQuestions,
            ),
            onComplete: onComplete,
          ),
      'memory match': (onComplete) => MemoryMatchGame(
            lesson: _lesson(
              id: 'tiny-memory',
              type: GameType.memoryMatch,
              questions: choiceQuestions,
            ),
            onComplete: onComplete,
          ),
      'drag drop': (onComplete) => DragDropGame(
            lesson: _lesson(
              id: 'tiny-drag',
              type: GameType.dragDrop,
              questions: orderQuestions,
            ),
            onComplete: onComplete,
          ),
      'sequence': (onComplete) => SequenceGame(
            lesson: _lesson(
              id: 'tiny-sequence',
              type: GameType.sequence,
              questions: orderQuestions,
            ),
            onComplete: onComplete,
          ),
      'tracing': (onComplete) => TracingGame(
            lesson: _lesson(
              id: 'tiny-tracing',
              type: GameType.tracing,
              questions: traceQuestions,
            ),
            onComplete: onComplete,
          ),
      'speech': (onComplete) => SpeechGame(
            lesson: _lesson(
              id: 'tiny-speech',
              type: GameType.speak,
              questions: speechQuestions,
            ),
            onComplete: onComplete,
          ),
    };

    for (final entry in engines.entries) {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
          home: entry.value((_) {}),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull, reason: entry.key);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
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

  testWidgets('high-risk play screens survive ultra-narrow large-text phones',
      (tester) async {
    tester.view.physicalSize = const Size(300, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'child_profiles': jsonEncode([
        _child('ultra-play', 'A very long tiny hero name').toMap(),
      ]),
      'active_child_id': 'ultra-play',
      'mg_tutorial_infinity-loop': true,
      'mg_tutorial_368-chickens': true,
      'mg_tutorial_stack-merge': true,
      'mg_tutorial_2048': true,
    });
    final preferences = await SharedPreferences.getInstance();

    Future<void> render(Widget screen) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.6),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: screen,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull,
          reason: screen.runtimeType.toString());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    await render(const StoryMakerScreen());
    await render(const KidWorldScreen());
    await render(const StackMergeGame());
    await render(const Classic2048Game());
    await render(const InfinityLoopGame());
    await render(const ChickenTapGame());
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

Lesson _lesson({
  required String id,
  required GameType type,
  required List<Question> questions,
  GradeLevel grade = GradeLevel.kg,
  Subject subject = Subject.english,
}) =>
    Lesson(
      id: id,
      title: 'Tiny Engine Lesson',
      subject: subject,
      grade: grade,
      gameType: type,
      questions: questions,
    );

Future<SharedPreferences> _preferences(List<ChildProfile> children) async {
  SharedPreferences.setMockInitialValues({
    'child_profiles':
        jsonEncode(children.map((child) => child.toMap()).toList()),
    'active_child_id': children.first.id,
  });
  return SharedPreferences.getInstance();
}
