# 07 — Gamification: Rewards, XP, Coin Economy, Leaderboards

> Implemented: `lib/features/gamification/**` (Wallet, RewardBundle,
> RewardEngine, level curve) + result-reveal UI. Below documents the full
> economy and the systems layered on top (P1–P3).

## Currencies
| Currency | Earned by | Spent on | Feel |
|---|---|---|---|
| **Coins** (soft) | finishing lessons, dailies | avatar items, home decor, lucky spin | frequent, generous |
| **XP** | attempting + mastery | drives Level (status only, not spendable) | always-up |
| **Gems** (premium-feel, NOT purchasable by kids) | flawless first-try runs, milestones | rare cosmetics, pets | scarce, special |
| **Stars** (0–3/lesson) | performance score | mastery map, certificates | legible score |
| **Energy** | regenerates over time | gently paces marathon sessions | wellbeing guardrail |

## Level curve
`xpForLevel(n) = n·(n-1)/2 · 100` → levels need 100, 200, 300… XP (gentle,
always achievable). Implemented in `Wallet`. Level is **status, never a gate** —
kids can't be blocked from learning by a number.

## Reward engine (tuning in one file)
`RewardEngine.compute(LessonResult)`:
- Coins = `baseCoins × starMultiplier` (1.0/1.2/1.5 for 1/2/3 stars).
- XP = `baseXp × (0.5 + mastery)` → effort always pays; mastery pays more.
- Gems = 1 only on a flawless first-try run.
- Stars from **first-try mastery**: ≥90%→3, ≥60%→2, else 1. **Finishing always
  ≥1 star** (no-loss design).

## Systems layered on the economy (specs)
- **Daily/Weekly/Monthly rewards:** login calendar; streak multiplier on coins.
- **Learning streak:** `streakDays` in wallet; +bonus, streak-freeze item.
- **Badges/Achievements:** rule set (e.g. "10 math lessons", "3-day streak",
  "first 3-star") evaluated after each result; stored per child.
- **Collections:** stickers/pets unlocked by gems/milestones; album screen.
- **Home decoration & avatar unlocks:** coin shop; cosmetic only.
- **Lucky Spin / Mystery Gift:** daily free spin; weighted reward table in
  Remote Config (auditable, no dark patterns, no real-money gambling).
- **Adventure Map & Boss Battle:** themed lesson chains ending in a chest.
- **Season Pass:** free track only for kids (cosmetics), parent-gated premium.
- **Daily Challenge:** one curated lesson/day with bonus coins.

## Leaderboards (friends-only, safe)
- Opt-in, **parent-approved friends** only. No open/global boards for children.
- Entries are **server-written** via Cloud Functions; expose only display name +
  avatar seed + score (no PII, no location, no messaging).
- Weekly reset (`weekId`) to keep it fresh and low-stakes; celebrates effort
  bands, not just #1, to protect motivation.

## Ethical guardrails
No loss-aversion traps, no pay-to-win, no ads, no purchases exposed to children,
no infinite-scroll. Energy + screen-time caps encourage healthy breaks.
Celebrations reward **effort and improvement**, not just raw correctness.
