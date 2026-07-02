import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../ai/adaptive_engine.dart';
import '../curriculum/domain/subject.dart';
import '../profiles/profiles_controller.dart';

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

class _ControlsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Controls', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.timer_rounded),
              title: Text('Daily screen-time limit'),
              subtitle: Text('30 minutes'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
            const ListTile(
              leading: Icon(Icons.notifications_rounded),
              title: Text('Progress notifications'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
            const ListTile(
              leading: Icon(Icons.shield_rounded),
              title: Text('Privacy & data (COPPA/GDPR)'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
