import '../../profiles/domain/grade_level.dart';
import '../domain/lesson.dart';
import '../domain/subject.dart';

part 'question_factory_banks.dart';

/// Generates broad, grade-appropriate question banks for each subject's
/// 50-level journey. Session length follows the learner's age and interaction
/// type rather than forcing every child through the same number of questions.
///
/// Design rules:
///  - Deterministic: content is a pure function of (grade, subject, gameType,
///    level, index). No Random/DateTime, so it is stable across rebuilds.
///  - Correct by construction: math is parametric (the answer is computed);
///    other subjects draw from curated primary-school banks where the right
///    answer is authored next to its distractors. Formal board alignment still
///    requires educator review before it can be claimed in product marketing.
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
      final q = _withLearningSupport(
        _one(seed + i, grade, subject, gameType, level, out.length),
        grade: grade,
        subject: subject,
        gameType: gameType,
        level: level,
      );
      final sig = _signature(q);
      if (seen.add(sig)) out.add(q);
      i++;
    }
    // Safety pad (bank smaller than count): accept remaining even if similar.
    while (out.length < count) {
      out.add(_withLearningSupport(
        _one(seed + i, grade, subject, gameType, level, out.length),
        grade: grade,
        subject: subject,
        gameType: gameType,
        level: level,
      ));
      i++;
    }
    return out;
  }

  static String _signature(Question q) {
    final opts = q.options.map((o) => '${o.label}/${o.emoji ?? ''}').join(',');
    return '${q.prompt}|$opts|${q.answer}';
  }

  static Question _withLearningSupport(
    Question question, {
    required GradeLevel grade,
    required Subject subject,
    required GameType gameType,
    required int level,
  }) {
    final text = '${question.prompt} ${question.speak ?? ''}'.toLowerCase();
    String skill;
    if (gameType == GameType.flashcard) {
      skill = subject == Subject.math ? 'math.facts' : 'english.letter-sounds';
    } else if (gameType == GameType.tracing) {
      skill = subject == Subject.math
          ? 'math.number-formation'
          : 'english.letter-formation';
    } else if (gameType == GameType.memoryMatch) {
      skill = 'logic.visual-memory';
    } else if (gameType == GameType.sequence) {
      skill =
          subject == Subject.english ? 'english.sequence' : 'logic.sequence';
    } else if (subject == Subject.math) {
      skill = switch (text) {
        final value when value.contains('lcm') => 'math.lcm',
        final value when value.contains('hcf') => 'math.hcf',
        final value when value.contains('volume') => 'math.volume',
        final value when value.contains('%') => 'math.percentage',
        final value when value.contains('fraction') || value.contains('/') =>
          'math.fractions',
        final value
            when value.contains('decimal') ||
                RegExp(r'\b0\.\d').hasMatch(value) =>
          'math.decimals',
        final value when value.contains('area') => 'math.area',
        final value when value.contains('perimeter') => 'math.perimeter',
        final value when value.contains('÷') || value.contains('shared') =>
          'math.division',
        final value when value.contains('×') || value.contains('multiple') =>
          'math.multiplication',
        final value when value.contains('+') || value.contains('altogether') =>
          'math.addition',
        final value
            when value.contains('-') ||
                value.contains('left') ||
                value.contains('take away') =>
          'math.subtraction',
        final value
            when value.contains('tens') ||
                value.contains('ones') ||
                value.contains('hundreds') =>
          'math.place-value',
        final value when value.contains('clock') || value.contains(':00') =>
          'math.time',
        _ => 'math.number-sense',
      };
    } else if (subject == Subject.english || subject == Subject.rhymes) {
      final upperMode = (level - 1) % 8;
      if (grade == GradeLevel.grade3) {
        skill = const [
          'english.nouns',
          'english.verbs',
          'english.adjectives',
          'english.synonyms',
          'english.antonyms',
          'english.pronouns',
          'english.prepositions',
          'english.prepositions',
        ][upperMode];
      } else if (grade == GradeLevel.grade4) {
        skill = const [
          'english.synonyms',
          'english.antonyms',
          'english.homophones',
          'english.prepositions',
          'english.conjunctions',
          'english.agreement',
          'english.adverbs',
          'english.adverbs',
        ][upperMode];
      } else if (grade == GradeLevel.grade5) {
        skill = const [
          'english.synonyms',
          'english.antonyms',
          'english.homophones',
          'english.conjunctions',
          'english.tenses',
          'english.agreement',
          'english.prepositions',
          'english.prepositions',
        ][upperMode];
      } else if (grade == GradeLevel.grade1 || grade == GradeLevel.grade2) {
        skill = const [
          'english.antonyms',
          'english.antonyms',
          'english.plurals',
          'english.plurals',
          'english.spelling',
          'english.spelling',
          'english.sentences',
          'english.sentences',
        ][upperMode];
      } else {
        skill = switch (text) {
          final value
              when value.contains('noun') || value.contains('naming word') =>
            'english.nouns',
          final value
              when value.contains('verb') || value.contains('action word') =>
            'english.verbs',
          final value
              when value.contains('adjective') ||
                  value.contains('describing word') =>
            'english.adjectives',
          final value
              when value.contains('opposite') || value.contains('antonym') =>
            'english.antonyms',
          final value
              when value.contains('synonym') || value.contains('word like') =>
            'english.synonyms',
          final value
              when value.contains('plural') ||
                  value.contains('more than one') =>
            'english.plurals',
          final value when value.contains('spell') => 'english.spelling',
          final value
              when value.contains('sentence') || value.contains('___') =>
            'english.sentences',
          final value when value.contains('rhyme') => 'english.rhyming',
          final value when value.contains('vowel') => 'english.vowels',
          _ => 'english.letter-sounds',
        };
      }
    } else if (subject == Subject.science || subject == Subject.evs) {
      skill = '${subject.name}.${grade.name}.core';
    } else if (subject == Subject.logic) {
      skill = text.contains('different')
          ? 'logic.classification'
          : text.contains('biggest') || text.contains('smallest')
              ? 'logic.comparison'
              : 'logic.patterns';
    } else {
      skill = '${subject.name}.core';
    }

    final prerequisites = switch (skill) {
      'math.subtraction' => const ['math.number-sense'],
      'math.multiplication' => const ['math.addition'],
      'math.division' => const ['math.multiplication'],
      'math.fractions' => const ['math.division'],
      'math.decimals' => const ['math.place-value'],
      'math.area' || 'math.perimeter' => const ['math.multiplication'],
      'math.volume' => const ['math.area'],
      'math.lcm' || 'math.hcf' => const ['math.multiplication'],
      'math.percentage' => const ['math.fractions'],
      'english.spelling' => const ['english.letter-sounds'],
      'english.sentences' => const ['english.nouns', 'english.verbs'],
      'english.adjectives' => const ['english.nouns'],
      'english.pronouns' => const ['english.nouns'],
      'english.adverbs' => const ['english.verbs'],
      'english.agreement' => const ['english.nouns', 'english.verbs'],
      'english.tenses' => const ['english.verbs'],
      'english.conjunctions' => const ['english.sentences'],
      _ => const <String>[],
    };
    final teachingTip = _teachingTip(skill);
    final correctAnswer = question.correctIndex != null &&
            question.correctIndex! >= 0 &&
            question.correctIndex! < question.options.length
        ? question.options[question.correctIndex!].label
        : question.answer;
    final rescueTip = correctAnswer == null
        ? '$teachingTip Let us try one smaller step together.'
        : '$teachingTip For this one, the answer is $correctAnswer. Now try it with fewer choices.';
    return question.withLearningSupport(
      skillId: skill,
      prerequisiteSkillIds: prerequisites,
      teachingTip: teachingTip,
      rescueTip: rescueTip,
    );
  }

  static String _teachingTip(String skill) => switch (skill) {
        'math.addition' =>
          'Addition joins groups. Start with the first group and count on.',
        'math.subtraction' =>
          'Subtraction takes away. Start with the whole group and count what remains.',
        'math.multiplication' =>
          'Multiplication means equal groups. Count each group or skip-count.',
        'math.division' => 'Division shares a total into equal groups.',
        'math.fractions' =>
          'A fraction describes equal parts: the bottom counts all equal parts and the top counts chosen parts.',
        'math.decimals' =>
          'Decimal places show tenths and hundredths. Line up decimal points when calculating.',
        'math.area' =>
          'Area counts the square units inside a shape: length times width.',
        'math.perimeter' =>
          'Perimeter is the distance around a shape. Add every outside side.',
        'math.volume' =>
          'Volume counts cubes inside: length times width times height.',
        'math.lcm' =>
          'The LCM is the first number found in both lists of multiples.',
        'math.hcf' =>
          'The HCF is the greatest number that divides both numbers exactly.',
        'math.percentage' =>
          'Percent means out of one hundred. Use a familiar fraction such as one half or one tenth.',
        'math.place-value' =>
          'A digit has a value based on its place: ones, tens, hundreds and beyond.',
        'math.time' =>
          'The short hand shows the hour and the long hand shows minutes.',
        'english.nouns' => 'A noun names a person, place, animal or thing.',
        'english.verbs' => 'A verb shows an action or a state.',
        'english.adjectives' => 'An adjective describes a noun.',
        'english.pronouns' =>
          'A pronoun can replace a naming word, such as she, he, it, we or they.',
        'english.prepositions' =>
          'A preposition shows where or when something is, such as under, beside or after.',
        'english.conjunctions' =>
          'A conjunction joins ideas. Words such as and, but, because and so connect parts.',
        'english.adverbs' =>
          'An adverb tells how, when or where an action happens.',
        'english.agreement' =>
          'The subject and verb must match: one is, many are.',
        'english.tenses' =>
          'Verb tense shows when something happens: past, present or future.',
        'english.homophones' =>
          'Homophones sound alike but have different spellings and meanings. Use the sentence clue.',
        'english.sentences' =>
          'A sentence needs words in an order that makes a complete thought.',
        'english.spelling' =>
          'Say the word slowly and listen for each sound in order.',
        'english.rhyming' => 'Rhyming words have the same ending sound.',
        'english.vowels' => 'The vowel letters are A, E, I, O and U.',
        'logic.patterns' =>
          'Find what changes each time, then repeat the same rule.',
        'logic.classification' =>
          'Look for two things that share a group; the other one is different.',
        'logic.comparison' =>
          'Compare the objects using the same feature, such as size.',
        _ =>
          'Look closely, listen to the clue, and connect it to something you already know.',
      };

  static Question _one(
    int index,
    GradeLevel grade,
    Subject subject,
    GameType gameType,
    int level,
    int slot,
  ) {
    switch (gameType) {
      case GameType.tracing:
        return _tracing(index, grade, subject);
      case GameType.sequence:
        return _sequence(index, grade, subject, level, slot);
      case GameType.memoryMatch:
        return _memory(index, grade, subject, slot);
      case GameType.dragDrop:
      case GameType.sorting:
        return _sorting(index, grade, subject, level, slot);
      case GameType.flashcard:
        return _flashcard(index, grade, subject, level);
      default:
        return _choiceBySubject(index, grade, subject, level, slot);
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

  static Question _flashcard(
      int index, GradeLevel grade, Subject subject, int level) {
    if (subject == Subject.math) {
      if (grade.difficultyTier >= 4) {
        final maxTable = switch (grade) {
          GradeLevel.grade2 => level < 21 ? 5 : 10,
          _ => 12,
        };
        final table = index % (maxTable - 1) + 2;
        final by = index ~/ 9 % 10 + 1;
        final product = table * by;
        return Question(
          id: 'gen_fc_tbl_$index',
          prompt: '$table × $by = $product',
          answer: '$table times $by is $product',
          speak: '$table times $by equals $product',
        );
      }
      final maxNumber = switch (grade) {
        GradeLevel.lkg => 5,
        GradeLevel.ukg => 10,
        GradeLevel.kg => 20,
        GradeLevel.grade1 => 100,
        _ => 50,
      };
      final n = index % maxNumber + 1;
      return Question(
        id: 'gen_fc_num_$index',
        prompt: '$n',
        promptEmoji: '🔢',
        answer: _numberWord(n),
        speak: n >= _numberWords.length
            ? 'The number $n.'
            : 'The number $n. ${_numberWords[n]}.',
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
  static Question _tracing(int index, GradeLevel grade, Subject subject) {
    if (subject == Subject.math) {
      final maxNumber = switch (grade) {
        GradeLevel.lkg => 5,
        GradeLevel.ukg => 10,
        GradeLevel.kg => 20,
        GradeLevel.grade1 => 50,
        _ => 100,
      };
      final n = index % (maxNumber + 1);
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
      int index, GradeLevel grade, Subject subject, int level, int slot) {
    final width =
        grade.difficultyTier <= 1 ? 3 : (grade.difficultyTier <= 4 ? 4 : 5);
    if (subject == Subject.math || subject == Subject.logic) {
      final steps = switch (grade) {
        GradeLevel.lkg => const [1],
        GradeLevel.ukg => const [1, 2],
        GradeLevel.kg => const [1, 2, 5],
        GradeLevel.grade1 => const [1, 2, 5, 10],
        GradeLevel.grade2 => const [2, 3, 5, 10],
        GradeLevel.grade3 => const [2, 3, 4, 5, 10],
        GradeLevel.grade4 => const [3, 4, 6, 7, 8, 9],
        GradeLevel.grade5 => const [4, 6, 7, 8, 9, 11, 12],
      };
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
    if (subject == Subject.english || subject == Subject.rhymes) {
      if (grade.isPreSchool) {
        final start = index % 23;
        return Question(
          id: 'gen_seq_${index}_$slot',
          prompt: 'Put the letters in order',
          speak: 'Tap the letters in alphabet order',
          options: [
            for (var i = 0; i < width; i++)
              AnswerOption(
                  label: String.fromCharCode('A'.codeUnitAt(0) + start + i))
          ],
        );
      }
      const sentences = [
        ['I', 'like', 'red', 'apples.'],
        ['The', 'sun', 'is', 'bright.'],
        ['Birds', 'build', 'small', 'nests.'],
        ['We', 'play', 'after', 'school.'],
        ['My', 'friend', 'reads', 'daily.'],
        ['Plants', 'need', 'water', 'and sunlight.'],
        ['The', 'little', 'puppy', 'barked.'],
        ['Please', 'close', 'the', 'door.'],
      ];
      final words = sentences[index % sentences.length];
      return Question(
          id: 'gen_seq_${index}_$slot',
          prompt: 'Build the sentence',
          speak: 'Tap the words to build a sentence',
          options: [for (final word in words) AnswerOption(label: word)]);
    }

    const earlySets = [
      ['🐜 Ant', '🐱 Cat', '🐶 Dog', '🐘 Elephant', '🐳 Whale'],
      ['🌰 Seed', '🌱 Sprout', '🪴 Plant', '🌳 Tree'],
      ['🥚 Egg', '🐛 Caterpillar', '🦋 Butterfly'],
      ['🌅 Morning', '☀️ Noon', '🌆 Evening', '🌙 Night'],
      ['🥚 Egg', '🐣 Chick', '🐔 Hen'],
      ['☁️ Cloud', '🌧️ Rain', '🌈 Rainbow'],
      ['🌱 Seed', '🌿 Plant', '🌸 Flower', '🍎 Fruit'],
      ['🐸 Tadpole', '🐸 Frog'],
    ];
    const olderSets = [
      ['🧊 Ice', '💧 Water', '💨 Water vapour'],
      ['🌑 New Moon', '🌓 Quarter Moon', '🌕 Full Moon'],
      ['👶 Baby', '🧒 Child', '🧑 Adult', '👴 Elder'],
      ['🍼 Baby', '🧒 Toddler', '🧑 Teen', '👨 Adult'],
      ['🌄 Dawn', '☀️ Noon', '🌅 Dusk', '🌙 Night'],
      ['🌱 Producer', '🐰 Herbivore', '🦊 Carnivore', '🍄 Decomposer'],
      ['🌧️ Rain', '🌊 Collection', '☀️ Evaporation', '☁️ Condensation'],
      ['🔋 Cell', '🔘 Switch', '💡 Bulb lights'],
    ];
    final sets =
        grade.difficultyTier <= 2 ? earlySets : [...earlySets, ...olderSets];
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
  static Question _memory(
      int index, GradeLevel grade, Subject subject, int slot) {
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
    final pairCount = switch (grade) {
      GradeLevel.lkg => 3,
      GradeLevel.ukg => 4,
      _ => 5,
    };
    final faces = sets[index % sets.length].take(pairCount);
    return Question(
      id: 'gen_mem_${index}_$slot',
      prompt: 'Find the matching pairs',
      speak: 'Find two matching pictures',
      options: [for (final f in faces) AnswerOption(label: f, emoji: f)],
    );
  }

  // ---------------------------------------------------------------------------
  // Sorting / drag-drop
  // ---------------------------------------------------------------------------
  static Question _sorting(
      int index, GradeLevel grade, Subject subject, int level, int slot) {
    final id = 'gen_sort_${index}_$slot';
    if (subject == Subject.math) {
      if (grade == GradeLevel.lkg) {
        const items = [
          ('3', '3️⃣', 0),
          ('Circle', '🔵', 1),
          ('5', '5️⃣', 0),
          ('Star', '⭐', 1),
          ('2', '2️⃣', 0),
          ('Square', '🟥', 1)
        ];
        final item = items[index % items.length];
        return Question(
            id: id,
            prompt: 'Where does this go?',
            promptEmoji: item.$2,
            speak: 'Is it a number or a shape?',
            correctIndex: item.$3,
            options: const [
              AnswerOption(label: 'Number', emoji: '🔢'),
              AnswerOption(label: 'Shape', emoji: '🔷')
            ]);
      }
      if (grade.isPreSchool) {
        final n = index % (grade == GradeLevel.ukg ? 10 : 20) + 1;
        final isSmall = n <= (grade == GradeLevel.ukg ? 5 : 10);
        return Question(
            id: id,
            prompt: 'Sort number $n',
            promptEmoji: '🔢',
            speak: 'Which number group?',
            correctIndex: isSmall ? 0 : 1,
            options: [
              AnswerOption(
                  label: grade == GradeLevel.ukg ? '1 to 5' : '1 to 10'),
              AnswerOption(
                  label: grade == GradeLevel.ukg ? '6 to 10' : '11 to 20')
            ]);
      }
      final divisor = grade.difficultyTier <= 4 ? 2 : index % 4 + 2;
      final n = index % 90 + 10;
      final divisible = n % divisor == 0;
      return Question(
          id: id,
          prompt: 'Sort $n',
          promptEmoji: '🔢',
          speak: 'Is $n divisible by $divisor?',
          correctIndex: divisible ? 0 : 1,
          options: [
            AnswerOption(label: 'Multiple of $divisor'),
            const AnswerOption(label: 'Not a multiple')
          ]);
    }

    if (subject == Subject.english || subject == Subject.rhymes) {
      if (grade.isPreSchool) {
        final item = _alphabet[index % _alphabet.length];
        final other = _alphabet[(index + 7) % _alphabet.length];
        return Question(
            id: id,
            prompt: 'First sound of ${item.$2}?',
            promptEmoji: item.$3,
            speak: 'Which letter does ${item.$2} start with?',
            correctIndex: 0,
            options: [
              AnswerOption(label: item.$1),
              AnswerOption(label: other.$1)
            ]);
      }
      const words = [
        ('garden', 'Noun', 0),
        ('jump', 'Action', 1),
        ('teacher', 'Noun', 0),
        ('write', 'Action', 1),
        ('river', 'Noun', 0),
        ('laugh', 'Action', 1),
        ('planet', 'Noun', 0),
        ('whisper', 'Action', 1),
        ('market', 'Noun', 0),
        ('build', 'Action', 1),
        ('pencil', 'Noun', 0),
        ('explore', 'Action', 1),
      ];
      final word = words[index % words.length];
      return Question(
          id: id,
          prompt: 'Sort “${word.$1}”',
          speak: 'Is ${word.$1} a naming word or an action word?',
          correctIndex: word.$3,
          options: const [
            AnswerOption(label: 'Naming word'),
            AnswerOption(label: 'Action word')
          ]);
    }

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
      id: id,
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
      int index, GradeLevel grade, Subject subject, int level, int slot) {
    switch (subject) {
      case Subject.math:
        return _math(index, grade, level, slot);
      case Subject.english:
      case Subject.rhymes:
        return _english(index, grade, level, slot);
      case Subject.evs:
      case Subject.science:
        return _world(index, grade, subject, level, slot);
      case Subject.logic:
        return _logic(index, grade, level, slot);
      case Subject.art:
        return _art(index, slot);
    }
  }

  // ---- MATH (parametric, infinite questions) --------------------------------
  static Question _math(int index, GradeLevel grade, int level, int slot) {
    final id = 'gen_math_${index}_$slot';
    final phase = ((level - 1) ~/ 10).clamp(0, 4);

    int differentFrom(int value, int max) {
      final candidate = (index ~/ 3) % max + 1;
      return candidate == value ? candidate % max + 1 : candidate;
    }

    Question compare(int max, {required bool bigger}) {
      final a = index % max + 1;
      final b = differentFrom(a, max);
      final answer = bigger ? (a > b ? a : b) : (a < b ? a : b);
      final other = answer == a ? b : a;
      final biggerPrompts = [
        'Which is bigger',
        'Find the bigger number',
        'Tap the larger number',
        'Which number has more',
        'Choose the bigger one',
      ];
      final smallerPrompts = [
        'Which is smaller',
        'Find the smaller number',
        'Tap the little number',
        'Which number has less',
        'Choose the smaller one',
      ];
      return _mc(
        id: id,
        prompt:
            '${(bigger ? biggerPrompts : smallerPrompts)[slot % 5]}: $a or $b?',
        speak: bigger ? 'Which number is bigger?' : 'Which number is smaller?',
        correct: AnswerOption(label: '$answer'),
        wrong: [AnswerOption(label: '$other')],
        shift: index,
      );
    }

    switch (grade) {
      case GradeLevel.lkg:
        // Ages 3–4: concrete quantities 1–5. Symbols are introduced only
        // after repeated counting practice; there is no subtraction.
        final max = phase < 2 ? 3 : 5;
        switch ((level - 1) % (phase < 3 ? 4 : 5)) {
          case 0:
          case 1:
            final n = index % max + 1;
            final object = const ['⭐', '🍎', '🐝', '🎈', '🐟'][slot % 5];
            return _numMc(
                index, id, 'Count ${object * n}', 'How many can you count?', n);
          case 2:
            final n = index % max + 1;
            final verb =
                const ['Find', 'Tap', 'Point to', 'Spot', 'Choose'][slot % 5];
            return _numMc(index, id, '$verb $n', 'Tap number $n', n);
          case 3:
            return compare(max, bigger: true);
          default:
            final a = index % 3 + 1;
            final object = const ['🍎', '🐝', '🎈', '⭐', '🐟'][slot % 5];
            return _numMc(index, id, '${object * a} and one more $object',
                '$a and one more. How many?', a + 1);
        }
      case GradeLevel.ukg:
        // Ages 4–5: 1–10, then teen numbers; concrete addition/subtraction.
        final max = phase < 2 ? 10 : 20;
        switch ((level - 1) % 7) {
          case 0:
            final n = index % 10 + 1;
            return _numMc(index, id, 'Count ${'🐝' * n}', 'Count the bees', n);
          case 1:
            final n = index % max + 1;
            return _numMc(
                index, id, 'After $n?', 'What comes after $n?', n + 1);
          case 2:
            final n = index % max + 2;
            return _numMc(
                index, id, 'Before $n?', 'What comes before $n?', n - 1);
          case 3:
            final a = index % 5 + 1;
            final b = index ~/ 2 % 3 + 1;
            return _numMc(index, id, '${'🍎' * a} and ${'🍎' * b}',
                '$a apples and $b more. How many apples?', a + b);
          case 4:
            final a = index % 6 + 4;
            final b = index % 3 + 1;
            final friend = const [
              'birds',
              'ducks',
              'butterflies',
              'fish',
              'bunnies',
              'bees',
              'frogs'
            ][slot % 7];
            return _numMc(index, id, '$a $friend. $b go away.',
                '$a $friend. $b go away. How many stay?', a - b);
          case 5:
            return compare(max, bigger: true);
          default:
            return compare(max, bigger: false);
        }
      case GradeLevel.kg:
        // Ages 5–6: numbers to 50, facts within 10/20 and gentle skip-counting.
        switch ((level - 1) % 8) {
          case 0:
            final n = index % (phase < 2 ? 20 : 50) + 1;
            return _numMc(index, id, 'After $n?', null, n + 1);
          case 1:
            final a = index % 9 + 1;
            final b = index ~/ 2 % 9 + 1;
            return _numMc(index, id, '$a + $b = ?', null, a + b);
          case 2:
            final a = index % 10 + 8;
            final b = index % 7 + 1;
            return _numMc(index, id, '$a - $b = ?', null, a - b);
          case 3:
            return compare(50, bigger: true);
          case 4:
            final tens = index % 5 + 1;
            return _numMc(index, id, '$tens tens = ?', null, tens * 10);
          default:
            final step = phase < 2 ? 2 : (index.isEven ? 5 : 10);
            final n = (index % 6 + 1) * step;
            final trail = const [
              '🐰 Hop',
              '🚀 Launch',
              '🌟 Star path',
              '🚂 Number train',
              '🐸 Lily pads',
              '🎈 Balloon trail',
              '🐝 Bee path',
              '🦋 Garden path'
            ][slot % 8];
            return _numMc(index, id, '$trail: $n, ${n + step}, ?',
                'What comes next?', n + 2 * step);
        }
      case GradeLevel.grade1:
        // Grade 1: place value and add/subtract within 20, growing to 100.
        final limit = phase < 2 ? 20 : 100;
        switch ((level - 1) % 8) {
          case 0:
            final a = index % (limit ~/ 2) + 1;
            final b = index ~/ 2 % (limit ~/ 3) + 1;
            return _numMc(index, id, '$a + $b = ?', null, a + b);
          case 1:
            final a = index % (limit ~/ 2) + limit ~/ 2;
            final b = index % (a.clamp(2, 20) - 1) + 1;
            return _numMc(index, id, '$a - $b = ?', null, a - b);
          case 2:
            final n = index % 90 + 10;
            return _numMc(index, id, 'Tens in $n?', null, n ~/ 10);
          case 3:
            final n = index % 90 + 10;
            return _numMc(index, id, 'Ones in $n?', null, n % 10);
          case 4:
            final hour = index % 12 + 1;
            return _mc(
                id: id,
                prompt: '🕐 Clock shows $hour o’clock. Choose it.',
                correct: AnswerOption(label: '$hour:00'),
                wrong: [
                  AnswerOption(label: '${hour % 12 + 1}:00'),
                  const AnswerOption(label: '12:30')
                ],
                shift: index);
          case 5:
            return compare(limit, bigger: true);
          default:
            final step = [2, 5, 10][index % 3];
            final n = (index % 8 + 1) * step;
            return _numMc(index, id, '$n, ${n + step}, ?', null, n + 2 * step);
        }
      case GradeLevel.grade2:
        // Grade 2: three-digit place value, regrouping, tables 2–10,
        // equal sharing, money and clock intervals.
        switch ((level - 1) % 10) {
          case 0:
            final a = index % 300 + 100;
            final b = index ~/ 2 % 150 + 20;
            return _numMc(index, id, '$a + $b = ?', null, a + b);
          case 1:
            final a = index % 300 + 300;
            final b = index ~/ 2 % 180 + 20;
            return _numMc(index, id, '$a - $b = ?', null, a - b);
          case 2:
            final a = index % (phase < 2 ? 4 : 9) + 2;
            final b = index ~/ 2 % 10 + 1;
            return _numMc(index, id, '$a × $b = ?', null, a * b);
          case 3:
            final groups = index % 5 + 2;
            final each = index % 6 + 2;
            return _numMc(index, id, '${groups * each} shared by $groups = ?',
                null, each);
          case 4:
            final n = index % 900 + 100;
            return _numMc(index, id, 'Hundreds in $n?', null, n ~/ 100);
          case 5:
            final rupees = index % 40 + 10;
            final spend = index % 9 + 1;
            return _numMc(
                index,
                id,
                'You have ₹$rupees and spend ₹$spend. Left?',
                null,
                rupees - spend);
          default:
            final step = [3, 4, 5, 10][index % 4];
            final n = (index % 8 + 1) * step;
            return _numMc(index, id, '$n, ${n + step}, ?', null, n + 2 * step);
        }
      case GradeLevel.grade3:
        // Grade 3: tables/division, 4-digit operations, simple fractions,
        // measurement and introductory area/perimeter. No LCM/HCF/decimals.
        switch ((level - 1) % 10) {
          case 0:
            final a = index % 3000 + 500;
            final b = index ~/ 2 % 900 + 100;
            return _numMc(index, id, '$a + $b = ?', null, a + b);
          case 1:
            final a = index % 3000 + 2000;
            final b = index ~/ 2 % 900 + 100;
            return _numMc(index, id, '$a - $b = ?', null, a - b);
          case 2:
            final a = index % 11 + 2;
            final b = index ~/ 2 % 10 + 1;
            return _numMc(index, id, '$a × $b = ?', null, a * b);
          case 3:
            final divisor = index % 9 + 2;
            final quotient = index ~/ 2 % 10 + 1;
            return _numMc(index, id, '${divisor * quotient} ÷ $divisor = ?',
                null, quotient);
          case 4:
            final d = [2, 3, 4, 5, 8][index % 5];
            return _mc(
                id: id,
                prompt: 'Which shows one part out of $d?',
                correct: AnswerOption(label: '1/$d'),
                wrong: [
                  AnswerOption(label: '$d/1'),
                  AnswerOption(label: '1/${d + 1}')
                ],
                shift: index);
          case 5:
            final cm = (index % 25 + 1) * 100;
            return _numMc(index, id, '$cm cm = ? m', null, cm ~/ 100);
          case 6:
            final l = index % 8 + 2;
            final w = index ~/ 2 % 6 + 2;
            return _numMc(index, id, 'Area of $l × $w rectangle?', null, l * w);
          default:
            final l = index % 8 + 2;
            final w = index ~/ 2 % 6 + 2;
            return _numMc(index, id, 'Perimeter of $l × $w rectangle?', null,
                2 * (l + w));
        }
      case GradeLevel.grade4:
        // Grade 4: large numbers, factors/multiples, equivalent fractions,
        // tenths/hundredths, geometry and unit conversion.
        switch ((level - 1) % 11) {
          case 0:
            final a = index % 8000 + 1000;
            final b = index ~/ 2 % 4000 + 500;
            return _numMc(index, id, '$a + $b = ?', null, a + b);
          case 1:
            final a = index % 8000 + 9000;
            final b = index ~/ 2 % 4000 + 500;
            return _numMc(index, id, '$a - $b = ?', null, a - b);
          case 2:
            final a = index % 99 + 11;
            final b = index ~/ 2 % 9 + 2;
            return _numMc(index, id, '$a × $b = ?', null, a * b);
          case 3:
            final n = index % 10 + 2;
            final multiplier = index ~/ 2 % 5 + 2;
            return _mc(
                id: id,
                prompt: 'Equivalent to 1/$n?',
                correct: AnswerOption(label: '$multiplier/${n * multiplier}'),
                wrong: [
                  AnswerOption(label: '1/${n + 1}'),
                  AnswerOption(label: '${multiplier + 1}/${n * multiplier}')
                ],
                shift: index);
          case 4:
            final hundredths = index % 99 + 1;
            final answer = (hundredths / 100).toStringAsFixed(2);
            return _mc(
                id: id,
                prompt: '$hundredths hundredths as a decimal?',
                correct: AnswerOption(label: answer),
                wrong: [
                  AnswerOption(label: '$hundredths.0'),
                  AnswerOption(
                      label: ((hundredths + 1) / 100).toStringAsFixed(2))
                ],
                shift: index);
          case 5:
            final n = index % 10 + 2;
            final factor =
                [2, 3, 5, 7].firstWhere((f) => n % f == 0, orElse: () => 1);
            return _mc(
                id: id,
                prompt: 'Which is a factor of $n?',
                correct: AnswerOption(label: '$factor'),
                wrong: [
                  AnswerOption(label: '${n + 1}'),
                  AnswerOption(label: '${n + 2}')
                ],
                shift: index);
          case 6:
            final kg = index % 25 + 1;
            return _numMc(index, id, '$kg kg = ? g', null, kg * 1000);
          default:
            final l = index % 12 + 3;
            final w = index ~/ 2 % 8 + 2;
            return _numMc(index, id, 'Area of $l × $w rectangle?', null, l * w);
        }
      case GradeLevel.grade5:
        // Grade 5: multi-step operations, fractions/decimals, percentage,
        // volume, LCM and HCF after the foundations from earlier grades.
        switch ((level - 1) % 12) {
          case 0:
            final a = index % 900 + 100;
            final b = index ~/ 3 % 90 + 10;
            return _numMc(index, id, '$a × $b = ?', null, a * b);
          case 1:
            final divisor = index % 18 + 2;
            final quotient = index ~/ 2 % 40 + 5;
            return _numMc(index, id, '${divisor * quotient} ÷ $divisor = ?',
                null, quotient);
          case 2:
            final d = [3, 4, 5, 6, 8, 10][index % 6];
            final a = index % (d - 1) + 1;
            final b = index ~/ 2 % (d - 1) + 1;
            return _numMc(index, id, '$a/$d + $b/$d = ?/$d', null, a + b);
          case 3:
            final a = index % 90 + 10;
            final b = index ~/ 2 % 90 + 10;
            return _numMc(
                index, id, '$a tenths + $b tenths = ? tenths', null, a + b);
          case 4:
            final percent = [10, 20, 25, 50][index % 4];
            final value = (index % 9 + 1) * 20;
            return _numMc(index, id, '$percent% of $value = ?', null,
                value * percent ~/ 100);
          case 5:
            final l = index % 8 + 2;
            final w = index ~/ 2 % 6 + 2;
            final h = index ~/ 3 % 5 + 2;
            return _numMc(
                index, id, 'Volume of $l × $w × $h cuboid?', null, l * w * h);
          case 6:
            final a = index % 6 + 2;
            final b = index ~/ 2 % 7 + 3;
            var lcm = a;
            while (lcm % b != 0) {
              lcm += a;
            }
            return _numMc(index, id, 'LCM of $a and $b?', null, lcm);
          default:
            var a = index % 18 + 8;
            var b = index ~/ 2 % 14 + 4;
            final originalA = a;
            final originalB = b;
            while (b != 0) {
              final remainder = a % b;
              a = b;
              b = remainder;
            }
            return _numMc(
                index, id, 'HCF of $originalA and $originalB?', null, a);
        }
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

  static Question _english(int index, GradeLevel grade, int level, int slot) {
    final id = 'gen_en_${index}_$slot';
    final k = index ~/ 2;
    final tier = grade.difficultyTier;
    final mode = switch (grade) {
      // LKG stays visual and voice-first: letter finding, picture naming and
      // initial sounds. It never depends on reading a word independently.
      GradeLevel.lkg => const [0, 0, 6, 2][(level - 1) % 4],
      // UKG introduces upper/lower-case matching and oral rhymes gradually.
      GradeLevel.ukg => const [0, 1, 2, 4, 6][(level - 1) % 5],
      _ => (level - 1) % 8,
    };

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
          final picture = _alphabet[k % _alphabet.length];
          final word = grade == GradeLevel.lkg
              ? picture.$2.toLowerCase()
              : _threeLetterWords[k % _threeLetterWords.length];
          final first = word[0].toUpperCase();
          final w1 = String.fromCharCode('A'.codeUnitAt(0) + (k % 26 + 5) % 26);
          final w2 =
              String.fromCharCode('A'.codeUnitAt(0) + (k % 26 + 12) % 26);
          return _mc(
            id: id,
            prompt: grade == GradeLevel.lkg
                ? '${picture.$3} Starts with?'
                : 'First letter of "$word"?',
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
            wrong: [
              AnswerOption(label: nonRhyme1),
              AnswerOption(label: nonRhyme2)
            ],
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
            ('Apple', '🍎'),
            ('Car', '🚗'),
            ('Ball', '⚽'),
            ('Fish', '🐟'),
            ('Star', '⭐'),
            ('Rain', '🌧️'),
            ('Bird', '🐦'),
            ('Phone', '📱'),
            ('Cake', '🎂'),
            ('Hat', '🎩'),
            ('Key', '🔑'),
            ('Door', '🚪'),
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

    if (grade.difficultyTier >= GradeLevel.grade3.difficultyTier) {
      return _upperPrimaryEnglish(index, grade, level, slot);
    }

    // Grades 1–2: opposites, regular plurals, spelling and short sentences.
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

  static Question _upperPrimaryEnglish(
      int index, GradeLevel grade, int level, int slot) {
    final id = 'gen_en_${index}_$slot';
    final k = index ~/ 2;
    const synonyms = [
      ('happy', 'glad', 'angry', 'tiny'),
      ('big', 'large', 'slow', 'quiet'),
      ('quick', 'fast', 'late', 'soft'),
      ('begin', 'start', 'finish', 'break'),
      ('silent', 'quiet', 'noisy', 'bright'),
      ('brave', 'bold', 'afraid', 'sleepy'),
      ('clever', 'smart', 'dull', 'weak'),
      ('tiny', 'small', 'huge', 'wide'),
      ('reply', 'answer', 'question', 'forget'),
      ('choose', 'select', 'drop', 'hide'),
      ('ancient', 'old', 'modern', 'young'),
      ('protect', 'guard', 'damage', 'lose'),
    ];
    const antonyms = [
      ('early', 'late', 'quick', 'first'),
      ('strong', 'weak', 'brave', 'heavy'),
      ('accept', 'refuse', 'receive', 'allow'),
      ('victory', 'defeat', 'prize', 'game'),
      ('include', 'exclude', 'enter', 'collect'),
      ('generous', 'selfish', 'helpful', 'cheerful'),
      ('increase', 'decrease', 'improve', 'measure'),
      ('visible', 'hidden', 'bright', 'clear'),
      ('maximum', 'minimum', 'middle', 'total'),
      ('careful', 'careless', 'gentle', 'useful'),
      ('arrive', 'depart', 'travel', 'visit'),
      ('create', 'destroy', 'build', 'draw'),
    ];
    const homophones = [
      ('The ___ is shining.', 'sun', 'son', 'soon'),
      ('I can ___ the bird.', 'see', 'sea', 'say'),
      ('She ate a juicy ___.', 'pear', 'pair', 'peer'),
      ('Please come over ___.', 'here', 'hear', 'hair'),
      ('The wind ___ hard.', 'blew', 'blue', 'blow'),
      ('We bought ___ pencils.', 'two', 'too', 'to'),
      ('The dog wagged ___ tail.', 'its', "it's", 'it'),
      ('The knight rode a ___.', 'horse', 'hoarse', 'house'),
      ('Please ___ your name.', 'write', 'right', 'rite'),
      ('The boat raised its ___.', 'sail', 'sale', 'sell'),
      ('Flour is made from ___.', 'wheat', 'sweet', 'wait'),
      ('I ___ the answer.', 'knew', 'new', 'know'),
    ];
    const prepositions = [
      ('The cat is ___ the table.', 'under', 'quickly', 'because'),
      ('The bird flew ___ the tree.', 'over', 'softly', 'but'),
      ('The book is ___ the bag.', 'inside', 'happy', 'and'),
      ('We walked ___ the river.', 'beside', 'bright', 'or'),
      ('The ball rolled ___ the chair.', 'behind', 'loudly', 'so'),
      ('She stood ___ her friends.', 'between', 'kindly', 'yet'),
      ('The train went ___ the tunnel.', 'through', 'slow', 'for'),
      ('A bridge runs ___ the road.', 'across', 'careful', 'nor'),
      ('Meet me ___ noon.', 'at', 'nearby', 'then'),
      ('The kite rose ___ the clouds.', 'above', 'blue', 'unless'),
      ('The puppy ran ___ its owner.', 'towards', 'playful', 'although'),
      ('We travelled ___ Delhi to Agra.', 'from', 'early', 'because'),
    ];
    const conjunctions = [
      ('I was tired, ___ I rested.', 'so', 'or', 'until'),
      ('Riya sang ___ danced.', 'and', 'because', 'unless'),
      ('Take an umbrella ___ it may rain.', 'because', 'but', 'or'),
      ('I called him, ___ he did not answer.', 'but', 'so', 'and'),
      ('Would you like tea ___ milk?', 'or', 'because', 'although'),
      ('Wait here ___ I return.', 'until', 'but', 'so'),
      ('We can play ___ homework is done.', 'after', 'or', 'yet'),
      ('She smiled ___ she saw the puppy.', 'when', 'but', 'unless'),
      ('___ it was cold, we wore coats.', 'Because', 'Or', 'Yet'),
      ('I will help ___ you ask politely.', 'if', 'and', 'but'),
      ('He practised ___ he could improve.', 'so that', 'or', 'yet'),
      ('___ the rain stopped, we went out.', 'After', 'But', 'Nor'),
    ];

    final mode = (level - 1) % 8;
    if (grade == GradeLevel.grade3) {
      switch (mode) {
        case 0:
          const rows = [
            ('The playful puppy ran.', 'puppy'),
            ('Mina opened the window.', 'Mina'),
            ('Birds built a nest.', 'Birds'),
            ('The river is wide.', 'river'),
            ('Our teacher smiled.', 'teacher'),
            ('A rainbow appeared.', 'rainbow'),
          ];
          final r = rows[k % rows.length];
          return _mc(
              id: id,
              prompt: 'Find the noun: ${r.$1}',
              correct: AnswerOption(label: r.$2),
              wrong: const [
                AnswerOption(label: 'quickly'),
                AnswerOption(label: 'and')
              ],
              shift: index);
        case 1:
          const rows = [
            ('The rabbit hops.', 'hops'),
            ('We read books.', 'read'),
            ('Fish swim in water.', 'swim'),
            ('The baby laughed.', 'laughed'),
            ('Stars shine brightly.', 'shine'),
            ('I carry my bag.', 'carry'),
          ];
          final r = rows[k % rows.length];
          return _mc(
              id: id,
              prompt: 'Find the action word: ${r.$1}',
              correct: AnswerOption(label: r.$2),
              wrong: const [
                AnswerOption(label: 'the'),
                AnswerOption(label: 'blue')
              ],
              shift: index);
        case 2:
          const rows = [
            ('a red ball', 'red'),
            ('a tall tree', 'tall'),
            ('soft fur', 'soft'),
            ('three apples', 'three'),
            ('a noisy class', 'noisy'),
            ('cold water', 'cold')
          ];
          final r = rows[k % rows.length];
          return _mc(
              id: id,
              prompt: 'Describing word in “${r.$1}”?',
              correct: AnswerOption(label: r.$2),
              wrong: const [
                AnswerOption(label: 'runs'),
                AnswerOption(label: 'and')
              ],
              shift: index);
        case 3:
          final r = synonyms[k % synonyms.length];
          return _mc(
              id: id,
              prompt: 'A word like “${r.$1}”?',
              correct: AnswerOption(label: r.$2),
              wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
              shift: index);
        case 4:
          final r = antonyms[k % antonyms.length];
          return _mc(
              id: id,
              prompt: 'Opposite of “${r.$1}”?',
              correct: AnswerOption(label: r.$2),
              wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
              shift: index);
        case 5:
          const rows = [
            ('Ria has a kite.', 'She'),
            ('Aman is running.', 'He'),
            ('The dogs are barking.', 'They'),
            ('The book is new.', 'It'),
            ('Mira and I sing.', 'We'),
            ('Sam and Ali play.', 'They')
          ];
          final r = rows[k % rows.length];
          return _mc(
              id: id,
              prompt: 'Replace the name: ${r.$1}',
              correct: AnswerOption(label: r.$2),
              wrong: const [
                AnswerOption(label: 'It'),
                AnswerOption(label: 'I')
              ],
              shift: index);
        default:
          final r = prepositions[k % prepositions.length];
          return _mc(
              id: id,
              prompt: r.$1,
              correct: AnswerOption(label: r.$2),
              wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
              shift: index);
      }
    }

    if (grade == GradeLevel.grade4) {
      switch (mode) {
        case 0:
          final r = synonyms[k % synonyms.length];
          return _mc(
              id: id,
              prompt: 'Synonym of “${r.$1}”?',
              correct: AnswerOption(label: r.$2),
              wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
              shift: index);
        case 1:
          final r = antonyms[k % antonyms.length];
          return _mc(
              id: id,
              prompt: 'Antonym of “${r.$1}”?',
              correct: AnswerOption(label: r.$2),
              wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
              shift: index);
        case 2:
          final r = homophones[k % homophones.length];
          return _mc(
              id: id,
              prompt: r.$1,
              correct: AnswerOption(label: r.$2),
              wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
              shift: index);
        case 3:
          final r = prepositions[k % prepositions.length];
          return _mc(
              id: id,
              prompt: r.$1,
              correct: AnswerOption(label: r.$2),
              wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
              shift: index);
        case 4:
          final r = conjunctions[k % conjunctions.length];
          return _mc(
              id: id,
              prompt: r.$1,
              correct: AnswerOption(label: r.$2),
              wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
              shift: index);
        case 5:
          const rows = [
            ('The birds ___ singing.', 'are', 'is', 'am'),
            ('My friend ___ helpful.', 'is', 'are', 'am'),
            ('I ___ ready.', 'am', 'is', 'are'),
            ('The children ___ outside.', 'are', 'is', 'am'),
            ('This book ___ mine.', 'is', 'are', 'am'),
            ('We ___ a team.', 'are', 'is', 'am'),
            ('Those flowers ___ colourful.', 'are', 'is', 'am'),
            ('The puppy ___ playful.', 'is', 'are', 'am'),
            ('You ___ very kind.', 'are', 'is', 'am')
          ];
          final r = rows[k % rows.length];
          return _mc(
              id: id,
              prompt: r.$1,
              correct: AnswerOption(label: r.$2),
              wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
              shift: index);
        default:
          const rows = [
            ('She sang ___.', 'beautifully', 'beautiful', 'beauty'),
            ('The turtle moved ___.', 'slowly', 'slow', 'slowness'),
            ('He answered ___.', 'politely', 'polite', 'politeness'),
            ('The rain fell ___.', 'heavily', 'heavy', 'heaviness'),
            ('We waited ___.', 'patiently', 'patient', 'patience'),
            ('The child smiled ___.', 'happily', 'happy', 'happiness'),
            ('The bell rang ___.', 'loudly', 'loud', 'loudness'),
            ('The artist worked ___.', 'carefully', 'careful', 'care'),
            ('The athlete ran ___.', 'swiftly', 'swift', 'swiftness')
          ];
          final r = rows[k % rows.length];
          return _mc(
              id: id,
              prompt: r.$1,
              correct: AnswerOption(label: r.$2),
              wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
              shift: index);
      }
    }

    switch (mode) {
      case 0:
        final r = synonyms[k % synonyms.length];
        return _mc(
            id: id,
            prompt: 'Best synonym of “${r.$1}”?',
            correct: AnswerOption(label: r.$2),
            wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
            shift: index);
      case 1:
        final r = antonyms[k % antonyms.length];
        return _mc(
            id: id,
            prompt: 'Best antonym of “${r.$1}”?',
            correct: AnswerOption(label: r.$2),
            wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
            shift: index);
      case 2:
        final r = homophones[k % homophones.length];
        return _mc(
            id: id,
            prompt: r.$1,
            correct: AnswerOption(label: r.$2),
            wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
            shift: index);
      case 3:
        final r = conjunctions[k % conjunctions.length];
        return _mc(
            id: id,
            prompt: r.$1,
            correct: AnswerOption(label: r.$2),
            wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
            shift: index);
      case 4:
        const rows = [
          ('If I study, I ___ learn.', 'will', 'would', 'had'),
          ('Yesterday we ___ the museum.', 'visited', 'visit', 'will visit'),
          ('By noon, she had ___ the book.', 'finished', 'finish', 'finishing'),
          ('Tomorrow they ___ compete.', 'will', 'did', 'have'),
          ('He has ___ his lunch.', 'eaten', 'ate', 'eat'),
          ('We were ___ when it rained.', 'playing', 'played', 'play'),
          ('She is ___ a model now.', 'building', 'built', 'build'),
          ('Last week they ___ a tree.', 'planted', 'plant', 'will plant'),
          (
            'By evening, I will have ___ it.',
            'completed',
            'complete',
            'completing'
          )
        ];
        final r = rows[k % rows.length];
        return _mc(
            id: id,
            prompt: r.$1,
            correct: AnswerOption(label: r.$2),
            wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
            shift: index);
      case 5:
        const rows = [
          ('The team of players ___ ready.', 'is', 'are', 'am'),
          ('Each child ___ a badge.', 'has', 'have', 'having'),
          ('Neither answer ___ correct.', 'is', 'are', 'be'),
          ('The books on the shelf ___ new.', 'are', 'is', 'was'),
          ('Mathematics ___ my favourite subject.', 'is', 'are', 'were'),
          ('My friends ___ nearby.', 'live', 'lives', 'living'),
          ('One of the lamps ___ broken.', 'is', 'are', 'were'),
          ('Both solutions ___ possible.', 'are', 'is', 'was'),
          ('The basket of mangoes ___ heavy.', 'is', 'are', 'were')
        ];
        final r = rows[k % rows.length];
        return _mc(
            id: id,
            prompt: r.$1,
            correct: AnswerOption(label: r.$2),
            wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
            shift: index);
      default:
        final r = prepositions[k % prepositions.length];
        return _mc(
            id: id,
            prompt: r.$1,
            correct: AnswerOption(label: r.$2),
            wrong: [AnswerOption(label: r.$3), AnswerOption(label: r.$4)],
            shift: index);
    }
  }

  static Question _world(
      int index, GradeLevel grade, Subject subject, int level, int slot) {
    final facts = _GradeWorldBanks.forGrade(grade, subject);
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

  // ---- LOGIC (expanded) ----------------------------------------------------
  static Question _logic(int index, GradeLevel grade, int level, int slot) {
    final id = 'gen_logic_${index}_$slot';
    final k = index ~/ 3;
    switch ((level - 1) % 3) {
      case 0: // Number pattern
        final steps = switch (grade) {
          GradeLevel.lkg => const [1],
          GradeLevel.ukg => const [1, 2],
          GradeLevel.kg => const [1, 2, 5],
          GradeLevel.grade1 => const [1, 2, 5, 10],
          GradeLevel.grade2 => const [2, 3, 4, 5, 10],
          GradeLevel.grade3 => const [2, 3, 4, 5, 6, 10],
          GradeLevel.grade4 => const [3, 4, 6, 7, 8, 9],
          GradeLevel.grade5 => const [4, 6, 7, 8, 9, 11, 12],
        };
        final step = steps[k % steps.length];
        final groups = switch (grade) {
          GradeLevel.lkg => 3,
          GradeLevel.ukg => 5,
          GradeLevel.kg => 6,
          _ => 10,
        };
        final start = (k % groups + 1) * step;
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
          ('Which is different?', 'Pen', '🖊️', 'Pizza', '🍕', 'Burger', '🍔'),
          ('Which is different?', 'Hat', '🎩', 'Bread', '🍞', 'Milk', '🥛'),
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
          ('biggest', 'Bus', '🚌', 'Car', '🚗', 'Bicycle', '🚲'),
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
