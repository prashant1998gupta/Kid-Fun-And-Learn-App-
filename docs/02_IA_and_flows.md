# 02 — Information Architecture & User Flows

## Navigation map
```
Splash
 └─ Onboarding (3 pages, voice) ── Skip ─┐
 └─ (returning) Profile Picker           │
                                         ▼
                              Create Child (name → grade → avatar)
                                         │
                                         ▼
        ┌──────────────── Home Dashboard ────────────────┐
        │  HUD (coins/gems/level/streak) · Mascot         │
        │  Daily Mission · Subject Learning Map           │
        └───┬───────────┬───────────┬───────────┬─────────┘
            ▼           ▼           ▼           ▼
      Subject →     Game Center  Achievements  Settings
      Unit →                      /Rewards
      Lesson →
      GAME (engine) → Result (stars, rewards, level-up) → Home / Replay

  Parent Gate (math challenge)
      └─ Parent Dashboard ─ progress · mastery · weak areas · controls
           └─ (P3) Teacher Dashboard / Admin Panel (web)
```

## Primary user flows

### F1 — First run (parent-assisted)
Splash → Onboarding → Create Child → Home. First lesson auto-suggested from
grade. ≤ 60s to first game.

### F2 — Returning child
Splash → Profile Picker ("Who's playing?") → tap avatar → Home → resume daily
mission.

### F3 — Play a lesson (the core loop)
Home → subject card → lesson → engine plays questions (voice prompt, tap answer,
wrong = wiggle+retry, right = celebrate) → Result reveal → rewards applied →
Home. Adaptive model updated silently.

### F4 — Play the daily Mini Game Adventure Trail

Home → Mini Games → grade-safe story world → choose Brave, Kind, or Curious →
play chapter 1/2/3 learning games → receive a relic stamp after each result →
hear the path-specific finale → open the one-time mystery chest → companion
remembers the ending and Kid World receives the earned progress. The chosen
path and chapter stamps persist per child for the calendar day.

Children can also use Learning/grade/Just Fun filters, Play Next, or Surprise
Me. Discovery and daily challenges only select age-eligible games.

### F4 — Parent checks progress
Home → Parents button → Parent Gate (solve `a×b`) → Dashboard → per-subject
mastery, weak areas, strengths, controls.

### F5 — Adjust experience
Home → Settings → toggle SFX/music/voice/haptics, theme (light/dark/system),
color-blind mode, large text. Persists offline.

## Screen inventory (status)
| Screen | Status |
|---|---|
| Splash, Onboarding | ✅ implemented |
| Profile Picker, Create Child, Avatar builder | ✅ |
| Home Dashboard, Subject Map, Daily Mission | ✅ |
| Game host + Tap-Choice engine + Result | ✅ |
| Parent Gate, Parent Dashboard | ✅ |
| Settings | ✅ |
| Learning Map (world path), Game Center, Achievements, Rewards, Leaderboard, Certificates, Reports | 🔜 specced (P1–P3) |
| Teacher Dashboard, Admin Panel | 🔜 specced (P3, web) |
