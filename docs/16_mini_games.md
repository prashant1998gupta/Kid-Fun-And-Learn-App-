# 16 — Mini Games: Fun Play Zone for Kids

## Overview

The **Mini Games** area is a connected, story-driven **Kid World** for playful
breaks from the curriculum. It contains no grading or wrong-answer pressure,
but it does share the child's wallet and growing pet so every play session has
an emotionally meaningful reward.

**Implementation status:** Complete. The catalog, four games, deep-linkable
routes, reactive high scores, OpenMoji art, voice tutorials, invisible adaptive
difficulty, story goals, local co-op, no-loss play, creative mode, wallet/pet
rewards, daily challenges, badges, physical controls, accessibility behavior,
and framework-independent rule tests are implemented.

### Engagement features now implemented

- Difficulty adapts invisibly. Children never need to label themselves Easy,
  Normal, or Hard; stalled play gets help and strong play gently scales up.
- First-play animated gesture guidance speaks every instruction aloud and is
  remembered locally after dismissal.
- Solo and local **Together** modes are available across all four games.
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
- One rotating local daily challenge with persistent progress.
- Seven local mini-game badges plus persistent coin, XP, high-score, play, and
  pet-growth progress.
- Local high scores and play history persist through `SharedPreferences`.

### Game-specific upgrades

| Game | Implemented engagement loop |
|------|-----------------------------|
| Flower Flow | Fix water paths for thirsty flowers; per-tile glow/notes; trace input; adaptive boards/hints; musical bloom finale; co-op turns |
| Egg Rescue | No-fail timed catching; split-screen sibling scores; spoken egg counting; golden chickens; eggs, bombs, combos, particles, pause, and giant golden finale |
| Rainbow Rescue | Tower-to-the-moon story; adaptive helper hand; color puffs; three-chain fireworks; rainbow wildcards; co-op turns; automatic full-tower rescue; endless creative sandbox |
| Animal Family | Animals replace abstract targets; every new animal speaks and dances; co-op turns; swipe/button/tilt control; one-step undo; automatic full-board rescue |

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

## 2. Mini Game Catalog (4 initial games)

Each is a **self-contained stateful widget** with no dependency on `Lesson`,
`Question`, or curriculum data. They are pure Flutter games.

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
├── mini_games_screen.dart        # Grid listing all mini games
├── mini_games_controller.dart    # Scores, wallet rewards, pet, badges, daily goal
├── data/
│   ├── mini_games_repository.dart # Persist mini-game progress
│   └── mini_pet.dart              # Pet stages, XP, accessories
├── games/
│   ├── infinity_loop_hex_game.dart
│   ├── chicken_tap_game.dart
│   ├── stack_merge_game.dart
│   └── classic_2048_game.dart
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

### Game Widget Interface

Every mini game follows this contract so the listing screen can host them:

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
/mini-games              → MiniGamesScreen (grid of game cards)
/mini-games/infinity-loop → InfinityLoopHexGame
/mini-games/368-chickens  → ChickenTapGame
/mini-games/stack-merge   → StackMergeGame
/mini-games/2048          → Classic2048Game
```

---

## 4. UI Design

### Mini Games Listing Screen

```
┌──────────────────────────────┐
│  ← Back    🎮 Mini Games     │
│                              │
│  ┌────────┐  ┌────────┐     │
│  │  🌸    │  │  🐔    │     │
│  │ Flower │  │  Egg   │     │
│  │  Flow  │  │ Rescue │     │
│  │HS: 3/5 │  │HS: 42  │     │
│  └────────┘  └────────┘     │
│  ┌────────┐  ┌────────┐     │
│  │  🌈    │  │  🐣    │     │
│  │Rainbow │  │ Animal │     │
│  │ Rescue │  │ Family │     │
│  │HS: 256 │  │HS: 512 │     │
│  └────────┘  └────────┘     │
│                              │
│  [Animated Background]       │
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
| 1 | Create `MiniGamesRepository` (high scores via SharedPreferences) | Small | None |
| 2 | Create `MiniGamesController` (simple notifier) | Small | Step 1 |
| 3 | Create `mini_games_screen.dart` with grid layout | Medium | Step 2 |
| 4 | Add `/mini-games` route to `router.dart` | Small | Step 3 |
| 5 | Add "Mini Games" quick action to Home screen | Small | Step 4 |
| 6 | Build **Flower Flow** game | Large | None |
| 7 | Build **Egg Rescue** game | Medium | None |
| 8 | Build **Rainbow Rescue** game | Large | None |
| 9 | Build **Animal Family** game | Medium | None |
| 10 | Add game routes `/mini-games/{id}` | Small | Steps 6-9 |
| 11 | Wire result persistence, wallet rewards, and pet growth | Small | Steps 1, 6-9 |

---

## 6. Why This Works for KidVerse

| Factor | Benefit |
|--------|---------|
| **Pure fun, no pressure** | No grading, no "wrong answers" — just play |
| **Brain training** | Logic puzzles (2048, Hex) + reaction (Chickens) + strategy (Merge) |
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
- `flutter test`: all 82 tests passing at the last implementation verification.
- Mini-game tests cover score persistence, wallet reward delivery, pet growth,
  daily resets, 2048 merge/undo/rescue rules, Stack chain/rainbow/rescue rules,
  Chicken target rules, and phone-viewport rendering for the catalog and all
  four game screens.

---

## 8. Implemented Routes

- `/mini-games`
- `/mini-games/infinity-loop`
- `/mini-games/368-chickens`
- `/mini-games/stack-merge`
- `/mini-games/2048`
