import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/celebration_overlay.dart';
import '../../core/widgets/currency_hud.dart';
import '../gamification/domain/wallet.dart';
import '../profiles/profiles_controller.dart';
import 'lucky_spin_controller.dart';

/// One reward wedge on the wheel.
class _Wedge {
  const _Wedge(this.label, this.color, this.reward);
  final String label;
  final Color color;
  final RewardBundle reward;
}

/// Daily Lucky Spin. Free once per day; the wheel spins to a random wedge and
/// pays out. Weighted purely by wedge count (transparent, no dark patterns).
class LuckySpinScreen extends ConsumerStatefulWidget {
  const LuckySpinScreen({super.key});

  @override
  ConsumerState<LuckySpinScreen> createState() => _LuckySpinScreenState();
}

class _LuckySpinScreenState extends ConsumerState<LuckySpinScreen>
    with SingleTickerProviderStateMixin {
  final _celebration = CelebrationController();

  static const _wedges = [
    _Wedge('10', AppColors.sky, RewardBundle(coins: 10)),
    _Wedge('20', AppColors.mint, RewardBundle(coins: 20)),
    _Wedge('5', AppColors.accent, RewardBundle(coins: 5)),
    _Wedge('💎', AppColors.gem, RewardBundle(gems: 1)),
    _Wedge('15', AppColors.bubblegum, RewardBundle(coins: 15)),
    _Wedge('30', AppColors.secondary, RewardBundle(coins: 30)),
    _Wedge('5', AppColors.sky, RewardBundle(coins: 5)),
    _Wedge('50', AppColors.star, RewardBundle(coins: 50)),
  ];

  late final AnimationController _controller;
  final _random = math.Random();

  double _angle = 0;
  bool _spinning = false;
  _Wedge? _won;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    final controller = ref.read(luckySpinControllerProvider.notifier);
    if (!controller.canSpinToday) return;

    setState(() {
      _spinning = true;
      _won = null;
    });
    AudioService.instance.playSfx(Sfx.whoosh);

    final n = _wedges.length;
    final sweep = 2 * math.pi / n;
    final target = _random.nextInt(n);
    // Rotate 5 full turns, then align the target wedge's center to the top
    // pointer (which sits at -pi/2).
    final centerLocal = (target + 0.5) * sweep;
    var align = (-math.pi / 2 - centerLocal) % (2 * math.pi);
    if (align < 0) align += 2 * math.pi;
    final end = 5 * 2 * math.pi + align;

    final anim = Tween<double>(begin: 0, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    void listener() => setState(() => _angle = anim.value);
    anim.addListener(listener);

    await _controller.forward(from: 0);
    anim.removeListener(listener);

    // Payout.
    final won = _wedges[target];
    await ref.read(profilesControllerProvider.notifier).applyReward(won.reward);
    await controller.markSpun();
    _celebration.fireworks();
    AudioService.instance.speak('You won a prize!');

    if (mounted) {
      setState(() {
        _spinning = false;
        _won = won;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(activeChildProvider);
    ref.watch(luckySpinControllerProvider); // rebuild when spun state changes
    final canSpin = ref.read(luckySpinControllerProvider.notifier).canSpinToday;

    return CelebrationOverlay(
      controller: _celebration,
      child: Scaffold(
        body: AnimatedBackground(
          theme: WorldTheme.night,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) {
                final compact =
                    viewport.maxWidth < 360 || viewport.maxHeight < 620;
                final wheelSize = math.min(
                  compact ? 230.0 : 280.0,
                  math.max(190.0, viewport.maxWidth - 56),
                );
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: viewport.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
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
                                  'Lucky Spin',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: (compact
                                          ? Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                          : Theme.of(context)
                                              .textTheme
                                              .headlineMedium)
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (child != null)
                                Flexible(
                                  child: CurrencyChip.coins(child.wallet.coins),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: compact ? 6 : 14,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _wheel(wheelSize),
                              SizedBox(height: compact ? 14 : 24),
                              _wonOrPrompt(context, canSpin, compact: compact),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(
                            compact ? AppSpacing.md : AppSpacing.lg,
                          ),
                          child: BouncyButton(
                            onTap: (canSpin && !_spinning) ? _spin : null,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                vertical: compact ? 15 : 18,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: canSpin
                                      ? [AppColors.accent, AppColors.secondary]
                                      : [Colors.grey, Colors.grey.shade400],
                                ),
                                borderRadius: const BorderRadius.all(
                                  AppSpacing.radiusPill,
                                ),
                              ),
                              child: Text(
                                canSpin ? 'SPIN!' : 'Come back tomorrow! 🌙',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 19 : 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _wheel(double size) {
    return SizedBox(
      width: size,
      height: size + 20,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Transform.rotate(
              angle: _angle,
              child: CustomPaint(
                size: Size(size, size),
                painter: _WheelPainter(_wedges),
              ),
            ),
          ),
          // Fixed pointer at the top.
          Positioned(
            top: 0,
            child: Icon(
              Icons.arrow_drop_down_rounded,
              color: Colors.white,
              size: math.max(42, size * 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wonOrPrompt(
    BuildContext context,
    bool canSpin, {
    required bool compact,
  }) {
    if (_won != null) {
      final r = _won!.reward;
      final text =
          r.gems > 0 ? 'You won ${r.gems} 💎!' : 'You won ${r.coins} 🪙!';
      return Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(color: Colors.white),
      );
    }
    return Text(
      canSpin ? 'Spin to win a prize!' : 'You already spun today',
      textAlign: TextAlign.center,
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: Colors.white70),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.wedges);
  final List<_Wedge> wedges;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweep = 2 * math.pi / wedges.length;
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (int i = 0; i < wedges.length; i++) {
      final start = i * sweep;
      final paint = Paint()..color = wedges[i].color;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..arcTo(rect, start, sweep, false)
          ..close(),
        paint,
      );

      // Label near the outer edge, at the wedge center angle.
      final mid = start + sweep / 2;
      final pos = Offset(
        center.dx + math.cos(mid) * radius * 0.66,
        center.dy + math.sin(mid) * radius * 0.66,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: wedges[i].label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Hub.
    canvas.drawCircle(center, 22, Paint()..color = Colors.white);
    canvas.drawCircle(center, 14, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) => false;
}
