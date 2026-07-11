# Curriculum and Grade-Fit Audit

**Status:** implemented engineering pass, educator review still required
**Scope:** LKG, UKG, KG, Grades 1–5; maths, English, EVS, science, logic and shared learning adventures

## Product principle

KidVerse should teach at the point where a child can succeed with a little
thought. It must not use the selected class merely as a label. Grade changes
must affect vocabulary, number range, abstraction, reading load, session
length, hints and the concepts that can appear.

The required loop is:

> See or hear a small idea → try it in a playful setting → receive immediate
> feedback → get a simpler clue after struggle → celebrate mastery → meet a
> slightly richer version later.

This is different from presenting 20 disconnected multiple-choice questions.

## Defects found in the previous generator

The former implementation was structurally valid but not sufficiently
grade-aware:

- LKG, UKG and KG used the same maths branch. LKG could receive symbolic
  addition, subtraction and numbers above its intended range.
- Grades 1 and 2 used the same branch, including multiplication regardless of
  whether its foundations had been introduced.
- Grades 3, 4 and 5 shared one advanced branch. Grade 3 could receive decimals,
  LCM and HCF.
- EVS and science ignored grade entirely. Preschool learners could encounter
  vapour, planets, geography and national-symbol recall.
- Logic number patterns ignored age and could skip-count by 11 or 12 in
  preschool.
- Sorting ignored subject. A maths lesson could ask a fruit/vegetable question,
  and an English lesson could ask an unrelated science category.
- English had only two bands: preschool and Grade 1+. It did not form an
  intentional Grade 1 → Grade 5 literacy progression.
- Every choice activity used a 20-question session. That is too long for most
  three- to five-year-olds and makes success feel far away.
- Technical checks verified indexes and duplicate options but did not verify
  whether the taught fact was true. A logic row incorrectly treated a planet
  as larger than a star, and two odd-one-out answers were reversed.

## Implemented class progression

### Session size

| Class | Typical age | Standard steps per level | Experience goal |
|---|---:|---:|---|
| LKG | 3 | 5 | very short, voice-first wins |
| UKG | 4 | 7 | short guided practice |
| KG | 5 | 8 | short practice with early symbols |
| Grade 1 | 6 | 10 | one focused skill mission |
| Grade 2 | 7 | 12 | guided fluency |
| Grade 3 | 8 | 12 | concept plus application |
| Grade 4 | 9 | 15 | mixed fluency and reasoning |
| Grade 5 | 10 | 15 | multi-step application |

Tracing, sequencing, flashcards and memory games remain shorter because their
interaction cost is higher than a single tap.

### Maths

| Class | Intended content |
|---|---|
| LKG | quantities 1–3, then 1–5; number recognition; visual comparison; one-more stories late in the journey |
| UKG | counting to 10, then 20; before/after; concrete addition and take-away; greater/smaller |
| KG | numbers to 50; facts within 10/20; tens; skip-counting by 2, 5 and 10 |
| Grade 1 | place value to 100; addition/subtraction; hour clocks; comparison; skip-counting; no formal multiplication track |
| Grade 2 | three-digit place value and operations; tables; equal sharing; money; number patterns |
| Grade 3 | four-digit operations; tables/division; simple fractions; unit conversion; introductory area/perimeter; no LCM/HCF/decimals |
| Grade 4 | larger operations; factors; equivalent fractions; tenths; measurement and geometry |
| Grade 5 | multi-step multiplication/division; fractions and decimals; percentage; volume; LCM and HCF |

Math sorting is now mathematical: preschool classifies numbers/shapes and
number bands; primary levels classify divisibility rather than unrelated food.

### English

| Class | Intended content |
|---|---|
| LKG | voice-led letter recognition, picture naming and initial sounds; no independent reading requirement |
| UKG | upper/lower-case matching, beginning sounds, vowels and picture-word association |
| KG | CVC words, rhyme, first/last sounds, vowels and simple word matching |
| Grades 1–2 | opposites, regular plurals, short spelling and simple sentence completion |
| Grade 3 | nouns, action words, adjectives, pronouns, prepositions and accessible synonym/antonym work |
| Grade 4 | homophones, conjunctions, prepositions, agreement, adverbs and vocabulary |
| Grade 5 | tense control, subject–verb agreement, conjunctions, homophones and more precise vocabulary |

English sorting now uses initial sounds for preschool and naming/action words
for primary children. English sequencing builds alphabet order or sentences
instead of showing unrelated life-cycle content.

### EVS and science

Every class now has a separate curated knowledge pool. The main progression is:

