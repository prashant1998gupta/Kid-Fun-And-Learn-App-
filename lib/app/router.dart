import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/curriculum/domain/lesson.dart';
import '../features/games/game_host_screen.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/art_studio/art_studio_screen.dart';
import '../features/mini_games/mini_games_screen.dart';
import '../features/mini_games/games/chicken_tap_game.dart';
import '../features/mini_games/games/classic_2048_game.dart';
import '../features/mini_games/games/infinity_loop_game.dart';
import '../features/mini_games/games/stack_merge_game.dart';
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
  static const miniGames = '/mini-games';
  static const infinityLoop = '/mini-games/infinity-loop';
  static const chickenTap = '/mini-games/368-chickens';
  static const stackMerge = '/mini-games/stack-merge';
  static const classic2048 = '/mini-games/2048';
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
          final subject = s.extra as Subject;
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
          final lesson = s.extra as Lesson;
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
