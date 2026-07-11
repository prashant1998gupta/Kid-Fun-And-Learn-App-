/// A child-selected way to solve today's mini-game story.
class MiniGameStoryPath {
  const MiniGameStoryPath({
    required this.id,
    required this.label,
    required this.icon,
    required this.quality,
    required this.action,
  });

  final String id;
  final String label;
  final String icon;
  final String quality;
  final String action;
}

const kMiniGameStoryPaths = <MiniGameStoryPath>[
  MiniGameStoryPath(
    id: 'brave',
    label: 'Brave',
    icon: '🔥',
    quality: 'courage',
    action: 'Dash forward bravely',
  ),
  MiniGameStoryPath(
    id: 'kind',
    label: 'Kind',
    icon: '💖',
    quality: 'kindness',
    action: 'Help every friend',
  ),
  MiniGameStoryPath(
    id: 'curious',
    label: 'Curious',
    icon: '🔎',
    quality: 'curiosity',
    action: 'Investigate every clue',
  ),
];

MiniGameStoryPath? miniGameStoryPathById(String? id) {
  if (id == null) return null;
  for (final path in kMiniGameStoryPaths) {
    if (path.id == id) return path;
  }
  return null;
}

/// A hand-authored story world wrapped around three otherwise independent
/// mini games. Relics make each stop feel like a chapter, not a checklist.
class MiniGameStoryWorld {
  const MiniGameStoryWorld({
    required this.id,
    required this.title,
    required this.icon,
    required this.intro,
    required this.relics,
    required this.finale,
  });

  final String id;
  final String title;
  final String icon;
  final String intro;
  final List<String> relics;
  final String finale;

  String chapterLine(int chapter, String gameName, MiniGameStoryPath path) {
    final relic = relics[chapter.clamp(0, relics.length - 1)];
    return '${path.action} through $gameName and find the $relic.';
  }

  String finaleFor(MiniGameStoryPath path) =>
      'Your ${path.quality} changed the ending! $finale';
}

const kMiniGameStoryWorlds = <MiniGameStoryWorld>[
  MiniGameStoryWorld(
    id: 'moon-garden',
    title: 'The Moon Garden Mystery',
    icon: '🌙',
    intro:
        'The moonflowers have gone dark. Three starlight seeds can wake them.',
    relics: ['silver seed', 'owl song', 'starlight key'],
    finale: 'The moonflowers bloom and paint the night with gentle light.',
  ),
  MiniGameStoryWorld(
    id: 'rainbow-river',
    title: 'The Rainbow River Rescue',
    icon: '🌈',
    intro: 'The river has lost its colours, and the cloud fish need your help.',
    relics: ['red ripple', 'golden giggle', 'blue waterfall'],
    finale: 'Every colour rushes home and the cloud fish dance downstream.',
  ),
  MiniGameStoryWorld(
    id: 'clockwork-castle',
    title: 'The Castle That Fell Asleep',
    icon: '🏰',
    intro:
        'The Clockwork Castle is frozen at midnight. Its three gears are hiding.',
    relics: ['tick gear', 'tock gear', 'morning bell'],
    finale: 'The castle wakes, the doors twirl open, and breakfast begins.',
  ),
  MiniGameStoryWorld(
    id: 'cloud-zoo',
    title: 'The Cloud Zoo Escape',
    icon: '☁️',
    intro: 'Three baby sky dragons floated away before their bedtime snack.',
    relics: ['feather map', 'berry basket', 'dragon whistle'],
    finale: 'The baby dragons glide home and make a heart in the clouds.',
  ),
  MiniGameStoryWorld(
    id: 'whisper-library',
    title: 'The Library of Lost Words',
    icon: '📚',
    intro:
        'Silly words jumped out of their stories and hid around the library.',
    relics: ['laughing letter', 'rhyme ribbon', 'golden bookmark'],
    finale: 'The words leap back onto every page and tell a brand-new tale.',
  ),
  MiniGameStoryWorld(
    id: 'coral-city',
    title: 'The Secret of Coral City',
    icon: '🐠',
    intro:
        'The great pearl is dim, so the underwater city cannot find morning.',
    relics: ['bubble compass', 'coral melody', 'sun pearl'],
    finale: 'The great pearl shines and a thousand tiny bubbles sparkle.',
  ),
  MiniGameStoryWorld(
    id: 'tiny-planet',
    title: 'The Tiny Planet Challenge',
    icon: '🪐',
    intro: 'A pocket-sized planet needs clean power before its first party.',
    relics: ['wind crystal', 'water wheel', 'sun battery'],
    finale: 'The little planet glows green and invites the whole galaxy.',
  ),
  MiniGameStoryWorld(
    id: 'dream-train',
    title: 'The Dream Train Express',
    icon: '🚂',
    intro:
        'The Dream Train lost three tickets and bedtime stories are waiting.',
    relics: ['pillow ticket', 'lullaby lantern', 'dream conductor hat'],
    finale: 'The train whistles softly and delivers a happy dream to everyone.',
  ),
];
