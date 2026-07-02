# 03 — UX Research (foundations that shaped the design)

## Developmental constraints by age
| Age | Motor | Cognition | Design response |
|---|---|---|---|
| 3–5 (LKG–KG) | imprecise taps, whole-hand | pre-literate, short attention (~3–5 min) | ≥64dp targets, voice-first, no text dependency, 1 concept/screen, instant feedback |
| 6–7 (Gr 1–2) | improving pointer control | early reading, 5–10 min focus | short labeled buttons, simple instructions, strong reward loops |
| 8–11 (Gr 3–5) | fine control | multi-step reasoning, mastery & status motivation | multi-step problems, streaks, friend leaderboards, certificates |

## Evidence-based principles applied
1. **Voice-first / minimal reading** — pre-readers can't gate on text; every
   prompt is spoken (`AudioService.speak`) and re-playable by tapping.
2. **No-fail loops** — early-childhood motivation research shows punishment
   depresses engagement; wrong answers wiggle + "try again", finishing always
   earns ≥1 star.
3. **Immediate, multisensory feedback** — sound + haptic + animation on every
   tap; correctness within ~100ms.
4. **Short sessions & healthy pacing** — energy meter + screen-time caps; daily
   mission is 3 short games, not an endless feed.
5. **Big, forgiving touch targets** — 64dp minimum for developing motor skills.
6. **Consistency & recognition over recall** — subjects carry fixed colors +
   icons + mascots so kids navigate by memory of look, not by reading.
7. **Agency & personalization** — avatar creation and cosmetic unlocks build
   ownership and return motivation.

## Competitive teardown (what we borrow / improve)
- **Khan Academy Kids:** warm mascots, no-fail, free — we match warmth, add
  deeper gamification & multi-child dashboards.
- **Duolingo ABC / Duolingo:** streaks, XP, bite-size — we adopt the loop,
  remove pressure mechanics unsuitable for under-6s.
- **Lingokids / ABCmouse:** breadth of curriculum & worlds — we mirror the
  world-themes, keep a cleaner, faster UI.
- **SplashLearn:** standards-aligned math — we align content and add richer
  cross-subject play.
Our wedge: **one delightful engine across all subjects & grades, offline-first,
transparent adaptive learning, and a genuinely useful parent dashboard.**

## Usability testing plan (P1)
Moderated sessions with 3–5 children per grade band; measure time-to-first-game,
taps-to-error, unaided task completion, and delight (smiles/verbal). Iterate
targets, voice clarity, and instruction length.
