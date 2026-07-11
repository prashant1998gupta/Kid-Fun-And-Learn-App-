# KidVerse 🌈

A world-class, gamified learning universe for children **LKG → Grade 5** (ages 3–11).
Built with **Flutter + Firebase**, offline-first, accessible, and delightful.

> **Status:** Release-candidate codebase with production hardening, automated
> quality gates, offline-safe runtime behavior, and store build workflows.
> Signing credentials, Firebase/App Check configuration, legal/store metadata,
> and final physical-device review remain operator-owned release gates. See
> [`docs/PRODUCTION_READINESS.md`](docs/PRODUCTION_READINESS.md).

---

## What's already built (runnable today)

A complete, playable loop with production architecture:

```
Splash → Onboarding → Create Child (name/grade/avatar) → Profile Picker
      → Home Dashboard (HUD, mascot, daily mission, subject map)
      → Tap-Choice Game (voice prompt, wrong-answer retry, celebration)
      → Reward Reveal (stars, coins/XP/gems count-up, level-up)
      → Parent Gate (COPPA math challenge) → Parent Dashboard (mastery, weak areas)
      → Settings (audio/voice/haptics, theme, accessibility)
```

Every layer the rest of the app reuses is in place: design system, animated
core widgets, state management, offline persistence, adaptive-learning engine,
reward economy, curriculum data pipeline, routing, and security rules.

### Kid World mini games

The Mini Games hub is now a connected learning storybook with **29 games**:

- **4 playful breaks:** Flower Flow, Egg Rescue, Rainbow Rescue, and Animal
  Family.
- **25 learning adventures / 1,250 persistent levels:** preschool through
  Class 5 literacy, maths, science, practical life, media literacy, finance,
  geography, sustainability, and computational thinking.
- **Daily Adventure Trail:** a grade-safe three-chapter journey selected from
  eight original story worlds. Children choose a Brave, Kind, or Curious path,
  collect named relics, hear narrated chapter transitions, and open a one-time
  mystery chest at the finale.
- **A living Kid World:** rewards feed the pet, unlock room/world objects, add
  companion memories, and award Trail Blazer or Story Hero badges.

Games use voice guidance, no-loss rescue behavior, haptics/SFX/celebrations,
accessible controls, grade-aware discovery filters, Play Next, and Surprise Me.
See
[`docs/16_mini_games.md`](docs/16_mini_games.md) for the complete specification.
The connected companion, room rewards, story missions, physical co-play, and
child-created hero loop are documented in
[`docs/17_living_kidverse.md`](docs/17_living_kidverse.md).
The current performance, optimization, and quality-improvement audit is in
[`docs/18_PERFORMANCE_AND_QUALITY_AUDIT.md`](docs/18_PERFORMANCE_AND_QUALITY_AUDIT.md).

### Run it

```bash
flutter pub get
flutter run          # any connected device / simulator / Chrome
flutter test         # full unit + widget suite (112 tests at last verification)
flutter analyze      # lints
```

> Firebase is **optional** to run — the app is fully functional offline. To
> enable cloud sync/auth/FCM, run `flutterfire configure` and drop in the
> generated `firebase_options.dart` (git-ignored).

---

## Architecture at a glance

**Feature-first Clean-ish architecture.** Each feature owns its `domain/`
(pure models), `data/` (repositories), and presentation (screens/widgets).
Cross-cutting primitives live in `core/`.

```
lib/
├── main.dart                 # bootstrap: prefs, audio, ProviderScope
├── app/
│   ├── kidverse_app.dart     # MaterialApp.router, theme, text-scaling
│   └── router.dart           # go_router table + kid-friendly transitions
├── core/
│   ├── theme/                # colors, typography, spacing, light/dark themes
│   ├── services/             # AudioService (SFX + music + TTS + haptics)
│   └── widgets/              # BouncyButton, MascotView, AnimatedBackground,
│                             #   CelebrationScope, CurrencyChip, ProgressBar
└── features/
    ├── onboarding/           # splash + onboarding carousel
    ├── profiles/             # multi-child, avatar builder, picker, persistence
    ├── curriculum/           # Subject/Unit/Lesson/Question models + JSON repo
    ├── games/                # game host + engines (tapChoice) + result screen
    ├── gamification/         # Wallet, RewardBundle, RewardEngine, level curve
    ├── ai/                   # SkillModel adaptive engine (weak-area detection)
    ├── parent/               # parent gate + dashboard
    └── settings/             # persisted settings + screen
```

