# 17 — Living KidVerse

## Purpose

Living KidVerse turns the app from a collection of activities into one world a
child owns. Learning, mini-games, drawing, storytelling, movement, rewards, and
the companion now change the same persistent child world.

## Implemented experience

- **Interactive child world:** a room/garden displays the active companion,
  placed rewards, and the child's hand-drawn hero.
- **One companion:** mini-games and physical missions feed the profile-level
  companion. It remembers a warm line about the child's most recent activity.
- **Interactive storybook memory:** the Mini Games hub rotates through eight
  story worlds. A child's Brave, Kind, or Curious choice changes three relic
  missions and the narrated finale; completing the trail writes that ending to
  the companion's memory and awards Story Hero progression.
- **Guided daily journey:** three age-eligible mini games become a beginning,
  middle, and finale instead of an unrelated grid. Chapter stamps and the
  one-time mystery chest persist per child for the day.
- **Real rewards:** lesson results now grant an actual room decoration, sticker,
  or companion snack. Duplicate prizes become companion XP rather than a fake
  reveal.
- **Story missions:** every curriculum lesson opens with a subject-specific
  emotional goal such as repairing the Moon Bridge or waking the Whispering
  Library.
- **Adventure continuity:** result actions prioritize continuing the journey or
  placing the new reward. Replay and Home remain available as secondary actions.
- **Child-made hero:** after saving a drawing, a child can type or speak its name
  and make it their world/story hero. Existing gallery drawings can also be
  selected.
- **Age-aware home:** preschool profiles see three large Play/Create/World
  choices; older children retain the richer achievement and economy shortcuts.
- **Physical co-play:** the Movement Mission uses device motion, a spoken team
  phrase, and a two-person high-five. It uses no camera and grants a real world
  item.

## Persistence and migration

The following backward-compatible fields live in `ChildProfile`, so they are
included in existing local persistence and cloud snapshot flows:

- `ownedRoomItems`
- `placedRoomItems`
- `companionXp`, `companionName`, `companionMemory`
- `heroDrawingId`, `heroName`
- `completedAdventures`

Missing fields from older profiles receive safe defaults. Saved drawing PNGs
remain local in `CanvasRepository`; profiles store only the selected drawing id
and name.

## Child-safety decisions

- No public user-generated content or photo upload.
- Speech recognition degrades to a completion fallback when unavailable.
- Physical missions avoid camera access and do not retain microphone audio.
- Rewards remain cosmetic and do not block learning.
- Duplicate rewards always convert into positive companion progress.

## Main implementation files

- `lib/features/world/kid_world_screen.dart`
- `lib/features/world/physical_mission_screen.dart`
- `lib/features/world/domain/world_prize.dart`
- `lib/features/games/adventure_intro.dart`
- `lib/features/games/game_host_screen.dart`
- `lib/features/games/game_result_screen.dart`
- `lib/features/profiles/domain/child_profile.dart`
