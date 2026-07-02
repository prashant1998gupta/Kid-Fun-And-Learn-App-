import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/collections/domain/collectible.dart';
import 'package:kidverse/features/profiles/domain/child_profile.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';

void main() {
  group('CollectionCatalog', () {
    test('ids are unique and stable', () {
      final ids = CollectionCatalog.all.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('pets + stickers partition the whole catalog', () {
      expect(
        CollectionCatalog.pets.length + CollectionCatalog.stickers.length,
        CollectionCatalog.all.length,
      );
      expect(CollectionCatalog.pets.every((c) => c.isPet), isTrue);
      expect(CollectionCatalog.stickers.every((c) => !c.isPet), isTrue);
    });

    test('totalWeight equals the sum of rarity weights', () {
      final sum = CollectionCatalog.all
          .fold(0, (a, c) => a + c.rarity.weight);
      expect(CollectionCatalog.totalWeight, sum);
    });

    test('byId resolves known ids and returns null otherwise', () {
      expect(CollectionCatalog.byId('pet_unicorn')?.name, 'Unicorn');
      expect(CollectionCatalog.byId('nope'), isNull);
    });
  });

  group('pickByWeight', () {
    test('roll 0 lands on the first catalog entry', () {
      expect(CollectionCatalog.pickByWeight(0).id, CollectionCatalog.all.first.id);
    });

    test('every valid roll maps to a real catalog member', () {
      final valid = CollectionCatalog.all.map((c) => c.id).toSet();
      for (var r = 0; r < CollectionCatalog.totalWeight; r++) {
        expect(valid.contains(CollectionCatalog.pickByWeight(r).id), isTrue);
      }
    });

    test('walks the cumulative distribution in catalog order', () {
      // The first item owns rolls [0, weight); the boundary roll flips to the
      // second item.
      final first = CollectionCatalog.all[0];
      final second = CollectionCatalog.all[1];
      expect(CollectionCatalog.pickByWeight(first.rarity.weight - 1).id, first.id);
      expect(CollectionCatalog.pickByWeight(first.rarity.weight).id, second.id);
    });

    test('is deterministic for a given roll', () {
      expect(
        CollectionCatalog.pickByWeight(17).id,
        CollectionCatalog.pickByWeight(17).id,
      );
    });
  });

  group('ChildProfile collection persistence', () {
    test('ownedCollectibles + activePetId survive a map round-trip', () {
      const profile = ChildProfile(
        id: 'c1',
        name: 'Mia',
        grade: GradeLevel.ukg,
        avatar: AvatarConfig(),
        ownedCollectibles: ['pet_fox', 'st_star'],
        activePetId: 'pet_fox',
      );
      final restored = ChildProfile.fromMap(profile.toMap());
      expect(restored.ownedCollectibles, ['pet_fox', 'st_star']);
      expect(restored.activePetId, 'pet_fox');
    });

    test('defaults are empty collection and no equipped pet', () {
      final restored = ChildProfile.fromMap(const {
        'id': 'c2',
        'name': 'Ravi',
        'grade': 'lkg',
      });
      expect(restored.ownedCollectibles, isEmpty);
      expect(restored.activePetId, isNull);
    });
  });
}
