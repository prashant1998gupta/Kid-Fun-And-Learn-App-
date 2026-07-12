# 16 — Mini Games: Fun Play Zone for Kids

## Overview

The **Mini Games** area is a connected, story-driven **Kid World** for playful
breaks from the curriculum. It contains no grading or wrong-answer pressure,
but it does share the child's wallet and growing pet so every play session has
an emotionally meaningful reward.

**Implementation status:** Complete. The catalog, twenty-nine games, deep-linkable
routes, reactive high scores, OpenMoji art, voice tutorials, invisible adaptive
difficulty, story goals, local co-op, no-loss play, creative mode, wallet/pet
rewards, daily challenges, badges, physical controls, accessibility behavior,
the rotating Adventure Trail, interactive storybook journeys, and
framework-independent rule tests are implemented.

### Engagement features now implemented

- Difficulty adapts invisibly. Children never need to label themselves Easy,
  Normal, or Hard; stalled play gets help and strong play gently scales up.
- First-play animated gesture guidance speaks every instruction aloud and is
  remembered locally after dismissal.
- Solo and local **Together** modes are available across the four casual games.
- Twenty-five dedicated learning adventures add 1,250 persistent levels. Toy Sort and
  Feed the Pet cover classification, food, and counting; Sound Safari covers
  listening and animal sounds; Number Garden covers quantities and early
  addition; Story Train covers sequencing and prediction; Letter Bakery covers
  first sounds and upper/lowercase letters; Clean Room Helper covers practical
  classification and everyday independence.
- Six Class 1–2 adventures extend the world into applied learning: Math Market
  covers totals and change; Word Wizard covers beginning/ending sounds and
  whole-word spelling; Sentence Train covers grammar and punctuation; Clock
  Adventure covers hour/half-hour clocks and routines; Nature Detective covers
  observation and habitats; Shape Builder covers recognition, sides, and
  patterns.
- Six Class 3–4 adventures add applied reasoning: Pizza Fraction Café covers
  reading, equivalence, and addition of fractions; Multiplication Kingdom
  connects equal groups, missing factors, and division; Grammar Detective
  covers parts of speech, agreement, tense, and conjunctions; Code the Robot
  covers sequences, loops, and debugging; Science Machine Lab covers matter,
  forces, circuits, simple machines, bodies, Earth, materials, and environment;
  Map Quest covers compass directions, grid coordinates, and route distance.
- Six Class 5 adventures focus on independent reasoning: Eco City Builder
  connects sustainability with evidence-based planning; Space Mission Control
  applies decimals, fractions, angles, and metric conversion; Business Bazaar
  covers budgets, discounts, profit, and unit price; Mystery Science Lab teaches
  variables, fair tests, measurement, and conclusions; News Detective builds
  fact, source, image-context, advertising, and sample-size literacy; Algorithm
  Quest develops nested-loop, condition, efficiency, and debugging skills.
- Every learning level contains five to nine short prompts. Seeded shuffling and
  rotating themes prevent adjacent rounds from presenting the same sequence.
- On selected rounds Pip deliberately makes a funny wrong guess. The child
  corrects Pip and becomes the teacher, turning practice into a confidence loop.
- Every completed learning level reveals a toy, pet item, picnic item, or garden
  decoration. Rewards persist per child and appear in the hub and Kid World.
- Sound, haptics, squish/pop feedback, confetti, mascot reactions, and a clear
  coin/XP/pet reward moment are shared across the games.
- Second-pass game juice keeps pieces inside their play boxes and adds physical
  feedback: Rainbow Rescue has a clipped board, drop-preview glow, landing
  shadow, landing bounce, and merge burst; Flower Flow has bloom rings; Animal
  Family has board squish/shake and a new-friend pop.
- Reduced motion, color-blind-safe shapes, semantic labels, and reachable
  bottom controls are accessibility defaults.
- Optional tilt control in Animal Family and trace gestures in Flower Flow add
  physical, memorable play.
- One grade-safe rotating local daily challenge with persistent progress.
- A daily three-stop **Adventure Trail** mixes games from across the complete
  catalog. Each finished stop receives a visible stamp; completing all three
  opens a persistent chest, grants 15 bonus coins and 20 bonus XP, and unlocks
  the Trail Blazer badge. Trails use the active child's grade band plus the
  four casual games, so younger children never receive an unsuitable Class 5
  mission while every game remains part of an age-appropriate rotation.
