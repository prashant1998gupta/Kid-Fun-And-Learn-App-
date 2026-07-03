import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import 'lottie_view.dart';
import 'openmoji_view.dart';

/// The friendly guides of KidVerse. Each has a personality and a signature
/// color; art is delivered as Lottie (preferred, for lip-sync/blink) with a
/// static image fallback.
enum Mascot {
  panda('Pip the Panda', 'assets/lottie/mascot_panda.json', Color(0xFF2D3436)),
  lion('Leo the Lion', 'assets/lottie/mascot_lion.json', Color(0xFFF9A825)),
  owl('Professor Hoot', 'assets/lottie/mascot_owl.json', Color(0xFF6C5CE7)),
  robot('Bolt the Robot', 'assets/lottie/mascot_robot.json', Color(0xFF00CEC9)),
  unicorn(
    'Luna the Unicorn',
    'assets/lottie/mascot_unicorn.json',
    Color(0xFFFD79A8),
  ),
  penguin(
    'Percy the Penguin',
    'assets/lottie/mascot_penguin.json',
    Color(0xFF0984E3),
  );

  const Mascot(this.displayName, this.lottie, this.color);
  final String displayName;
  final String lottie;
  final Color color;
}

/// A mascot that "breathes" (gentle scale) when idle and can bounce + speak on
/// demand. Falls back to an emoji placeholder until Lottie art is added, so the
/// app is fully runnable before the illustration pipeline lands.
class MascotView extends StatefulWidget {
  const MascotView({
    super.key,
    this.mascot = Mascot.panda,
    this.size = 160,
    this.onTap,
  });

  final Mascot mascot;
  final double size;
  final VoidCallback? onTap;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  static const _emoji = {
    Mascot.panda: '🐼',
    Mascot.lion: '🦁',
    Mascot.owl: '🦉',
    Mascot.robot: '🤖',
    Mascot.unicorn: '🦄',
    Mascot.penguin: '🐧',
  };

  @override
  void dispose() {
    _breath.dispose();
    _bounce.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounce.forward(from: 0);
    AudioService.instance.playSfx(Sfx.pop);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final breathe = Tween<double>(begin: 0.98, end: 1.03)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_breath);
    final bounce = Tween<double>(begin: 0, end: -18)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_bounce);

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _bounce]),
        builder: (context, child) => Transform.translate(
          offset: Offset(0, bounce.value),
          child: Transform.scale(scale: breathe.value, child: child),
        ),
        child: _art(),
      ),
    );
  }

  Widget _art() {
    // Art preference: mascot Lottie -> a real OpenMoji illustration on a soft
    // color medallion -> the plain emoji medallion. The OpenMoji step avoids
    // the washed-out "white blob" look of pale emoji glyphs.
    final emoji = _emoji[widget.mascot] ?? '⭐';
    final openMoji = OpenMojiView.has(emoji)
        ? Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.mascot.color.withValues(alpha: 0.16),
              boxShadow: [
                BoxShadow(
                  color: widget.mascot.color.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: EdgeInsets.all(widget.size * 0.14),
            child: OpenMojiView(
              emoji: emoji,
              size: widget.size * 0.72,
              fallback: _fallbackMedallion(),
            ),
          )
        : _fallbackMedallion();
    return LottieView(
      asset: widget.mascot.lottie,
      width: widget.size,
      height: widget.size,
      fallback: openMoji,
    );
  }

  Widget _fallbackMedallion() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.mascot.color.withValues(alpha: 0.15),
        boxShadow: [
          BoxShadow(
            color: widget.mascot.color.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _emoji[widget.mascot] ?? '⭐',
        style: TextStyle(fontSize: widget.size * 0.5),
      ),
    );
  }
}
