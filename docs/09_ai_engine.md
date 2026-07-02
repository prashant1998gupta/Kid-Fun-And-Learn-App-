# 09 — AI Learning Engine

> Implemented: `lib/features/ai/adaptive_engine.dart` (`SkillModel` +
> `AdaptiveController`), wired into the game host so every result updates it.

## Design principles
- **On-device first & privacy-preserving.** The adaptive model runs locally,
  needs no network, and stores only anonymous skill numbers. This is both a
  COPPA/GDPR-K win and an offline-reliability win.
- **Explainable, not black-box.** Parents/teachers see *why* ("weak in Math") —
  we use transparent, auditable heuristics, not opaque predictions on children.

## What it does (mapped to the brief)
| Feature | Mechanism |
|---|---|
| **Adaptive learning / difficulty adjustment** | Per-(child,subject) skill EMA (α=0.35) of first-try mastery → `difficultyDelta` returns −1/0/+1 to pick an easier/same/harder lesson bank on top of the grade tier |
| **Weak-area detection** | `weakAreas()` = subjects with skill < 0.55, weakest first → surfaced in Parent Dashboard & "Recommended practice" |
| **Strength detection** | `strengths()` = skill ≥ 0.75 |
| **Personalized practice / recommendation** | Home suggests next lesson biased toward weak areas at a comfortable difficulty |
| **Smart revision** | `struggles` tally per question; `revisionQuestionIds()` resurfaces items missed ≥2× (spaced) |
| **Progress prediction** | EMA trend + level curve project time-to-mastery (Parent report, P2) |
| **Speech recognition / pronunciation / reading practice** | `speech_to_text` (dep included) → phoneme/word-match scoring in the reading engine (P3); TTS models correct pronunciation via `AudioService.speak` |

## Model math (simple, robust)
```
skillₜ = skillₜ₋₁·(1−α) + mastery·α          # per subject, α = 0.35
mastery = firstTryCorrect / total            # rewards knowing it, not guessing
difficultyDelta = +1 if skill ≥ 0.85
                  −1 if skill < 0.40
                   0 otherwise
weakAreas = { subject : skill < 0.55 } sorted asc
```
Chosen EMA because it's stable, needs no history storage, adapts within a few
sessions, and is trivially explainable.

## Server-side evolution (P3, optional)
Anonymous aggregate skill/struggle signals can sync to Firestore to power a
cohort-level recommendation model and content difficulty calibration. The
on-device model remains the real-time driver; the server only refines defaults
via Remote Config. No individual child profiling leaves the device beyond
aggregate, non-identifying stats.
