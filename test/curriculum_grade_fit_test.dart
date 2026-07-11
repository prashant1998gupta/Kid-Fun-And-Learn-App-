import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/curriculum/data/curriculum_repository.dart';
import 'package:kidverse/features/curriculum/domain/lesson.dart';
import 'package:kidverse/features/curriculum/domain/subject.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CurriculumRepository repo;
  setUpAll(() async {
    repo = CurriculumRepository();
    await repo.ensureLoaded();
  });

  Iterable<Lesson> lessons(GradeLevel grade) sync* {
    for (final unit in repo.unitsForGrade(grade)) {
      yield* repo.lessonsForUnit(unit);
    }
  }

  String childFacingText(Question question) => [
        question.prompt,
        question.speak ?? '',
        question.answer ?? '',
        ...question.options.map((option) => option.label),
      ].join(' ');

  test('preschool questions are voice-guided and use age-safe concepts', () {
    final forbidden = <GradeLevel, List<RegExp>>{
      GradeLevel.lkg: [
        RegExp(r'[×÷]'),
        RegExp(
            r'\b(?:LCM|HCF|decimal|fraction|perimeter|area|vapou?r|planet|gravity)\b',
            caseSensitive: false),
      ],
      GradeLevel.ukg: [
        RegExp(r'[×÷]'),
        RegExp(
            r'\b(?:LCM|HCF|decimal|fraction|perimeter|area|planet|gravity)\b',
            caseSensitive: false),
      ],
      GradeLevel.kg: [
        RegExp(r'[×÷]'),
        RegExp(r'\b(?:LCM|HCF|decimal|fraction|perimeter|area)\b',
            caseSensitive: false),
      ],
    };
    final problems = <String>[];

    for (final grade in [GradeLevel.lkg, GradeLevel.ukg, GradeLevel.kg]) {
      for (final lesson in lessons(grade)) {
        for (final question in lesson.questions) {
          final where = '${grade.name}/${lesson.id}/${question.id}';
          if ((question.speak ?? '').trim().isEmpty) {
            problems.add('$where has no spoken guidance');
          }
          final text = childFacingText(question);
          for (final pattern in forbidden[grade]!) {
            if (pattern.hasMatch(text)) {
              problems.add('$where uses an advanced concept: $text');
            }
          }
        }
      }
    }
    expect(problems, isEmpty, reason: problems.take(20).join('\n'));
  });

  test('advanced math concepts unlock only in their intended classes', () {
    final forbidden = <GradeLevel, List<RegExp>>{
      GradeLevel.grade1: [
        RegExp(r'[×÷]'),
        RegExp(r'\b(?:fraction|decimal|area|perimeter|LCM|HCF|volume|%)\b',
            caseSensitive: false)
      ],
      GradeLevel.grade2: [
        RegExp(r'\b(?:fraction|decimal|area|perimeter|LCM|HCF|volume|%)\b',
            caseSensitive: false)
      ],
      GradeLevel.grade3: [
        RegExp(r'\b(?:decimal|LCM|HCF|volume|%)\b', caseSensitive: false)
      ],
      GradeLevel.grade4: [
        RegExp(r'\b(?:LCM|HCF|volume|%)\b', caseSensitive: false)
      ],
    };
    final problems = <String>[];
    for (final entry in forbidden.entries) {
      for (final lesson
          in lessons(entry.key).where((l) => l.subject == Subject.math)) {
        for (final question in lesson.questions) {
          final text = childFacingText(question);
          for (final pattern in entry.value) {
            if (pattern.hasMatch(text)) {
              problems.add('${entry.key.name}/${lesson.id}: $text');
            }
          }
        }
      }
    }
    expect(problems, isEmpty, reason: problems.take(20).join('\n'));
  });

  test('each grade receives its own EVS and science question pool', () {
    final promptsByGrade = <GradeLevel, Set<String>>{};
    for (final grade in GradeLevel.values) {
      promptsByGrade[grade] = {
        for (final lesson in lessons(grade).where(
            (l) => l.subject == Subject.evs || l.subject == Subject.science))
          for (final question in lesson.questions) question.prompt,
      };
      expect(promptsByGrade[grade], isNotEmpty);
    }
    for (var i = 0; i < GradeLevel.values.length; i++) {
      for (var j = i + 1; j < GradeLevel.values.length; j++) {
        expect(promptsByGrade[GradeLevel.values[i]],
            isNot(equals(promptsByGrade[GradeLevel.values[j]])),
            reason:
                '${GradeLevel.values[i].name} and ${GradeLevel.values[j].name} must not share an identical world-knowledge curriculum');
      }
    }
  });

  test('every generated level is focused on one taught skill', () {
    final problems = <String>[];
    for (final grade in GradeLevel.values) {
      for (final lesson in lessons(grade)) {
        final skills = lesson.questions.map((q) => q.skillId).toSet();
        if (skills.length != 1) {
          problems.add('${lesson.id} mixes ${skills.join(', ')}');
        }
        for (final question in lesson.questions) {
          if (question.skillId == 'general.practice' ||
              (question.teachingTip ?? '').trim().isEmpty ||
              (question.rescueTip ?? '').trim().isEmpty) {
            problems.add('${lesson.id}/${question.id} lacks learning metadata');
          }
        }
      }
    }
    expect(problems, isEmpty, reason: problems.take(20).join('\n'));
  });

  test('advanced skills declare their learning prerequisites', () {
    const advanced = {
      'math.multiplication',
      'math.division',
      'math.fractions',
      'math.decimals',
      'math.area',
      'math.perimeter',
      'math.volume',
      'math.lcm',
      'math.hcf',
      'math.percentage',
      'english.spelling',
      'english.sentences',
      'english.adjectives',
      'english.pronouns',
      'english.adverbs',
      'english.agreement',
      'english.tenses',
      'english.conjunctions',
    };
    for (final grade in GradeLevel.values) {
      for (final lesson in lessons(grade)) {
        for (final question in lesson.questions) {
          if (advanced.contains(question.skillId)) {
            expect(question.prerequisiteSkillIds, isNotEmpty,
                reason: '${question.skillId} needs a prerequisite');
          }
        }
      }
    }
  });
}
