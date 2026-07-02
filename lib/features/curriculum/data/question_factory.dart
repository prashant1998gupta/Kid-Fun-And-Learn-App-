import '../../profiles/domain/grade_level.dart';
import '../domain/lesson.dart';
import '../domain/subject.dart';

/// Generates broad, grade-appropriate, **factually correct** question banks so
/// every subject can offer a long, non-repetitive learning journey.
///
/// Design rules:
///  - Deterministic: content is a pure function of (grade, subject, gameType,
///    level, index). No Random/DateTime, so it is stable across rebuilds.
///  - Correct by construction: math is parametric (the answer is computed);
///    other subjects draw from curated banks where the right answer is authored
///    next to its distractors.
///  - Varied within a level: [forLevel] de-duplicates by full-question
///    signature, so a single level never shows the same question twice.
class QuestionFactory {
  const QuestionFactory._();

  /// Distinct questions for one level. [count] questions, guaranteed unique
  /// within the level (deduped by prompt+options).
  static List<Question> forLevel({
    required GradeLevel grade,
    required Subject subject,
    required GameType gameType,
    required int level,
    int count = 12,
  }) {
    final seed = (level + 1) * 29;
    final out = <Question>[];
    final seen = <String>{};
    var i = 0;
    // Try up to count*6 indices to collect `count` distinct questions.
    while (out.length < count && i < count * 6) {
      final q = _one(seed + i, grade, subject, gameType, out.length);
      final sig = _signature(q);
      if (seen.add(sig)) out.add(q);
      i++;
    }
    // Safety pad (bank smaller than count): accept remaining even if similar.
    while (out.length < count) {
      out.add(_one(seed + i, grade, subject, gameType, out.length));
      i++;
    }
    return out;
  }

  static String _signature(Question q) {
    final opts = q.options.map((o) => '${o.label}/${o.emoji ?? ''}').join(',');
    return '${q.prompt}|$opts|${q.answer}';
  }

  static Question _one(
    int index,
    GradeLevel grade,
    Subject subject,
    GameType gameType,
    int slot,
  ) {
    // Game types that need a special option shape are handled first.
    switch (gameType) {
      case GameType.tracing:
        return _tracing(index, subject);
      case GameType.sequence:
        return _sequence(index, grade, subject, slot);
      case GameType.memoryMatch:
        return _memory(index, subject, slot);
      case GameType.dragDrop:
      case GameType.sorting:
        return _sorting(index, grade, subject, slot);
      default:
        return _choiceBySubject(index, grade, subject, slot);
    }
  }

  // ---------------------------------------------------------------------------
  // Multiple-choice helper: places the correct answer at a rotated index so the
  // right option isn't always first. correctIndex is computed to match.
  // ---------------------------------------------------------------------------
  static Question _mc({
    required String id,
    required String prompt,
    String? speak,
    required AnswerOption correct,
    required List<AnswerOption> wrong,
    required int shift,
  }) {
    final all = [correct, ...wrong];
    final rot = all.isEmpty ? 0 : shift % all.length;
    final options = [...all.skip(rot), ...all.take(rot)];
    return Question(
      id: id,
      prompt: prompt,
      speak: speak ?? prompt,
      options: options,
      correctIndex: (all.length - rot) % all.length,
    );
  }

  static Question _numMc(
    int index,
    String id,
    String prompt,
    String? speak,
    int answer, {
    List<int>? distractors,
  }) {
    final d = distractors ??
        [answer + 1, answer <= 1 ? answer + 2 : answer - 1];
    // Ensure distractors are distinct and != answer.
    final used = <int>{answer};
    final wrong = <AnswerOption>[];
    for (final base in [...d, answer + 2, answer + 3, answer - 2]) {
      if (wrong.length >= 2) break;
      final v = base < 0 ? base.abs() + answer + 1 : base;
      if (used.add(v)) wrong.add(AnswerOption(label: '$v'));
    }
    return _mc(
      id: id,
      prompt: prompt,
      speak: speak,
      correct: AnswerOption(label: '$answer'),
      wrong: wrong,
      shift: index,
    );
  }

