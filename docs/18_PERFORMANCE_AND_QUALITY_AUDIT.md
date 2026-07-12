# KidVerse Performance & Quality Improvement Audit

Last audited: 2026-07-06  
Scope: Flutter app quality, game feel, performance, optimization, maintainability, and production polish.

> **Implementation update (2026-07-11):** the shared mini-game result pipeline,
> 29-screen compact-phone widget coverage, grade-safe discovery, and persistent
> Adventure Trail/story/chest flow are implemented and covered by the current
> 135-test suite. Recommendations below remain the long-term quality plan unless
> explicitly marked complete; DevTools profiling and physical-device visual
> sign-off are still required.

## Executive summary

KidVerse has a strong product direction: a playful learning world with mini
games, pets, rewards, voice guidance, profiles, parent controls, offline-first
storage, and Firebase-ready sync. The app is not weak because the idea is weak.
The biggest risk is that the app has grown faster than its internal systems.

The current pattern is:

```text
Great feature idea → implemented directly inside one screen/game
                   → another feature needs similar behavior
                   → copy/adapt logic
                   → bugs appear differently per screen
                   → more one-off fixes
```

That creates the feeling that "many bugs" exist even when `flutter analyze`
passes. The code compiles, but the user experience can still feel inconsistent:
one screen celebrates slowly, another jumps quickly; one mini game handles small
phones, another overflows; one reward path updates the pet, another does not.

The most important improvement is to turn repeated kid-facing behavior into
shared systems:

- One shared success/celebration timing system.
- One shared responsive game scaffold.
- One shared audio/voice queue.
- One shared mini-game result pipeline.
- Smaller game controllers with pure testable rules.
- Profiling-driven optimization instead of guessing.

## Current health snapshot

At the time of this audit:

- Static analysis is clean with `flutter analyze --fatal-infos`.
- Asset size is currently modest; assets are not the main performance problem.
- The codebase has several very large files, especially game and screen files.
- Many dependencies have newer major versions available and need controlled
  migration.
- Widget/regression tests exist, but performance profiling and golden/screenshot
  coverage should be expanded.

Important large files observed:

| Area | File | Concern |
|---|---|---|
| Curriculum factory | `lib/features/curriculum/data/question_factory.dart` | Very large content/logic file; hard to review and test incrementally. |
| Art Studio | `lib/features/art_studio/art_studio_screen.dart` | UI, drawing state, persistence, and interaction logic are concentrated together. |
| Chicken Tap | `lib/features/mini_games/games/chicken_tap_game.dart` | Game loop, timers, rendering, scoring, audio, and UI are mixed. |
| 2048 | `lib/features/mini_games/games/classic_2048_game.dart` | Game logic and widget presentation are tightly coupled. |
| Stack Merge | `lib/features/mini_games/games/stack_merge_game.dart` | Similar coupling of rules, interaction, layout, and rewards. |
| Infinity Loop | `lib/features/mini_games/games/infinity_loop_game.dart` | Puzzle rules, hints, animation, and completion flow are in one widget. |
| Home | `lib/features/home/home_screen.dart` | High-value screen; broad provider watching can cause unnecessary rebuilds. |
| Kid World | `lib/features/world/kid_world_screen.dart` | Visually complex screen; needs strict layout boundaries. |

## What is going wrong

### 1. Too much business/game logic lives inside UI widgets

Many game widgets are doing all of these jobs at once:

- building UI;
- owning timers and animation state;
- calculating scores;
- deciding difficulty;
- playing sounds;
- speaking voice prompts;
- writing rewards/progress;
- navigating to the next state.

This makes every game harder to stabilize. A UI layout fix can accidentally
touch game behavior. A game behavior fix can accidentally trigger layout bugs.

Better target:

```text
GameRules        pure logic; no Flutter imports
GameController   state machine, timer, score, current phase
GameScreen       renders state and sends user input
ResultPipeline   rewards, XP, achievements, pet growth
```

Example target structure:

```text
lib/features/mini_games/chicken_tap/
├── chicken_tap_rules.dart
├── chicken_tap_controller.dart
├── chicken_tap_state.dart
├── chicken_tap_screen.dart
└── widgets/
    ├── chicken_target_view.dart
    └── chicken_arena.dart
```

This allows fast unit tests:

```text
tap chicken → +1 egg
tap bomb → no game over in easy mode
miss twice → difficulty eases
golden chicken → bonus round
```

without needing to render a Flutter screen.

### 2. Repeated behaviors are implemented differently in different places

The app repeatedly needs:

- correct-answer celebration;
- wrong-answer retry feedback;
- voice prompt;
- first-play tutorial;
- rewards;
- pet XP;
- no-loss rescue behavior;
- result screen;
- responsive safe layout.

