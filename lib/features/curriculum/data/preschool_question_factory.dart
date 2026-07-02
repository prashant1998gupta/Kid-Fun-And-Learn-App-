import '../../profiles/domain/grade_level.dart';
import '../domain/lesson.dart';
import '../domain/subject.dart';

/// Builds broad, deterministic preschool practice banks from small authored
/// seeds. Generated questions stay offline, grade-aware, and easy to audit.
class PreschoolQuestionFactory {
  const PreschoolQuestionFactory._();

  static List<Question> expand(
    List<Question> seeds, {
    required GradeLevel grade,
    required Subject subject,
    required GameType gameType,
    int count = 20,
    int startIndex = 0,
  }) {
    final questions = [...seeds];
    for (var index = questions.length; index < count; index++) {
      questions.add(_generate(startIndex + index, grade, subject, gameType));
    }
    return questions.take(count).toList();
  }

  /// Builds a fresh generated session for synthetic map levels. This prevents
  /// Level 2/3/4 from cloning the exact same generated question bank as Level 1.
  static List<Question> sessionForLevel({
    required GradeLevel grade,
    required Subject subject,
    required GameType gameType,
    required int level,
    int count = 20,
  }) {
    final startIndex = level * 37;
    return expand(
      const [],
      grade: grade,
      subject: subject,
      gameType: gameType,
      count: count,
      startIndex: startIndex,
    );
  }

  static Question _generate(
    int index,
    GradeLevel grade,
    Subject subject,
    GameType gameType,
  ) {
    return switch (gameType) {
      GameType.tracing => _tracing(index),
      GameType.sequence => _sequence(index, grade),
      GameType.memoryMatch => _memory(index),
      GameType.dragDrop || GameType.sorting => _sorting(index),
      _ => _choiceFor(index, grade, subject),
    };
  }

  static Question _tracing(int index) {
    final glyph = String.fromCharCode('A'.codeUnitAt(0) + (index % 26));
    return Question(
      id: 'auto_trace_$index',
      prompt: 'Trace $glyph',
      answer: glyph,
      speak: 'Trace the letter $glyph',
    );
  }

  static Question _sequence(int index, GradeLevel grade) {
    final width = grade == GradeLevel.lkg ? 3 : 4;
    final start = (index % 10) + 1;
    return Question(
      id: 'auto_sequence_$index',
      prompt: 'Put $start to ${start + width - 1} in order',
      speak: 'Tap the numbers in order',
      options: [
        for (var value = start; value < start + width; value++)
          AnswerOption(label: '$value'),
      ],
    );
  }

  static Question _memory(int index) {
    const sets = [
      ['🐶', '🐱', '🐮', '🐷'],
      ['🍎', '🍌', '🍇', '🍓'],
      ['🔴', '🔵', '🟢', '🟡'],
      ['⭐', '❤️', '🌙', '☀️'],
    ];
    final faces = sets[index % sets.length];
    return Question(
      id: 'auto_memory_$index',
      prompt: 'Memory board ${index + 1}',
      options: [
        for (final face in faces) AnswerOption(label: face, emoji: face)
      ],
    );
  }

  static Question _sorting(int index) {
    const items = [
      ('Apple', '🍎', 'Fruit', '🍓', 'Veggie', '🥕', 0),
      ('Carrot', '🥕', 'Fruit', '🍓', 'Veggie', '🥕', 1),
      ('Banana', '🍌', 'Fruit', '🍓', 'Veggie', '🥕', 0),
      ('Broccoli', '🥦', 'Fruit', '🍓', 'Veggie', '🥕', 1),
      ('Fish', '🐟', 'Land', '🌳', 'Water', '🌊', 1),
      ('Lion', '🦁', 'Land', '🌳', 'Water', '🌊', 0),
      ('Whale', '🐳', 'Land', '🌳', 'Water', '🌊', 1),
      ('Dog', '🐶', 'Land', '🌳', 'Water', '🌊', 0),
      ('Ball', '⚽', 'Round', '🔵', 'Not round', '◼️', 0),
      ('Book', '📕', 'Round', '🔵', 'Not round', '◼️', 1),
    ];
    final item = items[index % items.length];
    return Question(
      id: 'auto_sort_$index',
      prompt: 'Sort ${item.$1} · ${index + 1}',
      promptEmoji: item.$2,
      speak: 'Where does the ${item.$1.toLowerCase()} go?',
      correctIndex: item.$7,
      options: [
        AnswerOption(label: item.$3, emoji: item.$4),
        AnswerOption(label: item.$5, emoji: item.$6),
      ],
    );
  }

