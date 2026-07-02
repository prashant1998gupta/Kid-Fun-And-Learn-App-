# 11 — Asset Lists: Sound, Image, Lottie + Illustration Prompts

## Sound assets (drop into `assets/audio/`)
Mapped in `lib/core/services/audio_service.dart`.

**SFX (`assets/audio/sfx/`)** — keep <400ms, normalized ~-14 LUFS:
`tap, correct, wrong, coin, level_up, star, unlock, reward, celebration, magic,
balloon_pop, puzzle_complete, whoosh`.

**Music (`assets/audio/music/`)** — seamless loops, calm, low-key:
`home_calm, forest, ocean, space, rain`.

**Recommended libraries (licensable/free):**
- **Kenney.nl** — "UI Audio", "Casual Game SFX", "Interface Sounds" (CC0).
- **Mixkit** Game SFX & music (free, check attribution).
- **Freesound.org** — filter CC0 for nature/ambience beds.
- **Pixabay Music** / **Uppbeat** — royalty-free calm loops.
- **ElevenLabs / Azure Neural TTS** — if pre-rendering mascot voice lines
  instead of on-device TTS (warmer, brand-consistent). Otherwise `flutter_tts`
  runs free on-device (already wired).

## Lottie animations (`assets/lottie/`)
Referenced by `Mascot` + celebration hooks. Needed:
`mascot_panda, mascot_lion, mascot_owl, mascot_robot, mascot_unicorn,
mascot_penguin` (each: idle-breathe, blink, talk, celebrate), plus
`confetti_burst, fireworks, level_up_badge, coin_spin, star_pop, chest_open,
lucky_wheel, loading_bounce`. Sources: **LottieFiles** (huge free kids library),
or author in **Rive** for interactive state machines.

## Image assets (`assets/images/`)
Currently the app runs with **emoji + painted placeholders** so no art blocks
development. Production illustration set (thousands) organized as:
`backgrounds/{space,jungle,ocean,candy,sunrise,night}`,
`avatars/{skin,hair,outfit,accessory,bg}` part-sprites,
`objects/{fruits,animals,vehicles,shapes,letters,numbers}`,
`ui/{buttons,badges,frames,stickers,pets,decor}`,
`rewards/{coin,gem,star,chest,certificate}`.

## Illustration prompt style guide (for generation/commission)
**Global style:** "flat design with soft 3D shading, thick rounded outlines,
pastel palette on saturated accents, big friendly eyes, no scary features,
centered, transparent background, children's storybook, high detail, cute."

Examples (append the global style to each):
- Mascot: *"a cute chubby panda teacher waving hello, round body, rosy cheeks,
  wearing tiny glasses"*.
- Object: *"a happy red apple with a smiling face and a green leaf"*.
- Background: *"a dreamy outer-space scene with rounded planets, friendly stars,
  soft nebula gradient in violet and blue"*.
- Reward: *"a shiny golden treasure chest bursting with coins and sparkles"*.
- Avatar part: *"a single cartoon hairstyle, curly brown hair, front view, flat
  color, no face"*.

**Diversity & inclusion:** full range of skin tones (5 in code), hair types,
abilities, and cultures represented across characters and scenarios.

## Icons
Base: **Material Symbols Rounded** (bundled with Flutter, consistent, free) at
large sizes. Custom animated hero icons (coin/star/chest/spin) shipped as Lottie
per the list above.
