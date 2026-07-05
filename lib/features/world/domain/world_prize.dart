import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum WorldPrizeKind { decoration, sticker, snack }

@immutable
class WorldPrize {
  const WorldPrize({
    required this.id,
    required this.title,
    required this.emoji,
    required this.kind,
    required this.color,
  });

  final String id;
  final String title;
  final String emoji;
  final WorldPrizeKind kind;
  final Color color;

  String get revealLine => switch (kind) {
        WorldPrizeKind.decoration => 'Put it in your world!',
        WorldPrizeKind.sticker => 'It is now in your sticker book!',
        WorldPrizeKind.snack => 'Your companion cannot wait to try it!',
      };
}

abstract final class WorldPrizeCatalog {
  static const all = <WorldPrize>[
    WorldPrize(
      id: 'room_sunflower',
      title: 'Sunny Flower',
      emoji: '🌻',
      kind: WorldPrizeKind.decoration,
      color: AppColors.star,
    ),
    WorldPrize(
      id: 'room_rainbow',
      title: 'Room Rainbow',
      emoji: '🌈',
      kind: WorldPrizeKind.decoration,
      color: AppColors.sky,
    ),
    WorldPrize(
      id: 'room_rocket',
      title: 'Toy Rocket',
      emoji: '🚀',
      kind: WorldPrizeKind.decoration,
      color: AppColors.accent,
    ),
    WorldPrize(
      id: 'room_castle',
      title: 'Tiny Castle',
      emoji: '🏰',
      kind: WorldPrizeKind.decoration,
      color: AppColors.primary,
    ),
    WorldPrize(
      id: 'sticker_superstar',
      title: 'Superstar Sticker',
      emoji: '⭐',
      kind: WorldPrizeKind.sticker,
      color: AppColors.star,
    ),
    WorldPrize(
      id: 'snack_apple',
      title: 'Crunchy Pet Snack',
      emoji: '🍎',
      kind: WorldPrizeKind.snack,
      color: AppColors.success,
    ),
  ];

  static WorldPrize forLesson(String lessonId) {
    final hash = lessonId.codeUnits.fold<int>(0, (sum, code) => sum + code);
    return all[hash % all.length];
  }

  static WorldPrize? byId(String id) {
    for (final prize in all) {
      if (prize.id == id) return prize;
    }
    return null;
  }
}
