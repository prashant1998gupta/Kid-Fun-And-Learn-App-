# 10 — Localization & Accessibility

## Localization
- `flutter_localizations` + `intl` included. Structure: ARB files under
  `lib/l10n/` (`app_en.arb`, `app_es.arb`, `app_hi.arb`, …), `gen-l10n` output.
- Settings expose `locale`; `SettingsController.locale` persists it.
- **Voice** localizes too: `AudioService.speak` sets TTS language per locale;
  or pre-rendered mascot lines per language in `assets/audio/voice/{locale}/`.
- Content JSON carries a `locale` field per lesson (or parallel files
  `curriculum_lkg_es.json`) so curriculum, not just chrome, translates.
- Launch targets: English first; then Spanish, Hindi, Arabic (RTL — layouts use
  directional widgets so mirroring is automatic), French, Portuguese.

## Accessibility (implemented + planned)
Implemented:
- **Large text** setting → clamped `MediaQuery` text scaling in `KidVerseApp`.
- **Color-blind mode** setting + Wong-safe palette in `AppColors`.
- **Voice guidance** everywhere; taps re-play prompts.
- **Semantics** on buttons/HUD (`BouncyButton` wraps `Semantics(button:true)`,
  `CurrencyChip` labels values) → screen-reader friendly.
- **Huge touch targets** (64dp) and one-hand-friendly bottom-anchored CTAs.

Planned (P1–P2):
- Subtitles/captions for all spoken lines (toggle).
- Reduced-motion mode (respect OS setting) that dampens particles/animations.
- Dyslexia-friendly font option.
- Full TalkBack/VoiceOver pass with focus order review.
- Switch-access / larger-hit-slop mode for motor accessibility.
