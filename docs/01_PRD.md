# 01 — Product Requirements Document

## Vision
KidVerse is a playful learning universe where children aged 3–11 feel like they
are **playing a game, not studying**. Every tap animates, every success
celebrates, and learning happens naturally through joyful, bite-sized play.

## Target users
| Persona | Age | Needs |
|---|---|---|
| **Emerging learner** (LKG–KG) | 3–5 | Pre-reading, big touch targets, voice-first, no text dependency |
| **Early primary** (Gr 1–2) | 6–7 | Foundational literacy & numeracy, short sessions, strong rewards |
| **Confident learner** (Gr 3–5) | 8–11 | Multi-step problems, mastery, competition (friend leaderboards) |
| **Parent** | adult | Trust, safety (COPPA), visible progress, screen-time control |
| **Teacher** | adult | Class rosters, assignments, analytics |

## Goals & non-goals
**Goals:** engagement that serves learning; measurable mastery gains; delight;
accessibility; offline reliability; child safety by default.
**Non-goals (v1):** social chat between children, user-generated public content,
third-party ads, in-app purchases shown to children.

## Success metrics (North Star + guardrails)
- **North Star:** weekly *learning minutes that end in mastery* per child.
- Engagement: D1/D7/D30 retention, streak length, sessions/week.
- Learning: first-try mastery trend per subject; weak-area closure rate.
- Guardrails: session length caps respected; zero unsafe content; crash-free
  sessions > 99.5%; 60fps on target low-end tablet.

## Core requirements (condensed from brief)
1. 8 grade bands with auto-adjusted difficulty.
2. Multi-child parent accounts; per-child avatar, wallet, progress.
3. Auth: Google, Apple, Phone, Parent email — all behind a parent gate.
4. Offline support, dark mode, tablet + phone, portrait + landscape.
5. Gamification: coins, XP, levels, gems, stars, streaks, daily/weekly rewards,
   badges, unlockable themes/pets/decor, lucky spin, adventure map.
6. 100+ game types driven by a shared, data-configured engine.
7. AI: adaptive difficulty, weak-area detection, smart revision, speech
   practice.
8. Parent/Teacher/Admin dashboards.
9. Accessibility: color-blind mode, voice, subtitles, large text, one-hand use.
10. Compliance: COPPA + GDPR-K; secure parent gate; no ads to kids.

## Release phases
- **P0 (done):** foundation + one complete game loop + parent dashboard.
- **P1:** 6 core game engines, LKG+UKG full curriculum, Firebase auth+sync, FCM.
- **P2:** Grades 1–3 curriculum, leaderboards, badges/collections, lucky spin.
- **P3:** Grades 4–5, teacher & admin dashboards, speech recognition, season pass.
- **P4:** localization rollout, A/B on reward pacing, live-ops content.