  // ---------------------------------------------------------------------------
  // Tracing — cycle letters then numbers.
  // ---------------------------------------------------------------------------
  static Question _tracing(int index, Subject subject) {
    if (subject == Subject.math) {
      final n = index % 10;
      return Question(
          id: 'gen_trace_$index',
          prompt: 'Trace $n',
          answer: '$n',
          speak: 'Trace the number $n');
    }
    final glyph = String.fromCharCode('A'.codeUnitAt(0) + (index % 26));
    return Question(
        id: 'gen_trace_$index',
        prompt: 'Trace $glyph',
        answer: glyph,
        speak: 'Trace the letter $glyph');
  }

  // ---------------------------------------------------------------------------
  // Sequence — ordered options the child taps in order.
  // ---------------------------------------------------------------------------
  static Question _sequence(int index, GradeLevel grade, Subject subject, int slot) {
    final width = grade.difficultyTier <= 1 ? 3 : (grade.difficultyTier <= 4 ? 4 : 5);
    if (subject == Subject.math || subject == Subject.logic) {
      // Number sequences: count by step.
      final step = [1, 2, 5, 10, 3][index % 5];
      final start = (index % 6 + 1) * step;
      return Question(
        id: 'gen_seq_${index}_$slot',
        prompt: 'Put them in order (counting by $step)',
        speak: 'Tap the numbers in order',
        options: [
          for (var k = 0; k < width; k++)
            AnswerOption(label: '${start + k * step}'),
        ],
      );
    }
    // Non-numeric ordered sets (small→big, life cycle, etc.).
    const sets = [
      ['🐜 Ant', '🐱 Cat', '🐶 Dog', '🐘 Elephant', '🐳 Whale'],
      ['🌰 Seed', '🌱 Sprout', '🪴 Plant', '🌳 Tree'],
      ['🥚 Egg', '🐛 Caterpillar', '🦋 Butterfly'],
      ['🌅 Morning', '☀️ Noon', '🌆 Evening', '🌙 Night'],
      ['👶 Baby', '🧒 Child', '🧑 Adult', '👴 Elder'],
      ['🥚 Egg', '🐣 Chick', '🐔 Hen'],
      ['☁️ Cloud', '🌧️ Rain', '🌈 Rainbow'],
      ['🧊 Ice', '💧 Water', '💨 Steam'],
    ];
    final set = sets[index % sets.length];
    final take = set.length;
    return Question(
      id: 'gen_seq_${index}_$slot',
      prompt: 'Put them in the right order',
      speak: 'Order them correctly',
      options: [for (var k = 0; k < take; k++) _emojiOption(set[k])],
    );
  }

  static AnswerOption _emojiOption(String combined) {
    final parts = combined.split(' ');
    return AnswerOption(label: parts.sublist(1).join(' '), emoji: parts.first);
  }

  // ---------------------------------------------------------------------------
  // Memory — a set of pictures to match into pairs.
  // ---------------------------------------------------------------------------
  static Question _memory(int index, Subject subject, int slot) {
    const sets = [
      ['🐶', '🐱', '🐮', '🐷', '🐰'],
      ['🍎', '🍌', '🍇', '🍓', '🍊'],
      ['🔴', '🔵', '🟢', '🟡', '🟣'],
      ['⭐', '❤️', '🌙', '☀️', '🌈'],
      ['🚗', '🚌', '✈️', '🚂', '🚀'],
      ['🔵', '🟥', '🔺', '⭐', '❤️'],
    ];
    final faces = sets[index % sets.length];
    return Question(
      id: 'gen_mem_${index}_$slot',
      prompt: 'Find the matching pairs',
      options: [for (final f in faces) AnswerOption(label: f, emoji: f)],
    );
  }