- Every trail is now one of eight hand-authored rotating story worlds: Moon
  Garden, Rainbow River, Clockwork Castle, Cloud Zoo, Whispering Library, Coral
  City, Tiny Planet, or Dream Train. Each has an opening problem, three unique
  relic chapters, and a full ending instead of generic checklist text.
- Children choose how the hero solves the story: **Brave**, **Kind**, or
  **Curious**. The selected path changes every chapter's spoken mission and the
  final ending, persists per child for the day, and becomes part of the shared
  companion's memory. Direct trail play waits for a choice; entering a chapter
  through the catalog safely defaults to Curious.
- A speaker button reads the current story aloud. Completing the third chapter
  automatically narrates the ending from any of the 29 game result flows and
  unlocks the Story Hero badge.
- The hub now has All, Learning, Preschool, Class 1–2, Class 3–4, Class 5, and
  Just Fun filters. **Play Next** follows the unfinished trail, while
  **Surprise Me** selects an unplayed game or the daily challenge afterward.
- Thirty-four local mini-game badges plus persistent coin, XP, high-score, play, and
  pet-growth progress.
- Local high scores and play history persist through `SharedPreferences`.

### Game-specific upgrades

| Game | Implemented engagement loop |
|------|-----------------------------|
| Flower Flow | Fix water paths for thirsty flowers; per-tile glow/notes; trace input; adaptive boards/hints; musical bloom finale; co-op turns |
| Egg Rescue | No-fail timed catching; split-screen sibling scores; spoken egg counting; golden chickens; eggs, bombs, combos, particles, pause, and giant golden finale |
| Rainbow Rescue | Tower-to-the-moon story; adaptive helper hand; color puffs; three-chain fireworks; rainbow wildcards; co-op turns; automatic full-tower rescue; endless creative sandbox |
| Animal Family | Animals replace abstract targets; every new animal speaks and dances; co-op turns; swipe/button/tilt control; one-step undo; automatic full-board rescue |
| Toy Sort | 50 levels; tap-or-drag baskets; color, category, habitat, size, and shape themes; two baskets first, then three; Teach Pip correction rounds; no failure state |
| Feed the Pet | 50 levels; spoken requests; food/color recognition; counting grows from 1–3 to 1–10; editable bowl; Teach Pip counting rounds; no failure state |
| Sound Safari | 50 levels; spoken sound clues; animal-to-sound and sound-to-animal matching; 15-animal rotation; Teach Pip listening rounds |
| Number Garden | 50 levels; visible one-to-one counting from 1–10; later levels introduce small addition groups; touch-friendly number answers |
| Story Train | 50 levels; illustrated event pairs; predict the logical next event; routines, nature, creativity, and self-care stories |
| Letter Bakery | 50 levels; 26 illustrated words; first-sound matching; uppercase foundations followed by lowercase transfer |
| Clean Room Helper | 50 levels; sort toys, clothes, dishes, bathroom items, and books into meaningful real-life places |
| Math Market | 50 Class 1–2 levels; add two/three prices; pay with coins; calculate friendly change; practical shop stories |
| Word Wizard Workshop | 50 Class 1–2 levels; beginning sounds, ending sounds, and whole-word spelling repair |
| Sentence Train | 50 Class 1–2 levels; choose correct verbs and describing words; finish telling, asking, and excited sentences with punctuation |
| Clock Adventure | 50 Class 1–2 levels; read full and half-hour clock faces; connect times to unique daily routines |
| Nature Detective | 50 Class 1–2 levels; infer animals/plants from clues and match living things to seven habitats |
| Shape Builder | 50 Class 1–2 levels; recognise eight shapes, count straight sides, and continue alternating patterns |
| Pizza Fraction Café | 50 Class 3–4 levels; read served parts, find equivalent fractions, and add fractions with like denominators |
| Multiplication Kingdom | 50 Class 3–4 levels; equal groups, facts through 12×12, division inverses, and missing factors |
| Grammar Detective | 50 Class 3–4 levels; nouns, verbs, adjectives, adverbs, pronouns, agreement, tense, punctuation, prepositions, conjunctions, and plurals |
| Code the Robot | 50 Class 3–4 levels; exact movement sequences, repeated-command loops, result prediction, and one-step debugging |
| Science Machine Lab | 50 Class 3–4 levels; authored reasoning missions across matter, forces, machines, circuits, life, Earth, materials, and environment |
| Map Quest | 50 Class 3–4 levels; cardinal directions, A1–C3 coordinate movement, and multi-leg distance problems |
| Eco City Builder | 50 Class 5 levels; clean energy, transport, water, waste, biodiversity, flood protection, and green-building choices |
| Space Mission Control | 50 Class 5 levels; decimals, straight-line angles, metric conversions, and fractions of quantities |
| Business Bazaar | 50 Class 5 levels; budgets, discounts, profit, and unit-price decisions |
| Mystery Science Lab | 50 Class 5 levels; variables, fair tests, reliable evidence, graphing, measurement, safety, and conclusions |
| News Detective | 50 Class 5 levels; facts and opinions, source/date checks, image context, corroboration, advertising, surveys, and corrections |
| Algorithm Quest | 50 Class 5 levels; nested loops, conditions, efficiency, boundary cases, and debugging |

