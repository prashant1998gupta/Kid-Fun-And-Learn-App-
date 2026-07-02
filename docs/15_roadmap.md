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

## How to extend (contributor quickstart)
- **New game:** create `features/games/engines/<name>_game.dart` taking
  `Lesson` + `onComplete(LessonResult)`; add a `GameType` + host case; author a
  lesson JSON. Rewards/celebration/adaptive tracking come free.
- **New lesson:** add to the grade JSON; no code.
- **New theme/world:** add a gradient + `WorldTheme` entry.
- **New screen:** add a route in `app/router.dart` with a transition.
