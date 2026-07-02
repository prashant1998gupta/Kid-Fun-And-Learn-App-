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
  };

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    for (final entry in _assetByGrade.entries) {
      await _loadAsset(entry.value, entry.key);
    }
    _loaded = true;
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
