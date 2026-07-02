# 04 — Design System, Colors, Typography, Icons, Mascots, Animation

> Implemented in code under `lib/core/theme/**` and `lib/core/widgets/**`.
> This doc is the human-readable spec + the parts still to be produced (art).

## Color palette (child-psychology grounded)
Source of truth: `lib/core/theme/app_colors.dart`.

| Token | Hex | Role / rationale |
|---|---|---|
| Primary (violet) | `#6C5CE7` | Playful, imaginative; brand anchor |
| Secondary (coral) | `#FF7675` | Warm, friendly; CTAs & English subject |
| Accent (sunshine) | `#FFC048` | Reward/coin energy; joy |
| Mint | `#55EFC4` | Success/calm |
| Sky | `#74B9FF` | Trust/openness |
| Bubblegum | `#FD79A8` | Fun/creativity; art subject |
| Success/Warn/Error/Info | `#00B894` / `#FDCB6E` / `#E17055` / `#0984E3` | Semantic |

**Currencies:** coin `#FFC048`, XP `#6C5CE7`, gem `#00CEC9`, star `#FFD32A`,
energy `#FF6B6B`.

**Subject signatures** (kids navigate by color, not text): Math violet, English
coral, EVS green, Science blue, Art pink, Logic orange, Rhymes magenta.

**Surfaces:** light `#F6F7FF`/white; dark uses gentle navy `#191A2E` (never pure
black — softer for young eyes at night).

**World gradients:** Space, Jungle, Ocean, Candy, Sunrise, Night — drive the
`AnimatedBackground`.

**Accessibility:** color-blind-safe alternate set (Wong palette) toggled by the
color-blind setting; all text pairs meet WCAG AA / AA-large.

## Typography
Source: `lib/core/theme/app_typography.dart` (via `google_fonts`).
- **Baloo 2** — display/headlines. Rounded, chunky, joyful, legible large.
- **Nunito** — body/UI. Humanist, rounded, superb small-size legibility.
- Sizes are intentionally large (display 48/36, body 18/16). Minimal reading is
  a product goal; when text appears it must be effortless.

## Spacing & shape
Source: `lib/core/theme/app_spacing.dart`.
- 4-pt scale (4→64). **Minimum touch target 64dp** (kids' motor skills).
- Everything rounded: cards 28r, buttons pill, sheets 40r top.

## Icon system
- Material Symbols **Rounded** as the base (already friendly, consistent,
  free). Large sizes (26–56). Currency & subject icons standardized in code.
- Custom animated icon spec for hero moments (coin, star, chest, spin wheel):
  deliver as Lottie; list in `docs/11_asset_lists.md`.

## Mascots
Defined in `lib/core/widgets/mascot.dart`. Each has name, signature color, Lottie
path, and an emoji fallback (so the app runs before art ships).

| Mascot | Name | Personality | Teaches |
|---|---|---|---|
| 🐼 Panda | Pip | Gentle, encouraging | Home guide |
| 🦉 Owl | Professor Hoot | Wise, curious | Instructions/quiz |
| 🤖 Robot | Bolt | Energetic, techy | Logic/coding |
| 🦄 Unicorn | Luna | Magical, celebratory | Rewards/celebration |
| 🦁 Lion | Leo | Brave, cheerful | Challenges |
| 🐧 Penguin | Percy | Silly, friendly | Play breaks |

**Art direction (illustration brief):** flat-with-soft-3D hybrid, thick rounded
outlines, pastel-on-saturated, big expressive eyes, no sharp teeth/scary faces,
diverse & inclusive. Rig for idle-breathe, blink, talk (mouth), and a
jump-celebrate. Deliver as Rive/Lottie.

## Animation guidelines
Implemented primitives: `BouncyButton` (press squish + SFX + haptic),
`MascotView` (breathe/blink/bounce), `AnimatedBackground` (drifting particles),
`CelebrationScope` (confetti/fireworks), `CurrencyChip` (count-up),
`ProgressBarKid` (spring fill), page transitions (fade/slide).

Rules:
- **Every tap reacts** within 100ms (scale to 0.9, spring back).
- **Every correct answer celebrates** (green, scale-pop, confetti, praise voice).
- **Wrong is gentle** — wiggle, "try again", never a harsh buzzer or score loss.
- Motion respects reduced-motion / can be dialed down; nothing strobes.
- Target 60fps; prefer `Transform`/`CustomPainter` over heavy widget rebuilds.
