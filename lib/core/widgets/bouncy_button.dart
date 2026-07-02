import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme/app_spacing.dart';

/// A tappable surface that squishes down on press and springs back — the
/// single most-reused interaction in the app. Every tap in KidVerse should
/// feel physical and rewarding.
///
/// Also fires a click SFX and a light haptic so touch feels "real".
class BouncyButton extends StatefulWidget {
  const BouncyButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleTo = 0.90,
    this.duration = const Duration(milliseconds: 120),
    this.sound = Sfx.tap,
    this.enableHaptic = true,
    this.borderRadius = AppSpacing.buttonRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleTo;
  final Duration duration;
  final Sfx? sound;
  final bool enableHaptic;
  final BorderRadius borderRadius;

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    lowerBound: 0,
    upperBound: 1,
  );

  bool get _enabled => widget.onTap != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _down(_) {
    if (!_enabled) return;
    _controller.forward();
  }

  void _up(_) {
    if (!_enabled) return;
    _controller.reverse();
  }

  Future<void> _handleTap() async {
    if (!_enabled) return;
    if (widget.sound != null) AudioService.instance.playSfx(widget.sound!);
    if (widget.enableHaptic) AudioService.instance.lightHaptic();
    widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 1, end: widget.scaleTo)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);

    return Semantics(
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: () => _controller.reverse(),
        onTap: _handleTap,
        child: ScaleTransition(
          scale: scale,
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
