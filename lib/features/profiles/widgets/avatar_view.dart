import 'package:flutter/material.dart';

import '../domain/child_profile.dart';

/// Renders an [AvatarConfig] as a layered, illustrated character.
///
/// Until the illustrated part-sprites ship, it composes a friendly placeholder
/// from colored shapes + an emoji face, driven by the same config indices — so
/// the customization UI is fully wired and every choice visibly changes the
/// avatar today.
class AvatarView extends StatelessWidget {
  const AvatarView({super.key, required this.config, this.size = 120});

  final AvatarConfig config;
  final double size;

  static const skins = [
    Color(0xFFFFE0BD),
    Color(0xFFF1C27D),
    Color(0xFFE0AC69),
    Color(0xFFC68642),
    Color(0xFF8D5524),
  ];
  static const hairColors = [
    Color(0xFF2C1B18),
    Color(0xFF6B4423),
    Color(0xFFD4A017),
    Color(0xFFB55239),
    Color(0xFF3D3D3D),
  ];
  static const backgrounds = [
    Color(0xFF74B9FF),
    Color(0xFF55EFC4),
    Color(0xFFFD79A8),
    Color(0xFFFFC048),
    Color(0xFFA29BFE),
  ];
  static const faces = ['😀', '😄', '🙂', '😊', '😎', '🤗'];
  static const accessories = ['', '🎀', '🧢', '👓', '👑', '⭐'];

  @override
  Widget build(BuildContext context) {
    final bg = backgrounds[config.background % backgrounds.length];
    final skin = skins[config.skin % skins.length];
    final hair = hairColors[config.hairColor % hairColors.length];
    final face = faces[config.outfit % faces.length];
    final acc = accessories[config.accessory % accessories.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [bg.withValues(alpha: 0.9), bg.withValues(alpha: 0.5)],
        ),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hair cap
          Positioned(
            top: size * 0.14,
            child: Container(
              width: size * 0.62,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: hair,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(size),
                ),
              ),
            ),
          ),
          // Face
          Container(
            width: size * 0.56,
            height: size * 0.56,
            decoration: BoxDecoration(color: skin, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(face, style: TextStyle(fontSize: size * 0.28)),
          ),
          if (acc.isNotEmpty)
            Positioned(
              top: size * 0.06,
              child: Text(acc, style: TextStyle(fontSize: size * 0.26)),
            ),
        ],
      ),
    );
  }
}
