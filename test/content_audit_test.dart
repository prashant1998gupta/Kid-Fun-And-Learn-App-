import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/curriculum/data/curriculum_repository.dart';
import 'package:kidverse/features/curriculum/domain/lesson.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';

/// Audits EVERY question across every grade for answer-correctness defects that
/// a child would experience as "I picked the right answer but it said wrong":
///  - choice games with null / out-of-range correctIndex
///  - empty option lists on a game that needs options
///  - duplicate option labels (two identical-looking choices)
///  - a distractor whose label equals the correct option's label
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Games whose advance depends on tapping the single correct option.
  const choiceGames = {
    GameType.tapChoice,
    GameType.listenAndTap,
    GameType.bubblePop,
    GameType.moleMatch,
    GameType.feedPet,
    GameType.bossBattle,
    GameType.countCatch,
    GameType.spotMatch,
  };

  test('AUDIT: every choice question is answerable and unambiguous', () async {
    final repo = CurriculumRepository();
    await repo.ensureLoaded();

    final problems = <String>[];

    for (final grade in GradeLevel.values) {
      for (final unit in repo.unitsForGrade(grade)) {
        for (final lesson in repo.lessonsForUnit(unit)) {
          if (!choiceGames.contains(lesson.gameType)) continue;
          for (final q in lesson.questions) {
            final where = '${grade.name}/${lesson.id}/${q.id}';

            if (q.options.isEmpty) {
              problems.add('$where: EMPTY options');
              continue;
            }
            if (q.correctIndex == null) {
              problems.add('$where: null correctIndex ("${q.prompt}")');
              continue;
            }
            if (q.correctIndex! < 0 || q.correctIndex! >= q.options.length) {
              problems.add('$where: correctIndex ${q.correctIndex} out of '
                  'range (${q.options.length} options)');
              continue;
            }
            // Duplicate labels → two identical-looking choices.
            final labels = q.options.map((o) => o.label.trim()).toList();
            final dupes = <String>{};
            final seen = <String>{};
            for (final l in labels) {
              if (!seen.add(l)) dupes.add(l);
            }
            if (dupes.isNotEmpty) {
              problems.add('$where: duplicate option label(s) '
                  '${dupes.toList()} in $labels ("${q.prompt}")');
            }
          }
        }
      }
    }

    if (problems.isNotEmpty) {
      // Print each defect so we can fix the exact content.
      // ignore: avoid_print
      print('\n===== CONTENT DEFECTS (${problems.length}) =====');
      for (final p in problems) {
        // ignore: avoid_print
        print(p);
      }
    }
    expect(problems, isEmpty,
        reason: '${problems.length} question defects found (see log above)');
  });
}
