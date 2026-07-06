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
import '../collections/domain/collectible.dart';
import '../mini_games/data/mini_pet.dart';
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
    final companion = MiniPet.forXp(child.companionXp);
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
                        onCompanionTap: () => _showCompanion(
                          context,
                          ref,
                          child,
                          equipped?.emoji ?? companion.emoji,
                        ),
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: preschool ? 1.35 : 1.7,
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
                    width: preschool ? 64 : 52,
                    height: preschool ? 64 : 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(portals[i].$1,
                        color: Colors.white, size: preschool ? 36 : 28),
                  ),
                  const SizedBox(height: 8),
                  Text(portals[i].$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: preschool ? 20 : 16,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 240.ms, delay: (i * 80).ms)
              .slideY(begin: 0.15, end: 0, delay: (i * 80).ms, duration: 300.ms),
      ],
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
    AudioService.instance.speak(child.companionMemory);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 72)),
            Text(child.companionName,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(child.companionMemory,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final name = await _askCompanionName(sheetContext, child);
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
              ],
            ),
          ],
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
    required this.onCompanionTap,
  });

  final ChildProfile child;
  final String companionEmoji;
  final SavedDrawing? hero;
  final VoidCallback onCompanionTap;

  @override
  Widget build(BuildContext context) {
    final placed = child.placedRoomItems
        .map(WorldPrizeCatalog.byId)
        .whereType<WorldPrize>()
        .take(6)
        .toList();
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
                              fit: BoxFit.contain),
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