  static Question _choiceFor(
    int index,
    GradeLevel grade,
    Subject subject,
  ) {
    return switch (subject) {
      Subject.english || Subject.rhymes => _letterChoice(index),
      Subject.math => _mathChoice(index, grade),
      Subject.evs || Subject.science => _worldChoice(index),
      Subject.logic => _logicChoice(index),
      Subject.art => _colorChoice(index),
    };
  }

  static Question _letterChoice(int index) {
    final target = String.fromCharCode('A'.codeUnitAt(0) + (index % 26));
    final next = String.fromCharCode('A'.codeUnitAt(0) + ((index + 1) % 26));
    final far = String.fromCharCode('A'.codeUnitAt(0) + ((index + 7) % 26));
    return _choice(
      id: 'auto_letter_$index',
      prompt: 'Tap the letter $target',
      speak: 'Find the letter $target',
      correct: AnswerOption(label: target),
      wrong: [AnswerOption(label: next), AnswerOption(label: far)],
      shift: index,
    );
  }

  static Question _mathChoice(int index, GradeLevel grade) {
    final max = grade == GradeLevel.lkg ? 6 : 12;
    return switch (index % 4) {
      0 => _numberChoice(
          index,
          prompt:
              'How many stars? ${List.filled((index % max) + 1, '⭐').join()}',
          answer: (index % max) + 1,
        ),
      1 => _additionChoice(index, grade, max),
      2 => _numberChoice(
          index,
          prompt: 'What comes after ${((index ~/ 2) % (max - 1)) + 1}?',
          answer: ((index ~/ 2) % (max - 1)) + 2,
        ),
      _ => _biggerNumberChoice(index, max),
    };
  }

  static Question _additionChoice(int index, GradeLevel grade, int max) {
    final left = ((index ~/ 2) % (max - 2)) + 1;
    final right =
        grade == GradeLevel.lkg ? ((index ~/ 3) % 2) + 1 : (index % 3) + 1;
    return _numberChoice(
      index,
      prompt: '$left + $right = ?',
      answer: left + right,
    );
  }

  static Question _biggerNumberChoice(int index, int max) {
    final left = ((index ~/ 3) % max) + 1;
    var right = ((left + index ~/ 2) % max) + 1;
    if (right == left) right = (right % max) + 1;
    final answer = left > right ? left : right;
    final smaller = left > right ? right : left;
    // The prompt names exactly two numbers, so the choices must be exactly
    // those two — never a third distractor that could be larger than the
    // correct answer (which would make the right answer look wrong).
    return _choice(
      id: 'auto_math_$index',
      prompt: 'Which number is bigger: $left or $right?',
      speak: 'Find the bigger number',
      correct: AnswerOption(label: '$answer'),
      wrong: [AnswerOption(label: '$smaller')],
      shift: index,
    );
  }

  static Question _numberChoice(
    int index, {
    required String prompt,
    required int answer,
  }) {
    return _choice(
      id: 'auto_math_$index',
      prompt: prompt,
      speak: prompt.replaceAll('⭐', ''),
      correct: AnswerOption(label: '$answer'),
      wrong: [
        AnswerOption(label: '${answer == 1 ? answer + 2 : answer - 1}'),
        AnswerOption(label: '${answer + 1}'),
      ],
      shift: index,
    );
  }

