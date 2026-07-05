import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Two things kids collect: flat [sticker]s for the sticker book, and [pet]s
/// that can be equipped as a companion on the Home world.
enum CollectibleKind { sticker, pet }

/// Drop rarity. `weight` is the relative chance of rolling this tier from a
/// Surprise Egg; higher rarities are rarer and celebrated harder on reveal.
enum Rarity {
  common('Common', 60, Color(0xFF95A5A6)),
  rare('Rare', 26, AppColors.sky),
  epic('Epic', 11, AppColors.primary),
  legendary('Legendary', 3, AppColors.star);

  const Rarity(this.label, this.weight, this.color);
  final String label;
  final int weight;
  final Color color;
}

/// A single collectible. Purely illustrated via emoji today; the `emoji` slot
/// is the natural swap point for real art in P2's asset pass.
@immutable
class Collectible {
  const Collectible({
    required this.id,
    required this.name,
    required this.emoji,
    required this.kind,
    required this.rarity,
  });

  final String id;
  final String name;
  final String emoji;
  final CollectibleKind kind;
  final Rarity rarity;

  bool get isPet => kind == CollectibleKind.pet;
}

/// The full, hand-curated collection. Ids are stable — never renumber, since
/// they're persisted in each child's profile.
class CollectionCatalog {
  const CollectionCatalog._();

  /// Coins to open one Surprise Egg.
  static const eggCost = 40;

  /// Coins refunded when an egg rolls a duplicate (kind, not punishing).
  static const duplicateRefund = 15;

  static const all = <Collectible>[
    // ---- Pets (equippable companions) ----------------------------------
    Collectible(
        id: 'pet_puppy',
        name: 'Puppy',
        emoji: '🐶',
        kind: CollectibleKind.pet,
        rarity: Rarity.common),
    Collectible(
        id: 'pet_kitten',
        name: 'Kitten',
        emoji: '🐱',
        kind: CollectibleKind.pet,
        rarity: Rarity.common),
    Collectible(
        id: 'pet_bunny',
        name: 'Bunny',
        emoji: '🐰',
        kind: CollectibleKind.pet,
        rarity: Rarity.rare),
    Collectible(
        id: 'pet_fox',
        name: 'Fox',
        emoji: '🦊',
        kind: CollectibleKind.pet,
        rarity: Rarity.rare),
    Collectible(
        id: 'pet_penguin',
        name: 'Penguin',
        emoji: '🐧',
        kind: CollectibleKind.pet,
        rarity: Rarity.epic),
    Collectible(
        id: 'pet_unicorn',
        name: 'Unicorn',
        emoji: '🦄',
        kind: CollectibleKind.pet,
        rarity: Rarity.legendary),
    Collectible(
        id: 'pet_dragon',
        name: 'Dragon',
        emoji: '🐲',
        kind: CollectibleKind.pet,
        rarity: Rarity.legendary),

    // ---- Stickers ------------------------------------------------------
    Collectible(
        id: 'st_star',
        name: 'Super Star',
        emoji: '⭐',
        kind: CollectibleKind.sticker,
        rarity: Rarity.common),
    Collectible(
        id: 'st_rainbow',
        name: 'Rainbow',
        emoji: '🌈',
        kind: CollectibleKind.sticker,
        rarity: Rarity.common),
    Collectible(
        id: 'st_flower',
        name: 'Flower',
        emoji: '🌸',
        kind: CollectibleKind.sticker,
        rarity: Rarity.common),
    Collectible(
        id: 'st_balloon',
        name: 'Balloon',
        emoji: '🎈',
        kind: CollectibleKind.sticker,
        rarity: Rarity.common),
    Collectible(
        id: 'st_rocket',
        name: 'Rocket',
        emoji: '🚀',
        kind: CollectibleKind.sticker,
        rarity: Rarity.rare),
    Collectible(
        id: 'st_crown',
        name: 'Crown',
        emoji: '👑',
        kind: CollectibleKind.sticker,
        rarity: Rarity.rare),
    Collectible(
        id: 'st_medal',
        name: 'Gold Medal',
        emoji: '🏅',
        kind: CollectibleKind.sticker,
        rarity: Rarity.epic),
    Collectible(
        id: 'st_gem',
        name: 'Diamond',
        emoji: '💎',
        kind: CollectibleKind.sticker,
        rarity: Rarity.epic),
    Collectible(
        id: 'st_trophy',
        name: 'Trophy',
        emoji: '🏆',
        kind: CollectibleKind.sticker,
        rarity: Rarity.legendary),
  ];

  static final Map<String, Collectible> _byId = {
    for (final c in all) c.id: c,
  };

  static Collectible? byId(String id) => _byId[id];

  static List<Collectible> get pets =>
      all.where((c) => c.kind == CollectibleKind.pet).toList();
  static List<Collectible> get stickers =>
      all.where((c) => c.kind == CollectibleKind.sticker).toList();

  /// Total weight across the whole catalog (each item carries its rarity
  /// weight). Exposed for the pure picker below.
  static int get totalWeight => all.fold(0, (sum, c) => sum + c.rarity.weight);

  /// Deterministically maps a roll in `[0, totalWeight)` to a collectible by
  /// walking the weighted cumulative distribution. Pure → unit-testable; the
  /// controller feeds it `Random().nextInt(totalWeight)`.
  static Collectible pickByWeight(int roll) {
    var cursor = roll;
    for (final c in all) {
      if (cursor < c.rarity.weight) return c;
      cursor -= c.rarity.weight;
    }
    return all.last; // roll == totalWeight guard
  }
}
