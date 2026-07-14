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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 360;
                    return Row(
                      children: [
                        BouncyButton(
                          onTap: () => Navigator.of(context).maybePop(),
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
                        Expanded(
                          child: Text(
                            'Theme Shop',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (compact
                                    ? Theme.of(context).textTheme.titleLarge
                                    : Theme.of(context)
                                        .textTheme
                                        .headlineMedium)
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(child: CurrencyChip.coins(child.wallet.coins)),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 360;
                    return GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: compact ? 180 : 220,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: compact ? 0.76 : 0.85,
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
                          onTap: () =>
                              _onTap(context, ref, item, owned, active),
                        ).animate().fadeIn(delay: (60 * i).ms).scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1, 1),
                            );
                      },
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
        const SnackBar(
            content: Text('Not enough coins yet — keep playing! 🪙')),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tight = constraints.maxHeight < 190;
          return Container(
            padding: EdgeInsets.all(tight ? 10 : 14),
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
                Text(item.emoji, style: TextStyle(fontSize: tight ? 40 : 48)),
                SizedBox(height: tight ? 4 : 6),
                Flexible(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: tight ? 16 : 18,
                      height: 1.05,
                    ),
                  ),
                ),
                SizedBox(height: tight ? 6 : 8),
                _statusPill(compact: tight),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusPill({required bool compact}) {
    final (label, bg, fg) = active
        ? ('In Use', Colors.white, AppColors.primary)
        : owned
            ? ('Use', Colors.white, AppColors.success)
            : (
                '🪙 ${item.cost}',
                Colors.black.withValues(alpha: 0.35),
                Colors.white
              );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 13 : 15,
        ),
      ),
    );
  }
}