  static Question _worldChoice(int index) {
    const facts = [
      ('Who says moo?', 'Cow', '🐄', 'Dog', '🐶', 'Duck', '🦆'),
      ('Who says woof?', 'Dog', '🐶', 'Cat', '🐱', 'Cow', '🐄'),
      ('Which one can fly?', 'Bird', '🐦', 'Fish', '🐟', 'Dog', '🐶'),
      ('Which one lives in water?', 'Fish', '🐟', 'Lion', '🦁', 'Cat', '🐱'),
      ('Which one is a fruit?', 'Apple', '🍎', 'Car', '🚗', 'Shoe', '👟'),
      ('What shines in daytime?', 'Sun', '☀️', 'Moon', '🌙', 'Umbrella', '☂️'),
      ('What do we use to see?', 'Eyes', '👀', 'Ears', '👂', 'Nose', '👃'),
      ('Which one grows?', 'Tree', '🌳', 'Rock', '🪨', 'Chair', '🪑'),
      (
        'What keeps us dry in rain?',
        'Umbrella',
        '☂️',
        'Spoon',
        '🥄',
        'Ball',
        '⚽'
      ),
      ('Which is safe to eat?', 'Banana', '🍌', 'Soap', '🧼', 'Crayon', '🖍️'),
    ];
    final fact = facts[index % facts.length];
    return _choice(
      id: 'auto_world_$index',
      prompt: '${fact.$1} · ${index + 1}',
      speak: fact.$1,
      correct: AnswerOption(label: fact.$2, emoji: fact.$3),
      wrong: [
        AnswerOption(label: fact.$4, emoji: fact.$5),
        AnswerOption(label: fact.$6, emoji: fact.$7),
      ],
      shift: index,
    );
  }

  static Question _logicChoice(int index) {
    const sets = [
      ('Which one is different?', 'Car', '🚗', 'Apple', '🍎', 'Banana', '🍌'),
      ('Which one is different?', 'Shoe', '👟', 'Dog', '🐶', 'Cat', '🐱'),
      (
        'Which shape has no corners?',
        'Circle',
        '🔵',
        'Square',
        '🟥',
        'Triangle',
        '🔺'
      ),
      ('Which one comes at night?', 'Moon', '🌙', 'Sun', '☀️', 'Rainbow', '🌈'),
      ('Which is the smallest?', 'Ant', '🐜', 'Dog', '🐶', 'Elephant', '🐘'),
    ];
    final set = sets[index % sets.length];
    return _choice(
      id: 'auto_logic_$index',
      prompt: '${set.$1} · ${index + 1}',
      speak: set.$1,
      correct: AnswerOption(label: set.$2, emoji: set.$3),
      wrong: [
        AnswerOption(label: set.$4, emoji: set.$5),
        AnswerOption(label: set.$6, emoji: set.$7),
      ],
      shift: index,
    );
  }

  static Question _colorChoice(int index) {
    const colors = [
      ('red', 'Red', '🔴', 'Blue', '🔵', 'Green', '🟢'),
      ('blue', 'Blue', '🔵', 'Yellow', '🟡', 'Red', '🔴'),
      ('green', 'Green', '🟢', 'Purple', '🟣', 'Orange', '🟠'),
    ];
    final color = colors[index % colors.length];
    return _choice(
      id: 'auto_color_$index',
      prompt: 'Tap ${color.$1} · ${index + 1}',
      speak: 'Find ${color.$1}',
      correct: AnswerOption(label: color.$2, emoji: color.$3),
      wrong: [
        AnswerOption(label: color.$4, emoji: color.$5),
        AnswerOption(label: color.$6, emoji: color.$7),
      ],
      shift: index,
    );
  }

  static Question _choice({
    required String id,
    required String prompt,
    required String speak,
    required AnswerOption correct,
    required List<AnswerOption> wrong,
    required int shift,
  }) {
    final original = [correct, ...wrong];
    final rotation = shift % original.length;
    final options = [
      ...original.skip(rotation),
      ...original.take(rotation),
    ];
    return Question(
      id: id,
      prompt: prompt,
      speak: speak,
      options: options,
      correctIndex: (original.length - rotation) % original.length,
    );
  }
}
