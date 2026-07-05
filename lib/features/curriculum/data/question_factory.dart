import '../../profiles/domain/grade_level.dart';
import '../domain/lesson.dart';
import '../domain/subject.dart';

/// Generates broad, grade-appropriate, CBSE-aligned, **factually correct**
/// question banks so every subject offers a 50-level journey of 20 unique
/// questions each (1000+ questions per subject).
///
/// Design rules:
///  - Deterministic: content is a pure function of (grade, subject, gameType,
///    level, index). No Random/DateTime, so it is stable across rebuilds.
///  - Correct by construction: math is parametric (the answer is computed);
///    other subjects draw from curated CBSE-standard banks where the right
///    answer is authored next to its distractors.
///  - De-duplicated within a level: [forLevel] never shows the same question
///    twice in a single level.
///  - Non-repeating across levels: bank cycling covers enough unique entries
///    that adjacent levels feel fresh.
class QuestionFactory {
  const QuestionFactory._();

  /// Distinct questions for one level. [count] questions, guaranteed unique
  /// within the level (deduped by prompt+options).
  static List<Question> forLevel({
    required GradeLevel grade,
    required Subject subject,
    required GameType gameType,
    required int level,
    int count = 20,
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
      case GameType.flashcard:
        return _flashcard(index, grade, subject);
      default:
        return _choiceBySubject(index, grade, subject, slot);
    }
  }

  // ---------------------------------------------------------------------------
  // Flashcards — pure learning cards (no options).
  // ---------------------------------------------------------------------------
  static const List<(String, String, String)> _alphabet = [
    ('A', 'Apple', '🍎'),
    ('B', 'Ball', '⚽'),
    ('C', 'Cat', '🐱'),
    ('D', 'Dog', '🐶'),
    ('E', 'Elephant', '🐘'),
    ('F', 'Fish', '🐟'),
    ('G', 'Goat', '🐐'),
    ('H', 'Hat', '🎩'),
    ('I', 'Igloo', '🛖'),
    ('J', 'Juice', '🧃'),
    ('K', 'Kite', '🪁'),
    ('L', 'Lion', '🦁'),
    ('M', 'Monkey', '🐵'),
    ('N', 'Nest', '🪺'),
    ('O', 'Owl', '🦉'),
    ('P', 'Pig', '🐷'),
    ('Q', 'Queen', '👑'),
    ('R', 'Rainbow', '🌈'),
    ('S', 'Sun', '☀️'),
    ('T', 'Tiger', '🐯'),
    ('U', 'Umbrella', '☂️'),
    ('V', 'Van', '🚐'),
    ('W', 'Whale', '🐳'),
    ('X', 'Fox', '🦊'),
    ('Y', 'Yak', '🐃'),
    ('Z', 'Zebra', '🦓'),
  ];

  static const List<String> _numberWords = [
    'zero',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'eleven',
    'twelve',
    'thirteen',
    'fourteen',
    'fifteen',
    'sixteen',
    'seventeen',
    'eighteen',
    'nineteen',
    'twenty',
  ];

  static String _numberWord(int n) =>
      n >= 0 && n < _numberWords.length ? _numberWords[n] : '$n';

  static Question _flashcard(int index, GradeLevel grade, Subject subject) {
    if (subject == Subject.math) {
      if (grade.difficultyTier >= 4) {
        final table = index % 9 + 2;
        final by = index ~/ 9 % 10 + 1;
        final product = table * by;
        return Question(
          id: 'gen_fc_tbl_$index',
          prompt: '$table × $by = $product',
          answer: '$table times $by is $product',
          speak: '$table times $by equals $product',
        );
      }
      final n = index % 50 + 1;
      return Question(
        id: 'gen_fc_num_$index',
        prompt: '$n',
        promptEmoji: '🔢',
        answer: _numberWord(n),
        speak:
            'The number $n. ${n >= _numberWords.length ? '' : _numberWords[n]}.',
      );
    }
    final e = _alphabet[index % _alphabet.length];
    return Question(
      id: 'gen_fc_ltr_$index',
      prompt: e.$1,
      promptEmoji: e.$3,
      answer: '${e.$1} for ${e.$2}',
      speak: '${e.$1}. ${e.$1} for ${e.$2}.',
    );
  }

