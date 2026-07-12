# Kid Experience System

## Goal

KidVerse should feel like one responsive world rather than a collection of
unrelated screens. The shared experience system adds delight, clarity and
sensory safety at the app root so lessons, mini-games, creative tools, the
preschool library and navigation receive the same behavior automatically.

The system follows four rules:

1. Every intentional touch receives immediate acknowledgement.
2. Success remains visible long enough to understand.
3. Voice is always clearer than background music.
4. Accessibility settings affect the whole app, not selected screens.

## Wonder Touch

`KidExperienceLayer` wraps the routed application. Each pointer-down creates a
small ring of differently shaped star particles at the exact local touch
position.

- The effect is visual-only; it never duplicates button sound or haptics.
- `IgnorePointer` ensures particles cannot block the game underneath.
- A maximum of six simultaneous bursts bounds paint and animation work during
  rapid-tap games.
- Each burst lasts 480 ms and removes itself.
- Reduced-motion disables the effect completely.
- No gesture trails, touch coordinates or interaction history are persisted.

This creates the distinctive feeling that the KidVerse world responds to the
child, including plain gesture surfaces that do not use Material ink effects.

## Layered sound

`AudioService` now separates sound into three responsibilities:

| Channel | Purpose | Behavior |
|---|---|---|
| UI | taps and whooshes | Lightweight volume; 45 ms repeat guard |
| Feedback | correct, reward, celebration and game effects | Can play without being cut off by the next UI tap |
| Music | ambient world soundtrack | Loops at a calm background level |

Previously every sound effect shared one player, so a rapid tap could cut off a
correct or reward sound. Separate UI and feedback players preserve the meaning
of success audio without creating an unbounded sound pool.

### Narration ducking

When text-to-speech begins, music automatically drops from 0.35 to 0.09 volume.
It returns to its normal level after the latest utterance finishes or narration
is stopped. A generation guard prevents an older, interrupted utterance from
raising the music while a newer instruction is still speaking.

TTS failure never blocks the visual interaction. English and Hindi language
switching from the preschool library continues to work.

## Success moment

`CelebrationOverlay` remains the single success surface used across learning
engines and major mini-games. It now provides:

- recognizable star-shaped confetti rather than color-only rectangles;
- a large central star medallion;
- a short **You did it!** label for readers, with the star as the pre-reader
  cue;
- the existing 1.6-second success beat before question progression;
- multi-cannon fireworks for major rewards;
- a static medallion with no confetti or Lottie motion when reduced-motion is
  active.

Shape plus color improves recognition for children who cannot distinguish all
confetti colors.

## Accessibility propagation

The root `MediaQuery.disableAnimations` value now mirrors the persisted
reduced-motion setting. Standard Flutter widgets and shared components can
therefore respect one platform-style signal.

`BouncyButton` skips its press-scale animation under reduced-motion while
retaining touch, sound (when enabled), semantics and haptic acknowledgement.
Animated backgrounds and supported games continue using the existing Riverpod
provider, so both old and new paths remain compatible.

## Performance boundaries

- Wonder Touch uses `CustomPaint`; it does not load images or Lottie files.
- Only active bursts repaint, and no more than six exist simultaneously.
- The overlay is pointer-transparent and does not rebuild game state.
- Sound uses two bounded SFX players, not one player per tap.
- Celebration particles remain capped at the existing conservative count.
- Reduced-motion removes the most animation work automatically.

## Implementation map

- Root wiring: `lib/app/kidverse_app.dart`
- Wonder Touch: `lib/core/widgets/kid_experience_layer.dart`
- Physical buttons: `lib/core/widgets/bouncy_button.dart`
- Success visuals: `lib/core/widgets/celebration_overlay.dart`
- Sound mixing and narration ducking: `lib/core/services/audio_service.dart`
- Regression coverage: `test/kid_experience_test.dart`

## Verification

Automated coverage verifies that:

- touch feedback appears without consuming the underlying tap;
- touch feedback removes itself;
- reduced-motion creates no Wonder Touch animation;
- reduced-motion success still has a clear static visual moment;
- existing learning-engine success delays still hold before progression.

Release checks:

```bash
flutter analyze --fatal-infos
flutter test
```

## Product guidance

Juice must communicate meaning rather than become visual noise. New features
should use the shared touch and celebration layers before adding custom particle
systems. Do not add a sound to every animation, do not stack spoken praise over
instructions, and do not bypass reduced-motion for decorative effects.

Future high-value work is educator and child testing on real low-end devices:
observe whether feedback is understood, whether audio levels are comfortable,
and whether any effect covers a target. Tune from observation rather than
increasing particle counts.
