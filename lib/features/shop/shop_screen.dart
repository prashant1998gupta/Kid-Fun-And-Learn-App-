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
import 'shop_catalog.dart';

/// The Theme Shop: spend coins to unlock world themes, then set one active.
/// Gives the coin economy a purpose. Cosmetic-only (no pay-to-win, no real money).
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(activeChildProvider);
    if (child == null) return const SizedBox.shrink();

    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.fromId(child.activeTheme),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
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
                      'Theme Shop',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const Spacer(),
                    CurrencyChip.coins(child.wallet.coins),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: ShopCatalog.themes.length,
                  itemBuilder: (context, i) {
                    final item = ShopCatalog.themes[i];
                    final owned = child.unlockedThemes.contains(item.id);
                    final active = child.activeTheme == item.id;
                    return _ThemeCard(
                      item: item,
                      owned: owned,
                      active: active,
                      onTap: () => _onTap(context, ref, item, owned, active),
                    ).animate().fadeIn(delay: (60 * i).ms).scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1, 1),
                        );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    ThemeItem item,
    bool owned,
    bool active,
  ) async {
    final profiles = ref.read(profilesControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    if (active) return;

    if (owned) {
      await profiles.setActiveTheme(item.id);
      AudioService.instance.playSfx(Sfx.tap);
      AudioService.instance.speak('New look!');
      return;
    }

    final bought = await profiles.spendCoins(item.cost);
    if (!bought) {
      AudioService.instance.playSfx(Sfx.wrong);
      messenger.showSnackBar(
        const SnackBar(content: Text('Not enough coins yet — keep playing! 🪙')),
      );
      return;
    }
    await profiles.unlockTheme(item.id);
    await profiles.setActiveTheme(item.id);
    AudioService.instance.playSfx(Sfx.unlock);
    AudioService.instance.speak('Yay! New theme unlocked!');
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.item,
    required this.owned,
    required this.active,
    required this.onTap,
  });

  final ThemeItem item;
  final bool owned;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      borderRadius: AppSpacing.cardRadius,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppSpacing.cardRadius,
          gradient: LinearGradient(
            colors: item.theme.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: active ? Border.all(color: Colors.white, width: 4) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 6),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            _statusPill(),
          ],
        ),
      ),
    );
  }

  Widget _statusPill() {
    final (label, bg, fg) = active
        ? ('In Use', Colors.white, AppColors.primary)
        : owned
            ? ('Use', Colors.white, AppColors.success)
            : ('🪙 ${item.cost}', Colors.black.withValues(alpha: 0.35),
                Colors.white);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 15),
      ),
    );
  }
}
