import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/curriculum/data/curriculum_repository.dart';
import 'package:kidverse/features/curriculum/domain/lesson.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';

void main() {
  // Asset-backed: verifies the hand-authored curriculum JSON parses cleanly
  // and the repository indexes it. Uses a widgets binding so rootBundle works.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Every grade that ships a content file must parse and cross-reference.
  const authoredGrades = [
    GradeLevel.lkg,
    GradeLevel.ukg,
    GradeLevel.grade1,
    GradeLevel.grade2,
    GradeLevel.grade3,
    GradeLevel.grade4,
    GradeLevel.grade5,
  ];

  test('all authored grades load and parse without errors', () async {
    final repo = CurriculumRepository();
    await repo.ensureLoaded();

    for (final grade in authoredGrades) {
      final units = repo.unitsForGrade(grade);
      expect(units, isNotEmpty, reason: '${grade.name} units should parse');

      // Every lessonId referenced by a unit must resolve to a real lesson with
      // at least one question — catches typos between units[] and lessons[].
      for (final unit in units) {
        final lessons = repo.lessonsForUnit(unit);
        expect(
          lessons.length,
          unit.lessonIds.length,
          reason: 'All lessonIds in ${unit.id} should resolve',
        );
        for (final lesson in lessons) {
          expect(lesson.questions, isNotEmpty,
              reason: '${lesson.id} should have questions');
          // The lesson's grade must match its owning unit.
          expect(lesson.grade, unit.grade,
              reason: '${lesson.id} grade should match ${unit.id}');
        }
      }
    }
  });

  test('grades 1-5 span several subjects each', () async {
    final repo = CurriculumRepository();
    await repo.ensureLoaded();
    for (final grade in [
      GradeLevel.grade1,
      GradeLevel.grade2,
      GradeLevel.grade3,
      GradeLevel.grade4,
      GradeLevel.grade5,
    ]) {
      expect(
        repo.subjectsForGrade(grade).length,
        greaterThanOrEqualTo(4),
        reason: '${grade.name} should span multiple subjects',
      );
    }
  });

  test('grades 4-5 finish with a playable boss battle', () async {
    final repo = CurriculumRepository();
    await repo.ensureLoaded();
    for (final grade in [GradeLevel.grade4, GradeLevel.grade5]) {
      final lessons = [
        for (final unit in repo.unitsForGrade(grade))
          ...repo.lessonsForUnit(unit),
      ];
      final bosses = lessons.where((l) => l.gameType == GameType.bossBattle);
      expect(bosses, isNotEmpty, reason: '${grade.name} needs a boss lesson');
      for (final boss in bosses) {
        expect(boss.questions.length, greaterThanOrEqualTo(4));
        expect(boss.questions.every((q) => q.correctIndex != null), isTrue);
      }
    }
  });

  test('grades 4-5 provide 50 levels with 20 questions each', () async {
    final repo = CurriculumRepository();
    await repo.ensureLoaded();
    for (final grade in [GradeLevel.grade4, GradeLevel.grade5]) {
      final lessons = [
        for (final unit in repo.unitsForGrade(grade))
          ...repo.lessonsForUnit(unit),
      ];
      expect(lessons.length, 50, reason: '${grade.name} needs 50 levels');
      expect(
        lessons.every((lesson) => lesson.questions.length >= 20),
        isTrue,
        reason: '${grade.name} levels need full question sessions',
      );
    }
  });
}
