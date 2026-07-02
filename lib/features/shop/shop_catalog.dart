import '../../core/widgets/animated_background.dart';

/// A purchasable world theme. Buying it unlocks the theme for the child's Home
/// background; the first ('sunrise') ships free so the shop always has an owned
/// item to demonstrate the "Use" state.
class ThemeItem {
  const ThemeItem({
    required this.id,
    required this.title,
    required this.emoji,
    required this.cost,
    required this.theme,
  });

  final String id;
  final String title;
  final String emoji;
  final int cost;
  final WorldTheme theme;
}

class ShopCatalog {
  const ShopCatalog._();

  static const themes = [
    ThemeItem(
      id: 'sunrise',
      title: 'Sunrise',
      emoji: '🌅',
      cost: 0,
      theme: WorldTheme.sunrise,
    ),
    ThemeItem(
      id: 'jungle',
      title: 'Jungle',
      emoji: '🌴',
      cost: 50,
      theme: WorldTheme.jungle,
    ),
    ThemeItem(
      id: 'ocean',
      title: 'Ocean',
      emoji: '🌊',
      cost: 80,
      theme: WorldTheme.ocean,
    ),
    ThemeItem(
      id: 'candy',
      title: 'Candy Land',
      emoji: '🍭',
      cost: 120,
      theme: WorldTheme.candy,
    ),
    ThemeItem(
      id: 'space',
      title: 'Outer Space',
      emoji: '🚀',
      cost: 150,
      theme: WorldTheme.space,
    ),
    ThemeItem(
      id: 'night',
      title: 'Starry Night',
      emoji: '🌙',
      cost: 200,
      theme: WorldTheme.night,
    ),
  ];
}