Inspired by: [Infinity Loop Hex](https://poki.com/en/g/infinity-loop-hex),
[368 Chickens](https://368chickens.com/),
[Stack Merge](https://lcpckp.github.io/stack-merge/),
[2048](https://poki.com/en/g/2048).

---

## 1. Entry Point

A new **"🎮 Mini Games"** card in the Home screen's quick actions row
(between "Season" and "Art Studio"), and a dedicated tab screen listing
all available mini games as a grid of cards.

```
Home Screen Quick Actions:
[Badges] [Daily Gift] [Spin] [Shop] [Collect] [Friends] [Season] [🎮 Mini Games] [🎨 Art Studio]
```

---

## 2. Mini Game Catalog (29 games)

Each is a **self-contained stateful widget** with no dependency on `Lesson`,
`Question`, or curriculum data. They are pure Flutter games.

The first four are casual logic/reaction breaks. The other twenty-five are
learning-first games from preschool through Class 5 whose level and
world-reward progress persists through `MiniGamesRepository`.

### Game 1: Flower Flow

**Type:** Puzzle / Relaxation
**Concept:** Help thirsty flowers by rotating water paths into one glowing
loop. Correctly aligned tiles glow, bloom, and play a positive note immediately.
**Controls:** Tap or trace across a hex tile to rotate it 60° clockwise.
**Win condition:** All pipes form a single continuous closed loop.
**Grid:** Starts at 3×3 and quietly grows after strong finishes; stalls trigger
an automatic single-tile assist.
**Visual:** Hex tiles drawn with `CustomPainter` (bezier curves for pipes).
**Completion:** Water-flow celebration, flower bloom, short tune, 1–3 stars,
coins, XP, and pet food.

### Game 2: Egg Rescue

**Type:** Arcade / Reaction
**Concept:** Help Mama Chicken collect eggs. The round is time-based and cannot
be lost; misses only make targets slower and longer-lived.
**Controls:** Tap chickens → they pop with an animation + sound.
**Scoring:** Target and combo points. Together mode divides the screen into
Player 1 and Player 2 halves with independent scores.
**Visual:** Animated chicken sprites (OpenMoji 🐔 or code-drawn). Eggs,
feathers on miss.
**Duration:** 35-second rounds, with eggs adding time. The finale introduces a
giant golden chicken, egg rain, and spoken counting from 1 to the egg total.

### Game 3: Rainbow Rescue

**Type:** Puzzle / Strategy (like 2048/Suika)
**Concept:** Numbers/balls fall from the top. Drop them onto a stack.
When two of the same number touch, they merge into the next number.
Goal: free rainbow color and build a tower toward the moon.
**Controls:** Tap left/right to move, tap to drop.
**Scoring:** Value of merged numbers.
**Visual:** Colorful numbered circles (2=red, 4=orange, 8=yellow, 16=green,
32=blue, 64=purple, 128=gold, 256=rainbow).
**Adaptive play:** A helper hand highlights the best column. Dry streaks make
matching blocks more likely; strong chains restore the full challenge.
**No loss:** A full tower triggers a rainbow rescue that clears space without
discarding the score. Creative mode is an endless, failure-free sandbox.

### Game 4: Animal Family

**Type:** Puzzle / Strategy
**Concept:** Equal animals merge into the next family member. New animals say
their name/sound and perform a small reduced-motion-aware dance.
**Controls:** Swipe, large arrow buttons, or optional accelerometer tilt.
**Scoring:** Points from merged tiles.
**Win condition:** Grow the family from chick to dragon and beyond.
**No loss:** A full board triggers a friendly dragon puff that clears the
smallest tiles and keeps the same board and score alive.
**Visual:** OpenMoji animals plus values; number mode includes shape cues when
color-blind mode is enabled.

---

## 3. Architecture

### File Structure

```
lib/features/mini_games/
├── mini_games_screen.dart        # Story hub, trail, filters, actions, game catalog
├── mini_games_controller.dart    # Results, grade pool, trails, chest, pet, badges
├── data/
│   ├── mini_games_repository.dart # Scores, levels, paths, stamps, chest persistence
│   ├── mini_game_story.dart       # Eight worlds, choices, relics, endings
│   └── mini_pet.dart              # Pet stages, XP, accessories
├── games/
│   ├── ...                        # 29 independently routed game screens
│   └── learning_adventure_game.dart # Shared engine for learning adventures
└── widgets/
    ├── game_tutorial.dart        # First-play animated voice tutorial
    └── mini_game_widgets.dart    # Story, play modes, rewards, toolbar, mascot
```

### Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Game state management | `StatefulWidget` per game + Riverpod progress controller | Rules stay local; shared persistence stays reactive |
| High score persistence | `SharedPreferences` via `MiniGamesRepository` | Same pattern as profiles, works offline |
| Screen navigation | New route `/mini-games` + sub-routes | Uses existing go_router setup |
| Rewards | Modest coins + XP plus pet XP | Makes play meaningful without overpowering learning rewards |
| Difficulty | Invisible and performance-adaptive | A pre-reader never has to self-assess or choose “Hard” |
| Failure | Rescue and continuation | Protects experimentation and emotional safety for under-6s |
| Co-op | Same-device Together mode | Enables siblings and parents to play without accounts/controllers |
| Creative play | Endless Stack sandbox | Supports making and experimentation, not only solving |
| Hub journey | Daily grade-safe three-chapter trail | Gives the catalog a beginning, middle, and ending |
| Story agency | Brave, Kind, or Curious path | Child choice changes missions and finale without changing safety |
| Chest claim | Per-child/per-day idempotent record | Prevents duplicated wallet rewards |

### Game Widget Interface

Games are independent routed widgets. They report milestones through the shared
controller/repository result pipeline; the following is the conceptual contract,
not a required Dart base class:

```dart
abstract class MiniGameWidget extends StatefulWidget {
  /// Unique ID for high score tracking.
  String get gameId;

  /// Display name shown on the card.
  String get gameName;

  /// Emoji icon for the card.
  String get gameIcon;
}

/// Conceptual result reported by each game at a milestone or round completion.
typedef OnGameResult = void Function(int score);
```

### Route Structure

```
/mini-games              → MiniGamesScreen (storybook trail + discovery catalog)
/mini-games/{game-id}    → one of 29 game screens
```

The complete implemented route list is recorded in section 8.

---

## 4. UI Design

### Mini Games Listing Screen

```
┌──────────────────────────────┐
│  ← Back  🎮 Mini Games  🔊   │
│  Moon Garden: Lost Starlight │
│  Choose: Brave Kind Curious  │
│  ● Relic 1 ─ ○ Relic 2 ─ ○  │
│       [PLAY NEXT CHAPTER]     │
│  All Learning P–K 1–2 3–4 5 │
│  [Surprise Me] [Daily Goal]  │
│  ┌────────┐  ┌────────┐     │
│  │ Game   │  │ Game   │ ... │
│  │ level  │  │ badge  │     │
│  └────────┘  └────────┘     │
│  [Kid World rewards + pet]   │
└──────────────────────────────┘
```

### In-Game Screen

Each game screen has:
- **Top bar:** Game name, score, high score, back button
- **Game area:** Full remaining space
- **Bottom:** Large controls where needed, plus restart/continue actions
- **Background:** Uses `AnimatedBackground` with a fun theme

### Game Card Widget (`_GameCard`)

```dart
// Reuses the same BouncyButton + action card pattern from home_screen.dart
SizedBox(
  width: 160,
  child: BouncyButton(
    onTap: () => context.push('/mini-games/${game.id}'),
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: [/* shadow with game's color */],
      ),
      child: Column(
        children: [
          Text(game.icon, style: TextStyle(fontSize: 48)),
          Text(game.name, style: ...),
          Text('Best: ${repo.highScore(game.id)}', style: ...),
        ],
      ),
    ),
  ),
)
```

---

## 5. Completed Implementation Sequence

| Step | Task | Effort | Dependencies |
|------|------|--------|-------------|
| 1 | Four casual games, routes, scores, rescue play, juice | Done | Foundation |
| 2 | Toy Sort + Feed the Pet learning progression | Done | 100 levels |
| 3 | Preschool learning adventures | Done | +250 levels |
| 4 | Classes 1–2 learning adventures | Done | +300 levels |
| 5 | Classes 3–4 learning adventures | Done | +300 levels |
| 6 | Class 5 learning adventures | Done | +300 levels |
| 7 | Shared rewards, pet/world unlocks, badges, daily goals | Done | Connected world |
| 8 | Grade-aware filters, Play Next, Surprise Me | Done | Discovery |
| 9 | Three-stop daily Adventure Trail and mystery chest | Done | Guided journey |
| 10 | Eight story worlds + Brave/Kind/Curious branching | Done | Storybook layer |
| 11 | Narration, companion memory, Trail Blazer/Story Hero | Done | Living finale |

---

## 6. Why This Works for KidVerse

| Factor | Benefit |
|--------|---------|
| **Play without pressure** | No loss screen; mistakes get a spoken hint and immediate retry |
| **Learning + brain training** | Classification/counting plus logic, reaction, and strategy |
| **Short sessions** | Each game can be played in 1-5 minutes |
| **Matches existing design** | Same BouncyButton, AnimatedBackground, rounded cards |
| **No curriculum dependency** | Self-contained widgets, no Lesson/Question needed |
| **Shareable** | High scores add replay value and friendly competition |
| **Extensible** | Add more games later by dropping in a new widget + card |

---

## 7. Comparison to Referenced Games

| Reference | KidVerse version | Key changes |
|-----------|-----------------|-------------|
| Infinity Loop Hex | Flower Flow | Water-and-flower story, instant glow/note feedback, adaptive help, trace and co-op |
| 368 Chickens | Egg Rescue | No-loss play, egg counting, split-screen co-op, golden finale |
| Stack Merge | Rainbow Rescue | Moon story, helper hand, rescue clearing, co-op, endless creative mode |
| 2048 Classic | Animal Family | Speaking/dancing animals, tilt, co-op, friendly full-board rescue |

---

## 9. Rewards and Accessibility

Every completed result flows through `MiniGamesController.recordResult` and:

1. saves the high score, play history, daily progress, and badges;
2. grants a score-scaled but modest coin and XP bundle to the active profile;
3. feeds persistent pet XP, evolving the pet and unlocking accessories; and
4. shows a visible reward banner alongside the game's celebration.

The new behavior respects `reducedMotionProvider`, the existing voice/SFX and
haptic preferences, and color-blind mode. Number tiles gain unique shape cues,
moving Chicken targets stop oscillating under reduced motion, Stack skips its
drop delay, and tutorial gestures become static. All primary actions retain
semantic labels and large one-hand-reachable touch targets.

## 10. Verification

- `flutter analyze`: zero issues.
- `flutter test`: all 135 tests pass at the latest verification.
- Mini-game tests cover score persistence, wallet reward delivery, pet growth,
  daily resets, 2048 merge/undo/rescue rules, Stack chain/rainbow/rescue rules,
  Chicken target rules, learning-level persistence, per-child Kid World items,
  full Toy Sort/Feed the Pet progression, and phone-viewport rendering for the
  catalog and all twenty-nine game screens, grade-band discovery filters,
  age-eligible Adventure Trail rotation, story-path persistence/reset, choice
  UI, one-time chest claims, story-ending companion memory, and chest bonus
  delivery. A separate rotation audit confirms that all 29 catalog games are
  reachable. The shared content audit validates 5,750 generated rounds across
  every 50-level adventure.

---

## 8. Implemented Routes

- `/mini-games`
- `/mini-games/infinity-loop`
- `/mini-games/368-chickens`
- `/mini-games/stack-merge`
- `/mini-games/2048`
- `/mini-games/toy-sort`
- `/mini-games/feed-the-pet`
- `/mini-games/sound-safari`
- `/mini-games/number-garden`
- `/mini-games/story-train`
- `/mini-games/letter-bakery`
- `/mini-games/clean-room-helper`
- `/mini-games/math-market`
- `/mini-games/word-wizard-workshop`
- `/mini-games/sentence-train`
- `/mini-games/clock-adventure`
- `/mini-games/nature-detective`
- `/mini-games/shape-builder`
- `/mini-games/fraction-cafe`
- `/mini-games/multiplication-kingdom`
- `/mini-games/grammar-detective`
- `/mini-games/code-the-robot`
- `/mini-games/science-machine-lab`
- `/mini-games/map-quest`
- `/mini-games/eco-city-builder`
- `/mini-games/space-mission-control`
- `/mini-games/business-bazaar`
- `/mini-games/mystery-science-lab`
- `/mini-games/news-detective`
- `/mini-games/algorithm-quest`
