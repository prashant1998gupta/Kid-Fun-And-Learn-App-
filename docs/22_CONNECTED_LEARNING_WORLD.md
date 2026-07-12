# Connected Learning World

## Purpose

This pass turns KidVerse from a set of good screens into a more connected child
experience. The same child profile now influences the home mood, learning
support, world memory, mini-game co-play, celebration energy and companion
suggestions.

The goal is not to add more noise. The goal is to make the app feel like it
remembers the child, slows down when support is needed, and gives children a
reason to return beyond finishing one isolated lesson.

## What shipped

### Memory Garden

The Kid World now includes a Memory Garden built from existing local progress:

| Garden element | Source |
|---|---|
| Flowers | Completed learning adventures |
| Fireflies | Companion XP |
| Growing tree | Overall adventure progress |
| Subject blooms | Adaptive strengths |
| Floating drawings | Recent child drawings saved on device |

No extra private child data is collected for the garden. It is a visual remix of
state the app already stores.

### Drawings Come Alive

Recent saved drawings now appear inside the Kid World as playful living memories.
This gives drawing a second life after the child leaves the drawing tool.

The current version shows local image files with gentle motion. It does not
upload drawings, classify them, or generate new images from them.

### Watch, Together, Your Turn

Lessons now have three support stages powered by the adaptive engine:

| Stage | When it appears | Experience |
|---|---|---|
| Watch | New or low-mastery skill | The app demonstrates one answer first |
| Together | Building skill | Choices are gently reduced where possible |
| Your Turn | Stronger mastery | The child gets the full challenge |

The stage is shown before a lesson and is passed to engines through a shared
learning support scope. Choice-based engines use the support stage directly.
Other engines still benefit from the shared intro, rescue behavior and adaptive
tracking.

### Smarter Spark Sidekick

Spark now reads local adaptive progress and recent companion memory to suggest a
helpful next activity. If a child has weak areas, Spark points toward the
highest-value subject. If there is no weak area yet, Spark nudges toward the
first adventure or the Memory Garden.

Spark remains deterministic and local-first. There is no server-side child
profiling in this implementation.

### Energy Mode

Each child profile now stores an energy mode:

| Mode | Intended feel |
|---|---|
| Calm | Softer pacing and fewer visual bursts |
| Ready | Balanced default |
| Super | More lively celebration timing and feedback |

Energy mode is selected from Home and affects sensory feedback only. It does not
make school content easier or harder. That separation matters: a child who feels
calm should not be treated as less capable.

### Learning Music

Correct answers, rewards and level-up moments now receive small generated music
tones. These tones are synthesized locally as short WAV buffers, so there are no
new licensed audio files or network dependencies.

The tones respect the existing sound setting. In tests and before the audio
service is initialized, the generated melody layer stays silent to avoid plugin
lifecycle issues.

### Sibling Co-op

Mini Games now include a Solo/Team toggle on the hub. Team mode is stored per
child profile and currently powers two selected games:

| Game | Co-op behavior |
|---|---|
| Toy Sort | Alternates shared turns between P1 and P2 |
| Feed the Pet | Alternates shared turns between P1 and P2 |

This is intentionally cooperative, not competitive. There is one shared score,
no loser state, and no penalty when a younger sibling needs help.

## Implementation map

- Profile state:
  `lib/features/profiles/domain/child_profile.dart`,
  `lib/features/profiles/profiles_controller.dart`
- Energy mode:
  `lib/features/home/home_screen.dart`,
  `lib/app/kidverse_app.dart`,
  `lib/core/widgets/kid_experience_layer.dart`
- Generated learning tones:
  `lib/core/services/audio_service.dart`
- Learning support stages:
  `lib/features/ai/adaptive_engine.dart`,
  `lib/features/games/learning_support.dart`,
  `lib/features/games/adventure_intro.dart`,
  `lib/features/games/game_host_screen.dart`
- Guided choice engines:
  `lib/features/games/engines/tap_choice_game.dart`,
  `lib/features/games/engines/bubble_pop_game.dart`,
  `lib/features/games/engines/feed_pet_game.dart`,
  `lib/features/games/engines/boss_battle_game.dart`,
  `lib/features/games/engines/listen_and_tap_game.dart`,
  `lib/features/games/engines/mole_match_game.dart`
- Memory Garden and smarter Spark:
  `lib/features/world/kid_world_screen.dart`
- Sibling co-op:
  `lib/features/mini_games/mini_games_screen.dart`,
  `lib/features/mini_games/games/toy_sort_game.dart`,
  `lib/features/mini_games/games/feed_pet_game.dart`

## Regression coverage

Automated tests cover:

- support-stage progression from Watch to Together to Your Turn;
- profile persistence for energy mode and sibling co-op;
- Memory Garden rendering with a saved child drawing;
- lesson mission completion through the Watch demo flow;
- sibling co-op turn display in Feed the Pet;
- existing profile, world, home, mini-game and gameplay stability paths.

Run before release:

```bash
flutter analyze --fatal-infos
flutter test
```

## Product notes

- The Memory Garden should stay reward-driven and calm. Do not turn it into a
  task list.
- Spark suggestions should sound like encouragement, not remediation. Avoid
  language like "weak" or "bad" in child-facing copy.
- Energy mode should remain a sensory preference. Difficulty should continue to
  come from mastery data.
- Co-op should be expanded game by game. Each game needs an authored co-play
  rule; a blanket two-player toggle would create confusing behavior.
- The generated melody layer is a production-safe bridge, not a final music
  identity. A future licensed music pack can replace or enrich it.
- Child drawings are private local memories. Do not upload or process them
  unless a parent-visible consent flow exists.

## Next production steps

1. Add physical-device checks for audio latency, haptics and performance on a
   low-end Android device.
2. Expand Team mode to more mini-games only after each game has a clear shared
   rule.
3. Add educator-reviewed copy for Watch/Together prompts in Hindi and English.
4. Commission a cohesive sound pack if KidVerse needs a stronger branded music
   identity.
5. Add screenshot or golden coverage for Memory Garden and the Energy selector.
