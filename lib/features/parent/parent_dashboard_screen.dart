import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/messaging_service.dart';
import '../ai/adaptive_engine.dart';
import '../auth/auth_controller.dart';
import '../curriculum/domain/subject.dart';
import '../profiles/profiles_controller.dart';
import '../progress/activity_log.dart';
import '../sync/sync_controller.dart';
import '../settings/settings_controller.dart';
import 'widgets/trend_charts.dart';

/// Parent Dashboard: progress overview, per-subject mastery, weak areas &
/// strengths (from the adaptive engine), and screen-time/goal controls.
/// Reached only through the [ParentGateScreen].
class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(profilesControllerProvider).children;
    final model = ref.watch(adaptiveControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Parent Dashboard')),
      body: children.isEmpty
          ? const Center(child: Text('No child profiles yet.'))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const _AccountCard(),
                const SizedBox(height: 16),
                const _SharingCard(),
                const SizedBox(height: 16),
                for (final child in children) ...[
                  _ChildHeader(name: child.name, grade: child.grade.label),
                  const SizedBox(height: 12),
                  _StatRow(
                    coins: child.wallet.coins,
                    xp: child.wallet.xp,
                    level: child.wallet.level,
                    streak: child.wallet.streakDays,
                  ),
                  const SizedBox(height: 16),
                  _TrendsCard(childId: child.id),
                  const SizedBox(height: 16),
                  _SubjectMastery(childId: child.id, model: model),
                  const SizedBox(height: 16),
                  _InsightCard(
                    title: 'Needs practice',
                    icon: Icons.trending_down_rounded,
                    color: AppColors.warning,
                    subjects: model.weakAreas(child.id),
                    emptyText: 'Doing great everywhere! 🎉',
                  ),
                  _InsightCard(
                    title: 'Strengths',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.success,
                    subjects: model.strengths(child.id),
                    emptyText: 'Keep playing to reveal strengths.',
                  ),
                  const Divider(height: 40),
                ],
                _ControlsCard(),
              ],
            ),
    );
  }
}

class _ChildHeader extends StatelessWidget {
  const _ChildHeader({required this.name, required this.grade});
  final String name;
  final String grade;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primary,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.headlineMedium),
            Text(grade, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.coins,
    required this.xp,
    required this.level,
    required this.streak,
  });
  final int coins, xp, level, streak;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value, IconData icon, Color color) {
      return Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(label, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        stat('Level', '$level', Icons.military_tech_rounded, AppColors.xp),
        const SizedBox(width: 8),
        stat('XP', '$xp', Icons.auto_awesome_rounded, AppColors.primary),
        const SizedBox(width: 8),
        stat('Coins', '$coins', Icons.monetization_on_rounded, AppColors.coin),
        const SizedBox(width: 8),
        stat(
          'Streak',
          '$streak',
          Icons.local_fire_department_rounded,
          AppColors.energy,
        ),
      ],
    );
  }
}