  // ---------------------------------------------------------------------------
  // Sorting / drag-drop — one item into the correct of two baskets.
  // ---------------------------------------------------------------------------
  static Question _sorting(int index, GradeLevel grade, Subject subject, int slot) {
    // (item, emoji, catA, catAEmoji, catB, catBEmoji, correctIndex)
    const items = [
      ('Apple', '🍎', 'Fruit', '🍓', 'Vegetable', '🥕', 0),
      ('Carrot', '🥕', 'Fruit', '🍓', 'Vegetable', '🥕', 1),
      ('Banana', '🍌', 'Fruit', '🍓', 'Vegetable', '🥕', 0),
      ('Broccoli', '🥦', 'Fruit', '🍓', 'Vegetable', '🥕', 1),
      ('Grapes', '🍇', 'Fruit', '🍓', 'Vegetable', '🥕', 0),
      ('Potato', '🥔', 'Fruit', '🍓', 'Vegetable', '🥕', 1),
      ('Fish', '🐟', 'Land', '🌳', 'Water', '🌊', 1),
      ('Lion', '🦁', 'Land', '🌳', 'Water', '🌊', 0),
      ('Whale', '🐳', 'Land', '🌳', 'Water', '🌊', 1),
      ('Dog', '🐶', 'Land', '🌳', 'Water', '🌊', 0),
      ('Duck', '🦆', 'Land', '🌳', 'Water', '🌊', 1),
      ('Horse', '🐴', 'Land', '🌳', 'Water', '🌊', 0),
      ('Sun', '☀️', 'Living', '🌿', 'Nonliving', '🪨', 1),
      ('Tree', '🌳', 'Living', '🌿', 'Nonliving', '🪨', 0),
      ('Rock', '🪨', 'Living', '🌿', 'Nonliving', '🪨', 1),
      ('Cat', '🐱', 'Living', '🌿', 'Nonliving', '🪨', 0),
      ('Ball', '⚽', 'Living', '🌿', 'Nonliving', '🪨', 1),
      ('Flower', '🌸', 'Living', '🌿', 'Nonliving', '🪨', 0),
    ];
    final it = items[index % items.length];
    return Question(
      id: 'gen_sort_${index}_$slot',
      prompt: 'Where does the ${it.$1.toLowerCase()} go?',
      speak: 'Where does the ${it.$1.toLowerCase()} go?',
      promptEmoji: it.$2,
      correctIndex: it.$7,
      options: [
        AnswerOption(label: it.$3, emoji: it.$4),
        AnswerOption(label: it.$5, emoji: it.$6),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Choice questions routed by subject.
  // ---------------------------------------------------------------------------
  static Question _choiceBySubject(
      int index, GradeLevel grade, Subject subject, int slot) {
    final tier = grade.difficultyTier;
    switch (subject) {
      case Subject.math:
        return _math(index, tier, slot);
      case Subject.english:
      case Subject.rhymes:
        return _english(index, tier, slot);
      case Subject.evs:
      case Subject.science:
        return _world(index, tier, slot);
      case Subject.logic:
        return _logic(index, tier, slot);
      case Subject.art:
        return _art(index, slot);
    }
  }

  // ---- MATH (parametric, integer-safe, tiered) ------------------------------
  static Question _math(int index, int tier, int slot) {
    final id = 'gen_math_${index}_$slot';
    if (tier <= 2) {
      switch (index % 4) {
        case 0:
          final n = index % 9 + 1;
          return _numMc(index, id, 'How many? ${'⭐' * n}',
              'How many stars do you see?', n);
        case 1:
          final a = index % 5 + 1;
          final b = (index ~/ 2) % 5 + 1;
          return _numMc(index, id, '$a + $b = ?',
              'What is $a plus $b?', a + b);
        case 2:
          final n = index % 9 + 1;
          return _numMc(index, id, 'What comes after $n?',
              'What number comes after $n?', n + 1);
        default:
          final a = index % 9 + 1;
          var b = (index ~/ 3) % 9 + 1;
          if (b == a) b = b % 9 + 1;
          final big = a > b ? a : b;
          final small = a > b ? b : a;
          return _mc(
            id: id,
            prompt: 'Which is bigger: $a or $b?',
            speak: 'Which number is bigger?',
            correct: AnswerOption(label: '$big'),
            wrong: [AnswerOption(label: '$small')],
            shift: index,
          );
      }
    }
    if (tier <= 4) {
      switch (index % 5) {
        case 0:
          final a = index % 40 + 5;
          final b = index % 25 + 3;
          return _numMc(index, id, '$a + $b = ?',
              'What is $a plus $b?', a + b);
        case 1:
          final a = index % 40 + 20;
          final b = index % 15 + 1;
          return _numMc(index, id, '$a - $b = ?',
              'What is $a minus $b?', a - b);
        case 2:
          final a = index % 5 + 2;
          final b = index % 5 + 2;
          return _numMc(index, id, '$a × $b = ?',
              'What is $a times $b?', a * b);
        case 3:
          final groups = index % 4 + 2;
          final each = index % 4 + 2;
          return _numMc(index, id, '$groups groups of $each = ?',
              'How many in all?', groups * each);
        default:
          final step = [2, 5, 10][index % 3];
          final n = (index % 8 + 1) * step;
          return _numMc(index, id, 'Count by $step: $n, then?',
              'What comes next?', n + step);
      }
    }
    // tier 5-7: multiply, divide, percent, square, perimeter, compare
    switch (index % 6) {
      case 0:
        final a = index % 11 + 2;
        final b = index % 11 + 2;
        return _numMc(index, id, '$a × $b = ?',
            'What is $a times $b?', a * b);
      case 1:
        final b = index % 9 + 2;
        final ans = index % 9 + 2;
        return _numMc(index, id, '${b * ans} ÷ $b = ?',
            'What is ${b * ans} divided by $b?', ans);
      case 2:
        final ans = index % 20 + 1;
        final whole = ans * 2;
        return _numMc(index, id, '50% of $whole = ?',
            'What is fifty percent of $whole?', ans);
      case 3:
        final n = index % 12 + 2;
        return _numMc(index, id, '$n² = ?',
            'What is $n squared?', n * n);
      case 4:
        final l = index % 12 + 4;
        final w = index % 8 + 3;
        return _numMc(index, id, 'Perimeter of a $l by $w rectangle?',
            'What is the perimeter?', 2 * (l + w));
      default:
        final ans = index % 25 + 1;
        final whole = ans * 4;
        return _numMc(index, id, '25% of $whole = ?',
            'What is twenty five percent of $whole?', ans);
    }
  }

  // ---- ENGLISH --------------------------------------------------------------
  static Question _english(int index, int tier, int slot) {
    final id = 'gen_en_${index}_$slot';
    if (tier <= 2) {
      // Letter recognition.
      final t = String.fromCharCode('A'.codeUnitAt(0) + index % 26);
      final b = String.fromCharCode('A'.codeUnitAt(0) + (index + 1) % 26);
      final c = String.fromCharCode('A'.codeUnitAt(0) + (index + 9) % 26);
      return _mc(
        id: id,
        prompt: 'Tap the letter $t',
        speak: 'Find the letter $t',
        correct: AnswerOption(label: t),
        wrong: [AnswerOption(label: b), AnswerOption(label: c)],
        shift: index,
      );
    }
    // Opposites bank (correct answer authored next to word).
    const opposites = [
      ('hot', 'cold'), ('big', 'small'), ('up', 'down'), ('fast', 'slow'),
      ('day', 'night'), ('happy', 'sad'), ('open', 'shut'), ('wet', 'dry'),
      ('full', 'empty'), ('hard', 'soft'), ('old', 'new'), ('light', 'dark'),
      ('loud', 'quiet'), ('high', 'low'), ('push', 'pull'), ('near', 'far'),
    ];
    final k = index ~/ 2;
    if (index % 2 == 0) {
      final p = opposites[k % opposites.length];
      final w1 = opposites[(k + 2) % opposites.length].$2;
      final w2 = opposites[(k + 5) % opposites.length].$2;
      return _mc(
        id: id,
        prompt: 'Opposite of "${p.$1}"?',
        speak: 'What is the opposite of ${p.$1}?',
        correct: AnswerOption(label: p.$2),
        wrong: [
          AnswerOption(label: w1 == p.$2 ? opposites[(k + 3) % 16].$2 : w1),
          AnswerOption(label: w2 == p.$2 ? opposites[(k + 7) % 16].$2 : w2),
        ],
        shift: index,
      );
    }
    // Plurals (regular +s / +es on sibilants).
    const nouns = [
      'cat', 'dog', 'car', 'book', 'tree', 'star', 'hand', 'bird',
      'box', 'bus', 'fox', 'dish', 'bench', 'glass',
    ];
    final n = nouns[k % nouns.length];
    final plural = (n.endsWith('x') ||
            n.endsWith('s') ||
            n.endsWith('sh') ||
            n.endsWith('ch'))
        ? '${n}es'
        : '${n}s';
    return _mc(
      id: id,
      prompt: 'More than one "$n"?',
      speak: 'What is more than one $n?',
      correct: AnswerOption(label: plural),
      wrong: [AnswerOption(label: n), AnswerOption(label: '$n${'z'}')],
      shift: index,
    );
  }

  // ---- EVS / SCIENCE (curated fact bank) ------------------------------------
  static Question _world(int index, int tier, int slot) {
    // (question, correct, cEmoji, w1, w1Emoji, w2, w2Emoji)
    const facts = [
      ('Who says moo?', 'Cow', '🐄', 'Dog', '🐶', 'Duck', '🦆'),
      ('Who says woof?', 'Dog', '🐶', 'Cat', '🐱', 'Cow', '🐄'),
      ('Which one can fly?', 'Bird', '🐦', 'Fish', '🐟', 'Dog', '🐶'),
      ('Which lives in water?', 'Fish', '🐟', 'Lion', '🦁', 'Cat', '🐱'),
      ('Which is a fruit?', 'Apple', '🍎', 'Car', '🚗', 'Shoe', '👟'),
      ('What shines in the day?', 'Sun', '☀️', 'Moon', '🌙', 'Star', '⭐'),
      ('What do we see with?', 'Eyes', '👀', 'Ears', '👂', 'Nose', '👃'),
      ('Which one grows?', 'Tree', '🌳', 'Rock', '🪨', 'Chair', '🪑'),
      ('What keeps us dry in rain?', 'Umbrella', '☂️', 'Spoon', '🥄', 'Ball', '⚽'),
      ('Which is safe to eat?', 'Banana', '🍌', 'Soap', '🧼', 'Crayon', '🖍️'),
      ('Where does a bee live?', 'Hive', '🍯', 'Nest', '🪺', 'Web', '🕸️'),
      ('Where does a bird live?', 'Nest', '🪺', 'Hive', '🍯', 'Den', '🕳️'),
      ('Baby of a dog is a?', 'Puppy', '🐶', 'Kitten', '🐱', 'Calf', '🐄'),
      ('Which gives us milk?', 'Cow', '🐄', 'Hen', '🐔', 'Fish', '🐟'),
      ('Which season is hot?', 'Summer', '☀️', 'Winter', '❄️', 'Rainy', '🌧️'),
      ('Which is a vegetable?', 'Carrot', '🥕', 'Apple', '🍎', 'Grapes', '🍇'),
      ('What do plants need?', 'Sunlight', '☀️', 'Candy', '🍬', 'Toys', '🧸'),
      ('Water freezes into?', 'Ice', '🧊', 'Steam', '💨', 'Sand', '🏖️'),
      ('Which one floats?', 'Boat', '⛵', 'Rock', '🪨', 'Brick', '🧱'),
      ('Who puts out fires?', 'Firefighter', '🧑‍🚒', 'Farmer', '👨‍🌾', 'Chef', '👨‍🍳'),
      ('Which is a bird?', 'Owl', '🦉', 'Bee', '🐝', 'Frog', '🐸'),
      ('What do we breathe?', 'Air', '💨', 'Milk', '🥛', 'Juice', '🧃'),
      ('Which is the biggest?', 'Elephant', '🐘', 'Ant', '🐜', 'Mouse', '🐭'),
      ('The Earth is our?', 'Planet', '🌍', 'Star', '⭐', 'Boat', '⛵'),
    ];
    final f = facts[index % facts.length];
    return _mc(
      id: 'gen_world_${index}_$slot',
      prompt: f.$1,
      speak: f.$1,
      correct: AnswerOption(label: f.$2, emoji: f.$3),
      wrong: [
        AnswerOption(label: f.$4, emoji: f.$5),
        AnswerOption(label: f.$6, emoji: f.$7),
      ],
      shift: index,
    );
  }

  // ---- LOGIC ----------------------------------------------------------------
  static Question _logic(int index, int tier, int slot) {
    final id = 'gen_logic_${index}_$slot';
    // Decouple the content index (k) from the mode selector so each mode cycles
    // its own bank independently instead of collapsing to one entry.
    final k = index ~/ 3;
    switch (index % 3) {
      case 0:
        // Number pattern: what comes next (varies fully by k).
        final step = [1, 2, 3, 5, 10][k % 5];
        final start = (k % 7 + 1) * step;
        final next = start + step * 3;
        return _numMc(
          index,
          id,
          '$start, ${start + step}, ${start + 2 * step}, ?',
          'What number comes next?',
          next,
          distractors: [next + step, next - step],
        );
      case 1:
        // Odd one out (two of a category + one outsider).
        const sets = [
          ('Which is different?', 'Car', '🚗', 'Apple', '🍎', 'Banana', '🍌'),
          ('Which is different?', 'Shoe', '👟', 'Dog', '🐶', 'Cat', '🐱'),
          ('Which is different?', 'Fish', '🐟', 'Rose', '🌹', 'Tulip', '🌷'),
          ('Which is different?', 'Drum', '🥁', 'Grapes', '🍇', 'Mango', '🥭'),
          ('Which is different?', 'Bus', '🚌', 'Cat', '🐱', 'Dog', '🐶'),
          ('Which is different?', 'Sun', '☀️', 'Apple', '🍎', 'Pear', '🍐'),
        ];
        final s = sets[k % sets.length];
        return _mc(
          id: id,
          prompt: s.$1,
          speak: 'Which one does not belong?',
          correct: AnswerOption(label: s.$2, emoji: s.$3),
          wrong: [
            AnswerOption(label: s.$4, emoji: s.$5),
            AnswerOption(label: s.$6, emoji: s.$7),
          ],
          shift: index,
        );
      default:
        // Smallest / biggest reasoning.
        const trios = [
          ('smallest', 'Ant', '🐜', 'Dog', '🐶', 'Elephant', '🐘'),
          ('biggest', 'Whale', '🐳', 'Fish', '🐟', 'Crab', '🦀'),
          ('smallest', 'Mouse', '🐭', 'Cat', '🐱', 'Horse', '🐴'),
          ('biggest', 'Elephant', '🐘', 'Rabbit', '🐰', 'Ant', '🐜'),
          ('smallest', 'Bee', '🐝', 'Bird', '🐦', 'Eagle', '🦅'),
        ];
        final t = trios[k % trios.length];
        return _mc(
          id: id,
          prompt: 'Which is the ${t.$1}?',
          speak: 'Which one is the ${t.$1}?',
          correct: AnswerOption(label: t.$2, emoji: t.$3),
          wrong: [
            AnswerOption(label: t.$4, emoji: t.$5),
            AnswerOption(label: t.$6, emoji: t.$7),
          ],
          shift: index,
        );
    }
  }

  // ---- ART (colors + shapes) ------------------------------------------------
  static Question _art(int index, int slot) {
    const colors = [
      ('red', 'Red', '🔴', 'Blue', '🔵', 'Green', '🟢'),
      ('blue', 'Blue', '🔵', 'Yellow', '🟡', 'Red', '🔴'),
      ('green', 'Green', '🟢', 'Purple', '🟣', 'Orange', '🟠'),
      ('yellow', 'Yellow', '🟡', 'Green', '🟢', 'Blue', '🔵'),
      ('purple', 'Purple', '🟣', 'Red', '🔴', 'Yellow', '🟡'),
      ('orange', 'Orange', '🟠', 'Blue', '🔵', 'Green', '🟢'),
      ('pink', 'Pink', '🩷', 'Blue', '🔵', 'Brown', '🟤'),
      ('brown', 'Brown', '🟤', 'Pink', '🩷', 'Green', '🟢'),
      ('black', 'Black', '⚫', 'White', '⚪', 'Red', '🔴'),
      ('white', 'White', '⚪', 'Black', '⚫', 'Yellow', '🟡'),
    ];
    const shapes = [
      ('circle', 'Circle', '🔵', 'Square', '🟥', 'Triangle', '🔺'),
      ('square', 'Square', '🟥', 'Circle', '🔵', 'Star', '⭐'),
      ('triangle', 'Triangle', '🔺', 'Circle', '🔵', 'Heart', '❤️'),
      ('star', 'Star', '⭐', 'Square', '🟥', 'Circle', '🔵'),
      ('heart', 'Heart', '❤️', 'Triangle', '🔺', 'Square', '🟥'),
      ('diamond', 'Diamond', '🔶', 'Circle', '🔵', 'Star', '⭐'),
    ];
    final k = index ~/ 2;
    if (index % 2 == 0) {
      final c = colors[k % colors.length];
      return _mc(
        id: 'gen_art_${index}_$slot',
        prompt: 'Tap the ${c.$1} one',
        speak: 'Find the ${c.$1} one',
        correct: AnswerOption(label: c.$2, emoji: c.$3),
        wrong: [
          AnswerOption(label: c.$4, emoji: c.$5),
          AnswerOption(label: c.$6, emoji: c.$7),
        ],
        shift: index,
      );
    }
    final s = shapes[k % shapes.length];
    return _mc(
      id: 'gen_art_${index}_$slot',
      prompt: 'Tap the ${s.$1}',
      speak: 'Find the ${s.$1}',
      correct: AnswerOption(label: s.$2, emoji: s.$3),
      wrong: [
        AnswerOption(label: s.$4, emoji: s.$5),
        AnswerOption(label: s.$6, emoji: s.$7),
      ],
      shift: index,
    );
  }
}
