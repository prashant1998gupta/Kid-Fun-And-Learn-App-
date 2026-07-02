import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

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
    _center.play();
    _playLottie();
    if (sound) {
      AudioService.instance.playSfx(Sfx.celebration);
      AudioService.instance.successHaptic();
    }
  }

  void _fireworks() {
    _left.play();
    _center.play();
    _right.play();
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
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && burst == _lottieBurst) {
        setState(() => _showLottie = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showLottie)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: LottieView(
                  key: ValueKey(_lottieBurst),
                  asset: 'assets/lottie/celebration_star.json',
                  width: 240,
                  height: 240,
                  repeat: false,
                  fallback: const Text('⭐', style: TextStyle(fontSize: 96)),
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
      ),
    );
  }
}
