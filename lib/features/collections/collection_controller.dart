import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamification/domain/wallet.dart';
import '../profiles/profiles_controller.dart';
import 'domain/collectible.dart';

/// The outcome of opening one Surprise Egg.
class EggResult {
  const EggResult({
    required this.collectible,
    required this.isNew,
    required this.coinsSpent,
    required this.coinsRefunded,
    this.autoEquippedPet = false,
  });

  final Collectible collectible;
  final bool isNew;
  final int coinsSpent;

  /// Coins handed back when the egg rolled a duplicate.
  final int coinsRefunded;

  /// True when this was the child's first pet and we equipped it for them.
  final bool autoEquippedPet;
}

/// Drives the Surprise Egg gacha: spend coins → weighted roll → grant, with a
/// gentle duplicate refund so a repeat never feels like a loss. The weighted
/// selection itself lives in [CollectionCatalog.pickByWeight] (pure/testable);
/// this class only wires it to the wallet + profile.
class CollectionController {
  CollectionController(this._ref);
  final Ref _ref;
  final _random = math.Random();

  ProfilesController get _profiles =>
      _ref.read(profilesControllerProvider.notifier);

  /// Whether the active child can afford an egg right now.
  bool get canAfford {
    final coins = _ref.read(activeChildProvider)?.wallet.coins ?? 0;
    return coins >= CollectionCatalog.eggCost;
  }

  /// Opens one egg. Returns null when there's no active child or not enough
  /// coins (the caller shows the "keep playing" nudge).
  Future<EggResult?> openEgg() async {
    final child = _ref.read(activeChildProvider);
    if (child == null) return null;

    final paid = await _profiles.spendCoins(CollectionCatalog.eggCost);
    if (!paid) return null;

    final roll = _random.nextInt(CollectionCatalog.totalWeight);
    final prize = CollectionCatalog.pickByWeight(roll);

    final isNew = await _profiles.grantCollectible(prize.id);

    var refund = 0;
    if (!isNew) {
      refund = CollectionCatalog.duplicateRefund;
      await _profiles.applyReward(const RewardBundle(
        coins: CollectionCatalog.duplicateRefund,
      ));
    }

    // First pet? Equip it automatically so the companion shows up immediately.
    var autoEquipped = false;
    if (isNew &&
        prize.isPet &&
        (_ref.read(activeChildProvider)?.activePetId == null)) {
      await _profiles.setActivePet(prize.id);
      autoEquipped = true;
    }

    return EggResult(
      collectible: prize,
      isNew: isNew,
      coinsSpent: CollectionCatalog.eggCost,
      coinsRefunded: refund,
      autoEquippedPet: autoEquipped,
    );
  }
}

final collectionControllerProvider = Provider<CollectionController>((ref) {
  return CollectionController(ref);
});
