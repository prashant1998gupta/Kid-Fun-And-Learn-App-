import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profiles/domain/grade_level.dart';
import '../domain/lesson.dart';
import '../domain/subject.dart';
import 'lesson_parser.dart';

/// Loads curriculum content. Today it reads bundled JSON assets (offline-first);
/// the same interface can later fetch from Firestore/Storage and cache locally,
/// with zero changes to callers.
class CurriculumRepository {
  CurriculumRepository();

  final Map<String, Lesson> _lessons = {};
  final List<Unit> _units = [];
  bool _loaded = false;

  /// Asset files per grade. As more grades are authored, add them here.
  static const _assetByGrade = {
    GradeLevel.lkg: 'assets/data/curriculum_lkg.json',
    GradeLevel.ukg: 'assets/data/curriculum_ukg.json',
    GradeLevel.kg: 'assets/data/curriculum_kg.json',
    GradeLevel.grade1: 'assets/data/curriculum_grade1.json',
    GradeLevel.grade2: 'assets/data/curriculum_grade2.json',
    GradeLevel.grade3: 'assets/data/curriculum_grade3.json',
    GradeLevel.grade4: 'assets/data/curriculum_grade4.json',
    GradeLevel.grade5: 'assets/data/curriculum_grade5.json',
  };

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    for (final entry in _assetByGrade.entries) {
      await _loadAsset(entry.value, entry.key);
    }
    for (final grade in [
      GradeLevel.lkg,
      GradeLevel.ukg,
      GradeLevel.kg,
      GradeLevel.grade4,
      GradeLevel.grade5,
    ]) {
      _expandGradeToFiftyLevels(grade);
    }
    _loaded = true;
  }

  /// Selected grades ship compact, reviewable seed JSON. At load time the
  /// levels are distributed evenly across their subject units, producing a
  /// 50-level learning journey without making asset files unmaintainable.
  void _expandGradeToFiftyLevels(GradeLevel grade) {
    final gradeUnitIndices = [
      for (var index = 0; index < _units.length; index++)
        if (_units[index].grade == grade) index,
    ];
    if (gradeUnitIndices.isEmpty) return;
    final levelsPerUnit = 50 ~/ gradeUnitIndices.length;
    final extraLevels = 50 % gradeUnitIndices.length;

    for (var position = 0; position < gradeUnitIndices.length; position++) {
      final unitIndex = gradeUnitIndices[position];
      final unit = _units[unitIndex];
      final seeds = lessonsForUnit(unit);
      if (seeds.isEmpty) continue;
      final target = levelsPerUnit + (position < extraLevels ? 1 : 0);
      final ids = [...unit.lessonIds];
      while (ids.length < target) {
        final level = ids.length + 1;
        final seed = seeds[(level - 1) % seeds.length];
        final id = '${unit.id}_level_$level';
        _lessons[id] = Lesson(
          id: id,
          title: '${seed.title} · Level $level',
          subject: seed.subject,
          grade: seed.grade,
          gameType: seed.gameType,
          questions: seed.questions,
          emoji: seed.emoji,
          instruction: seed.instruction,
          baseCoins: seed.baseCoins + level,
          baseXp: seed.baseXp + level * 2,
        );
        ids.add(id);
      }
      _units[unitIndex] = Unit(
        id: unit.id,
        title: unit.title,
        subject: unit.subject,
        grade: unit.grade,
        lessonIds: ids.take(target).toList(),
        emoji: unit.emoji,
      );
    }
  }

  Future<void> _loadAsset(String path, GradeLevel grade) async {
    try {
      final raw = await rootBundle.loadString(path);
      final json = jsonDecode(raw) as Map<String, dynamic>;

      for (final u in (json['units'] as List? ?? const [])) {
        final m = (u as Map).cast<String, dynamic>();
        _units.add(
          Unit(
            id: m['id'] as String,
            title: m['title'] as String,
            subject: Subject.fromId(m['subject'] as String),
            grade: GradeLevel.fromId(m['grade'] as String),
            emoji: m['emoji'] as String? ?? '📚',
            lessonIds: (m['lessonIds'] as List?)?.cast<String>() ?? const [],
          ),
        );
      }
      for (final l in (json['lessons'] as List? ?? const [])) {
        final lesson =
            LessonParser.lessonFromJson((l as Map).cast<String, dynamic>());
        _lessons[lesson.id] = lesson;
      }
    } catch (e) {
      // A missing/malformed grade file must not crash the app.
      // ignore: avoid_print
      print('Curriculum load failed for $path: $e');
    }
  }

  List<Unit> unitsForGrade(GradeLevel grade) =>
      _units.where((u) => u.grade == grade).toList();

  List<Unit> unitsForGradeSubject(GradeLevel grade, Subject subject) =>
      _units.where((u) => u.grade == grade && u.subject == subject).toList();

  Lesson? lessonById(String id) => _lessons[id];

  List<Lesson> lessonsForUnit(Unit unit) =>
      unit.lessonIds.map((id) => _lessons[id]).whereType<Lesson>().toList();

  Set<Subject> subjectsForGrade(GradeLevel grade) =>
      unitsForGrade(grade).map((u) => u.subject).toSet();
}

final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return CurriculumRepository();
});

/// Loads (once) and exposes the curriculum so screens can `.when(...)` on it.
final curriculumLoadProvider =
    FutureProvider<CurriculumRepository>((ref) async {
  final repo = ref.watch(curriculumRepositoryProvider);
  await repo.ensureLoaded();
  return repo;
});
