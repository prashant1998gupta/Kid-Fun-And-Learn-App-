# Preschool Learn & Trace Library

## Purpose

The Learn & Trace Library gives LKG, UKG and KG children a calm, replayable
place to learn without entering a scored lesson. It follows a simple loop:

1. Choose any category or item. Nothing is locked.
2. See a large symbol or picture and hear its name.
3. Trace the symbol or confirm the picture word.
4. Celebrate, repeat the same item, or choose another one.

This library complements curriculum lessons. It does not replace adaptive
questions, daily revision, or parent-visible lesson progress.

## Included content

The expanded library contains 1,011 independent practice items.

### Learn and trace (111 items)

| Category | Items | Learning treatment |
|---|---:|---|
| Capital letters | A–Z (26) | Letter, familiar example, picture, English voice, tracing |
| Small letters | a–z (26) | Separate lowercase card, example, voice, tracing |
| Numbers | 0–9 (10) | Numeral, number word, voice, tracing |
| हिंदी स्वर | 13 | Character, Hindi example, Hindi voice, tracing |
| हिंदी व्यंजन | 36 | Character, Hindi example where appropriate, Hindi voice, tracing |

Uppercase and lowercase are intentionally separate. A child can practise `P`
without being forced through A–O, and can return to `p` later without losing
their uppercase progress.

### Picture words (900 items)

| Category | Count |
|---|---:|
There are exactly 30 Picture Words sections with exactly 30 cards in every
section:

| Sections | Cards per section |
|---|---:|
| Body Parts, Fruits, Vegetables, Animals, Birds | 30 each |
| Colors, Shapes, Family, Transport, Everyday Things | 30 each |
| Farm Animals, Wild Animals, Sea Animals, Insects & Tiny Creatures | 30 each |
| Flowers & Plants, Nature, Weather & Seasons | 30 each |
| Clothes, Shoes & Accessories, Food, Drinks | 30 each |
| Kitchen Things, Home & Rooms, School Things, Toys & Play | 30 each |
| Sports, Musical Instruments, Community Helpers | 30 each |
| Places Around Us, Action Words | 30 each |

Picture-word cards use a large visual, a short label and spoken pronunciation.
They deliberately avoid definitions and quizzes at this age; recognition and
repetition come first.

## Child experience

- A prominent **Learn & Trace Anytime** card appears on Home only for LKG, UKG
  and KG profiles.
- The hub separates **Learn & Trace** from **Picture Words**.
- Opening an item automatically speaks it. **Hear Again** can be used without
  limits.
- Previous and Next move through the category, while the category grid permits
  random access.
- Guided tracing shows a large outline and a pulsing visual cue. **Free Draw**
  removes the strong guide so the child can form the symbol independently.
- **Clear**, **Again**, and **Another** make retrying explicit. There is no game
  over, score penalty, timer, energy cost, or daily limit.
- A completion celebration remains on screen until the child chooses what to do
  next. The app does not immediately advance after a successful trace.

## Voice behavior

`AudioService.speak` accepts a language per utterance. English content uses
`en-US`; Hindi content uses `hi-IN`. The service remembers the active TTS
language and changes it only when required. Existing callers remain English by
default.

Actual pronunciation depends on voices installed by the operating system. The
screen remains fully usable when TTS is muted or unavailable.

## Progress and privacy

Progress is local-first and stored per child in SharedPreferences under
`preschool_practice_<childId>`. Only two counters are stored per item:

- `views`: the number of times the learn card was opened;
- `practices`: the number of completed traces or confirmed picture words.

The child sees gentle states instead of grades:

| State | Rule |
|---|---|
| New | No view or practice yet |
| Practising | Viewed, or completed fewer than three times |
| Great job | Completed at least three times |

The counters do not lock content or prevent further practice. Siblings using
the same device have independent records. No drawing coordinates, microphone
recordings, photos, or personal text are stored.

## Implementation map

- Catalog and grade availability:
  `lib/features/preschool_library/preschool_practice_catalog.dart`
- The 900-card Picture Words data bank:
  `lib/features/preschool_library/preschool_picture_word_data.dart`
- Per-child persistence and stages:
  `lib/features/preschool_library/preschool_practice_controller.dart`
- Hub, category, learn and tracing screens:
  `lib/features/preschool_library/preschool_practice_screen.dart`
- Language-aware TTS:
  `lib/core/services/audio_service.dart`
- Home entry and route:
  `lib/features/home/home_screen.dart`, `lib/app/router.dart`
- Regression coverage:
  `test/preschool_practice_test.dart`

## Quality gates

Automated tests verify:

- expected A–Z, a–z, 0–9 and Hindi catalog sizes;
- exactly 30 Picture Words categories and exactly 30 cards in each;
- exactly 900 Picture Words cards overall;
- globally unique IDs and non-empty voice/visual content;
- availability for LKG/UKG/KG and exclusion from Grade 1+;
- persistence, three-stage progress, and sibling isolation;
- separate tracing and picture-word sections in the UI;
- disabled completion before drawing;
- trace success, celebration, replay and canvas reset.

Run before release:

```bash
flutter analyze --fatal-infos
flutter test
```

## Pedagogical and production notes

- The current guide uses the displayed font outline. It is appropriate for
  familiarisation and free practice, but it is not a handwriting assessment.
- The pulsing marker is a general visual invitation, not an authored,
  glyph-specific stroke-order instruction. Do not market it as certified
  stroke-order teaching.
- Before claiming handwriting instruction, commission educator-reviewed vector
  paths for each Latin and Devanagari glyph, including numbered strokes and
  direction arrows. Those paths should be tested with teachers and children on
  the exact fonts shipped by the app.
- Replace emoji with a cohesive, licensed illustration pack when the visual
  asset pipeline is ready. Emoji appearance varies across Android, iOS and web.
- Native Hindi voices and pronunciation should be checked on the minimum
  supported Android and iOS versions before store release.
- Future vocabulary additions should remain concrete, familiar, culturally
  inclusive, visually unambiguous and pronounceable in one short phrase.

These limits are explicit so the feature is honest: it is a safe, useful
learn-see-hear-practise library today, with a clear path to educator-certified
stroke teaching later.