When each game or question engine implements these independently, the app feels
uneven. A child does not care that one engine is technically different from
another. They only feel, "Why did this one jump so fast?" or "Why did this one
not cheer?"

Create reusable systems instead of many local implementations.

Recommended shared systems:

| System | Purpose |
|---|---|
| `SuccessBeat` | Shows correct state, plays SFX/haptic, speaks praise, waits a consistent duration, then advances. |
| `RetryBeat` | Handles wrong answer feedback without punishment. |
| `KidAudioQueue` | Prevents TTS/SFX overlap and repeated voice spam. |
| `ResponsiveGameScaffold` | Gives every game safe padding, scroll behavior, title/actions, and compact layout rules. |
| `MiniGameResultPipeline` | Records score, coins, XP, pet growth, achievements, and daily challenge progress once. |
| `FirstPlayCoach` | One tutorial overlay/gesture coach reused by every game. |
| `DifficultyAdapter` | Invisible difficulty adjustment based on misses, stalls, and success streaks. |

### 3. Performance optimization is not yet measurement-first

Do not optimize by guessing. The app uses:

- animations;
- particles;
- TTS;
- haptics;
- timers;
- SVG/PNG illustrations;
- game loops;
- Riverpod rebuilds;
- Firebase-ready services;
- SharedPreferences persistence.

Any one of these can be fine alone, but together they need profiling.

Required profiling workflow:

```bash
flutter run --profile
```

Then open Flutter DevTools and inspect:

- frame chart;
- UI thread time;
- raster thread time;
- rebuild counts;
- memory growth;
- shader compilation;
- image cache behavior;
- CPU during mini games;
- app startup timeline.

Performance decisions should come from evidence:

```text
"Chicken Tap drops frames because all targets rebuild every 70ms"
```

is useful.

```text
"Maybe animations are slow"
```

is not enough.

### 4. Audio and TTS need stronger control

The app is voice-heavy, which is correct for pre-readers. But audio can become a
performance and UX problem if every tap interrupts the previous voice line.

Current risk patterns:

- repeated `speak()` calls can interrupt each other;
- SFX may stop previous SFX before playing a new one;
- success praise can overlap with next question prompt;
- voice can continue after navigation if not stopped;
- audio calls may happen inside hot tap/game paths.

Recommended `KidAudioQueue` behavior:

- Important instruction lines cancel previous speech.
- Tiny tap feedback should not trigger TTS.
- Success praise should have a minimum spacing window.
- Next prompt should wait until the success beat completes.
- Leaving a screen should stop screen-owned speech.
- Short SFX should use a tiny player pool so taps feel instant.

Suggested rules:

| Audio event | Behavior |
|---|---|
| Screen instruction | Can interrupt older instruction. |
| Success praise | Debounced; no more than once per success beat. |
| Tap SFX | Lightweight; no TTS. |
| Wrong answer | Short encouragement only after clear wrong state. |
| Navigation away | Stop TTS owned by that screen. |

### 5. SharedPreferences is doing too much

`SharedPreferences` is good for tiny values:

- settings;
- selected profile ID;
- first-play flags;
- simple counters.

It is not ideal as the long-term source of truth for structured app state:

- profiles;
- progress;
- achievements;
- drawings;
- mini-game history;
- sync snapshots;
- larger JSON blobs.

Problems with overusing SharedPreferences:

- no schema;
- harder migrations;
- risk of large JSON corruption;
- difficult partial updates;
- difficult querying;
- repeated encode/decode overhead;
- harder debugging when many features write keys independently.

Recommended direction:

| Data | Recommended storage |
|---|---|
| Settings | SharedPreferences |
| First-play tutorial flags | SharedPreferences |
| Active child ID | SharedPreferences |
| Profiles | Hive/Isar/SQLite-style local store |
| Progress | Local database |
| Achievements | Local database |
| Drawings | File storage + database metadata |
| Mini-game history | Local database |
| Sync snapshot metadata | Local database |

### 6. Provider watching is sometimes too broad

If a screen watches an entire child profile object, the whole screen may rebuild
when only coins, XP, theme, pet, or collectibles change.

Better:

```dart
final coins = ref.watch(
  activeChildProvider.select((child) => child?.wallet.coins ?? 0),
);
```

instead of:

```dart
final child = ref.watch(activeChildProvider);
final coins = child?.wallet.coins ?? 0;
```

Use `select()` aggressively on high-traffic screens:

- Home;
- Mini Games;
- Kid World;
- Game Result;
- Parent Dashboard;
- Shop;
- Collections.

