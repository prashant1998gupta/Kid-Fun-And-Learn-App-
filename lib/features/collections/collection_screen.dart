import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/currency_hud.dart';
import '../profiles/profiles_controller.dart';
import 'collection_controller.dart';
import 'domain/collectible.dart';

/// The Collection Book: open Surprise Eggs, browse the sticker album, and equip
/// a pet companion. Gives the coin economy a second, collect-'em-all sink that
/// drives retention. All ownership lives on the child profile, so it syncs.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(activeChildProvider);
    if (child == null) return const SizedBox.shrink();

    final owned = child.ownedCollectibles.toSet();
    final total = CollectionCatalog.all.length;

    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.fromId(child.activeTheme),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(coins: child.wallet.coins),
              ),
              SliverToBoxAdapter(
                child: _EggCard(
                  opening: _opening,
                  canAfford: child.wallet.coins >= CollectionCatalog.eggCost,
                  onOpen: _openEgg,
                  collectedCount: owned.length,
                  total: total,
                ),
              ),
              _SectionHeader(title: '🐾 Pets', owned: owned, kind: CollectibleKind.pet),
              _CollectibleGrid(
                items: CollectionCatalog.pets,
                owned: owned,
                activePetId: child.activePetId,
                onEquipPet: (id) => ref
                    .read(profilesControllerProvider.notifier)
                    .setActivePet(id),
              ),
              _SectionHeader(title: '✨ Stickers', owned: owned, kind: CollectibleKind.sticker),
              _CollectibleGrid(
                items: CollectionCatalog.stickers,
                owned: owned,
                activePetId: null,
                onEquipPet: null,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEgg() async {
    if (_opening) return;
    setState(() => _opening = true);
    AudioService.instance.playSfx(Sfx.magic);
    final result = await ref.read(collectionControllerProvider).openEgg();
    if (!mounted) return;
    setState(() => _opening = false);

    if (result == null) {
      AudioService.instance.playSfx(Sfx.wrong);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins yet — keep playing to earn more! 🪙'),
        ),
      );
      return;
    }
    await _showReveal(result);
  }

  Future<void> _showReveal(EggResult result) async {
    AudioService.instance.playSfx(
      result.collectible.rarity == Rarity.legendary ? Sfx.celebration : Sfx.reward,
    );
    AudioService.instance.speak(
      result.isNew ? 'Wow! You got a ${result.collectible.name}!' : 'A duplicate — here are some coins back!',
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _RevealDialog(result: result),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          BouncyButton(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Collection',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white),
          ),
          const Spacer(),
          CurrencyChip.coins(coins),
        ],
      ),
    );
  }
}

class _EggCard extends StatelessWidget {
  const _EggCard({
    required this.opening,
    required this.canAfford,
    required this.onOpen,
    required this.collectedCount,
    required this.total,
  });

  final bool opening;
  final bool canAfford;
  final VoidCallback onOpen;
  final int collectedCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final egg = Text('🥚', style: TextStyle(fontSize: opening ? 64 : 58));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.bubblegum],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppSpacing.cardRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            opening
                ? egg
                    .animate(onPlay: (c) => c.repeat())
                    .shake(hz: 6, duration: 500.ms)
                : egg,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Surprise Egg',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Collected $collectedCount / $total',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  BouncyButton(
                    onTap: opening ? null : onOpen,
                    borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: canAfford ? Colors.white : Colors.white54,
                        borderRadius:
                            const BorderRadius.all(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        opening ? 'Opening…' : 'Open  🪙 ${CollectionCatalog.eggCost}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.owned,
    required this.kind,
  });
  final String title;
  final Set<String> owned;
  final CollectibleKind kind;

  @override
  Widget build(BuildContext context) {
    final items = CollectionCatalog.all.where((c) => c.kind == kind);
    final have = items.where((c) => owned.contains(c.id)).length;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            Text(
              '$have / ${items.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectibleGrid extends StatelessWidget {
  const _CollectibleGrid({
    required this.items,
    required this.owned,
    required this.activePetId,
    required this.onEquipPet,
  });

  final List<Collectible> items;
  final Set<String> owned;
  final String? activePetId;
  final void Function(String id)? onEquipPet;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 120,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.82,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final item = items[i];
            final isOwned = owned.contains(item.id);
            final isActivePet = item.id == activePetId;
            return _CollectibleTile(
              item: item,
              owned: isOwned,
              activePet: isActivePet,
              onTap: (isOwned && item.isPet && onEquipPet != null)
                  ? () {
                      onEquipPet!(item.id);
                      AudioService.instance.playSfx(Sfx.tap);
                      AudioService.instance.speak('${item.name} is your buddy!');
                    }
                  : null,
            ).animate().fadeIn(delay: (40 * i).ms);
          },
          childCount: items.length,
        ),
      ),
    );
  }
}

class _CollectibleTile extends StatelessWidget {
  const _CollectibleTile({
    required this.item,
    required this.owned,
    required this.activePet,
    required this.onTap,
  });

  final Collectible item;
  final bool owned;
  final bool activePet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      decoration: BoxDecoration(
        color: owned
            ? Colors.white
            : Colors.white.withValues(alpha: 0.35),
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: activePet ? AppColors.success : item.rarity.color,
          width: activePet ? 4 : 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            owned ? item.emoji : '❓',
            style: TextStyle(
              fontSize: 40,
              color: owned ? null : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            owned ? item.name : '???',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: owned ? Colors.black87 : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          _pill(),
        ],
      ),
    );
    return onTap == null
        ? tile
        : BouncyButton(
            borderRadius: AppSpacing.cardRadius,
            onTap: onTap,
            child: tile,
          );
  }

  Widget _pill() {
    final (label, color) = activePet
        ? ('Buddy', AppColors.success)
        : owned && item.isPet
            ? ('Tap to equip', item.rarity.color)
            : (item.rarity.label, item.rarity.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: owned ? 1 : 0.6),
        borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _RevealDialog extends StatelessWidget {
  const _RevealDialog({required this.result});
  final EggResult result;

  @override
  Widget build(BuildContext context) {
    final c = result.collectible;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(color: c.rarity.color, width: 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: c.rarity.color,
                borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
              ),
              child: Text(
                c.rarity.label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(c.emoji, style: const TextStyle(fontSize: 96))
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 12),
            Text(
              result.isNew ? c.name : 'Duplicate ${c.name}',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              result.isNew
                  ? (result.autoEquippedPet
                      ? 'Added to your collection — and equipped as your buddy!'
                      : 'Added to your collection!')
                  : 'You already had this — here are 🪙 ${result.coinsRefunded} coins back!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Yay!'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
