# 15 — Build Roadmap (module-by-module)

The foundation + one complete vertical slice is done. Each item below is an
incremental addition on the existing rails (design system, game engine host,
reward/adaptive flow, repositories). Nothing here requires re-architecting.

## ✅ P0 — Foundation (this repo)
Design system, core animated widgets, Riverpod state, offline persistence,
models (profile/wallet/curriculum), adaptive engine, reward engine, router,
splash/onboarding, multi-child profiles + avatar builder, home dashboard, one
full game engine (Tap-Choice) + result/celebration, parent gate + dashboard,
settings, Firestore/Storage security rules, unit tests, full docs.

## P1 — Depth on the core loop
1. **Game engines:** MemoryMatch, DragDrop, Tracing, Sequence, Bubble/Catch.
   (Each: 1 widget under `features/games/engines/` + 1 case in
   `game_host_screen.dart`.)
2. **Curriculum:** complete LKG + UKG across all subjects (author JSON like
   `curriculum_lkg.json`); add `curriculum_ukg.json`.
3. **Learning Map:** node-path world screen stringing lessons (AdventureMap).
4. **Firebase live:** auth (Google/Apple/Phone/Email), `SyncService`
   local↔Firestore, FCM streak reminders.
5. **Achievements + daily reward calendar + lucky spin.**

## P2 — Breadth & retention
1. Grades 1–3 curriculum (Math/English/EVS/Science/Logic/Art).
2. Collections (stickers/pets), home decoration, coin shop.
3. Friends leaderboard (Cloud Functions writer) + certificates.
4. Parent: performance graphs over time, goals, homework, reward approval.
5. Real illustration + Lottie asset integration (replace placeholders).

## P3 — Scale & roles
1. Grades 4–5 curriculum; boss battles; season pass (cosmetic).
2. **Speech recognition** reading/pronunciation engine (`speech_to_text`).
3. **Teacher Dashboard** (web) + **Admin Panel** (web) on scaffolded rules.
4. Server recommendation refinement via Remote Config.
5. Localization rollout (ES/HI/AR-RTL/FR/PT).

## P4 — Polish & live-ops
Reduced-motion + full a11y pass, golden/integration test suite, CI gates,
A/B on reward pacing, seasonal/festival themes & events, performance hardening
for low-end tablets.

## Completed milestones

- [x] **M11:** Guarded speech service, pronunciation game/scoring, Android
  microphone permission, host integration, and Grade 1 pronunciation lesson.
- [x] **M12:** Lottie wrapper with emoji fallback, repository-owned loading,
  mascot, and celebration animations wired into shared UI.
- [x] **M13:** Generated localization for English, Spanish, Hindi, and Arabic;
  persisted language picker, localized home/settings subset, and RTL support.
- [x] **M14:** Grade 4–5 multi-subject curriculum, dedicated boss-battle
  engine/lessons, and an offline cosmetic season pass with sync coverage.
- [x] **M15:** Reliable answer-to-result transition, 50-level Grade 4–5
  journeys, 20-question lesson sessions, and a 50-tier season track.
- [x] **M16:** Voice-first LKG/UKG/KG sessions, dedicated large-target
  Listen & Tap play, and a complete KG phonics/math/logic/world curriculum.
- [x] **M17:** Full preschool package with 50 levels per LKG/UKG/KG band,
  20-question sessions, and grade-aware generated practice banks.
- [x] **M18:** Mole Match educational mini-game with moving targets, combos,
  safe timer lifecycle, and LKG/UKG/KG curriculum integration.
- [x] **M19:** Anti-repeat generated-level question banks, unique generated
  question IDs for progress tracking, and dark-mode contrast fixes for
  fixed-white game prompt cards.
- [x] **M20:** Every round now has a concrete reward moment, core preschool
  cards use code-drawn illustrated objects instead of emoji-only placeholders,
  mascots have playful retry/rescue/reward voice reactions, and Feed-the-Pet is
  playable across LKG/UKG/KG.
- [x] **M21:** Mini Games engagement pass with three difficulty modes, daily
  challenges, seven local badges, tutorials, mascot feedback, richer Chicken
  targets, generated Infinity boards, Stack Merge chains, and expanded 2048.
- [x] **M22:** Mini Games juice pass: Rainbow Rescue pieces are clipped inside
  the board with drop-preview shadow, landing bounce, and merge burst; Flower
  Flow has bloom pulses; Animal Family has board squish/shake and new-friend
  pop feedback.
- [x] **M23:** Living KidVerse pass: persistent interactive child world, one
  cross-mode companion, real placeable lesson prizes, story-framed missions,
  age-aware home navigation, child-drawn story heroes, physical co-play, and
  continue-adventure result flow.
