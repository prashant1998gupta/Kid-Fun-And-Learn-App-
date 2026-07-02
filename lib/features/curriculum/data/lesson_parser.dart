import '../../profiles/domain/grade_level.dart';
import '../domain/lesson.dart';
import '../domain/subject.dart';
import 'preschool_question_factory.dart';

/// Parses the curriculum JSON schema into domain [Lesson]s.
///
/// The schema is intentionally simple so non-engineers (curriculum designers)
/// can author content, and so it can later be served from Firestore/Storage
/// without code changes.
class LessonParser {
  static Lesson lessonFromJson(Map<String, dynamic> j) {
    final grade = GradeLevel.fromId(j['grade'] as String);
    final subject = Subject.fromId(j['subject'] as String);
    final gameType = _gameType(j['gameType'] as String);
    final seeds = ((j['questions'] as List?) ?? const [])
        .map((q) => _question((q as Map).cast<String, dynamic>()))
        .toList();
    return Lesson(
      id: j['id'] as String,
      title: j['title'] as String,
      subject: subject,
      grade: grade,
      gameType: gameType,
      emoji: j['emoji'] as String? ?? '⭐',
      instruction: j['instruction'] as String? ?? '',
      baseCoins: (j['baseCoins'] ?? 10) as int,
      baseXp: (j['baseXp'] ?? 20) as int,
      questions: grade.isPreSchool
          ? PreschoolQuestionFactory.expand(
              seeds,
              grade: grade,
              subject: subject,
              gameType: gameType,
            )
          : _expandQuestions(seeds, targetCount: 20),
    );
  }

  static Question _question(Map<String, dynamic> j) {
    return Question(
      id: j['id'] as String? ?? 'q',
      prompt: j['prompt'] as String? ?? '',
      promptEmoji: j['promptEmoji'] as String?,
      promptImage: j['promptImage'] as String?,
      correctIndex: j['correctIndex'] as int?,
      correctIndices: (j['correctIndices'] as List?)?.cast<int>() ?? const [],
      pairs: (j['pairs'] as List?)?.cast<String>() ?? const [],
      answer: j['answer'] as String?,
      speak: j['speak'] as String?,
      options: ((j['options'] as List?) ?? const [])
          .map((o) => AnswerOption.fromJson((o as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  /// Expands compact seed banks to twenty rounds. Preschool banks are handled
  /// by [PreschoolQuestionFactory] so added rounds contain varied learning
  /// prompts rather than simple repetition.
  static List<Question> _expandQuestions(
    List<Question> seeds, {
    required int targetCount,
  }) {
    if (seeds.isEmpty || seeds.length >= targetCount) return seeds;
    return List<Question>.generate(targetCount, (index) {
      final source = seeds[index % seeds.length];
      final cycle = index ~/ seeds.length;
      final options = source.options;
      final canRotate = options.length > 1 && source.correctIndex != null;
      final shift = canRotate ? cycle % options.length : 0;
      final rotated = shift == 0
          ? options
          : [...options.skip(shift), ...options.take(shift)];
      final correctIndex = canRotate
          ? (source.correctIndex! - shift) % options.length
          : source.correctIndex;
      return Question(
        id: '${source.id}_${cycle + 1}',
        prompt: source.prompt,
        promptEmoji: source.promptEmoji,
        promptImage: source.promptImage,
        options: rotated,
        correctIndex: correctIndex,
        correctIndices: source.correctIndices,
        pairs: source.pairs,
        answer: source.answer,
        speak: source.speak,
      );
    });
  }

  static GameType _gameType(String id) {
    return GameType.values.firstWhere(
      (g) => g.name == id,
      orElse: () => GameType.tapChoice,
    );
  }
}
