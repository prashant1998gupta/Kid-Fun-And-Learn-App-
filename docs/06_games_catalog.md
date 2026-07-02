# 06 — Game Catalog (100+) & Engine Specification

## The engine model
A `Lesson` declares a `GameType`; `GameHostScreen` maps it to an **engine
widget**. Engines are generic and content-driven, so **one engine powers many
lessons/games** across all grades. Adding a game type = 1 engine + 1 `switch`
case; the reward/XP/celebration/adaptive flow is shared.

Implemented today: **TapChoice, MemoryMatch, DragDrop, Tracing, Sequence,
BubblePop, ListenAndTap, MoleMatch, FeedPet, Speech, and BossBattle**. Below is
the full engine roadmap and the 100+ game catalog each engine renders.

## Core engines (10) → cover 100+ games
| Engine | Interaction | Powers these games |
|---|---|---|
| **TapChoice** ✅ | pick correct option(s) | Letter Hunt, Number Catch, Color Match, Animal Sounds, Odd-One-Out, Quiz Battle, Spelling multiple-choice, Fast Tap, Reaction Time |
| **MemoryMatch** | flip & pair | Memory Cards, Shadow Matching, Spot Matching, Flash-card pairs |
| **DragDrop** | drag item→target | Sorting, Feed-the-Monster, Fruit Basket, Word Builder (letter tiles), Fill-the-Blank, Dress-up, Garden/Farm placing |
| **FeedPet** ✅ | tap the right snack/object to care for a pet | Feed the Puppy, Pet Snack Rescue, Healthy Food, Animal Care, Caretaking choices |
| **Tracing** | finger-trace path | Letter/Number/Shape tracing, Maze, Join-the-dots, Draw & Color |
| **Sequence/Order** | order items | Pattern Builder, Story Sequence, Number Line, Before/After, Simon Says |
| **BubblePop/Catch** | tap/miss moving items | Bubble Pop, Balloon Pop, Fishing, Star Catch, Rocket Dodge, Fruit Slice |
| **Counting/Math** | manipulate quantities | Count, Add/Sub race, Math Race, Coin shop, Compare, Times-table blast |
| **Builder** | assemble parts | Shape Builder, Puzzle (jigsaw), Cooking, Castle build, Lego-style |
| **Rhythm/Music** | tap on beat | Music Rhythm, Dance, Sing-along, Piano tiles |
| **AdventureMap** | node-based journey | Treasure Hunt, Space Mission, Pirate Island, Magic Forest, Boss Battle |

## 100+ game ideas (mapped to engines & subjects)
> Each renders via the engine in brackets; difficulty scales by grade tier.

**Literacy (English):** Letter Hunt [TapChoice], Alphabet Tracing [Tracing],
Vowel Friends [TapChoice], Phonics Pop [Bubble], Word Builder [DragDrop],
Rhyming Pairs [Memory], Sight-Word Sprint [TapChoice], Spelling Bee [DragDrop],
Sentence Order [Sequence], Story Sequence [Sequence], Opposite Match [Memory],
Silent-e Magic [TapChoice], Reading Aloud [Speech], Prefix/Suffix build
[DragDrop], Punctuation catch [Bubble].

**Numeracy (Math):** Count to 5/10/20 [Counting], Number Trace [Tracing],
Number Catch [Bubble], Shape Explorer [TapChoice], Shape Builder [Builder],
Add/Subtract Race [Math], Compare (>/<) [TapChoice], Skip Counting [Sequence],
Times-Table Blast [Math], Fractions Pizza [Builder], Money Shop [Math],
Measurement match [Memory], Clock reading [TapChoice], Place value [DragDrop],
Number line jumps [Sequence], Symmetry mirror [Tracing].

**EVS / Science:** Animal Sounds [TapChoice], Habitat Sort [DragDrop], Body
Parts [DragDrop], Fruits & Veggies [Memory], Weather Wheel [TapChoice], Plant
Growth Sequence [Sequence], Food Chain [Sequence], Recycle Sort [DragDrop],
Solar System [AdventureMap], States of Matter [TapChoice], Good/Bad habits
[Sorting], Seasons [TapChoice], Magnet game [DragDrop], Day/Night [TapChoice].

**Logic & Puzzles:** Pattern Builder [Sequence], Odd-One-Out [TapChoice],
Jigsaw [Builder], Maze [Tracing], Sudoku-jr [DragDrop], Find-the-Difference
[TapChoice], Hidden Object [TapChoice], Shadow Match [Memory], Sorting by
attribute [DragDrop], Coding Basics (arrow sequence) [Sequence], Tangram
[Builder], Logic grid [DragDrop].

**Art & Music:** Draw & Color [Tracing], Coloring Book [Tracing], Music Rhythm
[Rhythm], Dance Along [Rhythm], Piano Tiles [Rhythm], Instrument Match [Memory],
Mix Colors [Builder], Sticker Studio [Builder].

**Adventure / meta:** Treasure Hunt, Space Mission, Pirate Island, Magic Forest,
Castle Quest, Animal Rescue, Superhero training, Mini Racing, Boss Battle,
Daily Challenge — all [AdventureMap] wrappers that string core-engine lessons
into a themed journey with a reward chest at the end.

## Content authoring
All the above are **data**, not code: a lesson JSON (see
`assets/data/curriculum_lkg.json`) names the `gameType` and supplies questions.
Curriculum designers add lessons without engineering. Schema in
`lib/features/curriculum/data/lesson_parser.dart`.
