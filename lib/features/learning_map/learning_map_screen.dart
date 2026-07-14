import 'dart:math' as math;

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
import '../curriculum/data/curriculum_repository.dart';
import '../curriculum/domain/lesson.dart';
import '../curriculum/domain/subject.dart';
import '../ai/adaptive_engine.dart';
import '../ai/adaptive_learning_service.dart';
import '../profiles/domain/grade_level.dart';
import '../profiles/profiles_controller.dart';
import '../progress/progress_controller.dart';

/// A winding "adventure path" of lesson nodes for one subject. Nodes unlock in
/// order (finish one to open the next), show earned stars, and the journey ends
/// in a treasure chest that opens when every lesson is complete.
class LearningMapScreen extends ConsumerWidget {
  const LearningMapScreen({super.key, required this.subject});
  final Subject subject;

  static const _rowHeight = 132.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoAsync = ref.watch(curriculumLoadProvider);
    final child = ref.watch(activeChildProvider);
    final progress = ref.watch(progressControllerProvider);
    final adaptive = ref.watch(adaptiveControllerProvider);

    return Scaffold(
      body: AnimatedBackground(
        theme: _themeFor(subject),
        child: SafeArea(
          child: repoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Oops: $e')),
            data: (repo) {
              if (child == null) return const SizedBox.shrink();
              final lessons = _orderedLessons(repo, child.grade);
              const learningService = AdaptiveLearningService();
              final recommendation = learningService.recommend(
                childId: child.id,
                orderedLessons: lessons,
                progress: progress,
                model: adaptive,
              );
              final revision = learningService.buildRevision(
                childId: child.id,
                orderedLessons: lessons,
                progress: progress,
                model: adaptive,
              );
              final path = lessons.isEmpty
                  ? const Center(
                      child: Text(
                        'More adventures coming soon! 🚀',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    )
                  : _Path(
                      lessons: lessons,
                      childId: child.id,
                      progress: progress,
                      subject: subject,
                    );
              final smartCard = recommendation == null
                  ? null
                  : _SmartNextCard(
                      recommendation: recommendation,
                      revision: revision,
                      color: subject.color,
                    );

              return LayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final compact = constraints.maxHeight < 420 ||
                      constraints.maxWidth < 360 ||
                      textScale > 1.25;
                  if (compact) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          children: [
                            _TopBar(subject: subject),
                            if (smartCard != null) smartCard,
                            SizedBox(
                              height: math.max(
                                220,
                                constraints.maxHeight * 0.68,
                              ),
                              child: path,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      _TopBar(subject: subject),
                      if (smartCard != null) smartCard,
                      Expanded(child: path),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  List<Lesson> _orderedLessons(CurriculumRepository repo, GradeLevel grade) {
    final units = repo.unitsForGradeSubject(grade, subject);
    return [for (final u in units) ...repo.lessonsForUnit(u)];
  }

  static WorldTheme _themeFor(Subject s) => switch (s) {
        Subject.math => WorldTheme.space,
        Subject.english => WorldTheme.sunrise,
        Subject.evs => WorldTheme.jungle,
        Subject.science => WorldTheme.ocean,
        Subject.art => WorldTheme.candy,
        Subject.logic => WorldTheme.night,
        Subject.rhymes => WorldTheme.candy,
      };
}

class _SmartNextCard extends StatelessWidget {
  const _SmartNextCard({
    required this.recommendation,
    required this.revision,
    required this.color,
  });

  final LearningRecommendation recommendation;
  final SmartRevisionPlan? revision;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final stage = conceptStage(recommendation.mastery);
    return Container(
      key: const ValueKey('smart-play-next'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Text(recommendation.foundation ? '🧱' : '✨',
              style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.foundation
                      ? 'Build a foundation first'
                      : 'Smart Play Next',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.lightText),
                ),
                Text(
                  '${skillLabel(recommendation.skillId)} • ${stage.label}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  recommendation.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.lightTextSoft),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('play-recommended-lesson'),
                      style: FilledButton.styleFrom(backgroundColor: color),
                      onPressed: () => context.push(
                        AppRoutes.game,
                        extra: recommendation.lesson,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play Next'),
                    ),
                    if (revision != null)
                      OutlinedButton.icon(
                        key: const ValueKey('play-smart-revision'),
                        onPressed: () => context.push(
                          AppRoutes.game,
                          extra: revision!.lesson,
                        ),
                        icon: const Icon(Icons.auto_fix_high_rounded),
                        label: const Text('5-Step Revision'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.subject});
  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          return Row(
            children: [
              BouncyButton(
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.home),
                child: Container(
                  padding: EdgeInsets.all(compact ? 8 : 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.primary,
                    size: compact ? 23 : 26,
                  ),
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
              Icon(subject.icon, color: Colors.white, size: compact ? 26 : 30),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: Text(
                  subject.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (compact
                          ? Theme.of(context).textTheme.titleLarge
                          : Theme.of(context).textTheme.headlineMedium)
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Path extends StatelessWidget {
  const _Path({
    required this.lessons,
    required this.childId,
    required this.progress,
    required this.subject,
  });

  final List<Lesson> lessons;
  final String childId;
  final ProgressState progress;
  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final short = constraints.maxHeight < 360;
        final rowHeight = short ? 104.0 : LearningMapScreen._rowHeight;
        final nodeSize = short ? 64.0 : 84.0;
        final chestSize = short ? 48.0 : 64.0;
        final chestLabelWidth = short ? 100.0 : 132.0;
        final centerX = width / 2;
        final amplitude = (width / 2) - nodeSize / 2 - AppSpacing.lg;
        final totalHeight =
            lessons.length * rowHeight + chestSize + 96 + (short ? 16 : 40);

        Offset centerOf(int i) => Offset(
              centerX + amplitude * math.sin(i * 0.9),
              i * rowHeight + rowHeight / 2 + (short ? 12 : 20),
            );

        // Determine unlock: node i is unlocked if i==0 or lesson i-1 completed.
        bool unlocked(int i) =>
            i == 0 || progress.isCompleted(childId, lessons[i - 1].id);
        final allDone =
            lessons.every((l) => progress.isCompleted(childId, l.id));

        final chestCenter =
            Offset(centerX, lessons.length * rowHeight + (short ? 42 : 60));

        return SingleChildScrollView(
          child: SizedBox(
            width: width,
            height: totalHeight,
            child: Stack(
              children: [
                // The connecting trail behind the nodes.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TrailPainter(
                      points: [
                        for (int i = 0; i < lessons.length; i++) centerOf(i),
                        chestCenter,
                      ],
                    ),
                  ),
                ),
                // Lesson nodes.
                for (int i = 0; i < lessons.length; i++)
                  Positioned(
                    left: centerOf(i).dx - nodeSize / 2,
                    top: centerOf(i).dy - nodeSize / 2,
                    child: _Node(
                      index: i,
                      lesson: lessons[i],
                      stars: progress.starsFor(childId, lessons[i].id),
                      unlocked: unlocked(i),
                      color: subject.color,
                      size: nodeSize,
                      compact: short,
                    ),
                  ),
                // Reward chest.
                Positioned(
                  left: chestCenter.dx - chestLabelWidth / 2,
                  top: chestCenter.dy - chestSize / 2,
                  child: SizedBox(
                    width: chestLabelWidth,
                    child: _Chest(
                      open: allDone,
                      iconSize: chestSize,
                      compact: short,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.index,
    required this.lesson,
    required this.stars,
    required this.unlocked,
    required this.color,
    required this.size,
    required this.compact,
  });

  final int index;
  final Lesson lesson;
  final int stars;
  final bool unlocked;
  final Color color;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final done = stars > 0;
    final node = BouncyButton(
      onTap: unlocked
          ? () {
              AudioService.instance.speak(lesson.title);
              context.push(AppRoutes.game, extra: lesson);
            }
          : () {
              AudioService.instance.playSfx(Sfx.wrong);
              AudioService.instance.speak('Finish the one before to unlock!');
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unlocked
                  ? LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)])
                  : const LinearGradient(
                      colors: [Color(0xFF9E9E9E), Color(0xFF757575)]),
              boxShadow: [
                BoxShadow(
                  color:
                      (unlocked ? color : Colors.black).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: unlocked
                  ? Text(lesson.emoji,
                      style: TextStyle(fontSize: compact ? 27 : 34))
                  : const Icon(Icons.lock_rounded,
                      color: Colors.white, size: 30),
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          if (done)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int s = 0; s < 3; s++)
                  Icon(
                    s < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: s < stars ? AppColors.star : Colors.white54,
                    size: compact ? 13 : 16,
                  ),
              ],
            ),
        ],
      ),
    );

    // The current available (not-yet-done) node gently pulses to invite a tap.
    if (unlocked && !done) {
      return node.animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 900.ms,
          );
    }
    return node;
  }
}

class _Chest extends StatelessWidget {
  const _Chest({
    required this.open,
    required this.iconSize,
    required this.compact,
  });
  final bool open;
  final double iconSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(open ? '🎉' : '🎁', style: TextStyle(fontSize: iconSize))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -4, end: 4, duration: 1200.ms),
        Text(
          open ? 'You did it!' : 'Finish all to open!',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : 16),
        ),
      ],
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.points});
  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Dashed smooth-ish polyline between node centers.
    for (int i = 0; i < points.length - 1; i++) {
      _dashedLine(canvas, points[i], points[i + 1], paint);
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 14.0;
    const gap = 10.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final start = a + dir * d;
      final end = a + dir * math.min(d + dash, total);
      canvas.drawLine(start, end, paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => old.points != points;
}
