import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/curriculum/domain/lesson.dart';
import '../features/games/game_host_screen.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/art_studio/art_studio_screen.dart';
import '../features/story_maker/story_maker_screen.dart';
import '../features/mini_games/mini_games_screen.dart';
import '../features/mini_games/games/chicken_tap_game.dart';
import '../features/mini_games/games/classic_2048_game.dart';
import '../features/mini_games/games/infinity_loop_game.dart';
import '../features/mini_games/games/stack_merge_game.dart';
import '../features/mini_games/games/toy_sort_game.dart';
import '../features/mini_games/games/feed_pet_game.dart';
import '../features/mini_games/games/learning_adventure_game.dart';
import '../features/curriculum/domain/subject.dart';
import '../features/home/home_screen.dart';
import '../features/learning_map/learning_map_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/spin/lucky_spin_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/certificates/certificate_screen.dart';
import '../features/collections/collection_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/parent/parent_dashboard_screen.dart';
import '../features/parent/parent_gate.dart';
import '../features/profiles/profile_create_screen.dart';
import '../features/profiles/profile_picker_screen.dart';
import '../features/profiles/profiles_controller.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/season/season_pass_screen.dart';
import '../features/world/kid_world_screen.dart';
import '../features/world/physical_mission_screen.dart';

/// Central route table. Uses [go_router] for typed, deep-linkable navigation
/// with custom kid-friendly transitions.
class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const profilePicker = '/profiles';
  static const profileCreate = '/profiles/create';
  static const home = '/home';
  static const learningMap = '/learning-map';
  static const achievements = '/achievements';
  static const shop = '/shop';
  static const collection = '/collection';
  static const spin = '/spin';
  static const game = '/game';
  static const settings = '/settings';
  static const parentGate = '/parent-gate';
  static const parentDashboard = '/parent';
  static const signIn = '/sign-in';
  static const leaderboard = '/leaderboard';
  static const certificate = '/certificate';
  static const season = '/season';
  static const about = '/about';
  static const artStudio = '/art-studio';
  static const storyMaker = '/story-maker';
  static const miniGames = '/mini-games';
  static const infinityLoop = '/mini-games/infinity-loop';
  static const chickenTap = '/mini-games/368-chickens';
  static const stackMerge = '/mini-games/stack-merge';
  static const classic2048 = '/mini-games/2048';
  static const toySort = '/mini-games/toy-sort';
  static const feedThePet = '/mini-games/feed-the-pet';
  static const soundSafari = '/mini-games/sound-safari';
  static const numberGarden = '/mini-games/number-garden';
  static const storyTrain = '/mini-games/story-train';
  static const letterBakery = '/mini-games/letter-bakery';
  static const cleanRoomHelper = '/mini-games/clean-room-helper';
  static const mathMarket = '/mini-games/math-market';
  static const wordWizard = '/mini-games/word-wizard-workshop';
  static const sentenceTrain = '/mini-games/sentence-train';
  static const clockAdventure = '/mini-games/clock-adventure';
  static const natureDetective = '/mini-games/nature-detective';
  static const shapeBuilder = '/mini-games/shape-builder';
  static const fractionCafe = '/mini-games/fraction-cafe';
  static const multiplicationKingdom = '/mini-games/multiplication-kingdom';
  static const grammarDetective = '/mini-games/grammar-detective';
  static const codeTheRobot = '/mini-games/code-the-robot';
  static const scienceMachineLab = '/mini-games/science-machine-lab';
  static const mapQuest = '/mini-games/map-quest';
  static const ecoCityBuilder = '/mini-games/eco-city-builder';
  static const spaceMissionControl = '/mini-games/space-mission-control';
  static const businessBazaar = '/mini-games/business-bazaar';
  static const mysteryScienceLab = '/mini-games/mystery-science-lab';
  static const newsDetective = '/mini-games/news-detective';
  static const algorithmQuest = '/mini-games/algorithm-quest';
  static const kidWorld = '/kid-world';
  static const physicalMission = '/kid-world/move';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (_, s) => _fade(const OnboardingScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.profilePicker,
        pageBuilder: (_, s) => _fade(const ProfilePickerScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.profileCreate,
        pageBuilder: (_, s) => _slide(const ProfileCreateScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (_, s) => _fade(const HomeScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.learningMap,
        pageBuilder: (context, s) {
          final subject = s.extra;
          if (subject is! Subject) {
            return _fade(const _InvalidDeepLinkScreen(), s);
          }
          return _slide(LearningMapScreen(subject: subject), s);
        },
      ),
      GoRoute(
        path: AppRoutes.achievements,
        pageBuilder: (_, s) => _slide(const AchievementsScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.shop,
        pageBuilder: (_, s) => _slide(const ShopScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.collection,
        pageBuilder: (_, s) => _slide(const CollectionScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.spin,
        pageBuilder: (_, s) => _slide(const LuckySpinScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.game,
        pageBuilder: (context, s) {
          final lesson = s.extra;
          if (lesson is! Lesson) {
            return _fade(const _InvalidDeepLinkScreen(), s);
          }
          return _slide(GameHostScreen(lesson: lesson), s);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (_, s) => _slide(const SettingsScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.about,
        pageBuilder: (_, s) => _slide(const AboutScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.artStudio,
        pageBuilder: (_, s) => _slide(const ArtStudioScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.storyMaker,
        pageBuilder: (_, s) => _slide(const StoryMakerScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.miniGames,
        pageBuilder: (_, s) => _slide(const MiniGamesScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.infinityLoop,
        pageBuilder: (_, s) => _slide(const InfinityLoopGame(), s),
      ),
      GoRoute(
        path: AppRoutes.chickenTap,
        pageBuilder: (_, s) => _slide(const ChickenTapGame(), s),
      ),
      GoRoute(
        path: AppRoutes.stackMerge,
        pageBuilder: (_, s) => _slide(const StackMergeGame(), s),
      ),
      GoRoute(
        path: AppRoutes.classic2048,
        pageBuilder: (_, s) => _slide(const Classic2048Game(), s),
      ),
      GoRoute(
        path: AppRoutes.toySort,
        pageBuilder: (_, s) => _slide(const ToySortGame(), s),
      ),
      GoRoute(
        path: AppRoutes.feedThePet,
        pageBuilder: (_, s) => _slide(const FeedPetGame(), s),
      ),
      GoRoute(
        path: AppRoutes.soundSafari,
        pageBuilder: (_, s) => _slide(const SoundSafariGame(), s),
      ),
      GoRoute(
        path: AppRoutes.numberGarden,
        pageBuilder: (_, s) => _slide(const NumberGardenGame(), s),
      ),
      GoRoute(
        path: AppRoutes.storyTrain,
        pageBuilder: (_, s) => _slide(const StoryTrainGame(), s),
      ),
      GoRoute(
        path: AppRoutes.letterBakery,
        pageBuilder: (_, s) => _slide(const LetterBakeryGame(), s),
      ),
      GoRoute(
        path: AppRoutes.cleanRoomHelper,
        pageBuilder: (_, s) => _slide(const CleanRoomHelperGame(), s),
      ),
      GoRoute(
        path: AppRoutes.mathMarket,
        pageBuilder: (_, s) => _slide(const MathMarketGame(), s),
      ),
      GoRoute(
        path: AppRoutes.wordWizard,
        pageBuilder: (_, s) => _slide(const WordWizardWorkshopGame(), s),
      ),
      GoRoute(
        path: AppRoutes.sentenceTrain,
        pageBuilder: (_, s) => _slide(const SentenceTrainGame(), s),
      ),
      GoRoute(
        path: AppRoutes.clockAdventure,
        pageBuilder: (_, s) => _slide(const ClockAdventureGame(), s),
      ),
      GoRoute(
        path: AppRoutes.natureDetective,
        pageBuilder: (_, s) => _slide(const NatureDetectiveGame(), s),
      ),
      GoRoute(
        path: AppRoutes.shapeBuilder,
        pageBuilder: (_, s) => _slide(const ShapeBuilderGame(), s),
      ),
      GoRoute(
        path: AppRoutes.fractionCafe,
        pageBuilder: (_, s) => _slide(const FractionCafeGame(), s),
      ),
      GoRoute(
        path: AppRoutes.multiplicationKingdom,
        pageBuilder: (_, s) => _slide(const MultiplicationKingdomGame(), s),
      ),
      GoRoute(
        path: AppRoutes.grammarDetective,
        pageBuilder: (_, s) => _slide(const GrammarDetectiveGame(), s),
      ),
      GoRoute(
        path: AppRoutes.codeTheRobot,
        pageBuilder: (_, s) => _slide(const CodeTheRobotGame(), s),
      ),
      GoRoute(
        path: AppRoutes.scienceMachineLab,
        pageBuilder: (_, s) => _slide(const ScienceMachineLabGame(), s),
      ),
      GoRoute(
        path: AppRoutes.mapQuest,
        pageBuilder: (_, s) => _slide(const MapQuestGame(), s),
      ),
      GoRoute(
        path: AppRoutes.ecoCityBuilder,
        pageBuilder: (_, s) => _slide(const EcoCityBuilderGame(), s),
      ),
      GoRoute(
        path: AppRoutes.spaceMissionControl,
        pageBuilder: (_, s) => _slide(const SpaceMissionControlGame(), s),
      ),
      GoRoute(
        path: AppRoutes.businessBazaar,
        pageBuilder: (_, s) => _slide(const BusinessBazaarGame(), s),
      ),
      GoRoute(
        path: AppRoutes.mysteryScienceLab,
        pageBuilder: (_, s) => _slide(const MysteryScienceLabGame(), s),
      ),
      GoRoute(
        path: AppRoutes.newsDetective,
        pageBuilder: (_, s) => _slide(const NewsDetectiveGame(), s),
      ),
      GoRoute(
        path: AppRoutes.algorithmQuest,
        pageBuilder: (_, s) => _slide(const AlgorithmQuestGame(), s),
      ),
      GoRoute(
        path: AppRoutes.kidWorld,
        pageBuilder: (_, s) => _slide(const KidWorldScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.physicalMission,
        pageBuilder: (_, s) => _slide(const PhysicalMissionScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.parentGate,
        pageBuilder: (_, s) => _slide(const ParentGateScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.parentDashboard,
        pageBuilder: (_, s) => _slide(const ParentDashboardScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        pageBuilder: (_, s) => _slide(const SignInScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        pageBuilder: (_, s) => _slide(const LeaderboardScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.certificate,
        pageBuilder: (_, s) => _slide(const CertificateScreen(), s),
      ),
      GoRoute(
        path: AppRoutes.season,
        pageBuilder: (_, s) => _slide(const SeasonPassScreen(), s),
      ),
    ],
    errorBuilder: (_, __) => const _InvalidDeepLinkScreen(),
    redirect: (context, state) {
      // After splash, if there are no child profiles, force onboarding.
      final profiles = ref.read(profilesControllerProvider);
      final loc = state.matchedLocation;
      final atEntry = loc == AppRoutes.splash || loc == AppRoutes.onboarding;
      if (!atEntry && !profiles.hasProfiles && loc == AppRoutes.home) {
        return AppRoutes.profilePicker;
      }
      return null;
    },
  );
});

CustomTransitionPage<void> _fade(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _InvalidDeepLinkScreen extends StatelessWidget {
  const _InvalidDeepLinkScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KidVerse')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🧭', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              const Text(
                'That adventure link is not available.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

CustomTransitionPage<void> _slide(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (_, animation, __, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
