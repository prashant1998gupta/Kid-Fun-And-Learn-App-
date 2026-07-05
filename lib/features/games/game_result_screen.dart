import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/mascot.dart';
import '../achievements/domain/achievement.dart';
import '../gamification/domain/wallet.dart';
import '../gamification/reward_engine.dart';
import '../world/domain/world_prize.dart';

/// The reward-reveal screen shown after a lesson: animated stars, the reward
/// bundle counting up, mascot celebration, and (if applicable) a level-up.
class GameResultScreen extends StatefulWidget {
  const GameResultScreen({
    super.key,
    required this.result,
    required this.reward,
    required this.leveledUp,
    required this.newLevel,
    required this.onReplay,
    required this.onContinue,
    required this.onVisitWorld,
    required this.onHome,
    required this.prize,
    required this.prizeWasNew,
    this.newBadges = const [],
  });

  final LessonResult result;
  final RewardBundle reward;
  final bool leveledUp;
  final int newLevel;
  final VoidCallback onReplay;
  final VoidCallback onContinue;
  final VoidCallback onVisitWorld;
  final VoidCallback onHome;
  final WorldPrize prize;
  final bool prizeWasNew;
  final List<Achievement> newBadges;

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.playSfx(Sfx.levelUp);
      final line = widget.leveledUp
          ? 'Level up! You reached level ${widget.newLevel}!'
          : PraiseLines.nextSuccess();
      AudioService.instance.speak(line);
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        AudioService.instance.playSfx(Sfx.reward);
        AudioService.instance.speak(PraiseLines.nextRewardReveal());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final stars = widget.result.stars;
    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.candy,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MascotView(mascot: Mascot.unicorn, size: 150)
                            .animate()
                            .scale(curve: Curves.elasticOut, duration: 700.ms),
                        const SizedBox(height: 12),
                        Text(
                          widget.leveledUp ? 'LEVEL UP!' : 'Great Job!',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(color: Colors.white),
                        ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                        const SizedBox(height: 16),
                        _Stars(stars: stars),
                        const SizedBox(height: 24),
                        _RewardRow(reward: widget.reward),
                        const SizedBox(height: 18),
                        _RewardMoment(
                          prize: widget.prize,
                          isNew: widget.prizeWasNew,
                        ),
                        if (widget.newBadges.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _BadgeBanner(badges: widget.newBadges),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 14,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BouncyButton(
                      onTap: widget.onContinue,
                      child: _pill('Continue Adventure 🚀', AppColors.success),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 0,
                      children: [
                        TextButton(
                          onPressed: widget.onVisitWorld,
                          child: const Text('Place reward 🏡'),
                        ),
                        TextButton(
                          onPressed: widget.onReplay,
                          child: const Text('Play again'),
                        ),
                        IconButton(
                          tooltip: 'Home',
                          onPressed: widget.onHome,
                          icon: const Icon(Icons.home_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _RewardMoment extends StatelessWidget {
  const _RewardMoment({required this.prize, required this.isNew});

  final WorldPrize prize;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: prize.color, width: 3),
        boxShadow: [
          BoxShadow(
            color: prize.color.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: prize.color.withValues(alpha: 0.16),
              borderRadius: AppSpacing.cardRadius,
            ),
            alignment: Alignment.center,
            child: Text(prize.emoji, style: const TextStyle(fontSize: 58)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNew ? 'NEW WORLD REWARD' : 'COMPANION BONUS',
                  style: const TextStyle(
                    color: AppColors.lightTextSoft,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  prize.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.lightText,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isNew
                      ? prize.revealLine
                      : 'You already own this, so your companion gained extra sparkle!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.lightTextSoft,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 650.ms).scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 3; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 64,
            color: i < stars ? AppColors.star : Colors.white54,
          )
              .animate(delay: (250 * i).ms)
              .scale(
                curve: Curves.elasticOut,
                duration: 600.ms,
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
              )
              .then()
              .shake(hz: 4, rotation: 0.1, duration: 300.ms),
      ],
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.reward});
  final RewardBundle reward;

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, int value, Color color) {
      if (value <= 0) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(AppSpacing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 6),
            Text(
              '+$value',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        chip(Icons.monetization_on_rounded, reward.coins, AppColors.coin),
        chip(Icons.auto_awesome_rounded, reward.xp, AppColors.xp),
        chip(Icons.diamond_rounded, reward.gems, AppColors.gem),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.4, end: 0);
  }
}

/// Celebrates any achievements unlocked by this lesson.
class _BadgeBanner extends StatelessWidget {
  const _BadgeBanner({required this.badges});
  final List<Achievement> badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'New Badge!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              for (final b in badges)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(b.emoji, style: const TextStyle(fontSize: 40)),
                    Text(
                      b.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}