**State management:** Riverpod (`StateNotifier` + `Provider`).
**Routing:** go_router with fade/slide page transitions.
**Persistence:** SharedPreferences (offline source of truth) → mirrors to
Firestore in production.
**Content:** JSON-authored curriculum (`assets/data/*.json`) parsed into typed
domain models — non-engineers can author lessons; can move to Firestore with
zero caller changes.

### Why these choices
- **Data-driven games.** A `Lesson` declares a `GameType`; the `GameHostScreen`
  maps it to an engine. **Adding a game = add one engine widget + one case.**
  The reward, XP, celebration, and adaptive-tracking flow are shared by all.
- **Offline-first.** Kids use tablets on planes and in cars. Local store is
  authoritative; the network is an enhancement, never a dependency.
- **No-punishment design.** Wrong answers wiggle and invite a retry; finishing
  always yields ≥1 star. Rooted in early-childhood motivation research.

---

## The 50 Deliverables — index

| # | Deliverable | Where |
|---|---|---|
| 1 | Product Requirements (PRD) | [docs/01_PRD.md](docs/01_PRD.md) |
| 2 | Information Architecture | [docs/02_IA_and_flows.md](docs/02_IA_and_flows.md) |
| 3 | User Flows | [docs/02_IA_and_flows.md](docs/02_IA_and_flows.md) |
| 4 | UX Research | [docs/03_ux_research.md](docs/03_ux_research.md) |
| 5–6 | Wireframes & Hi-Fi UI | Implemented as live screens (`lib/features/**`) |
| 7–13 | Design System, Colors, Type, Icons, Illustration prompts, Mascots, Animation guide | [docs/04_design_system.md](docs/04_design_system.md) + `lib/core/theme/**` |
| 14–19 | Flutter structure, Firebase arch, Firestore, API, state mgmt, folders | [docs/05_backend_architecture.md](docs/05_backend_architecture.md) |
| 20–22 | Every screen / widget / navigation | `lib/features/**`, `lib/app/router.dart` |
| 23 | Game logic (100+ game catalog + engine spec) | [docs/06_games_catalog.md](docs/06_games_catalog.md) |
| 24–27 | Rewards, XP, coin economy, leaderboards | `lib/features/gamification/**` + [docs/07_gamification.md](docs/07_gamification.md) |
| 28–30 | Parent / Teacher / Admin dashboards | `lib/features/parent/**` + [docs/08_dashboards.md](docs/08_dashboards.md) |
| 31 | AI Learning Engine | `lib/features/ai/adaptive_engine.dart` + [docs/09_ai_engine.md](docs/09_ai_engine.md) |
| 32–33 | Database schema + Security rules | [docs/05_backend_architecture.md](docs/05_backend_architecture.md) + `firebase/*.rules` |
| 34 | Localization | [docs/10_localization.md](docs/10_localization.md) |
| 35 | Dark theme | `lib/core/theme/app_theme.dart` (implemented) |
| 36–38 | Sound / Image / Lottie asset lists | [docs/11_asset_lists.md](docs/11_asset_lists.md) |
| 39 | Testing plan | [docs/12_testing_plan.md](docs/12_testing_plan.md) |
| 40–42 | Deployment + Play/App Store checklists | [docs/13_deployment.md](docs/13_deployment.md) |
| 43–47 | Marketing, screenshots, logo, splash, onboarding | [docs/14_brand_and_marketing.md](docs/14_brand_and_marketing.md) |
| 48–50 | Source code + build roadmap | this repo + [docs/15_roadmap.md](docs/15_roadmap.md) |

---

## Honest scope note

A fully-finished version of everything in the brief (100+ bespoke games, 8 full
grade curriculums, thousands of illustrations, 4 role dashboards, live infra) is
a multi-person, multi-quarter studio effort. This repository delivers the
**engineered foundation and a complete, correct vertical slice** so that each
remaining module is a well-defined, incremental addition on proven rails —
plus complete specifications for everything not yet coded. The roadmap in
[docs/15_roadmap.md](docs/15_roadmap.md) sequences the rest.