### 7. Screens need stricter responsive layout contracts

Many bugs in kid apps are not logic bugs. They are layout bugs:

- small iPhone width;
- tablet landscape;
- large text scale;
- dark mode;
- reduced motion;
- safe area/notch;
- keyboard visible;
- older low-DPI Android tablets;
- parent device with accessibility text size enabled.

Every major screen should pass these layout modes:

| Mode | Requirement |
|---|---|
| 320px width phone | No overflow, all core actions reachable. |
| 375px iPhone | Primary target must look polished. |
| Large text 1.3x | Buttons and labels still usable. |
| Dark mode | Text contrast still readable. |
| Reduced motion | No essential information hidden behind animation. |
| Landscape | Either supported gracefully or intentionally constrained. |
| Tablet | Layout expands intentionally, not just stretched. |

The app already started adding stability tests for this. Continue that pattern.

### 8. There are too many competing product systems

The app includes many engaging systems:

- learning path;
- mini games;
- pet;
- world;
- shop;
- collections;
- art studio;
- story maker;
- spin wheel;
- season pass;
- leaderboard;
- parent dashboard.

This can be magical, but it can also become noisy. For kids, the strongest loop
should be simple:

```text
Play → clear success → reward → pet/world grows → next playful challenge
```

Everything else should support that loop.

If a feature does not strengthen that loop, it should be secondary, hidden, or
delayed until the core loop feels excellent.

## Performance risks by area

### Home screen

Risks:

- broad provider rebuilds;
- multiple animated elements;
- mascot/art rendering;
- daily rewards/spin checks;
- subject grid density;
- voice greeting on entry.

Improvements:

- use `select()` for specific child fields;
- avoid speaking on every rebuild/re-entry;
- split hero/header/subject grid into smaller const-friendly widgets;
- add screenshot/golden coverage for 320, 375, and tablet widths.

### Mini games

Risks:

- timers and `setState()` causing whole-game rebuilds;
- game logic mixed with rendering;
- audio calls inside hot paths;
- large widgets rebuilding every tick;
- different completion/reward flows per game.

Improvements:

- isolate moving pieces with `RepaintBoundary`;
- use `ValueNotifier`, controller state, or fine-grained widgets for hot areas;
- keep game rules pure;
- centralize result recording;
- use one success beat and one no-loss rescue pattern.

### Art Studio

Risks:

- large stateful screen;
- painting operations;
- saved drawings encoded as base64 PNG in preferences;
- many UI controls in one file;
- possible memory growth if images are not bounded.

Improvements:

- move drawing persistence to file storage;
- split canvas, toolbar, gallery, trace mode, and save flow;
- cap saved drawing dimensions;
- add memory profiling after repeated drawing/save/delete cycles.

### Kid World

Risks:

- visually dense layout;
- companion/pet scaling;
- room item placement;
- drawing/object rendering;
- labels clipping on small screens.

Improvements:

- maintain strict bounds for all placed objects;
- use percentage-based placement with min/max size;
- test small phone and tablet layouts;
- avoid huge emoji/text fallback without constraints.

### Parent Dashboard

Risks:

- large screen with many provider reads;
- summaries and charts may rebuild unnecessarily;
- future cloud data may arrive async and trigger jank.

Improvements:

- split into panels;
- use `select()` for each panel;
- lazy-load deeper analytics;
- keep child-facing app startup independent of parent dashboard heavy work.

## Optimization plan

### Phase 1: Stabilize the core child loop

Goal: make the most repeated experience feel consistent and polished.

Tasks:

- Build `SuccessBeat`.
- Build `RetryBeat`.
- Make every learning engine use the same success/retry timing.
- [x] Make every mini game use the same result pipeline. The controller now
  centralizes score, wallet, pet/world, badge, daily-goal, trail, and story
  completion reporting.
- Ensure every correct answer has:
  - visible selected/correct state;
  - SFX/haptic;
  - spoken praise if voice is enabled;
  - at least 1200–1500ms before advancing;
  - no double-tap duplicate completion.
- Ensure every mini-game win has:
  - clear "you did it" moment;
  - coins/XP/pet progress;
  - obvious next action.

Acceptance criteria:

- A child can see what they did right before the app moves on.
- No screen feels like it jumps instantly after success.
- Tests cover success timing for every engine.

### Phase 2: Split big games into rules/controller/view

Goal: reduce bug risk and make game behavior testable.

Refactor order:

1. Chicken Tap
2. Infinity Loop
3. Stack Merge
4. 2048 / Animal Family
5. Art Studio

For each game:

- extract pure rules;
- extract state object;
- extract controller/state machine;
- leave screen as presentation only;
- add rule tests;
- add compact layout tests.

