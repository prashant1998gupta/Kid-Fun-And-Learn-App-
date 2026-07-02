import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Renders a Lottie animation from assets, falling back to [fallback] whenever
/// the file is missing or fails to parse.
///
/// This is the single seam for KidVerse's illustration pipeline: screens use
/// [LottieView] with an emoji/placeholder fallback today, and the moment a real
/// `.json` animation is dropped into `assets/lottie/`, it renders automatically
/// — no screen changes. Keeps the app fully runnable before the art lands.
class LottieView extends StatelessWidget {
  const LottieView({
    super.key,
    required this.asset,
    required this.fallback,
    this.width,
    this.height,
    this.repeat = true,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final Widget fallback;
  final double? width;
  final double? height;
  final bool repeat;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      // Missing/invalid asset → show the fallback instead of throwing.
      errorBuilder: (context, error, stack) => SizedBox(
        width: width,
        height: height,
        child: Center(child: fallback),
      ),
    );
  }
}
