import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/curriculum/data/curriculum_repository.dart';
import 'package:kidverse/features/curriculum/domain/lesson.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CurriculumRepository repo;
  setUpAll(() async {
    repo = CurriculumRepository();
    await repo.ensureLoaded();
  });

  // Games whose progression depends on tapping the one correct option.
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

  String signature(Question q) {
    final opts = q.options.map((o) => '${o.label}/${o.emoji ?? ''}').join(',');
    return '${q.prompt}|$opts|${q.answer}';
  }

  test('every subject in every grade is a full 50-level journey', () {
    for (final grade in GradeLevel.values) {
      final units = repo.unitsForGrade(grade);
      expect(units, isNotEmpty, reason: '${grade.name} should have subjects');
      for (final unit in units) {
        final lessons = repo.lessonsForUnit(unit);
        expect(lessons.length, 50,
            reason: '${unit.id} should offer 50 levels');
      }
    }
  });

  test('every level has a full, non-repeating question set', () {
    // Minimum questions by mini-game (memory is one board; tap games a round).
    int minFor(GameType g) => switch (g) {
          GameType.memoryMatch => 1,
          GameType.sequence => 5,
          GameType.tracing => 6,
          _ => 10,
        };
    for (final grade in GradeLevel.values) {
      for (final unit in repo.unitsForGrade(grade)) {
        for (final lesson in repo.lessonsForUnit(unit)) {
          expect(lesson.questions.length,
              greaterThanOrEqualTo(minFor(lesson.gameType)),
              reason: '${lesson.id} (${lesson.gameType.name}) is too short');
          // No two questions in a level are identical.
          final sigs = lesson.questions.map(signature).toList();
          expect(sigs.toSet().length, sigs.length,
              reason: '${lesson.id} repeats a question within the level');
        }
      }
    }
  });

  test('every choice question is answerable and unambiguous', () {
    final problems = <String>[];
    for (final grade in GradeLevel.values) {
      for (final unit in repo.unitsForGrade(grade)) {
        for (final lesson in repo.lessonsForUnit(unit)) {
          if (!choiceGames.contains(lesson.gameType)) continue;
          for (final q in lesson.questions) {
            final where = '${grade.name}/${lesson.id}/${q.id}';
            if (q.options.isEmpty) {
              problems.add('$where: empty options');
              continue;
            }
            if (q.correctIndex == null ||
                q.correctIndex! < 0 ||
                q.correctIndex! >= q.options.length) {
              problems.add('$where: bad correctIndex ${q.correctIndex}');
              continue;
            }
            final labels = q.options.map((o) => o.label.trim()).toList();
            if (labels.toSet().length != labels.length) {
              problems.add('$where: duplicate options $labels');
            }
          }
        }
      }
    }
    if (problems.isNotEmpty) {
      // ignore: avoid_print
      print('\nCONTENT DEFECTS (${problems.length}):\n${problems.join('\n')}');
    }
    expect(problems, isEmpty, reason: '${problems.length} defects');
  });

  test('sequence & tracing levels carry the data their engines need', () {
    for (final grade in GradeLevel.values) {
      for (final unit in repo.unitsForGrade(grade)) {
        for (final lesson in repo.lessonsForUnit(unit)) {
          for (final q in lesson.questions) {
            if (lesson.gameType == GameType.tracing) {
              expect(q.answer, isNotNull,
                  reason: '${lesson.id} tracing needs an answer glyph');
            }
            if (lesson.gameType == GameType.sequence ||
                lesson.gameType == GameType.memoryMatch) {
              expect(q.options.length, greaterThanOrEqualTo(2),
                  reason: '${lesson.id} needs options');
            }
          }
        }
      }
    }
  });

  test('grades 4-5 include boss-battle levels', () {
    for (final grade in [GradeLevel.grade4, GradeLevel.grade5]) {
      final all = [
        for (final unit in repo.unitsForGrade(grade))
          ...repo.lessonsForUnit(unit),
      ];
      expect(all.any((l) => l.gameType == GameType.bossBattle), isTrue,
          reason: '${grade.name} should include boss battles');
    }
  });
}
