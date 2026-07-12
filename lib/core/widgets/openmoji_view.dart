import 'package:flutter/material.dart';

import 'openmoji_map.g.dart';

/// Renders a bundled [OpenMoji](https://openmoji.org) illustration for an emoji
/// string, or [fallback] when that emoji isn't in our bundled subset.
///
/// OpenMoji art (CC BY-SA 4.0) is consistent, colorful, and kid-friendly —
/// unlike platform system emoji, which vary per device and read as "just text".
/// Only the emoji actually used by the app are bundled (see
/// `tool/fetch_openmoji.py`), so the payload stays small.
class OpenMojiView extends StatelessWidget {
  const OpenMojiView({
    super.key,
    required this.emoji,
    required this.fallback,
    this.size = 72,
  });

  final String emoji;
  final Widget fallback;
  final double size;

  /// Whether a bundled OpenMoji image exists for [emoji].
  static bool has(String? emoji) =>
      emoji != null && kOpenMojiFiles.containsKey(emoji);

  /// Asset path for the bundled OpenMoji image, when one exists.
  static String? assetPathFor(String? emoji) {
    final name = emoji == null ? null : kOpenMojiFiles[emoji];
    return name == null ? null : 'assets/openmoji/$name.png';
  }

  @override
  Widget build(BuildContext context) {
    final path = assetPathFor(emoji);
    if (path == null) return fallback;
    return Image.asset(
      path,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