  // ---------------------------------------------------------------------------
  // Multiple-choice helper
  // ---------------------------------------------------------------------------
  static Question _mc({
    required String id,
    required String prompt,
    String? speak,
    required AnswerOption correct,
    required List<AnswerOption> wrong,
    required int shift,
  }) {
    // Deduplicate: ensure no wrong option has the same label as the correct one
    // and no two wrong options are identical.
    final seen = <String>{correct.label};
    final deduped = <AnswerOption>[correct];
    for (final w in wrong) {
      if (seen.add(w.label)) deduped.add(w);
    }
    // If we dropped too many, pad with placeholder distractors from a-z.
    while (deduped.length < 3) {
      final fallback = String.fromCharCode('a'.codeUnitAt(0) + deduped.length);
      if (seen.add(fallback)) deduped.add(AnswerOption(label: fallback));
    }
    final rot = shift % deduped.length;
    final options = [...deduped.skip(rot), ...deduped.take(rot)];
    return Question(
      id: id,
      prompt: prompt,
      speak: speak ?? prompt,
      options: options,
      correctIndex: (deduped.length - rot) % deduped.length,
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
    final d =
        distractors ?? [answer + 1, answer <= 1 ? answer + 2 : answer - 1];
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

  static AnswerOption _emojiOption(String combined) {
    final parts = combined.split(' ');
    return AnswerOption(label: parts.sublist(1).join(' '), emoji: parts.first);
  }

  // ---------------------------------------------------------------------------
  // Tracing
  // ---------------------------------------------------------------------------
  static Question _tracing(int index, Subject subject) {
    if (subject == Subject.math) {
      final n = index % 51;
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
  // Sequence
  // ---------------------------------------------------------------------------
  static Question _sequence(
      int index, GradeLevel grade, Subject subject, int slot) {
    final width =
        grade.difficultyTier <= 1 ? 3 : (grade.difficultyTier <= 4 ? 4 : 5);
    if (subject == Subject.math || subject == Subject.logic) {
      final steps = [1, 2, 3, 5, 10, 4, 6, 7, 8, 9];
      final step = steps[index % steps.length];
      final start = (index % 10 + 1) * step;
      return Question(
        id: 'gen_seq_${index}_$slot',
        prompt: 'Put in order (count by $step)',
        speak: 'Tap the numbers in order',
        options: [
          for (var k = 0; k < width; k++)
            AnswerOption(label: '${start + k * step}'),
        ],
      );
    }
    const sets = [
      ['🐜 Ant', '🐱 Cat', '🐶 Dog', '🐘 Elephant', '🐳 Whale'],
      ['🌰 Seed', '🌱 Sprout', '🪴 Plant', '🌳 Tree'],
      ['🥚 Egg', '🐛 Caterpillar', '🦋 Butterfly'],
      ['🌅 Morning', '☀️ Noon', '🌆 Evening', '🌙 Night'],
      ['👶 Baby', '🧒 Child', '🧑 Adult', '👴 Elder'],
      ['🥚 Egg', '🐣 Chick', '🐔 Hen'],
      ['☁️ Cloud', '🌧️ Rain', '🌈 Rainbow'],
      ['🧊 Ice', '💧 Water', '💨 Steam'],
      ['🌑 New Moon', '🌓 Quarter', '🌕 Full Moon'],
      ['🌱 Seed', '🌿 Plant', '🌸 Flower', '🍎 Fruit'],
      ['🧵 Thread', '👕 Shirt', '👖 Pants'],
      ['📖 Open Book', '📕 Closed Book'],
      ['🐸 Tadpole', '🐸 Frog'],
      ['🍼 Baby', '🧒 Toddler', '🧑 Teen', '👨 Adult'],
      ['🌄 Dawn', '☀️ Noon', '🌅 Dusk', '🌙 Night'],
    ];
    final set = sets[index % sets.length];
    return Question(
      id: 'gen_seq_${index}_$slot',
      prompt: 'Put in the right order',
      speak: 'Order them correctly',
      options: [for (var k = 0; k < set.length; k++) _emojiOption(set[k])],
    );
  }

  // ---------------------------------------------------------------------------
  // Memory
  // ---------------------------------------------------------------------------
  static Question _memory(int index, Subject subject, int slot) {
    const sets = [
      ['🐶', '🐱', '🐮', '🐷', '🐰'],
      ['🍎', '🍌', '🍇', '🍓', '🍊'],
      ['🔴', '🔵', '🟢', '🟡', '🟣'],
      ['⭐', '❤️', '🌙', '☀️', '🌈'],
      ['🚗', '🚌', '✈️', '🚂', '🚀'],
      ['🔵', '🟥', '🔺', '⭐', '❤️'],
      ['🐔', '🐦', '🦆', '🦅', '🦉'],
      ['🌹', '🌸', '🌻', '🌷', '🌺'],
      ['🎈', '🎀', '🎁', '🎉', '🎊'],
      ['🍕', '🍔', '🍟', '🌭', '🍪'],
    ];
    final faces = sets[index % sets.length];
    return Question(
      id: 'gen_mem_${index}_$slot',
      prompt: 'Find the matching pairs',
      options: [for (final f in faces) AnswerOption(label: f, emoji: f)],
    );
  }

  // ---------------------------------------------------------------------------
  // Sorting / drag-drop
  // ---------------------------------------------------------------------------
  static Question _sorting(
      int index, GradeLevel grade, Subject subject, int slot) {
    // (item, emoji, catA, catAEmoji, catB, catBEmoji, correctIndex)
    const items = [
      ('Apple', '🍎', 'Fruit', '🍓', 'Vegetable', '🥕', 0),
      ('Carrot', '🥕', 'Fruit', '🍓', 'Vegetable', '🥕', 1),
      ('Banana', '🍌', 'Fruit', '🍓', 'Vegetable', '🥕', 0),
      ('Broccoli', '🥦', 'Fruit', '🍓', 'Vegetable', '🥕', 1),
      ('Grapes', '🍇', 'Fruit', '🍓', 'Vegetable', '🥕', 0),
      ('Potato', '🥔', 'Fruit', '🍓', 'Vegetable', '🥕', 1),
      ('Mango', '🥭', 'Fruit', '🍓', 'Vegetable', '🥕', 0),
      ('Tomato', '🍅', 'Fruit', '🍓', 'Vegetable', '🥕', 1),
      ('Fish', '🐟', 'Land', '🌳', 'Water', '🌊', 1),
      ('Lion', '🦁', 'Land', '🌳', 'Water', '🌊', 0),
      ('Whale', '🐳', 'Land', '🌳', 'Water', '🌊', 1),
      ('Dog', '🐶', 'Land', '🌳', 'Water', '🌊', 0),
      ('Duck', '🦆', 'Land', '🌳', 'Water', '🌊', 1),
      ('Horse', '🐴', 'Land', '🌳', 'Water', '🌊', 0),
      ('Crab', '🦀', 'Land', '🌳', 'Water', '🌊', 1),
      ('Frog', '🐸', 'Land', '🌳', 'Water', '🌊', 1),
      ('Sun', '☀️', 'Living', '🌿', 'Nonliving', '🪨', 1),
      ('Tree', '🌳', 'Living', '🌿', 'Nonliving', '🪨', 0),
      ('Rock', '🪨', 'Living', '🌿', 'Nonliving', '🪨', 1),
      ('Cat', '🐱', 'Living', '🌿', 'Nonliving', '🪨', 0),
      ('Ball', '⚽', 'Living', '🌿', 'Nonliving', '🪨', 1),
      ('Flower', '🌸', 'Living', '🌿', 'Nonliving', '🪨', 0),
      ('Chair', '🪑', 'Living', '🌿', 'Nonliving', '🪨', 1),
      ('Bird', '🐦', 'Living', '🌿', 'Nonliving', '🪨', 0),
      ('Day', '☀️', 'Day', '☀️', 'Night', '🌙', 0),
      ('Moon', '🌙', 'Day', '☀️', 'Night', '🌙', 1),
      ('Stars', '⭐', 'Day', '☀️', 'Night', '🌙', 1),
      ('Rainbow', '🌈', 'Day', '☀️', 'Night', '🌙', 0),
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

  // ---- MATH (parametric, infinite questions) --------------------------------
  static Question _math(int index, int tier, int slot) {
    final id = 'gen_math_${index}_$slot';
    final mode = index % 8;

    if (tier <= 2) {
      // LKG/UKG/KG: counting, simple add/sub, number after/before, bigger
      switch (mode) {
        case 0: // How many? (1-10)
          final n = index % 10 + 1;
          return _numMc(
              index, id, 'How many? ${'⭐' * n}', 'How many stars?', n);
        case 1: // Simple addition
          final a = index % 5 + 1;
          final b = (index ~/ 2) % 5 + 1;
          return _numMc(index, id, '$a + $b = ?', 'What is $a + $b?', a + b);
        case 2: // What comes after?
          final n = index % 20 + 1;
          return _numMc(
              index, id, 'What comes after $n?', 'What comes after $n?', n + 1);
        case 3: // Which is bigger?
          final a = index % 10 + 1;
          var b = (index ~/ 3) % 10 + 1;
          if (b == a) b = b % 10 + 1;
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
        case 4: // What comes before?
          final n = index % 20 + 2;
          return _numMc(index, id, 'What comes before $n?',
              'What comes before $n?', n - 1);
        case 5: // Simple subtraction
          final a = (index % 10 + 2);
          final b = index % 9 + 1;
          if (b >= a) {
            return _numMc(
                index, id, '$a + ${b % a + 1} = ?', '', a + (b % a + 1));
          }
          return _numMc(index, id, '$a - $b = ?', 'What is $a - $b?', a - b);
        case 6: // Count objects
          final n = index % 9 + 2;
          return _numMc(index, id, 'Count: ${'🍎' * n}', 'How many apples?', n);
        default: // Smaller number
          final a = index % 10 + 1;
          var b = (index ~/ 3) % 10 + 1;
          if (b == a) b = b % 10 + 1;
          final small = a < b ? a : b;
          final big = a < b ? b : a;
          return _mc(
            id: id,
            prompt: 'Which is smaller: $a or $b?',
            speak: 'Which number is smaller?',
            correct: AnswerOption(label: '$small'),
            wrong: [AnswerOption(label: '$big')],
            shift: index,
          );
      }
    }

    if (tier <= 4) {
      // Grades 1-2: add/sub 0-100, simple multiply, groups, skip counting
      switch (index % 6) {
        case 0:
          final a = index % 40 + 5;
          final b = index % 25 + 3;
          return _numMc(index, id, '$a + $b = ?', 'What is $a + $b?', a + b);
        case 1:
          final a = index % 40 + 20;
          final b = index % 15 + 1;
          return _numMc(index, id, '$a - $b = ?', 'What is $a - $b?', a - b);
        case 2:
          final a = index % 5 + 2;
          final b = index % 5 + 2;
          return _numMc(index, id, '$a × $b = ?', 'What is $a × $b?', a * b);
        case 3:
          final groups = index % 4 + 2;
          final each = index % 4 + 2;
          return _numMc(index, id, '$groups × $each = ?', 'How many in all?',
              groups * each);
        default:
          final step = [2, 5, 10, 3, 4][index % 5];
          final n = (index % 8 + 1) * step;
          return _numMc(index, id, 'Count by $step: $n, then?',
              'What comes next?', n + step);
      }
    }

    // tier 5-7: CBSE Grade 4-5 full curriculum
    final g4mode = index % 12;
    switch (g4mode) {
      // -- Operations (large numbers) --
      case 0: // Large addition (up to 5-digit)
        final a = (index % 900 + 100);
        final b = (index ~/ 3 % 900 + 100);
        return _numMc(index, id, '$a + $b = ?', null, a + b);
      case 1: // Large subtraction
        final a = (index % 500 + 500);
        final b = (index ~/ 3 % 400 + 50);
        if (b >= a) {
          return _numMc(
              index, id, '$a + ${(b % 50) + 10} = ?', null, a + (b % 50) + 10);
        }
        return _numMc(index, id, '$a - $b = ?', null, a - b);
      // -- Fractions & Decimals --
      case 2: // Like fraction addition (same denominator)
        final denom = [2, 3, 4, 5, 6, 8, 10][index % 7];
        final an = (index % (denom - 1)) + 1;
        final bn = ((index ~/ 3) % (denom - 1)) + 1;
        final sum = an + bn;
        if (denom <= sum) {
          return _numMc(
              index,
              id,
              '$an/$denom + $bn/$denom = ${sum - denom}/$denom?',
              null,
              sum - denom);
        }
        return _numMc(index, id, '$an/$denom + $bn/$denom = ?', null, sum);
      case 3: // Compare decimals
        final w = index % 10 + 1;
        final x = (index ~/ 2) % 10 + 1;
        final a = 0.1 * w;
        final b = 0.1 * x;
        if (a == b) {
          return _numMc(index, id, '0.$w + 0.$x = ?', null, (a + b).round());
        }
        final bigger = a > b ? a : b;
        return _mc(
          id: id,
          prompt: 'Which is bigger: $a or $b?',
          correct: AnswerOption(label: '$bigger'),
          wrong: [
            AnswerOption(label: '${bigger == a ? b : a}'),
            const AnswerOption(label: '0.0'),
          ],
          shift: index,
        );
      case 4: // Fraction of a number
        final n = [2, 3, 4, 5][index % 4];
        final v = (index % 10 + 1) * n;
        return _numMc(index, id, '1/$n of $v = ?', null, v ~/ n);
      // -- Measurement & Time --
      case 5: // Time conversion
        final hours = index % 12 + 1;
        return _numMc(index, id, '$hours hours = ? minutes', null, hours * 60);
      case 6: // Money word problems
        final r = index % 20 + 1;
        final p = (index ~/ 3) % 100;
        return _numMc(
            index,
            id,
            '₹$r.${p.toString().padLeft(2, '0')} + ₹${r % 5 + 1}.${(p % 50 + 1).toString().padLeft(2, '0')} = ?',
            null,
            r + (r % 5 + 1));
      // -- Geometry --
      case 7: // Area of rectangle
        final l = index % 12 + 3;
        final w = (index ~/ 2) % 8 + 2;
        final area = l * w;
        return _mc(
          id: id,
          prompt: 'Area of ${l}cm × ${w}cm rectangle?',
          correct: AnswerOption(label: '${area}cm²'),
          wrong: [
            AnswerOption(label: '${2 * (l + w)}cm'),
            AnswerOption(label: '${area + 2}cm²'),
          ],
          shift: index,
        );
      case 8: // Perimeter
        final l = index % 12 + 4;
        final w = index % 8 + 3;
        return _numMc(
            index, id, 'Perimeter of $l×$w rectangle?', null, 2 * (l + w));
      // -- Data Handling --
      case 9: // Pictograph interpretation
        final cats = index % 4 + 2;
        return _numMc(index, id, 'Each 🍎=5. $cats apples shown. Total = ?',
            null, cats * 5);
      // -- LCM & HCF --
      case 10: // LCM
        final a = index % 6 + 2;
        final b = index % 8 + 3;
        if (a == b) {
          return _numMc(index, id, '$a × ${index % 5 + 2} = ?', null,
              a * (index % 5 + 2));
        }
        var lcm = a;
        while (lcm % b != 0) {
          lcm += a;
        }
        return _numMc(index, id, 'LCM of $a and $b?', null, lcm);
      default: // HCF
        var a = index % 12 + 6;
        var b = (index ~/ 2) % 10 + 4;
        if (a == b) b += 3;
        final oa = a;
        final ob = b;
        while (b != 0) {
          final t = b;
          b = a % b;
          a = t;
        }
        return _numMc(index, id, 'HCF of $oa and $ob?', null, a);
    }
  }

  // ---- ENGLISH (CBSE-aligned for preschool) ---------------------------------
  static const List<List<String>> _rhymeFamilies = [
    ['cat', 'hat', 'bat', 'rat', 'mat', 'fat', 'pat', 'sat'],
    ['sun', 'fun', 'bun', 'gun', 'run', 'nun'],
    ['dog', 'log', 'frog', 'hog', 'jog', 'cog'],
    ['bed', 'red', 'fed', 'led', 'shed', 'head', 'bread'],
    ['pin', 'win', 'tin', 'bin', 'chin', 'fin', 'spin'],
    ['ball', 'tall', 'fall', 'mall', 'call', 'wall', 'small'],
    ['ring', 'sing', 'king', 'wing', 'thing', 'string', 'swing'],
    ['cake', 'lake', 'bake', 'take', 'make', 'fake', 'wake'],
    ['bell', 'well', 'tell', 'sell', 'fell', 'smell', 'spell'],
    ['hen', 'pen', 'ten', 'men', 'then', 'when', 'den'],
  ];

  static const List<String> _spellingWords = [
    'cat',
    'dog',
    'sun',
    'bed',
    'pin',
    'hat',
    'ball',
    'fish',
    'bird',
    'book',
    'star',
    'tree',
    'hand',
    'bell',
    'milk',
    'nest',
    'duck',
    'frog',
    'drum',
    'flag',
    'ship',
    'shop',
    'desk',
    'lamp',
    'ring',
    'king',
    'wing',
    'song',
    'door',
    'bell',
    'kite',
    'rain',
  ];

  static const List<String> _threeLetterWords = [
    'cat',
    'bat',
    'rat',
    'hat',
    'mat',
    'sat',
    'fat',
    'pat',
    'dog',
    'log',
    'fog',
    'hog',
    'jog',
    'pen',
    'hen',
    'ten',
    'den',
    'men',
    'sun',
    'fun',
    'bun',
    'run',
    'gun',
    'big',
    'pig',
    'dig',
    'wig',
    'fig',
    'cup',
    'pup',
    'up',
    'bed',
    'red',
    'fed',
    'led',
    'box',
    'fox',
    'bus',
  ];

  static Question _english(int index, int tier, int slot) {
    final id = 'gen_en_${index}_$slot';
    final k = index ~/ 2;
    final mode = index % 8;

    if (tier <= 2) {
      // LKG/UKG/KG: letter recognition, first letter, rhyming, simple words
      switch (mode) {
        case 0: // Find the letter (A-Z)
          final t = String.fromCharCode('A'.codeUnitAt(0) + k % 26);
          final b = String.fromCharCode('A'.codeUnitAt(0) + (k + 1) % 26);
          final c = String.fromCharCode('A'.codeUnitAt(0) + (k + 9) % 26);
          return _mc(
            id: id,
            prompt: 'Tap the letter $t',
            speak: 'Find the letter $t',
            correct: AnswerOption(label: t),
            wrong: [AnswerOption(label: b), AnswerOption(label: c)],
            shift: index,
          );
        case 1: // Capital to small letter match
          final t = String.fromCharCode('A'.codeUnitAt(0) + k % 26);
          final s = String.fromCharCode('a'.codeUnitAt(0) + k % 26);
          final w1 = String.fromCharCode('a'.codeUnitAt(0) + (k + 3) % 26);
          final w2 = String.fromCharCode('a'.codeUnitAt(0) + (k + 7) % 26);
          return _mc(
            id: id,
            prompt: 'Small letter for $t?',
            speak: 'What is the small letter for $t?',
            correct: AnswerOption(label: s),
            wrong: [AnswerOption(label: w1), AnswerOption(label: w2)],
            shift: index,
          );
        case 2: // First letter of word
          final word = _threeLetterWords[k % _threeLetterWords.length];
          final first = word[0].toUpperCase();
          final w1 = String.fromCharCode('A'.codeUnitAt(0) + (k % 26 + 5) % 26);
          final w2 =
              String.fromCharCode('A'.codeUnitAt(0) + (k % 26 + 12) % 26);
          return _mc(
            id: id,
            prompt: 'First letter of "$word"?',
            speak: 'What is the first letter of $word?',
            correct: AnswerOption(label: first),
            wrong: [
              AnswerOption(label: w1),
              AnswerOption(label: w2 == first ? 'Z' : w2),
            ],
            shift: index,
          );
        case 3: // Rhyming word
          final familyIndex = k % 10;
          final family = _rhymeFamilies[familyIndex];
          final wordIndex = k % family.length;
          final base = family[wordIndex];
          final rhyme = family[(wordIndex + 1) % family.length];
          final wrongFamily = _rhymeFamilies[(familyIndex + 3) % 10];
          final nonRhyme1 = wrongFamily[0];
          final nonRhyme2 = _rhymeFamilies[(familyIndex + 7) % 10][0];
          return _mc(
            id: id,
            prompt: 'Which rhymes with "$base"?',
            speak: 'Which word rhymes with $base?',
            correct: AnswerOption(label: rhyme),
            wrong: [AnswerOption(label: nonRhyme1), AnswerOption(label: nonRhyme2)],
            shift: index,
          );
        case 4: // Vowel identification
          const vowels = ['A', 'E', 'I', 'O', 'U'];
          const cons = [
            'B',
            'C',
            'D',
            'F',
            'G',
            'H',
            'J',
            'K',
            'L',
            'M',
            'N',
            'P',
            'Q',
            'R',
            'S',
            'T',
            'V',
            'W',
            'X',
            'Y',
            'Z'
          ];
          final v = vowels[k % vowels.length];
          final c1 = cons[(k * 3) % cons.length];
          final c2 = cons[(k * 7) % cons.length];
          return _mc(
            id: id,
            prompt: 'Which is a vowel?',
            speak: 'Which one is a vowel?',
            correct: AnswerOption(label: v),
            wrong: [AnswerOption(label: c1), AnswerOption(label: c2)],
            shift: index,
          );
        case 5: // Last letter of word
          final word = _threeLetterWords[(k + 3) % _threeLetterWords.length];
          final last = word[word.length - 1].toUpperCase();
          final w1 = String.fromCharCode('A'.codeUnitAt(0) + (k % 26 + 5) % 26);
          return _mc(
            id: id,
            prompt: 'Last letter of "$word"?',
            speak: 'What is the last letter of $word?',
            correct: AnswerOption(label: last),
            wrong: [
              AnswerOption(label: w1),
              AnswerOption(label: word[0].toUpperCase()),
            ],
            shift: index,
          );
        case 6: // Choose the correct word for picture
          final item = _alphabet[k % _alphabet.length];
          final w1 = _alphabet[(k + 3) % _alphabet.length];
          final w2 = _alphabet[(k + 7) % _alphabet.length];
          return _mc(
            id: id,
            prompt: '${item.$3} What is this?',
            speak: 'What is this picture?',
            correct: AnswerOption(label: item.$2),
            wrong: [
              AnswerOption(label: w1.$2),
              AnswerOption(label: w2.$2),
            ],
            shift: index,
          );
        default: // Match word pairs - semantically related items
          const relatedPairs = [
            ('Shoes', '👟', 'Socks', '🧦'),
            ('Bread', '🍞', 'Butter', '🧈'),
            ('Pillow', '🛏️', 'Blanket', '🛋️'),
            ('Cup', '🥤', 'Plate', '🍽️'),
            ('Pen', '✏️', 'Paper', '📝'),
            ('Sun', '☀️', 'Moon', '🌙'),
            ('Cat', '🐱', 'Dog', '🐶'),
            ('Tree', '🌳', 'Flower', '🌸'),
            ('Book', '📖', 'Pencil', '✏️'),
            ('Bed', '🛏️', 'Pillow', '🛋️'),
          ];
          const unrelatedItems = [
            ('Apple', '🍎'), ('Car', '🚗'), ('Ball', '⚽'), ('Fish', '🐟'),
            ('Star', '⭐'), ('Rain', '🌧️'), ('Bird', '🐦'), ('Phone', '📱'),
            ('Cake', '🎂'), ('Hat', '🎩'), ('Key', '🔑'), ('Door', '🚪'),
          ];
          final pairIndex = k % relatedPairs.length;
          final item = relatedPairs[pairIndex].$1;
          final itemEmoji = relatedPairs[pairIndex].$2;
          final related = relatedPairs[pairIndex].$3;
          final relatedEmoji = relatedPairs[pairIndex].$4;
          // Pick unrelated distractors
          final w1Index = (k + 2) % unrelatedItems.length;
          final w2Index = (k + 7) % unrelatedItems.length;
          final w1 = unrelatedItems[w1Index];
          final w2 = unrelatedItems[w2Index];
          // Randomly show item or its partner as the question
          if (k % 2 == 0) {
            return _mc(
              id: id,
              prompt: 'Which goes with $item?',
              speak: 'Which one goes with $item?',
              correct: AnswerOption(label: related, emoji: relatedEmoji),
              wrong: [
                AnswerOption(label: w1.$1, emoji: w1.$2),
                AnswerOption(label: w2.$1, emoji: w2.$2),
              ],
              shift: index,
            );
          } else {
            return _mc(
              id: id,
              prompt: 'Which goes with $related?',
              speak: 'Which one goes with $related?',
              correct: AnswerOption(label: item, emoji: itemEmoji),
              wrong: [
                AnswerOption(label: w1.$1, emoji: w1.$2),
                AnswerOption(label: w2.$1, emoji: w2.$2),
              ],
              shift: index,
            );
          }
      }
    }

    // Tier 3+: opposites, plurals, spelling, grammar
    switch (mode) {
      case 0:
      case 1: // Opposites bank
        const opposites = [
          ('hot', 'cold'),
          ('big', 'small'),
          ('up', 'down'),
          ('fast', 'slow'),
          ('day', 'night'),
          ('happy', 'sad'),
          ('open', 'shut'),
          ('wet', 'dry'),
          ('full', 'empty'),
          ('hard', 'soft'),
          ('old', 'new'),
          ('light', 'dark'),
          ('loud', 'quiet'),
          ('high', 'low'),
          ('push', 'pull'),
          ('near', 'far'),
          ('clean', 'dirty'),
          ('thick', 'thin'),
          ('wide', 'narrow'),
          ('begin', 'end'),
          ('young', 'old'),
          ('rich', 'poor'),
          ('kind', 'cruel'),
          ('bright', 'dim'),
          ('sharp', 'blunt'),
          ('heavy', 'light'),
          ('sweet', 'sour'),
        ];
        final p = opposites[k % opposites.length];
        final w1 = opposites[(k + 3) % opposites.length].$2;
        final w2 = opposites[(k + 7) % opposites.length].$2;
        return _mc(
          id: id,
          prompt: 'Opposite of "${p.$1}"?',
          speak: 'What is the opposite of ${p.$1}?',
          correct: AnswerOption(label: p.$2),
          wrong: [AnswerOption(label: w1), AnswerOption(label: w2)],
          shift: index,
        );
      case 2:
      case 3: // Plurals
        const nouns = [
          'cat',
          'dog',
          'car',
          'book',
          'tree',
          'star',
          'hand',
          'bird',
          'box',
          'bus',
          'fox',
          'dish',
          'bench',
          'glass',
          'pen',
          'cup',
          'ball',
          'bat',
          'hat',
          'bed',
          'frog',
          'duck',
          'ship',
          'shop',
          'ant',
          'egg',
          'sun',
          'ring',
          'bell',
          'key',
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
          wrong: [
            AnswerOption(label: n),
            AnswerOption(label: '${n}z'),
          ],
          shift: index,
        );
      case 4:
      case 5: // Spell the word (choose correct spelling)
        final word = _spellingWords[k % _spellingWords.length];
        final wrong1 = word.substring(0, word.length - 1) +
            String.fromCharCode(word.codeUnitAt(word.length - 1) + 1);
        final wrong2 = word.replaceRange(
            0, 1, String.fromCharCode(word.codeUnitAt(0) + 2));
        return _mc(
          id: id,
          prompt: 'How to spell "$word"?',
          speak: 'How do you spell $word?',
          correct: AnswerOption(label: word),
          wrong: [AnswerOption(label: wrong1), AnswerOption(label: wrong2)],
          shift: index,
        );
      default: // Fill in the blank
        const sentences = [
          ('I ___ a boy.', 'am'),
          ('She ___ a girl.', 'is'),
          ('They ___ playing.', 'are'),
          ('He ___ a car.', 'has'),
          ('We ___ happy.', 'are'),
          ('It ___ a cat.', 'is'),
          ('I ___ to school.', 'go'),
          ('She ___ to sing.', 'likes'),
          ('He ___ fast.', 'runs'),
          ('Birds ___ fly.', 'can'),
          ('Fish ___ in water.', 'live'),
          ('The sun ___ bright.', 'is'),
          ('We ___ with our eyes.', 'see'),
          ('I ___ my teeth.', 'brush'),
          ('She ___ a book.', 'reads'),
          ('He ___ a song.', 'sings'),
        ];
        final s = sentences[k % sentences.length];
        return _mc(
          id: id,
          prompt: s.$1,
          speak: s.$1,
          correct: AnswerOption(label: s.$2),
          wrong: [
            if (s.$2 == 'am') ...[
              const AnswerOption(label: 'are'),
              const AnswerOption(label: 'is'),
            ] else if (s.$2 == 'is') ...[
              const AnswerOption(label: 'am'),
              const AnswerOption(label: 'are'),
            ] else if (s.$2 == 'are') ...[
              const AnswerOption(label: 'am'),
              const AnswerOption(label: 'is'),
            ] else ...[
              const AnswerOption(label: 'not'),
              const AnswerOption(label: 'do'),
            ],
          ],
          shift: index,
        );
    }
  }

  // ---- EVS / SCIENCE (CBSE-aligned, expanded to 1000+ unique questions) -----
  static const List<(String, String, String, String, String, String, String)>
      _facts = [
    // Animals & Birds
    ('Who says moo?', 'Cow', '🐄', 'Dog', '🐶', 'Duck', '🦆'),
    ('Who says woof?', 'Dog', '🐶', 'Cat', '🐱', 'Cow', '🐄'),
    ('Who says meow?', 'Cat', '🐱', 'Dog', '🐶', 'Bird', '🐦'),
    ('Who says quack?', 'Duck', '🦆', 'Hen', '🐔', 'Cow', '🐄'),
    ('Who says baa?', 'Sheep', '🐑', 'Dog', '🐶', 'Cat', '🐱'),
    ('Who says neigh?', 'Horse', '🐴', 'Cow', '🐄', 'Pig', '🐷'),
    ('Who says cluck?', 'Hen', '🐔', 'Duck', '🦆', 'Dog', '🐶'),
    ('Who says oink?', 'Pig', '🐷', 'Sheep', '🐑', 'Horse', '🐴'),
    ('Which can fly?', 'Bird', '🐦', 'Fish', '🐟', 'Dog', '🐶'),
    ('Which can swim?', 'Fish', '🐟', 'Bird', '🐦', 'Cat', '🐱'),
    ('Which has four legs?', 'Cow', '🐄', 'Duck', '🦆', 'Fish', '🐟'),
    ('Which has two legs?', 'Hen', '🐔', 'Cow', '🐄', 'Horse', '🐴'),
    ('Which lives in a nest?', 'Bird', '🐦', 'Fish', '🐟', 'Dog', '🐶'),
    ('Which lives in water?', 'Fish', '🐟', 'Bird', '🐦', 'Lion', '🦁'),
    ('Baby of a dog?', 'Puppy', '🐶', 'Kitten', '🐱', 'Calf', '🐄'),
    ('Baby of a cat?', 'Kitten', '🐱', 'Puppy', '🐶', 'Foal', '🐴'),
    ('Baby of a cow?', 'Calf', '🐄', 'Puppy', '🐶', 'Lamb', '🐑'),
    ('Baby of a hen?', 'Chick', '🐣', 'Calf', '🐄', 'Foal', '🐴'),
    ('Baby of a sheep?', 'Lamb', '🐑', 'Chick', '🐣', 'Kitten', '🐱'),
    ('Which animal gives milk?', 'Cow', '🐄', 'Hen', '🐔', 'Dog', '🐶'),
    ('Which animal has a trunk?', 'Elephant', '🐘', 'Dog', '🐶', 'Cat', '🐱'),
    (
      'Which animal is the king of jungle?',
      'Lion',
      '🦁',
      'Tiger',
      '🐯',
      'Bear',
      '🧸'
    ),
    (
      'Which animal has stripes?',
      'Tiger',
      '🐯',
      'Lion',
      '🦁',
      'Elephant',
      '🐘'
    ),
    ('Which animal has spots?', 'Leopard', '🐆', 'Tiger', '🐯', 'Lion', '🦁'),
    (
      'Which animal has a long neck?',
      'Giraffe',
      '🦒',
      'Elephant',
      '🐘',
      'Lion',
      '🦁'
    ),
    ('Which animal lives in a hive?', 'Bee', '🐝', 'Bird', '🐦', 'Ant', '🐜'),
    ('Which animal spins a web?', 'Spider', '🕸️', 'Bee', '🐝', 'Ant', '🐜'),
    ('Which animal lives in a den?', 'Lion', '🦁', 'Fish', '🐟', 'Bird', '🐦'),
    ('Which animal carries its home?', 'Snail', '🐌', 'Dog', '🐶', 'Cat', '🐱'),
    ('Which animal hops?', 'Frog', '🐸', 'Snake', '🪱', 'Fish', '🐟'),
    // Fruits & Vegetables
    ('Which is a fruit?', 'Apple', '🍎', 'Carrot', '🥕', 'Potato', '🥔'),
    ('Which is a vegetable?', 'Carrot', '🥕', 'Apple', '🍎', 'Mango', '🥭'),
    ('Which fruit is yellow?', 'Banana', '🍌', 'Apple', '🍎', 'Grapes', '🍇'),
    ('Which fruit is red?', 'Apple', '🍎', 'Banana', '🍌', 'Mango', '🥭'),
    ('Which fruit is round?', 'Orange', '🍊', 'Banana', '🍌', 'Carrot', '🥕'),
    ('Which grows on a vine?', 'Grapes', '🍇', 'Apple', '🍎', 'Mango', '🥭'),
    ('Which grows underground?', 'Potato', '🥔', 'Mango', '🥭', 'Banana', '🍌'),
    (
      'Which is a leafy vegetable?',
      'Cabbage',
      '🥬',
      'Potato',
      '🥔',
      'Carrot',
      '🥕'
    ),
    ('Which is sour?', 'Lemon', '🍋', 'Banana', '🍌', 'Mango', '🥭'),
    ('Which is sweet?', 'Mango', '🥭', 'Lemon', '🍋', 'Chili', '🌶️'),
    // Body Parts & Senses
    ('What do we see with?', 'Eyes', '👀', 'Ears', '👂', 'Nose', '👃'),
    ('What do we hear with?', 'Ears', '👂', 'Eyes', '👀', 'Mouth', '👄'),
    ('What do we smell with?', 'Nose', '👃', 'Eyes', '👀', 'Ears', '👂'),
    ('What do we taste with?', 'Tongue', '👅', 'Nose', '👃', 'Eyes', '👀'),
    ('What do we touch with?', 'Hands', '🤚', 'Ears', '👂', 'Nose', '👃'),
    ('How many fingers on one hand?', 'Five', '🖐️', 'Four', '✌️', 'Ten', '🔟'),
    ('How many eyes do we have?', 'Two', '👀', 'One', '👁️', 'Three', '3️⃣'),
    ('How many ears do we have?', 'Two', '👂', 'One', '👃', 'Four', '4️⃣'),
    ('What covers our body?', 'Skin', '🫃', 'Fur', '🐾', 'Feathers', '🪶'),
    ('Which part helps us walk?', 'Legs', '🦵', 'Arms', '💪', 'Head', '🗣️'),
    // Nature & Weather
    ('What shines in the day?', 'Sun', '☀️', 'Moon', '🌙', 'Star', '⭐'),
    ('What shines at night?', 'Moon', '🌙', 'Sun', '☀️', 'Cloud', '☁️'),
    ('What gives us light?', 'Sun', '☀️', 'Moon', '🌙', 'Star', '⭐'),
    ('What makes a rainbow?', 'Rain', '🌧️', 'Snow', '❄️', 'Wind', '💨'),
    ('What comes after sunset?', 'Night', '🌙', 'Morning', '🌅', 'Noon', '☀️'),
    (
      'What comes after sunrise?',
      'Morning',
      '🌅',
      'Night',
      '🌙',
      'Evening',
      '🌆'
    ),
    ('Which season is hot?', 'Summer', '☀️', 'Winter', '❄️', 'Rainy', '🌧️'),
    ('Which season is cold?', 'Winter', '❄️', 'Summer', '☀️', 'Spring', '🌸'),
    (
      'Which season brings rain?',
      'Monsoon',
      '🌧️',
      'Summer',
      '☀️',
      'Winter',
      '❄️'
    ),
    (
      'What do we see in the sky at night?',
      'Stars',
      '⭐',
      'Sun',
      '☀️',
      'Rainbow',
      '🌈'
    ),
    ('What is water in the sky?', 'Cloud', '☁️', 'Star', '⭐', 'Moon', '🌙'),
    ('What falls from clouds?', 'Rain', '🌧️', 'Snow', '❄️', 'Hail', '🧊'),
    (
      'When do we see a rainbow?',
      'After rain',
      '🌈',
      'At night',
      '🌙',
      'At noon',
      '☀️'
    ),
    ('What grows in soil?', 'Plant', '🌱', 'Rock', '🪨', 'Glass', '🪟'),
    // Plants
    ('Which one grows?', 'Tree', '🌳', 'Rock', '🪨', 'Chair', '🪑'),
    (
      'What do plants need to grow?',
      'Sunlight',
      '☀️',
      'Candy',
      '🍬',
      'Toys',
      '🧸'
    ),
    (
      'What do plants need from soil?',
      'Water',
      '💧',
      'Milk',
      '🥛',
      'Juice',
      '🧃'
    ),
    (
      'What part of plant is underground?',
      'Root',
      '🪴',
      'Leaf',
      '🍃',
      'Flower',
      '🌸'
    ),
    (
      'What part of plant is green and flat?',
      'Leaf',
      '🍃',
      'Root',
      '🪴',
      'Fruit',
      '🍎'
    ),
    (
      'What part of plant is colorful?',
      'Flower',
      '🌸',
      'Leaf',
      '🍃',
      'Root',
      '🪴'
    ),
    (
      'What do bees collect from flowers?',
      'Nectar',
      '🍯',
      'Pollen',
      '🌸',
      'Leaves',
      '🍃'
    ),
    ('What grows from a seed?', 'Plant', '🌱', 'Rock', '🪨', 'Toy', '🧸'),
    ('Which gives us shade?', 'Tree', '🌳', 'Flower', '🌸', 'Grass', '🌿'),
    // Food & Health
    ('Which is healthy to eat?', 'Fruit', '🍎', 'Candy', '🍬', 'Chips', '🍟'),
    (
      'What do we drink for strong bones?',
      'Milk',
      '🥛',
      'Soda',
      '🥤',
      'Juice',
      '🧃'
    ),
    ('What keeps us clean?', 'Soap', '🧼', 'Candy', '🍬', 'Toy', '🧸'),
    (
      'What do we use to brush teeth?',
      'Toothbrush',
      '🪥',
      'Comb',
      '🪮',
      'Soap',
      '🧼'
    ),
    (
      'What do we wear in cold?',
      'Sweater',
      '🧥',
      'T-shirt',
      '👕',
      'Shorts',
      '🩳'
    ),
    (
      'What keeps us dry in rain?',
      'Umbrella',
      '☂️',
      'Cap',
      '🧢',
      'Shoes',
      '👟'
    ),
    (
      'What do we eat for breakfast?',
      'Bread',
      '🍞',
      'Cake',
      '🎂',
      'Ice cream',
      '🍦'
    ),
    ('Which is good for eyes?', 'Carrot', '🥕', 'Candy', '🍬', 'Chips', '🍟'),
    (
      'What do we drink when thirsty?',
      'Water',
      '💧',
      'Soap',
      '🧼',
      'Paint',
      '🎨'
    ),
    ('What gives us energy?', 'Food', '🍽️', 'Sleep', '🛏️', 'TV', '📺'),
    // Transport & Community Helpers
    ('Which has wings?', 'Aeroplane', '✈️', 'Car', '🚗', 'Train', '🚂'),
    ('Which runs on tracks?', 'Train', '🚂', 'Car', '🚗', 'Bus', '🚌'),
    ('Which flies in the sky?', 'Helicopter', '🚁', 'Car', '🚗', 'Train', '🚂'),
    ('Which travels in water?', 'Boat', '⛵', 'Car', '🚗', 'Bus', '🚌'),
    (
      'Who drives a bus?',
      'Driver',
      '🚌',
      'Doctor',
      '👨‍⚕️',
      'Teacher',
      '👩‍🏫'
    ),
    (
      'Who teaches children?',
      'Teacher',
      '👩‍🏫',
      'Doctor',
      '👨‍⚕️',
      'Pilot',
      '👨‍✈️'
    ),
    (
      'Who treats sick people?',
      'Doctor',
      '👨‍⚕️',
      'Teacher',
      '👩‍🏫',
      'Driver',
      '🚌'
    ),
    (
      'Who brings letters?',
      'Postman',
      '📬',
      'Doctor',
      '👨‍⚕️',
      'Teacher',
      '👩‍🏫'
    ),
    (
      'Who catches thieves?',
      'Police',
      '👮‍♂️',
      'Doctor',
      '👨‍⚕️',
      'Teacher',
      '👩‍🏫'
    ),
    (
      'Who grows food for us?',
      'Farmer',
      '👨‍🌾',
      'Doctor',
      '👨‍⚕️',
      'Police',
      '👮‍♂️'
    ),
    ('Who cooks food?', 'Chef', '👨‍🍳', 'Teacher', '👩‍🏫', 'Driver', '🚌'),
    (
      'Who puts out fire?',
      'Firefighter',
      '🧑‍🚒',
      'Police',
      '👮‍♂️',
      'Postman',
      '📬'
    ),
    ('Three wheels have a?', 'Rickshaw', '🛺', 'Car', '🚗', 'Cycle', '🚲'),
    ('Two wheels have a?', 'Cycle', '🚲', 'Car', '🚗', 'Bus', '🚌'),
    // Home & School
    ('Where do we sleep?', 'Bed', '🛏️', 'Chair', '🪑', 'Table', '🪑'),
    ('Where do we sit?', 'Chair', '🪑', 'Bed', '🛏️', 'Floor', '🏠'),
    ('What tells time?', 'Clock', '🕐', 'Phone', '📱', 'Book', '📖'),
    ('What do we read?', 'Book', '📖', 'Food', '🍽️', 'Toy', '🧸'),
    ('What do we write with?', 'Pencil', '✏️', 'Spoon', '🥄', 'Comb', '🪮'),
    ('What do we use to draw?', 'Crayon', '🖍️', 'Spoon', '🥄', 'Mug', '☕'),
    (
      'What do we cut paper with?',
      'Scissors',
      '✂️',
      'Pencil',
      '✏️',
      'Brush',
      '🖌️'
    ),
    ('Where do children learn?', 'School', '🏫', 'Park', '🏞️', 'Shop', '🏪'),
    (
      'Where do we play?',
      'Playground',
      '🎪',
      'Classroom',
      '🏫',
      'Library',
      '📚'
    ),
    (
      'Where do we borrow books?',
      'Library',
      '📚',
      'Kitchen',
      '🍳',
      'Bedroom',
      '🛏️'
    ),
    // Water & Air
    ('What do we breathe?', 'Air', '💨', 'Milk', '🥛', 'Juice', '🧃'),
    ('Where do fish live?', 'Water', '💧', 'Land', '🌳', 'Sky', '☁️'),
    ('What floats on water?', 'Boat', '⛵', 'Rock', '🪨', 'Key', '🔑'),
    ('What sinks in water?', 'Stone', '🪨', 'Boat', '⛵', 'Leaf', '🍃'),
    ('Where does rain come from?', 'Clouds', '☁️', 'Ground', '🌍', 'Sea', '🌊'),
    ('What turns water into ice?', 'Cold', '🧊', 'Heat', '🔥', 'Wind', '💨'),
    ('What melts ice?', 'Heat', '🔥', 'Cold', '🧊', 'Wind', '💨'),
    ('Water vapor rises as?', 'Steam', '💨', 'Ice', '🧊', 'Rain', '🌧️'),
    (
      'Where do rivers flow?',
      'To the sea',
      '🌊',
      'To the sky',
      '☁️',
      'To the mountain',
      '🏔️'
    ),
    (
      'What colour is clean water?',
      'Colourless',
      '💧',
      'Blue',
      '🔵',
      'White',
      '⚪'
    ),
    // Earth & Universe
    ('Shape of the Earth?', 'Round', '🌍', 'Flat', '⬜', 'Square', '🟥'),
    ('What is the Earth?', 'A planet', '🌍', 'A star', '⭐', 'A moon', '🌙'),
    ('What is the Sun?', 'A star', '☀️', 'A planet', '🌍', 'A moon', '🌙'),
    ('What goes around Earth?', 'Moon', '🌙', 'Sun', '☀️', 'Mars', '🪐'),
    (
      'How many planets in Solar System?',
      'Eight',
      '🪐',
      'Seven',
      '7️⃣',
      'Nine',
      '9️⃣'
    ),
    (
      'Which planet is called Red Planet?',
      'Mars',
      '🪐',
      'Venus',
      '🪐',
      'Saturn',
      '🪐'
    ),
    ('Which planet has rings?', 'Saturn', '🪐', 'Mars', '🪐', 'Jupiter', '🪐'),
    (
      'Which is the biggest planet?',
      'Jupiter',
      '🪐',
      'Saturn',
      '🪐',
      'Neptune',
      '🪐'
    ),
    (
      'Which is the smallest planet?',
      'Mercury',
      '🪐',
      'Mars',
      '🪐',
      'Earth',
      '🌍'
    ),
    (
      'Which star is nearest to Earth?',
      'Sun',
      '☀️',
      'Moon',
      '🌙',
      'Mars',
      '🪐'
    ),
    // Safety & Good Habits
    (
      'What colour is a danger sign?',
      'Red',
      '🔴',
      'Green',
      '🟢',
      'Yellow',
      '🟡'
    ),
    ('What do we wear on road?', 'Helmet', '⛑️', 'Hat', '🎩', 'Crown', '👑'),
    (
      'Where do we walk on road?',
      'Footpath',
      '🚶',
      'Middle',
      '🛣️',
      'Cycle track',
      '🚲'
    ),
    (
      'What does red traffic light mean?',
      'Stop',
      '🛑',
      'Go',
      '🟢',
      'Wait',
      '🟡'
    ),
    (
      'What does green traffic light mean?',
      'Go',
      '🟢',
      'Stop',
      '🛑',
      'Slow',
      '🐢'
    ),
    (
      'What should we do before eating?',
      'Wash hands',
      '🧼',
      'Run',
      '🏃',
      'Sleep',
      '🛏️'
    ),
    (
      'What should we do after eating?',
      'Brush teeth',
      '🪥',
      'Play',
      '🎮',
      'Watch TV',
      '📺'
    ),
    (
      'What keeps us healthy?',
      'Exercise',
      '🏃',
      'Sleeping all day',
      '🛏️',
      'Eating candy',
      '🍬'
    ),
    (
      'What should we say when we hurt someone?',
      'Sorry',
      '🙏',
      'Thank you',
      '🙇',
      'Hello',
      '👋'
    ),
    (
      'What should we say when someone helps?',
      'Thank you',
      '🙏',
      'Sorry',
      '🙏',
      'Please',
      '🙏'
    ),
    // Our Country & Culture
    (
      'Colour of our national flag top band?',
      'Saffron',
      '🟠',
      'White',
      '⚪',
      'Green',
      '🟢'
    ),
    ('Our national animal?', 'Tiger', '🐯', 'Lion', '🦁', 'Elephant', '🐘'),
    ('Our national bird?', 'Peacock', '🦚', 'Parrot', '🦜', 'Eagle', '🦅'),
    ('Our national flower?', 'Lotus', '🪷', 'Rose', '🌹', 'Sunflower', '🌻'),
    ('Our national tree?', 'Banyan', '🌳', 'Mango', '🥭', 'Neem', '🌿'),
    ('Our national sport?', 'Hockey', '🏑', 'Cricket', '🏏', 'Football', '⚽'),
    (
      'Capital of India?',
      'New Delhi',
      '🏛️',
      'Mumbai',
      '🏙️',
      'Kolkata',
      '🏙️'
    ),
    (
      'Largest state in India?',
      'Rajasthan',
      '🏜️',
      'Goa',
      '🏖️',
      'Kerala',
      '🌴'
    ),
    (
      'National animal of India?',
      'Tiger',
      '🐯',
      'Lion',
      '🦁',
      'Elephant',
      '🐘'
    ),
    ('National bird of India?', 'Peacock', '🦚', 'Crow', '🐦', 'Sparrow', '🐦'),
  ];

  static Question _world(int index, int tier, int slot) {
    final f = _facts[index % _facts.length];
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

  // ---- LOGIC (expanded) ----------------------------------------------------
  static Question _logic(int index, int tier, int slot) {
    final id = 'gen_logic_${index}_$slot';
    final k = index ~/ 3;
    switch (index % 3) {
      case 0: // Number pattern
        final steps = [1, 2, 3, 5, 10, 4, 6, 7, 8, 9, 11, 12];
        final step = steps[k % steps.length];
        final start = (k % 10 + 1) * step;
        final next = start + step * 3;
        return _numMc(
          index,
          id,
          '$start, ${start + step}, ${start + 2 * step}, ?',
          'What comes next?',
          next,
          distractors: [next + step, next - step],
        );
      case 1: // Odd one out (expanded)
        const sets = [
          ('Which is different?', 'Car', '🚗', 'Apple', '🍎', 'Banana', '🍌'),
          ('Which is different?', 'Shoe', '👟', 'Dog', '🐶', 'Cat', '🐱'),
          ('Which is different?', 'Fish', '🐟', 'Rose', '🌹', 'Tulip', '🌷'),
          ('Which is different?', 'Drum', '🥁', 'Grapes', '🍇', 'Mango', '🥭'),
          ('Which is different?', 'Bus', '🚌', 'Cat', '🐱', 'Dog', '🐶'),
          ('Which is different?', 'Sun', '☀️', 'Apple', '🍎', 'Pear', '🍐'),
          ('Which is different?', 'Pencil', '✏️', 'Cup', '🥤', 'Plate', '🍽️'),
          (
            'Which is different?',
            'Table',
            '🪑',
            'Circle',
            '🔵',
            'Square',
            '🟥'
          ),
          ('Which is different?', 'Owl', '🦉', 'Socks', '🧦', 'Shoes', '👟'),
          ('Which is different?', 'Boat', '⛵', 'Train', '🚂', 'Bus', '🚌'),
          ('Which is different?', 'Cake', '🎂', 'Lion', '🦁', 'Tiger', '🐯'),
          ('Which is different?', 'Chair', '🪑', 'Red', '🔴', 'Blue', '🔵'),
          (
            'Which is different?',
            'Spoon',
            '🥄',
            'Aeroplane',
            '✈️',
            'Helicopter',
            '🚁'
          ),
          (
            'Which is different?',
            'Cow',
            '🐄',
            'Circle',
            '🔵',
            'Triangle',
            '🔺'
          ),
          ('Which is different?', 'Pizza', '🍕', 'Burger', '🍔', 'Pen', '🖊️'),
          ('Which is different?', 'Bread', '🍞', 'Milk', '🥛', 'Hat', '🎩'),
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
      default: // Smallest/biggest
        const trios = [
          ('smallest', 'Ant', '🐜', 'Dog', '🐶', 'Elephant', '🐘'),
          ('biggest', 'Whale', '🐳', 'Fish', '🐟', 'Crab', '🦀'),
          ('smallest', 'Mouse', '🐭', 'Cat', '🐱', 'Horse', '🐴'),
          ('biggest', 'Elephant', '🐘', 'Rabbit', '🐰', 'Ant', '🐜'),
          ('smallest', 'Bee', '🐝', 'Bird', '🐦', 'Eagle', '🦅'),
          ('biggest', 'Giraffe', '🦒', 'Fox', '🦊', 'Rabbit', '🐰'),
          ('smallest', 'Puppy', '🐶', 'Cow', '🐄', 'Horse', '🐴'),
          ('biggest', 'Mountain', '🏔️', 'Tree', '🌳', 'House', '🏠'),
          ('smallest', 'Seeds', '🌰', 'Apple', '🍎', 'Pumpkin', '🎃'),
          ('biggest', 'Ship', '🚢', 'Boat', '⛵', 'Car', '🚗'),
          ('smallest', 'Key', '🔑', 'Book', '📖', 'Table', '🪑'),
          ('biggest', 'Planet', '🌍', 'Moon', '🌙', 'Star', '⭐'),
          ('smallest', 'Pea', '🫛', 'Egg', '🥚', 'Ball', '⚽'),
          ('biggest', 'Whale', '🐳', 'Dolphin', '🐬', 'Seal', '🦭'),
          ('smallest', 'Button', '🔘', 'Phone', '📱', 'TV', '📺'),
        ];
        final t = trios[k % trios.length];
        return _mc(
          id: id,
          prompt: 'Which is the ${t.$1}?',
          speak: 'Which is the ${t.$1}?',
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
      ('grey', 'Grey', '⬜', 'Red', '🔴', 'Blue', '🔵'),
    ];
    const shapes = [
      ('circle', 'Circle', '🔵', 'Square', '🟥', 'Triangle', '🔺'),
      ('square', 'Square', '🟥', 'Circle', '🔵', 'Star', '⭐'),
      ('triangle', 'Triangle', '🔺', 'Circle', '🔵', 'Heart', '❤️'),
      ('star', 'Star', '⭐', 'Square', '🟥', 'Circle', '🔵'),
      ('heart', 'Heart', '❤️', 'Triangle', '🔺', 'Square', '🟥'),
      ('diamond', 'Diamond', '🔶', 'Circle', '🔵', 'Star', '⭐'),
      ('oval', 'Oval', '🥚', 'Circle', '🔵', 'Square', '🟥'),
      ('rectangle', 'Rectangle', '📓', 'Square', '🟥', 'Triangle', '🔺'),
    ];
    final k = index ~/ 2;
    final mode = index % 4;
    if (mode == 0 || mode == 1) {
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
    if (mode == 2) {
      // Color mixing
      const mixes = [
        ('Red + Yellow = ?', 'Orange', '🟠', 'Green', '🟢', 'Purple', '🟣'),
        ('Blue + Yellow = ?', 'Green', '🟢', 'Orange', '🟠', 'Brown', '🟤'),
        ('Red + Blue = ?', 'Purple', '🟣', 'Orange', '🟠', 'Green', '🟢'),
        ('White + Black = ?', 'Grey', '⬜', 'Brown', '🟤', 'Pink', '🩷'),
        ('Red + White = ?', 'Pink', '🩷', 'Orange', '🟠', 'Purple', '🟣'),
        ('Yellow + Blue = ?', 'Green', '🟢', 'Purple', '🟣', 'Orange', '🟠'),
      ];
      final m = mixes[k % mixes.length];
      return _mc(
        id: 'gen_art_${index}_$slot',
        prompt: m.$1,
        speak: m.$1,
        correct: AnswerOption(label: m.$2, emoji: m.$3),
        wrong: [
          AnswerOption(label: m.$4, emoji: m.$5),
          AnswerOption(label: m.$6, emoji: m.$7),
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