Acceptance criteria:

- Game rule tests run without widget pumping.
- Game screen contains mostly build/rendering code.
- Timer cleanup and navigation cleanup are tested.

### Phase 3: Profile and optimize hot paths

Goal: improve real performance based on evidence.

Commands:

```bash
flutter run --profile
```

Manual test scenarios:

- open app cold;
- switch profiles;
- play Chicken Tap for 2 minutes;
- play Stack Merge until many blocks exist;
- solve Infinity Loop multiple levels;
- open Kid World with many room items;
- draw/save/delete in Art Studio repeatedly;
- toggle dark mode/reduced motion;
- use large text;
- background/foreground app.

Record:

- average frame time;
- worst frame spikes;
- memory before/after;
- UI thread hot spots;
- raster thread hot spots;
- image cache size;
- rebuild counts.

Acceptance criteria:

- Child-facing gameplay stays near 60fps on target devices.
- No memory growth after repeated game sessions.
- No visible jank on reward/celebration transitions.

### Phase 4: Improve local persistence

Goal: make data safer, faster, and easier to migrate.

Tasks:

- design local data schema;
- keep SharedPreferences only for tiny settings/flags;
- move profiles/progress/achievements/drawings to structured storage;
- write migration from existing SharedPreferences keys;
- add corrupt-data tests;
- add backup/restore tests.

Acceptance criteria:

- corrupt local data cannot block startup;
- child progress survives migration;
- large drawing data is not stored as giant preferences JSON.

### Phase 5: Dependency upgrade pass

Goal: avoid falling behind before release.

Observed categories needing planned upgrades:

- Firebase packages;
- Riverpod packages;
- GoRouter;
- Google Sign-In;
- Sign in with Apple;
- audio packages;
- animation/UI packages.

Upgrade strategy:

```text
one dependency group → analyze → test → build web → build iOS simulator → manual smoke
```

Do not bulk-upgrade everything in one commit.

Recommended batches:

1. GoRouter and navigation tests.
2. Riverpod and generated/provider code.
3. Audio packages.
4. Firebase/auth packages.
5. Animation/UI packages.

Acceptance criteria:

- all tests pass after each batch;
- no auth/navigation regression;
- no new platform warnings that block store builds.

## Concrete implementation recommendations

### Add a shared success beat

Target API:

```dart
class SuccessBeat {
  const SuccessBeat({
    this.duration = const Duration(milliseconds: 1400),
  });

  Future<void> play({
    required VoidCallback showCorrect,
    required FutureOr<void> Function() advance,
    String? praise,
  });
}
```

Every question engine should follow the same sequence:

```text
lock input
show correct visual state
play correct SFX/haptic
show celebration overlay
speak short praise
wait success beat
advance or complete
unlock only if still on screen
```

### Add a shared responsive game scaffold

Target behavior:

- respects safe area;
- gives consistent header/title;
- handles compact phones;
- supports large text;
- scrolls only when needed;
- keeps primary controls reachable;
- provides optional pause/help buttons;
- wraps game content in constraints.

Target API:

```dart
ResponsiveGameScaffold(
  title: 'Egg Rescue',
  instruction: 'Catch chickens. Avoid bombs.',
  header: ...,
  body: ...,
  controls: ...,
)
```

### Add a mini-game result pipeline

Current risk: games can accidentally record rewards differently.

Target:

```dart
await ref.read(miniGameResultPipelineProvider).complete(
  gameId: 'chicken_tap',
  score: score,
  duration: elapsed,
  difficulty: difficultySnapshot,
);
```

Pipeline responsibilities:

- high score;
- play count;
- daily challenge;
- coins;
- XP;
- pet growth;
- achievements;
- parent/activity log;
- result event for analytics if enabled.

### Add an audio queue

Target:

```dart
audio.sayInstruction('Tap the matching animal');
audio.sayPraise('Great job!');
audio.playTap();
audio.playCorrect();
audio.stopScreenVoice(ownerId);
```

Rules:

- one owner per screen/game;
- no duplicate same line within a short interval;
- screen disposal stops owned voice;
- noncritical voice can be skipped if another line is playing.

### Make game loops fine-grained

Avoid full-screen `setState()` on every tick when only targets move.

Prefer:

- `AnimatedBuilder` around the arena only;
- `RepaintBoundary` around frequently painted game area;
- immutable state snapshots;
- separate widgets for score/header/controls;
- no persistence writes inside high-frequency loops.

## Testing plan additions

The app already has useful unit/widget coverage. Add these categories:

### Layout matrix tests

For every major child-facing screen:

