import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/ai/adaptive_engine.dart';
import 'package:kidverse/features/curriculum/domain/lesson.dart';
import 'package:kidverse/features/curriculum/domain/subject.dart';
import 'package:kidverse/features/gamification/reward_engine.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';

void main() {
  const multiplication = Question(
    id: 'multiply-1',
    prompt: '3 × 2?',
    skillId: 'math.multiplication',
    prerequisiteSkillIds: ['math.addition'],
  );
  const lesson = Lesson(
    id: 'skill-lesson',
    title: 'Equal groups',
    subject: Subject.math,
    grade: GradeLevel.grade2,
    gameType: GameType.tapChoice,
    questions: [multiplication],
  );

  test('adaptive model tracks concept mastery independently of subject', () {
    final model = SkillModel();
    expect(model.hasSeenConcept('child', 'math.multiplication'), isFalse);
    model.observe(
      'child',
      const LessonResult(
        lesson: lesson,
        correct: 1,
        total: 1,
        firstTryCorrect: 1,
        struggledQuestionIds: [],
        durationSeconds: 10,
      ),
    );
    expect(model.hasSeenConcept('child', 'math.multiplication'), isTrue);
    expect(model.conceptMastery('child', 'math.multiplication'),
        greaterThan(0.35));
    expect(model.prerequisitesMet('child', ['math.addition']), isFalse);
  });

  test('concept mastery survives persistence migration', () {
    final model = SkillModel();
    model.observe(
      'child',
      const LessonResult(
        lesson: lesson,
        correct: 1,
        total: 1,
        firstTryCorrect: 1,
        struggledQuestionIds: [],
        durationSeconds: 10,
      ),
    );
    final restored = SkillModel.fromMap(model.toMap());
    expect(restored.conceptMastery('child', 'math.multiplication'),
        model.conceptMastery('child', 'math.multiplication'));
  });
}
