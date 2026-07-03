# 16 — Mini Games: Fun Play Zone for Kids

## Overview

Add a **"Mini Games" tab** to the Home screen — a separate section from the
learning curriculum where kids can play fun, casual puzzle/arcade games just
for enjoyment. No lessons, no grading, no curriculum — pure entertainment
that keeps kids engaged with the app during breaks.

**Implementation status:** Complete. The catalog, four games, deep-linkable
routes, reactive local high scores, real OpenMoji card/chicken art, and game
logic tests are implemented. Mini games remain separate from curriculum and
do not award coins, XP, stars, or collectibles.

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

### Game 1: Infinity Loop Hex

**Type:** Puzzle / Relaxation
**Concept:** Tap hexagonal tiles to rotate pipe segments until all pipes
connect in a closed loop. No timer, no score — just satisfying completion.
**Controls:** Tap a hex tile → rotates 60° clockwise.
**Win condition:** All pipes form a single continuous closed loop.
**Grid:** 4×4 or 5×5 hexagonal grid.
**Visual:** Hex tiles drawn with `CustomPainter` (bezier curves for pipes).
**Difficulty:** Randomly generated boards → varying complexity.

### Game 2: 368 Chickens (Simple Tap Counter)

**Type:** Arcade / Reaction
**Concept:** Chickens appear on screen one by one in rapid succession.
Tap each chicken before it disappears. Miss 3 = game over.
**Controls:** Tap chickens → they pop with an animation + sound.
**Scoring:** 1 point per chicken tapped. Combo multiplier for consecutive
taps without missing.
**Visual:** Animated chicken sprites (OpenMoji 🐔 or code-drawn). Eggs,
feathers on miss.
**Duration:** 30-second rounds (endless mode optional).

### Game 3: Stack Merge (Number Merge)

**Type:** Puzzle / Strategy (like 2048/Suika)
**Concept:** Numbers/balls fall from the top. Drop them onto a stack.
When two of the same number touch, they merge into the next number.
Goal: reach the highest number possible.
**Controls:** Tap left/right to move, tap to drop.
**Scoring:** Value of merged numbers.
**Visual:** Colorful numbered circles (2=red, 4=orange, 8=yellow, 16=green,
32=blue, 64=purple, 128=gold, 256=rainbow).
**Difficulty:** Stack gets taller over time.

### Game 4: 2048 (Classic)

**Type:** Puzzle / Strategy
**Concept:** Classic 2048. Swipe tiles on a 4×4 grid. Equal numbers merge.
**Controls:** Swipe up/down/left/right (or arrow buttons for kids).
**Scoring:** Points from merged tiles.
**Win condition:** Reach 2048 tile.
**Visual:** Colored number tiles with the KidVerse palette.

---

## 3. Architecture

### File Structure

```
lib/features/mini_games/
├── mini_games_screen.dart        # Grid listing all mini games
├── mini_games_controller.dart    # State: high scores, unlocks
├── data/
│   └── mini_games_repository.dart # Save high scores via SharedPreferences
├── games/
│   ├── infinity_loop_hex_game.dart
│   ├── chicken_tap_game.dart
│   ├── stack_merge_game.dart
│   └── classic_2048_game.dart
└── widgets/
    ├── game_card.dart            # Reusable game card widget
    └── score_display.dart        # Score + high score widget
```

### Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Game state management | `StatefulWidget` per game | Each game is self-contained, no Riverpod needed |
| High score persistence | `SharedPreferences` via `MiniGamesRepository` | Same pattern as profiles, works offline |
| Screen navigation | New route `/mini-games` + sub-routes | Uses existing go_router setup |
| No rewards system | Mini games give **no coins/XP/stars** | Pure fun — prevents grinding for rewards |
| No adaptive engine | All kids play the same game | Skill-based games, not curriculum |

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

/// Each game reports back via this callback when it ends.
typedef OnGameOver = void Function(int score);
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
│  │  🔷    │  │  🐔    │     │
│  │Infinity│  │ 368    │     │
│  │Loop Hex│  │Chickens│     │
│  │HS: 3/5 │  │HS: 42  │     │
│  └────────┘  └────────┘     │
│  ┌────────┐  ┌────────┐     │
│  │  🔢    │  │  2048  │     │
│  │ Stack  │  │  2048  │     │
│  │ Merge  │  │Classic │     │
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
- **Bottom:** Brief instruction (first time only) + restart button
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

## 5. Implementation Order

| Step | Task | Effort | Dependencies |
|------|------|--------|-------------|
| 1 | Create `MiniGamesRepository` (high scores via SharedPreferences) | Small | None |
| 2 | Create `MiniGamesController` (simple notifier) | Small | Step 1 |
| 3 | Create `mini_games_screen.dart` with grid layout | Medium | Step 2 |
| 4 | Add `/mini-games` route to `router.dart` | Small | Step 3 |
| 5 | Add "Mini Games" quick action to Home screen | Small | Step 4 |
| 6 | Build **Infinity Loop Hex** game | Large | None |
| 7 | Build **368 Chickens** game | Medium | None |
| 8 | Build **Stack Merge** game | Large | None |
| 9 | Build **Classic 2048** game | Medium | None |
| 10 | Add game routes `/mini-games/{id}` | Small | Steps 6-9 |
| 11 | Wire high score saving on game over | Small | Steps 1, 6-9 |

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
| Infinity Loop Hex | Same mechanic | Simpler grid (4×4), rounder graphics, kid colors |
| 368 Chickens | Same tap-to-catch | Chickens instead of generic circles, fun sounds, combo system |
| Stack Merge | Like 2048 + Suika | Merge by dropping, auto-stack, no complex gestures |
| 2048 Classic | Same rules | Bigger number text, kid-friendly colors, swipe + button controls |

---

## 8. Implemented Routes

- `/mini-games`
- `/mini-games/infinity-loop`
- `/mini-games/368-chickens`
- `/mini-games/stack-merge`
- `/mini-games/2048`