- 320x640;
- 375x812;
- 390x844;
- tablet portrait;
- landscape;
- text scale 1.3;
- dark mode;
- reduced motion.

Pass condition:

- no overflow;
- primary action visible;
- text readable;
- no clipped mascot/pet/object.

### Game lifecycle tests

For every game:

- start game;
- interact rapidly;
- pause/restart;
- navigate away mid-animation;
- navigate away while TTS is speaking;
- complete game twice quickly;
- dispose screen while timer is active.

Pass condition:

- no exceptions;
- no duplicate rewards;
- no timer after dispose;
- no speech continuing unexpectedly.

### Reward consistency tests

For every completion path:

- lesson success;
- mini-game win;
- daily reward;
- spin reward;
- collection reward;
- art-to-world reward.

Pass condition:

- wallet updates once;
- XP updates once;
- pet/world progress updates once;
- achievements evaluate once;
- UI shows reward clearly.

### Performance smoke tests

Flutter tests cannot replace DevTools profiling, but they can catch obvious
regressions:

- pump mini games at compact sizes;
- simulate rapid taps;
- ensure no layout exceptions;
- ensure no repeated completion after locked state.

## Metrics to track before release

Technical:

- cold startup time;
- first interactive frame;
- average frame time in each mini game;
- worst frame spikes during celebration;
- memory after 10 minutes of play;
- crash-free session rate;
- number of layout overflow exceptions in QA;
- test count and coverage of game rules.

Product:

- first session completion rate;
- percentage of children who finish first lesson;
- number of mini games played per session;
- pet/world return interactions;
- parent profile creation success rate;
- where children quit;
- which games are replayed;
- which screens cause parent help.

Kid experience:

- can a pre-reader understand first play with sound on?
- does every success feel rewarding?
- are controls reachable with one hand?
- does wrong answer feel safe, not punishing?
- does the app avoid overstimulation?
- does the child know what to do next?

## Priority roadmap

### Must do before serious production release

- Shared success/retry beat.
- Shared result pipeline.
- Game lifecycle cleanup tests.
- Small-phone/dark-mode/large-text layout matrix.
- Audio queue/debounce.
- Physical-device QA on low-end Android and iPhone.
- Controlled dependency upgrade plan.
- Structured local persistence plan.

### Should do soon

- Split Chicken Tap into rules/controller/view.
- Split 2048 rules from UI.
- Split Stack Merge rules from UI.
- Split Infinity Loop puzzle logic from UI.
- Add DevTools profiling report.
- Add golden/screenshot tests for important screens.
- Add route/navigation regression tests.

### Nice but powerful

- In-app QA/debug panel for:
  - current child ID;
  - wallet;
  - pet XP;
  - active game state;
  - reduced motion;
  - force reward;
  - reset tutorial flags.
- Performance overlay shortcut in debug builds.
- Local analytics event log visible to developer.
- A/B test hooks for tutorial timing and success duration.

## Anti-patterns to avoid

Avoid:

- adding another big feature before stabilizing the core loop;
- copying celebration/reward logic into each game;
- storing more large JSON blobs in SharedPreferences;
- calling TTS on every tiny tap;
- using full-screen `setState()` for high-frequency game loops;
- bulk-upgrading dependencies without intermediate tests;
- relying only on analyzer as proof of quality;
- fixing one screen size while breaking another;
- making kids choose difficulty manually;
- hiding important feedback behind fast navigation.

Prefer:

- one shared system per repeated behavior;
- pure game rules with unit tests;
- profiling before optimization;
- compact reusable UI scaffolds;
- child-friendly no-loss flows;
- consistent reward/XP/pet updates;
- physical-device testing.

## Definition of "production ready" for this app

KidVerse should be considered production ready only when:

- core child loop is consistent and delightful;
- every game has no-crash lifecycle behavior;
- every success has a visible beat before advancing;
- every reward goes through one result pipeline;
- no major screen overflows on compact phones or large text;
- audio does not overlap or continue after leaving screens;
- local data survives corruption/migration cases;
- app is profiled on real devices;
- dependency upgrades are planned and tested;
- release builds pass web/iOS/Android smoke checks;
- parent/privacy/legal/store requirements are completed.

## The blunt takeaway

The app does not need less imagination. It needs stronger rails under the
imagination.

Right now, the product is full of good ideas. The next level is to stop making
each idea a one-off implementation and instead build the reusable systems that
make every idea feel stable, fast, and consistent.

The highest-impact next move is:

```text
SuccessBeat + ResultPipeline + ResponsiveGameScaffold
```

Those three systems will remove a large class of bugs and make future features
faster to build without breaking the kid experience.
