import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/shop/shop_catalog.dart';

void main() {
  group('ShopCatalog', () {
    test('has a free starter theme so the shop is never empty of owned items',
        () {
      final free = ShopCatalog.themes.where((t) => t.cost == 0).toList();
      expect(free, isNotEmpty);
      expect(free.first.id, 'sunrise');
    });

    test('theme ids are unique', () {
      final ids = ShopCatalog.themes.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('paid themes cost a positive number of coins', () {
      for (final t in ShopCatalog.themes.where((t) => t.id != 'sunrise')) {
        expect(t.cost, greaterThan(0), reason: '${t.id} should have a price');
      }
    });
  });
}
