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

## How to extend (contributor quickstart)
- **New game:** create `features/games/engines/<name>_game.dart` taking
  `Lesson` + `onComplete(LessonResult)`; add a `GameType` + host case; author a
  lesson JSON. Rewards/celebration/adaptive tracking come free.
- **New lesson:** add to the grade JSON; no code.
- **New theme/world:** add a gradient + `WorldTheme` entry.
- **New screen:** add a route in `app/router.dart` with a transition.
