import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/services/audio_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../achievements/achievements_controller.dart';
import '../rewards/daily_reward_controller.dart';
import '../spin/lucky_spin_controller.dart';
import 'domain/child_profile.dart';
import 'profiles_controller.dart';
import 'widgets/avatar_view.dart';

/// "Who's playing today?" — the multi-child selector (à la streaming apps).
/// Tapping an avatar sets the active child and enters the home world.
class ProfilePickerScreen extends ConsumerWidget {
  const ProfilePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesControllerProvider);

    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.sunrise,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  "Who's playing today?",
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                const SizedBox(height: 40),
                Expanded(
                  child: GridView.count(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    mainAxisSpacing: AppSpacing.lg,
                    crossAxisSpacing: AppSpacing.lg,
                    children: [
                      for (final child in profiles.children)
                        _ProfileTile(child: child, ref: ref),
                      _AddTile(),
                    ],
                  ),
                ),
                BouncyButton(
                  onTap: () => context.push(AppRoutes.parentGate),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius:
                          const BorderRadius.all(AppSpacing.radiusPill),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Parents',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
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

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.child, required this.ref});
  final ChildProfile child;
  final WidgetRef ref;

  void _select(BuildContext context) async {
    await ref.read(profilesControllerProvider.notifier).selectChild(child.id);
    ref.read(achievementsControllerProvider.notifier).refreshForActiveChild();
    ref.read(dailyRewardControllerProvider.notifier).refreshForActiveChild();
    ref.read(luckySpinControllerProvider.notifier).refreshForActiveChild();
    AudioService.instance.speak('Hi ${child.name}! Ready to play?');
    if (context.mounted) context.go(AppRoutes.home);
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove profile?'),
        content: Text(
          'All progress for "${child.name}" will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () async {
        final confirmed = await _confirmDelete(context);
        if (confirmed && context.mounted) {
          ref.read(profilesControllerProvider.notifier).removeChild(child.id);
        }
      },
      child: BouncyButton(
        borderRadius: AppSpacing.cardRadius,
        onTap: () => _select(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarView(config: child.avatar, size: 102),
            const SizedBox(height: 7),
            Text(
              child.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white),
            ),
            Text(
              child.grade.label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms),
    );
  }
}

class _AddTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      borderRadius: AppSpacing.cardRadius,
      onTap: () => context.push(AppRoutes.profileCreate),
      child: const DottedCircle(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 56),
            SizedBox(height: 8),
            Text(
              'Add Kid',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DottedCircle extends StatelessWidget {
  const DottedCircle({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 3,
        ),
        color: Colors.white.withValues(alpha: 0.12),
      ),
      child: child,
    );
  }
}
