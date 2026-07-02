import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/celebration_overlay.dart';
import '../../core/widgets/currency_hud.dart';
import '../../core/widgets/lottie_view.dart';
import '../../core/widgets/mascot.dart';
import '../../l10n/app_localizations.dart';
import '../collections/domain/collectible.dart';
import '../curriculum/data/curriculum_repository.dart';
import '../curriculum/domain/subject.dart';
import '../profiles/domain/child_profile.dart';
import '../profiles/profiles_controller.dart';
import '../profiles/widgets/avatar_view.dart';
import '../rewards/daily_reward_controller.dart';
import '../rewards/daily_reward_sheet.dart';
import '../spin/lucky_spin_controller.dart';

/// The home world: greeting + HUD + daily mission + learning map of subjects.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _celebration = CelebrationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.playMusic(MusicTrack.home);
      final child = ref.read(activeChildProvider);
      if (child != null) {
        AudioService.instance
            .speak('Welcome back ${child.name}! What shall we learn today?');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(activeChildProvider);
    final curriculumAsync = ref.watch(curriculumLoadProvider);

    if (child == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return CelebrationOverlay(
      controller: _celebration,
      child: Scaffold(
        body: AnimatedBackground(
          theme: WorldTheme.fromId(child.activeTheme),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _TopBar(child: child)),
                SliverToBoxAdapter(child: _Greeting(child: child)),
                SliverToBoxAdapter(child: _DailyMission()),
                const SliverToBoxAdapter(child: _QuickActions()),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: curriculumAsync.when(
                    loading: () => const SliverToBoxAdapter(
                      child: Center(
                        child: LottieView(
                          asset: 'assets/lottie/loading_star.json',
                          width: 120,
                          height: 120,
                          fallback: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: Center(child: Text('Oops: $e')),
                    ),
                    data: (repo) => _SubjectGrid(repo: repo),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.child});
  final ChildProfile child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = child.wallet;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          BouncyButton(
            onTap: () => context.go(AppRoutes.profilePicker),
            child: AvatarView(config: child.avatar, size: 56),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                CurrencyChip.coins(w.coins),
                const SizedBox(width: 8),
                CurrencyChip.gems(w.gems),
              ],
            ),
          ),
          BouncyButton(
            sound: Sfx.tap,
            onTap: () => context.push(AppRoutes.settings),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings_rounded, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.child});
  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final w = child.wallet;
    final pet = child.activePetId == null
        ? null
        : CollectionCatalog.byId(child.activePetId!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              MascotView(
                mascot: Mascot.values.firstWhere(
                  (m) => m.name == child.mascotId,
                  orElse: () => Mascot.panda,
                ),
                size: 96,
              ),
              if (pet != null)
                Positioned(
                  right: -6,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child:
                        Text(pet.emoji, style: const TextStyle(fontSize: 26)),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                        begin: 0,
                        end: -4,
                        duration: 1200.ms,
                        curve: Curves.easeInOut,
                      ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).greeting(child.name),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Level ${w.level}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '🔥 ${w.streakDays} day streak',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ProgressBarKid(progress: w.levelProgress),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }
}

class _DailyMission extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
          ),
          borderRadius: AppSpacing.cardRadius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 44)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Mission",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Complete 3 games to earn a treasure chest!',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  const ProgressBarKid(
                    progress: 0.33,
                    color: Colors.white,
                    height: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}

/// Quick access to Badges and the Daily Gift.
class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canClaim =
        ref.watch(dailyRewardControllerProvider.notifier).canClaimToday;
    final canSpin =
        ref.watch(luckySpinControllerProvider.notifier).canSpinToday;
    // Watch state so the dots update after claiming/spinning.
    ref.watch(dailyRewardControllerProvider);
    ref.watch(luckySpinControllerProvider);

    Widget action({
      required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap,
      bool showDot = false,
    }) {
      return SizedBox(
        width: 108,
        child: BouncyButton(
          borderRadius: AppSpacing.cardRadius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppSpacing.cardRadius,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: color, size: 34),
                    if (showDot)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(label, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            action(
              icon: Icons.emoji_events_rounded,
              label: 'Badges',
              color: AppColors.star,
              onTap: () => context.push(AppRoutes.achievements),
            ),
            const SizedBox(width: AppSpacing.md),
            action(
              icon: Icons.card_giftcard_rounded,
              label: 'Daily Gift',
              color: AppColors.secondary,
              showDot: canClaim,
              onTap: () => showDailyRewardSheet(context),
            ),
            const SizedBox(width: AppSpacing.md),
            action(
              icon: Icons.casino_rounded,
              label: 'Spin',
              color: AppColors.gem,
              showDot: canSpin,
              onTap: () => context.push(AppRoutes.spin),
            ),
            const SizedBox(width: AppSpacing.md),
            action(
              icon: Icons.storefront_rounded,
              label: 'Shop',
              color: AppColors.mint,
              onTap: () => context.push(AppRoutes.shop),
            ),
            const SizedBox(width: AppSpacing.md),
            action(
              icon: Icons.pets_rounded,
              label: 'Collect',
              color: AppColors.bubblegum,
              onTap: () => context.push(AppRoutes.collection),
            ),
            const SizedBox(width: AppSpacing.md),
            action(
              icon: Icons.leaderboard_rounded,
              label: 'Friends',
              color: AppColors.sky,
              onTap: () => context.push(AppRoutes.leaderboard),
            ),
            const SizedBox(width: AppSpacing.md),
            action(
              icon: Icons.auto_awesome_rounded,
              label: 'Season',
              color: AppColors.primary,
              onTap: () => context.push(AppRoutes.season),
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns a **sliver** (used directly inside [SliverPadding.sliver]).
class _SubjectGrid extends ConsumerWidget {
  const _SubjectGrid({required this.repo});
  final CurriculumRepository repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(activeChildProvider)!;
    final subjects = repo.subjectsForGrade(child.grade).toList();
    if (subjects.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'More lessons coming soon! 🚀',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => _SubjectCard(subject: subjects[i])
            .animate()
            .fadeIn(delay: (80 * i).ms)
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
        childCount: subjects.length,
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject});
  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      borderRadius: AppSpacing.cardRadius,
      onTap: () {
        AudioService.instance.speak("Let's explore ${subject.label}!");
        context.push(AppRoutes.learningMap, extra: subject);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [subject.color, subject.color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppSpacing.cardRadius,
          boxShadow: [
            BoxShadow(
              color: subject.color.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(subject.icon, size: 56, color: Colors.white),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                subject.label,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