- LKG: familiar animals, senses, food, hygiene, home and helpers.
- UKG: young animals, body functions, weather, routines, transport and safety.
- KG: living/non-living, plant parts, habitats, air/water and good habits.
- Grade 1: immediate community and observable science.
- Grade 2: neighbourhoods, maps, materials, states, forces and habitats.
- Grade 3: landforms, resources, community systems, plants, matter, simple
  circuits, Earth rotation and food chains.
- Grade 4: map coordinates, climate, conservation, adaptations, heat,
  reversible changes, magnets, sound and light.
- Grade 5: population, trade, budgets, citizenship, sustainability, body
  systems, ecosystems, solutions, circuits, light and fair tests.

Ambiguous or incorrect legacy facts are no longer in the playable pool. For
example, bees collect both nectar and pollen, India has no officially declared
national sport, and stars cannot be treated as smaller than planets.

### Logic and memory

Number-pattern steps now rise by class: LKG uses only +1; UKG adds +2; KG adds
gentle +5; larger skips unlock through primary grades. Preschool memory boards
also contain fewer pairs than older boards.

## Learning-adventure review

The 23 shared learning adventures already have a strong play wrapper: garden
counting, shopping, pizza fractions, robot commands, investigations, space
missions and business stories. Their internal 50-level curves generally move
from recognition to application:

- Preschool adventures remain visual and spoken, with addition appearing late
  in Number Garden.
- Class 1–2 adventures begin with sounds, whole-hour clocks, simple totals and
  familiar nature clues before introducing change, half-hours and properties.
- Class 3–4 adventures begin with fraction models, multiplication groups,
  basic grammar, movement commands and compass directions before equivalent
  fractions, division, loops, debugging and map coordinates.
- Class 5 adventures apply school concepts to sustainability, space, money,
  evidence, news literacy and algorithms.

Every learning adventure now declares typed `minGrade` and `maxGrade` values.
The hub, daily trail and direct game route enforce those values. Shared story
worlds also scale their internal content curve by exact class while preserving
the child’s existing 1–50 progress: LKG, UKG, Grade 1 and Grade 3 receive
gentler ceilings than KG, Grade 2 and Grade 4 respectively.

## Skill graph and learning rescue

Generated questions now carry a stable `skillId`, prerequisite skill IDs, a
teach-first explanation and a rescue explanation. One level focuses on one
primary skill instead of mixing unrelated concepts. The adventure intro labels
a concept as a new skill or quick reminder and teaches its rule before play.

The offline adaptive model records concept mastery separately from broad
subject mastery and persists it backward-compatibly. After two wrong attempts,
answer-based engines pause with a spoken visual explanation, then reduce the
question to two choices or highlight the next correct step. This behavior is
shared by tap choice, listen-and-tap, boss battle, feed-the-pet, bubble pop,
mole match, drag/sort, sequence and the 23 learning adventures.

## Automated guardrails

`test/curriculum_grade_fit_test.dart` now prevents regressions by checking:

- every preschool question has spoken guidance;
- advanced concepts cannot leak into younger classes;
- LCM, HCF, percentages and volume unlock only at the intended stage;
- EVS/science pools are not identical across classes;
- age-based session lengths remain intentional.

Existing audits continue to verify valid answer indexes, non-empty choices,
unique visible options, complete engine data and no repeated question inside a
level.

## What “production-ready curriculum” still requires

Engineering can enforce scope, consistency and correctness-by-construction,
but it cannot certify a curriculum alone. Before store release:

1. Have an early-years educator review LKG–KG voice prompts and cultural fit.
2. Have primary teachers review each grade/subject sample against the target
   board and school sequence. Do not market the content as “CBSE certified”
   without a formal review and permission.
3. Run moderated playtests with at least five children per age band. Record
   confusion, not just whether an answer was eventually correct.
4. Track anonymous, consent-safe metrics: first-attempt accuracy, retries,
   hint use, abandon point, completion time and replay choice.
5. Flag a level for review when many children abandon it or when accuracy
   changes sharply from the previous level.
6. Add a content manifest containing `skillId`, prerequisite, grade range,
   reading load, expected time, source/reviewer and review date.
7. Add teach cards or worked examples before a new abstract concept. Feedback
   after a wrong answer should explain the idea, not only reveal correctness.

## Recommended next implementation

The next step is teacher-facing mastery reporting and prerequisite routing. The
skill graph and mastery data now exist; the learning map should recommend a
short prerequisite mission when mastery is below threshold and show parents
which skills are secure, developing or repeatedly rescued.
