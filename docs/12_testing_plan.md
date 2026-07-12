# 12 — Testing & Quality Plan

> **Current verified baseline:** `flutter analyze` is clean and all **135 tests**
> pass. Release web and Android debug builds also complete. Physical-device
> visual/accessibility sign-off remains a manual release gate.

## Layers
| Layer | Tool | What |
|---|---|---|
| **Unit** | `flutter_test` | Pure domain: `Wallet` level curve, `RewardEngine`, `SkillModel` EMA/weak-areas, `GradeLevel`, parsers. (Started: `test/wallet_reward_test.dart`.) |
| **Widget** | `flutter_test` | `BouncyButton` fires callback/haptic; `TapChoiceGame` advances on correct, wiggles on wrong; result screen renders stars; parent gate rejects wrong answers. |
| **Golden** | `golden_toolkit` | Home, result, avatar renders across light/dark, phone/tablet, portrait/landscape. |
| **Integration** | `integration_test` | Full loop: onboarding → create child → play lesson → reward applied → parent dashboard reflects mastery. |
| **Manual/device lab** | Firebase Test Lab | Low-end Android tablet fps, offline mode, rotation, TTS availability. |

## Key test cases
- Reward: flawless → 3★ + gem; partial → ≥1★, 0 gems; coins scale by stars.
- Wallet: level thresholds exact at 100/300/600 XP; serialization round-trip.
- Adaptive: repeated low mastery → subject appears in `weakAreas`, `delta=-1`;
  high mastery → `strengths`, `delta=+1`; struggle count ≥2 → revision id.
- Offline: kill network → create child, play, earn rewards, reopen → persisted.
- Parent gate: wrong product blocks; correct opens dashboard; child can't brute
  force (answer > 1 digit, resets on error).
- A11y: large-text scaling doesn't overflow cards; color-blind palette applied;
  semantics labels present.
- Mini games: phone layout for the hub and all 29 routed games; score, level,
  pet, wallet, world-item, daily-goal, and badge persistence; no-loss rescue
  rules; grade-band discovery; age-eligible daily selection; all-game rotation;
  story-path persistence and next-day reset; one-time chest claims and exact
  15-coin/20-XP delivery; companion finale memory; and a 5,750-round generated
  content audit across the 25 learning adventures.

## Performance budget
- 60fps on a 2019-class Android tablet during confetti + background particles.
- Cold start < 2.5s to interactive (excluding splash dwell).
- Memory: no leaks across 20 lesson loops (dispose controllers — audited in
  every `State`).
- Battery: cap particle count; pause `AnimatedBackground` controllers when
  backgrounded (P1 lifecycle hook).

## CI (P1)
GitHub Actions: `flutter analyze` (zero warnings gate) → `flutter test`
(coverage ≥70% on domain) → build Android/iOS. Golden + integration on merge to
main.
