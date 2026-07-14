import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../constants/feedback_timing.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';
import 'lottie_view.dart';

/// Drives celebration effects on a [CelebrationOverlay]. Create one in your
/// widget's State, hand it to the overlay, and call [celebrate]/[fireworks]
/// from anywhere — no `InheritedWidget`/context lookup, so it works whether the
/// caller sits above or below the overlay in the tree.
class CelebrationController {
  _CelebrationOverlayState? _state;

  void _attach(_CelebrationOverlayState s) => _state = s;
  void _detach(_CelebrationOverlayState s) {
    if (identical(_state, s)) _state = null;
  }

  /// Confetti burst from the top-center. [sound] plays the celebration SFX.
  void celebrate({bool sound = true}) => _state?._celebrate(sound);

  /// Bigger multi-cannon burst for level-ups / big wins.
  void fireworks() => _state?._fireworks();
}

/// Wraps a subtree and renders confetti cannons on demand via a
/// [CelebrationController].
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.controller,
    required this.child,
  });

  final CelebrationController controller;
  final Widget child;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  final ConfettiController _center =
      ConfettiController(duration: const Duration(seconds: 1));
  final ConfettiController _left =
      ConfettiController(duration: const Duration(seconds: 1));
  final ConfettiController _right =
      ConfettiController(duration: const Duration(seconds: 1));
  int _lottieBurst = 0;
  bool _showLottie = false;

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.mint,
    AppColors.sky,
    AppColors.bubblegum,
    AppColors.star,
  ];

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
  }

  @override
  void didUpdateWidget(covariant CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach(this);
      widget.controller._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    _center.dispose();
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  void _celebrate(bool sound) {
    if (!MediaQuery.disableAnimationsOf(context)) _center.play();
    _playLottie();
    if (sound) {
      AudioService.instance.playSfx(Sfx.celebration);
      AudioService.instance.successHaptic();
    }
  }

  void _fireworks() {
    if (!MediaQuery.disableAnimationsOf(context)) {
      _left.play();
      _center.play();
      _right.play();
    }
    _playLottie();
    AudioService.instance.playSfx(Sfx.reward);
    AudioService.instance.successHaptic();
  }

  void _playLottie() {
    setState(() {
      _lottieBurst++;
      _showLottie = true;
    });
    final burst = _lottieBurst;
    Future<void>.delayed(FeedbackTiming.successBeat, () {
      if (mounted && burst == _lottieBurst) {
        setState(() => _showLottie = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      children: [
        widget.child,
        if (_showLottie)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: _SuccessMoment(
                  key: ValueKey(_lottieBurst),
                  reducedMotion: reducedMotion,
                ),
              ),
            ),
          ),
        _emitter(_left, -math.pi / 4, Alignment.bottomLeft),
        _emitter(_center, -math.pi / 2, Alignment.topCenter),
        _emitter(_right, -3 * math.pi / 4, Alignment.bottomRight),
      ],
    );
  }

  Widget _emitter(
    ConfettiController controller,
    double direction,
    Alignment alignment,
  ) {
    return Align(
      alignment: alignment,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirection: direction,
        emissionFrequency: 0.05,
        numberOfParticles: 18,
        maxBlastForce: 22,
        minBlastForce: 8,
        gravity: 0.25,
        colors: _colors,
        createParticlePath: _starParticle,
      ),
    );
  }

  Path _starParticle(Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final inner = outer * 0.44;
    final path = Path();
    for (var point = 0; point < 10; point++) {
      final angle = -math.pi / 2 + point * math.pi / 5;
      final radius = point.isEven ? outer : inner;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      if (point == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }
}

class _SuccessMoment extends StatelessWidget {
  const _SuccessMoment({required this.reducedMotion, super.key});

  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final popupSize = math
        .min(250.0, math.min(media.size.width * 0.68, media.size.height * 0.36))
        .clamp(132.0, 250.0)
        .toDouble();
    final lottieSize = popupSize * 0.96;
    final badgeSize = popupSize * 0.42;
    final starSize = badgeSize * 0.63;
    final pillBottom = popupSize * 0.17;
    final moment = SizedBox(
      width: popupSize,
      height: popupSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!reducedMotion)
            LottieView(
              asset: 'assets/lottie/celebration_star.json',
              width: lottieSize,
              height: lottieSize,
              repeat: false,
              fallback: const SizedBox.shrink(),
            ),
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text('⭐', style: TextStyle(fontSize: starSize)),
          ),
          Positioned(
            bottom: pillBottom,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: popupSize < 180 ? 12 : 16,
                  vertical: popupSize < 180 ? 5 : 7,
                ),
                child: Text(
                  'You did it!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: popupSize < 180 ? 14 : 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (reducedMotion) return moment;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.55, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: moment,
    );
  }
}
