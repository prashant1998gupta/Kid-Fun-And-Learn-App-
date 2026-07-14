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
import '../art_studio/data/canvas_repository.dart';
import '../ai/adaptive_engine.dart';
import '../collections/domain/collectible.dart';
import '../curriculum/domain/subject.dart';
import '../mini_games/data/mini_pet.dart';
import '../mini_games/data/learning_world_item.dart';
import '../mini_games/mini_games_controller.dart';
import '../profiles/domain/child_profile.dart';
import '../profiles/profiles_controller.dart';
import 'domain/world_prize.dart';

class KidWorldScreen extends ConsumerWidget {
  const KidWorldScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(activeChildProvider);
    if (child == null) return const SizedBox.shrink();
    final drawings = ref.read(canvasRepositoryProvider).loadAll();
    final hero = drawings.where((d) => d.id == child.heroDrawingId).firstOrNull;
    final recentDrawings = drawings.reversed.take(3).toList();
    final strengths = ref.watch(adaptiveControllerProvider).strengths(child.id);
    final companion = MiniPet.forXp(child.companionXp);
    final learningItems = ref
        .watch(miniGamesControllerProvider)
        .learningWorldItems
        .map(LearningWorldCatalog.byId)
        .whereType<LearningWorldItem>()
        .toList();
    final equipped = child.activePetId == null
        ? null
        : CollectionCatalog.byId(child.activePetId!);

    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.sunrise,
        child: SafeArea(
          child: Column(
            children: [
              _header(context, child),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _LivingRoom(
                        child: child,
                        companionEmoji: equipped?.emoji ?? companion.emoji,
                        hero: hero,
                        learningItems: learningItems,
                        onCompanionTap: () => _showCompanion(
                          context,
                          ref,
                          child,
                          equipped?.emoji ?? companion.emoji,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _MemoryGarden(
                        child: child,
                        strengths: strengths,
                        drawings: recentDrawings,
                      ),
                      const SizedBox(height: 18),
                      _portals(context, child.grade.isPreSchool),
                      if (child.ownedRoomItems.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _inventory(context, ref, child),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ChildProfile child) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            BouncyButton(
              onTap: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${child.name}\'s World',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
            Text('✨ ${child.companionXp}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );

  Widget _portals(BuildContext context, bool preschool) {
    // Material icons (not raw emoji) so the tiles always render crisply — the
    // emoji font can lag on first paint on web and show as empty boxes.
    final portals = <(IconData, String, Color, VoidCallback)>[
      (
        Icons.sports_esports_rounded,
        preschool ? 'Play' : 'Game Garden',
        AppColors.accent,
        () => context.push(AppRoutes.miniGames)
      ),
      (
        Icons.palette_rounded,
        'Create',
        AppColors.bubblegum,
        () => context.push(AppRoutes.artStudio)
      ),
      (
        Icons.auto_stories_rounded,
        'Make a Story',
        AppColors.sky,
        () => context.push(AppRoutes.storyMaker)
      ),
      (
        Icons.directions_run_rounded,
        'Move!',
        AppColors.success,
        () => context.push(AppRoutes.physicalMission)
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final iconBox = compact ? 48.0 : (preschool ? 64.0 : 52.0);
        final iconSize = compact ? 27.0 : (preschool ? 36.0 : 28.0);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: compact ? 1.05 : (preschool ? 1.35 : 1.7),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            for (var i = 0; i < portals.length; i++)
              BouncyButton(
                onTap: portals[i].$4,
                // Clean gradient card — no white outline. A soft shadow in the
                // tile's own colour gives depth instead of a hard white border.
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  padding: EdgeInsets.all(compact ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        portals[i].$3,
                        portals[i].$3.withValues(alpha: 0.72),
                      ],
                    ),
                    borderRadius: AppSpacing.cardRadius,
                    boxShadow: [
                      BoxShadow(
                        color: portals[i].$3.withValues(alpha: 0.38),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: iconBox,
                        height: iconBox,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          portals[i].$1,
                          color: Colors.white,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            portals[i].$2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 16 : (preschool ? 20 : 16),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 240.ms, delay: (i * 80).ms).slideY(
                    begin: 0.15,
                    end: 0,
                    delay: (i * 80).ms,
                    duration: 300.ms,
                  ),
          ],
        );
      },
    );
  }

  Widget _inventory(BuildContext context, WidgetRef ref, ChildProfile child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: AppSpacing.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My things — tap to place or pack away',
              style: TextStyle(
                  color: AppColors.lightText,
                  fontWeight: FontWeight.w900,
                  fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final id in child.ownedRoomItems)
                if (WorldPrizeCatalog.byId(id) case final prize?)
                  BouncyButton(
                    onTap: () => ref
                        .read(profilesControllerProvider.notifier)
                        .toggleRoomItem(id),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: child.placedRoomItems.contains(id)
                            ? prize.color.withValues(alpha: 0.22)
                            : const Color(0xFFECECEC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(prize.emoji,
                          style: const TextStyle(fontSize: 30)),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCompanion(
    BuildContext context,
    WidgetRef ref,
    ChildProfile child,
    String emoji,
  ) async {
    final adaptive = ref.read(adaptiveControllerProvider);
    final weak = adaptive.weakAreas(child.id);
    final suggestion = weak.isNotEmpty
        ? 'I have an idea! Let us help your ${weak.first.label} garden grow.'
        : child.completedAdventures == 0
            ? 'Let us begin an adventure and plant our first memory flower!'
            : 'Your garden is growing beautifully. Choose anything you love!';
    AudioService.instance.speak('${child.companionMemory} $suggestion');
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 520;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                compact ? 16 : 24,
                24,
                24 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: TextStyle(fontSize: compact ? 54 : 72)),
                  Text(
                    child.companionName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    child.companionMemory,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: compact ? 15 : 17),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.star.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '💡 $suggestion',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          AudioService.instance.playSfx(Sfx.celebration);
                          AudioService.instance.speak(
                              '${child.companionName} loves dancing with you!');
                        },
                        icon: const Icon(Icons.music_note_rounded),
                        label: const Text('Dance'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final name =
                              await _askCompanionName(sheetContext, child);
                          if (name != null) {
                            await ref
                                .read(profilesControllerProvider.notifier)
                                .renameCompanion(name);
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          }
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Rename'),
                      ),
                      if (weak.isNotEmpty) ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            context.push(AppRoutes.learningMap,
                                extra: weak.first);
                          },
                          icon: const Icon(Icons.explore_rounded),
                          label: const Text('Spark’s idea'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<String?> _askCompanionName(
    BuildContext context,
    ChildProfile child,
  ) async {
    final controller = TextEditingController(text: child.companionName);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Name your companion'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 18,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}

class _LivingRoom extends StatelessWidget {
  const _LivingRoom({
    required this.child,
    required this.companionEmoji,
    required this.hero,
    required this.learningItems,
    required this.onCompanionTap,
  });

  final ChildProfile child;
  final String companionEmoji;
  final SavedDrawing? hero;
  final List<LearningWorldItem> learningItems;
  final VoidCallback onCompanionTap;

  @override
  Widget build(BuildContext context) {
    final placed = child.placedRoomItems
        .map(WorldPrizeCatalog.byId)
        .whereType<WorldPrize>()
        .take(6)
        .toList();
    final learning = learningItems.take(6).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = (width * 0.62).clamp(235.0, 310.0);
        const decorationSpots = <Alignment>[
          Alignment(-0.82, -0.48),
          Alignment(0.82, -0.48),
          Alignment(-0.82, 0.52),
          Alignment(0.82, 0.52),
          Alignment(-0.48, -0.72),
          Alignment(0.48, -0.72),
        ];
        return SizedBox(
          height: height,
          child: Container(
            key: const ValueKey('living-world-scene'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB8E8FF), Color(0xFFFFE5A8)],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 16),
              ],
            ),
            child: Stack(
              children: [
                const Positioned(
                    left: 18,
                    top: 14,
                    child: Text('☀️', style: TextStyle(fontSize: 38))),
                const Positioned(
                    right: 18,
                    top: 16,
                    child: Text('☁️', style: TextStyle(fontSize: 38))),
                Positioned.fill(
                  top: height * 0.54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF8ED081).withValues(alpha: 0.75),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(50)),
                    ),
                  ),
                ),
                for (var i = 0; i < placed.length; i++)
                  Align(
                    alignment: decorationSpots[i],
                    child: IgnorePointer(
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          shape: BoxShape.circle,
                        ),
                        child: Text(placed[i].emoji,
                            style: const TextStyle(fontSize: 30)),
                      ),
                    ),
                  ),
                for (var i = 0; i < learning.length; i++)
                  Align(
                    alignment: decorationSpots[
                        (i + placed.length) % decorationSpots.length],
                    child: IgnorePointer(
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFFF7D6).withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFC048),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          learning[i].emoji,
                          style: const TextStyle(fontSize: 31),
                        ),
                      ),
                    ),
                  ),
                if (hero != null)
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Column(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Image.memory(hero!.thumbnailBytes,
                                  fit: BoxFit.contain)
                              .animate(
                                  onPlay: (controller) =>
                                      controller.repeat(reverse: true))
                              .moveY(begin: 0, end: -5, duration: 1300.ms),
                        ),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: Text(
                            child.heroName ?? 'My Hero',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.lightText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: const Alignment(0, 0.12),
                  child: BouncyButton(
                    onTap: onCompanionTap,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(companionEmoji,
                                style:
                                    TextStyle(fontSize: width < 360 ? 58 : 68))
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(begin: 0.98, end: 1.04, duration: 1100.ms),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            '${child.companionName} • tap me!',
                            key: const ValueKey('living-world-companion-label'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.lightText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
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

class _MemoryGarden extends StatelessWidget {
  const _MemoryGarden({
    required this.child,
    required this.strengths,
    required this.drawings,
  });

  final ChildProfile child;
  final List<Subject> strengths;
  final List<SavedDrawing> drawings;

  @override
  Widget build(BuildContext context) {
    final flowers = child.completedAdventures.clamp(0, 12);
    final fireflies = (child.companionXp ~/ 35).clamp(0, 8);
    final tree = switch (child.completedAdventures) {
      >= 20 => '🌳',
      >= 8 => '🌲',
      >= 3 => '🌿',
      _ => '🌱',
    };
    final subjectBlooms = {
      Subject.math: '🔢',
      Subject.english: '📚',
      Subject.evs: '🌍',
      Subject.science: '🔬',
      Subject.art: '🎨',
      Subject.logic: '🧩',
      Subject.rhymes: '🎵',
    };
    final message = flowers == 0
        ? 'Complete an adventure to grow your first memory flower.'
        : 'Your learning has grown $flowers memory flowers and $fireflies fireflies!';
    return BouncyButton(
      onTap: () => AudioService.instance.speak(message),
      child: Container(
        key: const ValueKey('memory-garden'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB8F2D0), Color(0xFFFFE8A3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 14),
          ],
        ),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Text(
                  'My Memory Garden',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppColors.lightText,
                      fontSize: 20,
                      fontWeight: FontWeight.w900),
                ),
                Text('$tree ✨$fireflies', style: const TextStyle(fontSize: 28)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 5,
              runSpacing: 5,
              children: [
                for (var index = 0; index < flowers; index++)
                  Text(
                    const ['🌸', '🌻', '🌷', '🌼'][index % 4],
                    style: const TextStyle(fontSize: 28),
                  ),
                for (final subject in strengths)
                  Text(subjectBlooms[subject] ?? '⭐',
                      style: const TextStyle(fontSize: 28)),
              ],
            ),
            if (drawings.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < drawings.length; index++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: ClipOval(
                        child: Image.memory(
                          drawings[index].thumbnailBytes,
                          key: ValueKey('living-drawing-${drawings[index].id}'),
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .moveY(
                            begin: 0,
                            end: index.isEven ? -6 : 6,
                            duration: (1100 + index * 180).ms,
                          ),
                    ),
                ],
              ),
              const Text('Your drawings are alive in the garden! 🎨',
                  style: TextStyle(
                      color: AppColors.lightText, fontWeight: FontWeight.w800)),
            ],
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.lightText, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