/// Quick links to the weekly certificate and the friends leaderboard.
class _SharingCard extends StatelessWidget {
  const _SharingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.celebration_rounded,
                    color: AppColors.secondary),
                const SizedBox(width: 8),
                Text('Sharing & Friends',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.certificate),
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text('Certificate'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.leaderboard),
                    icon: const Icon(Icons.leaderboard_rounded),
                    label: const Text('Leaderboard'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Over-time trends: this week's totals + a 7-day activity bar chart.
class _TrendsCard extends ConsumerWidget {
  const _TrendsCard({required this.childId});
  final String childId;

  static const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(activityControllerProvider);
    final today = ActivityController.today;
    final week = log.lastNDays(childId, 7, today);
    final lessons = [for (final d in week) d.lessons];
    final labels = [
      for (final d in week)
        _weekdayInitials[
            DateTime.utc(2020).add(Duration(days: d.day)).weekday - 1],
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('This Week',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniStat(
                  label: 'Lessons',
                  value: '${log.weeklyLessons(childId, today)}',
                  icon: Icons.school_rounded,
                  color: AppColors.primary,
                ),
                _MiniStat(
                  label: 'Stars',
                  value: '${log.weeklyStars(childId, today)}',
                  icon: Icons.star_rounded,
                  color: AppColors.star,
                ),
                _MiniStat(
                  label: 'Active days',
                  value: '${log.activeDays(childId, today)}/7',
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.success,
                ),
                _MiniStat(
                  label: 'Streak',
                  value: '${log.currentStreak(childId, today)}',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.energy,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Lessons per day',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            if (log.weeklyLessons(childId, today) == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No activity yet this week — play a lesson to start the chart! 📈',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              WeeklyBarChart(
                values: lessons,
                labels: labels,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _SubjectMastery extends StatelessWidget {
  const _SubjectMastery({required this.childId, required this.model});
  final String childId;
  final SkillModel model;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject Mastery',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final s in Subject.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(s.icon, color: s.color, size: 22),
                    const SizedBox(width: 10),
                    SizedBox(width: 120, child: Text(s.label)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(AppSpacing.radiusPill),
                        child: LinearProgressIndicator(
                          value: model.skillFor(childId, s),
                          minHeight: 12,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          color: s.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(model.skillFor(childId, s) * 100).round()}%',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.subjects,
    required this.emptyText,
  });
  final String title;
  final IconData icon;
  final Color color;
  final List<Subject> subjects;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 10),
            if (subjects.isEmpty)
              Text(emptyText, style: Theme.of(context).textTheme.bodyMedium)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in subjects)
                    Chip(
                      avatar: Icon(s.icon, color: s.color, size: 18),
                      label: Text(s.label),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Account + cloud-sync controls. Sign-in is optional; the card leads with the
/// current session state and a clear sync status line.
class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final sync = ref.watch(syncControllerProvider);
    final signedIn = auth.status == AuthStatus.signedIn;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  signedIn ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: signedIn ? AppColors.success : AppColors.info,
                ),
                const SizedBox(width: 8),
                Text('Account & Sync',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 10),
            if (signedIn) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_rounded),
                title: Text(auth.account?.label ?? 'Parent'),
                subtitle: Text('Signed in with '
                    '${auth.account?.provider.label ?? 'account'}'),
              ),
              Text(_syncLine(sync),
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: sync.status == SyncStatus.syncing
                          ? null
                          : () => ref
                              .read(syncControllerProvider.notifier)
                              .pushNow(),
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('Sync now'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(authControllerProvider.notifier).signOut(),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign out'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Sign in to back up progress to the cloud and sync across '
                'devices. Optional — everything works offline.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.signIn),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Sign in / Create account'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _syncLine(SyncState sync) {
    switch (sync.status) {
      case SyncStatus.syncing:
        return 'Syncing…';
      case SyncStatus.synced:
        return 'Progress backed up to the cloud ✓';
      case SyncStatus.offline:
        return 'Cloud unavailable — saved on this device.';
      case SyncStatus.error:
        return sync.message ?? 'Sync issue — data is safe on this device.';
      case SyncStatus.idle:
        return 'Ready to sync.';
    }
  }
}

class _ControlsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final auth = ref.watch(authControllerProvider);

    Future<void> setNotifications(bool value) async {
      final ok = await MessagingService.instance.setEnabled(
        value,
        uid: auth.account?.uid,
      );
      if (!context.mounted) return;
      await ref
          .read(settingsControllerProvider.notifier)
          .setNotificationsEnabled(value && ok);
      if (value && !ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications are unavailable. Check cloud setup and device permission.',
            ),
          ),
        );
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Controls', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_rounded),
              title: const Text('Parent progress reminders'),
              subtitle: const Text(
                'Off by default. Permission is requested only when you enable it.',
              ),
              value: settings.notificationsEnabled,
              onChanged: setNotifications,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shield_rounded),
              title: const Text('Privacy & data'),
              subtitle: const Text(
                'Offline by default. Cloud sync is optional and parent-controlled.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.about),
            ),
            if (auth.status == AuthStatus.signedIn)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever_rounded,
                    color: AppColors.error),
                title: const Text('Delete cloud account'),
                subtitle: const Text(
                  'Permanently removes the parent account and cloud backup. Local profiles stay on this device.',
                ),
                onTap: () => _confirmAccountDeletion(context, ref),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAccountDeletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete cloud account?'),
            content: const Text(
              'This permanently deletes the parent sign-in, cloud backup, and shared leaderboard entry. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete permanently'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final ok = await ref.read(authControllerProvider.notifier).deleteAccount();
    if (!context.mounted) return;
    final error = ref.read(authControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Cloud account deletion started.' : (error ?? 'Delete failed.'),
        ),
      ),
    );
  }
}
