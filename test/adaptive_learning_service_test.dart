import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/ai/adaptive_engine.dart';
import 'package:kidverse/features/ai/adaptive_learning_service.dart';
import 'package:kidverse/features/curriculum/domain/lesson.dart';
import 'package:kidverse/features/curriculum/domain/subject.dart';
import 'package:kidverse/features/gamification/reward_engine.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';
import 'package:kidverse/features/progress/progress_controller.dart';

Question question(String id, String skill, int answer,
        {List<String> prerequisites = const []}) =>
    Question(
      id: id,
      prompt: 'Question $id',
      skillId: skill,
      prerequisiteSkillIds: prerequisites,
      correctIndex: answer,
      options: const [
        AnswerOption(label: 'A'),
        AnswerOption(label: 'B'),
        AnswerOption(label: 'C'),
      ],
    );

Lesson lesson(String id, String skill, int count,
        {List<String> prerequisites = const []}) =>
    Lesson(
      id: id,
      title: id,
      subject: Subject.math,
      grade: GradeLevel.grade2,
      gameType: GameType.tapChoice,
      questions: [
        for (var i = 0; i < count; i++)
          question('$id-$i', skill, i % 3, prerequisites: prerequisites),
      ],
    );

void observePerfect(SkillModel model, Lesson source) {
  model.observe(
    'child',
    LessonResult(
      lesson: source,
      correct: source.questions.length,
      total: source.questions.length,
      firstTryCorrect: source.questions.length,
    ),
  );
}

void main() {
  const service = AdaptiveLearningService();
  final addition = lesson('addition', 'math.addition', 6);
  final multiplication = lesson(
    'multiplication',
    'math.multiplication',
    6,
    prerequisites: const ['math.addition'],
  );
  final division = lesson(
    'division',
    'math.division',
    6,
    prerequisites: const ['math.multiplication'],
  );
  final lessons = [addition, multiplication, division];

  test('missing prerequisite routes to a foundation replay', () {
    final model = SkillModel();
    const progress = ProgressState({'child|addition': 3});
    final result = service.recommend(
      childId: 'child',
      orderedLessons: lessons,
      progress: progress,
      model: model,
    );

    expect(result, isNotNull);
    expect(result!.lesson.id, 'addition');
    expect(result.skillId, 'math.addition');
    expect(result.foundation, isTrue);
  });

  test('secure prerequisite allows the next unlocked skill', () {
    final model = SkillModel();
    observePerfect(model, addition);
    observePerfect(model, addition);
    const progress = ProgressState({'child|addition': 3});
    final result = service.recommend(
      childId: 'child',
      orderedLessons: lessons,
      progress: progress,
      model: model,
    );

    expect(result, isNotNull);
    expect(result!.lesson.id, 'multiplication');
    expect(result.foundation, isFalse);
  });

  test('smart revision is confidence first, targeted, and five steps', () {
    final model = SkillModel();
    observePerfect(model, addition);
    observePerfect(model, addition);
    const progress = ProgressState({'child|addition': 3});
    final plan = service.buildRevision(
      childId: 'child',
      orderedLessons: lessons,
      progress: progress,
      model: model,
    );

    expect(plan, isNotNull);
    expect(plan!.lesson.questions, hasLength(5));
    expect(plan.lesson.grade, GradeLevel.grade2);
    expect(plan.lesson.gameType, GameType.tapChoice);
    expect(plan.lesson.questions.first.skillId, 'math.addition');
    expect(
      plan.lesson.questions
          .where((question) => question.skillId == plan.focusSkillId)
          .length,
      greaterThanOrEqualTo(3),
    );
  });

  test('concept stage labels are parent-friendly', () {
    expect(conceptStage(0.3), ConceptStage.needsHelp);
    expect(conceptStage(0.6), ConceptStage.developing);
    expect(conceptStage(0.8), ConceptStage.mastered);
    expect(skillLabel('math.place-value'), 'Place value');
  });
}