- [x] **M24:** Learning Mini Games pass: Toy Sort and Feed the Pet each provide
  50 persistent, voice-guided, no-fail levels; children practise color, shape,
  size, category, habitat, food recognition, and counting to 10. Teach-Pip
  rounds let the child correct the mascot, every completed level unlocks a
  tangible item, and earned objects appear in both the mini-game hub and the
  shared Kid World scene.
- [x] **M25:** Preschool Learning Adventures pass: Sound Safari, Number Garden,
  Story Train, Letter Bakery, and Clean Room Helper add 250 persistent levels
  for listening, animal sounds, counting, early addition, event sequencing,
  prediction, phonics, letter matching, and practical-life sorting. All five
  use the shared no-fail voice-guided engine, Teach-Pip confidence rounds,
  daily challenges, badges, and distinct Kid World reward paths.
- [x] **M26:** Classes 1–2 Learning Adventures pass: Math Market, Word Wizard
  Workshop, Sentence Train, Clock Adventure, Nature Detective, and Shape
  Builder add 300 persistent levels for coin arithmetic and change, spelling,
  grammar and punctuation, hour/half-hour clocks and routines, nature clues and
  habitats, plus 2D-shape properties and patterns. Catalog cards carry a clear
  Class 1–2 label and every game has voice, Teach-Pip, badges, daily goals, and
  its own first Kid World reward.
- [x] **M27:** Classes 3–4 Learning Adventures pass: Pizza Fraction Café,
  Multiplication Kingdom, Grammar Detective, Code the Robot, Science Machine
  Lab, and Map Quest add 300 persistent levels for fractions, multiplication
  and division, grammar analysis, algorithms and debugging, scientific
  reasoning, compass directions, coordinates, and distance. Every generated
  round is audited and every game carries the Class 3–4 catalog label, voice,
  Teach-Pip, daily goal, badge, and distinct world reward.
- [x] **M28:** Class 5 Learning Adventures pass: Eco City Builder, Space
  Mission Control, Business Bazaar, Mystery Science Lab, News Detective, and
  Algorithm Quest add 300 persistent levels for sustainability, applied maths,
  financial literacy, experimental design, media literacy, and computational
  thinking. Every game has voice, Teach-Pip, five-round daily goals, a Class 5
  catalog label, its own badge, and a distinct first Kid World reward.
- [x] **M29:** Out-of-the-box Mini Game World pass: all 29 games participate in
  a rotating three-stop Adventure Trail with persistent stamps, a one-time
  daily mystery chest, bonus wallet rewards, and a Trail Blazer badge. The hub
  adds age-appropriate trail selection, grade-aware discovery filters, and
  smart Play Next and Surprise Me actions, turning the catalog into a guided
  daily journey instead of a wall of unrelated game cards.
- [x] **M30:** Interactive Storybook pass: Adventure Trails rotate through
  eight original story worlds with an opening mystery, three named relic
  chapters, and a narrated finale. Children choose a Brave, Kind, or Curious
  path that changes the mission language and ending; the choice persists per
  child, feeds the companion's memory, and unlocks the Story Hero badge when
  any three-game story is completed.
- [x] **M31:** Documentation synchronization pass: README, PRD, information
  architecture, game catalog, gamification, testing, living-world, performance
  audit, and mini-game architecture now describe the implemented 29-game,
  1,250-level interactive storybook system and the 135-test verification state.

## Quality rules for Codex follow-up work

- **No cloned level banks:** any generated `*_level_*` lesson must create or
  rotate a fresh question bank. Do not copy `seed.questions` directly into a
  generated level.
- **Unique question IDs:** generated sessions must keep per-question IDs unique
  inside the lesson so struggle tracking and smart revision stay accurate.
- **Dark-mode foreground rule:** if a widget uses a fixed light surface such as
  `Colors.white`, its text must explicitly use a dark foreground such as
  `AppColors.lightText`. If it uses a theme surface, use
  `colorScheme.onSurface`.

## Next Codex quality queue

- [ ] Add light/dark widget or golden coverage for Home, Settings, Learning Map,
  and every game prompt card.
- [ ] Add a duplicate-content audit that checks adjacent generated levels do not
  show the same first 5 prompts in the same order.
- [ ] Expand authored preschool content pools for animals, sounds, shapes,
  safety, rhymes, and early maths so generated levels feel less formulaic.
- [x] Persist reward-moment prizes into room decoration, sticker, and pet-food
  outcomes instead of showing them only as a round-end reveal.
- [ ] Replace code-drawn fallback objects with commissioned PNG/SVG/Lottie art
  for the production illustration set.

## How to extend (contributor quickstart)
- **New game:** create `features/games/engines/<name>_game.dart` taking
  `Lesson` + `onComplete(LessonResult)`; add a `GameType` + host case; author a
  lesson JSON. Rewards/celebration/adaptive tracking come free.
- **New lesson:** add to the grade JSON; no code.
- **New theme/world:** add a gradient + `WorldTheme` entry.
- **New screen:** add a route in `app/router.dart` with a transition.
