import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/curriculum/data/curriculum_repository.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';

void main() {
  // Asset-backed: verifies the hand-authored curriculum JSON parses cleanly
  // and the repository indexes it. Uses a widgets binding so rootBundle works.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LKG + UKG curriculum load and parse without errors', () async {
    final repo = CurriculumRepository();
    await repo.ensureLoaded();

    final lkgUnits = repo.unitsForGrade(GradeLevel.lkg);
    final ukgUnits = repo.unitsForGrade(GradeLevel.ukg);

    expect(lkgUnits, isNotEmpty, reason: 'LKG units should parse');
    expect(ukgUnits, isNotEmpty, reason: 'UKG units should parse');

    // Every lessonId referenced by a unit must resolve to a real lesson with
    // at least one question — catches typos between units[] and lessons[].
    for (final unit in [...lkgUnits, ...ukgUnits]) {
      final lessons = repo.lessonsForUnit(unit);
      expect(
        lessons.length,
        unit.lessonIds.length,
        reason: 'All lessonIds in ${unit.id} should resolve',
      );
      for (final lesson in lessons) {
        expect(lesson.questions, isNotEmpty,
            reason: '${lesson.id} should have questions');
      }
    }
  });
}
