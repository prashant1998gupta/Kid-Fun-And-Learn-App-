/// A small object earned in a learning mini game and displayed in Kid World.
class LearningWorldItem {
  const LearningWorldItem({
    required this.id,
    required this.emoji,
    required this.name,
  });

  final String id;
  final String emoji;
  final String name;
}

/// Hand-picked, readable rewards. They alternate between Toy Sort and Feed the
/// Pet so both games visibly improve the same room and garden.
class LearningWorldCatalog {
  LearningWorldCatalog._();

  static const items = <LearningWorldItem>[
    LearningWorldItem(id: 'learning_ball', emoji: '⚽', name: 'Play ball'),
    LearningWorldItem(id: 'learning_bowl', emoji: '🥣', name: 'Pet bowl'),
    LearningWorldItem(id: 'learning_kite', emoji: '🪁', name: 'Rainbow kite'),
    LearningWorldItem(id: 'learning_apple', emoji: '🍎', name: 'Apple basket'),
    LearningWorldItem(id: 'learning_teddy', emoji: '🧸', name: 'Teddy friend'),
    LearningWorldItem(id: 'learning_flower', emoji: '🌻', name: 'Sunflower'),
    LearningWorldItem(
        id: 'learning_blocks', emoji: '🧱', name: 'Building blocks'),
    LearningWorldItem(id: 'learning_tree', emoji: '🌳', name: 'Garden tree'),
    LearningWorldItem(id: 'learning_train', emoji: '🚂', name: 'Toy train'),
    LearningWorldItem(
        id: 'learning_picnic', emoji: '🧺', name: 'Picnic basket'),
    LearningWorldItem(id: 'learning_puzzle', emoji: '🧩', name: 'Puzzle box'),
    LearningWorldItem(
        id: 'learning_rainbow', emoji: '🌈', name: 'Rainbow arch'),
    LearningWorldItem(id: 'learning_market', emoji: '🏪', name: 'Market stall'),
    LearningWorldItem(
        id: 'learning_spellbook', emoji: '📖', name: 'Magic word book'),
    LearningWorldItem(
        id: 'learning_station', emoji: '🚉', name: 'Train station'),
    LearningWorldItem(id: 'learning_clock', emoji: '🕰️', name: 'Garden clock'),
    LearningWorldItem(
        id: 'learning_butterflies', emoji: '🦋', name: 'Butterfly garden'),
    LearningWorldItem(id: 'learning_castle', emoji: '🏰', name: 'Shape castle'),
  ];

  static LearningWorldItem? byId(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static LearningWorldItem rewardFor(String gameId, int completedLevel) {
    final offset = switch (gameId) {
      'toy-sort' => 0,
      'feed-the-pet' => 1,
      'sound-safari' => 2,
      'number-garden' => 3,
      'story-train' => 4,
      'letter-bakery' => 5,
      'clean-room-helper' => 6,
      'math-market' => 7,
      'word-wizard-workshop' => 8,
      'sentence-train' => 9,
      'clock-adventure' => 10,
      'nature-detective' => 11,
      'shape-builder' => 12,
      _ => 0,
    };
    final index = ((completedLevel - 1) * 2 + offset) % items.length;
    return items[index];
  }
}
