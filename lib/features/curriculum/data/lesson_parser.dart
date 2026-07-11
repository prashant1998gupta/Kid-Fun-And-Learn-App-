import '../../profiles/domain/grade_level.dart';
import '../domain/lesson.dart';
import '../domain/subject.dart';

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
      // Authored lessons are *seeds*: they define the subject, mini-game types
      // and artwork. The playable 50-level journeys (with fresh, non-repeating
      // questions) are generated in CurriculumRepository via QuestionFactory.
      questions: seeds,
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
      skillId: j['skillId'] as String? ?? 'general.practice',
      prerequisiteSkillIds:
          (j['prerequisiteSkillIds'] as List?)?.cast<String>() ?? const [],
      teachingTip: j['teachingTip'] as String?,
      rescueTip: j['rescueTip'] as String?,
      options: ((j['options'] as List?) ?? const [])
          .map((o) => AnswerOption.fromJson((o as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  static GameType _gameType(String id) {
    return GameType.values.firstWhere(
      (g) => g.name == id,
      orElse: () => GameType.tapChoice,
    );
  }
}
