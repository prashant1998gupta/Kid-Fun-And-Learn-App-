import '../curriculum/domain/lesson.dart';
import '../progress/progress_controller.dart';
import 'adaptive_engine.dart';

enum ConceptStage { needsHelp, developing, mastered }

extension ConceptStageData on ConceptStage {
  String get label => switch (this) {
        ConceptStage.needsHelp => 'Needs help',
        ConceptStage.developing => 'Developing',
        ConceptStage.mastered => 'Mastered',
      };
}

ConceptStage conceptStage(double mastery) {
  if (mastery >= 0.75) return ConceptStage.mastered;
  if (mastery >= 0.5) return ConceptStage.developing;
  return ConceptStage.needsHelp;
}

String skillLabel(String skillId) {
  final raw = skillId.split('.').last.replaceAll('-', ' ');
  return raw.isEmpty
      ? 'Practice'
      : '${raw[0].toUpperCase()}${raw.substring(1)}';
}

class LearningRecommendation {
  const LearningRecommendation({
    required this.lesson,
    required this.skillId,
    required this.reason,
    required this.foundation,
    required this.mastery,
  });

  final Lesson lesson;
  final String skillId;
  final String reason;
  final bool foundation;
  final double mastery;
}

class SmartRevisionPlan {
  const SmartRevisionPlan({
    required this.lesson,
    required this.focusSkillId,
    required this.reason,
  });

  final Lesson lesson;
  final String focusSkillId;
  final String reason;
}

class AdaptiveLearningService {
  const AdaptiveLearningService();

  LearningRecommendation? recommend({
    required String childId,
    required List<Lesson> orderedLessons,
    required ProgressState progress,
    required SkillModel model,
  }) {
    if (orderedLessons.isEmpty) return null;
    final nextIndex = orderedLessons.indexWhere(
      (lesson) => !progress.isCompleted(childId, lesson.id),
    );
    final next = nextIndex < 0 ? null : orderedLessons[nextIndex];

    if (next != null && next.questions.isNotEmpty) {
      final question = next.questions.first;
      final missing = question.prerequisiteSkillIds
          .where((skill) => model.conceptMastery(childId, skill) < 0.6)
          .toList()
        ..sort((a, b) => model
            .conceptMastery(childId, a)
            .compareTo(model.conceptMastery(childId, b)));
      if (missing.isNotEmpty) {
        final prerequisite = missing.first;
        final foundationLesson = _lessonForSkill(
          orderedLessons,
          prerequisite,
          preferCompletedBy: (lesson) =>
              progress.isCompleted(childId, lesson.id),
        );
        if (foundationLesson != null) {
          return LearningRecommendation(
            lesson: foundationLesson,
            skillId: prerequisite,
            reason:
                'A quick ${skillLabel(prerequisite).toLowerCase()} mission will make ${skillLabel(question.skillId).toLowerCase()} easier.',
            foundation: true,
            mastery: model.conceptMastery(childId, prerequisite),
          );
        }
      }
    }

    final weak = model
        .conceptMasteries(childId)
        .entries
        .where((entry) => entry.value < 0.55)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    for (final entry in weak) {
      final lesson = _lessonForSkill(
        orderedLessons,
        entry.key,
        preferCompletedBy: (candidate) =>
            progress.isCompleted(childId, candidate.id),
      );
      if (lesson != null) {
        return LearningRecommendation(
          lesson: lesson,
          skillId: entry.key,
          reason:
              '${skillLabel(entry.key)} is still developing. A short replay can build confidence.',
          foundation: true,
          mastery: entry.value,
        );
      }
    }

    final lesson = next ?? orderedLessons.last;
    final skill = lesson.questions.isEmpty
        ? '${lesson.subject.name}.practice'
        : lesson.questions.first.skillId;
    return LearningRecommendation(
      lesson: lesson,
      skillId: skill,
      reason: next == null
          ? 'The journey is complete. Replay this skill to improve your stars.'
          : 'This is the next unlocked step in the ${lesson.subject.label} journey.',
      foundation: false,
      mastery: model.conceptMastery(childId, skill),
    );
  }

  SmartRevisionPlan? buildRevision({
    required String childId,
    required List<Lesson> orderedLessons,
    required ProgressState progress,
    required SkillModel model,
  }) {
    if (orderedLessons.isEmpty) return null;
    final recommendation = recommend(
      childId: childId,
      orderedLessons: orderedLessons,
      progress: progress,
      model: model,
    );
    if (recommendation == null) return null;

    final usable = <({Lesson lesson, Question question, int lessonIndex})>[
      for (var lessonIndex = 0;
          lessonIndex < orderedLessons.length;
          lessonIndex++)
        for (final question in orderedLessons[lessonIndex].questions)
          if (question.correctIndex != null && question.options.length >= 2)
            (
              lesson: orderedLessons[lessonIndex],
              question: question,
              lessonIndex: lessonIndex,
            ),
    ];
    if (usable.length < 5) return null;

    final chosen = <Question>[];
    final signatures = <String>{};
    void add(Question question) {
      final signature = '${question.id}|${question.prompt}';
      if (signatures.add(signature)) chosen.add(question);
    }

    final confidence = usable.where((item) {
      final mastery = model.conceptMastery(childId, item.question.skillId);
      return mastery >= 0.65 || item.lessonIndex == 0;
    });
    add(confidence.isNotEmpty
        ? confidence.first.question
        : usable.first.question);

    var focusSkillId = recommendation.skillId;
    var target =
        usable.where((item) => item.question.skillId == focusSkillId).toList();
    if (target.length < 3) {
      final bySkill = <String,
          List<({Lesson lesson, Question question, int lessonIndex})>>{};
      for (final item in usable) {
        bySkill.putIfAbsent(item.question.skillId, () => []).add(item);
      }
      final candidates = bySkill.entries
          .where((entry) => entry.value.length >= 3)
          .toList()
        ..sort((a, b) => model
            .conceptMastery(childId, a.key)
            .compareTo(model.conceptMastery(childId, b.key)));
      if (candidates.isNotEmpty) {
        focusSkillId = candidates.first.key;
        target = candidates.first.value;
      }
    }
    for (final item in target) {
      if (chosen.length >= 4) break;
      add(item.question);
    }

    final lowMastery = [...usable]..sort((a, b) => model
        .conceptMastery(childId, a.question.skillId)
        .compareTo(model.conceptMastery(childId, b.question.skillId)));
    for (final item in lowMastery) {
      if (chosen.length >= 4) break;
      add(item.question);
    }

    final nextIndex = orderedLessons.indexWhere(
      (lesson) => !progress.isCompleted(childId, lesson.id),
    );
    final challengeLimit = nextIndex < 0
        ? orderedLessons.length - 1
        : (nextIndex + 1).clamp(0, orderedLessons.length - 1);
    final challenge = usable
        .where((item) => item.lessonIndex <= challengeLimit)
        .toList()
      ..sort((a, b) => b.lessonIndex.compareTo(a.lessonIndex));
    for (final item in challenge) {
      if (chosen.length >= 5) break;
      add(item.question);
    }
    for (final item in usable) {
      if (chosen.length >= 5) break;
      add(item.question);
    }
    if (chosen.length < 5) return null;

    final source = recommendation.lesson;
    return SmartRevisionPlan(
      focusSkillId: focusSkillId,
      reason:
          'One confidence question, three ${skillLabel(focusSkillId).toLowerCase()} steps, and one gentle challenge.',
      lesson: Lesson(
        id: 'smart_revision_${source.grade.name}_${source.subject.name}',
        title: 'Daily Smart Revision',
        subject: source.subject,
        grade: source.grade,
        gameType: GameType.tapChoice,
        questions: chosen.take(5).toList(growable: false),
        emoji: '🎯',
        instruction: 'Five small steps chosen for you.',
        baseCoins: 8,
        baseXp: 16,
      ),
    );
  }

  Lesson? _lessonForSkill(
    List<Lesson> lessons,
    String skillId, {
    required bool Function(Lesson lesson) preferCompletedBy,
  }) {
    final matches = lessons
        .where((lesson) =>
            lesson.questions.isNotEmpty &&
            lesson.questions.first.skillId == skillId)
        .toList();
    if (matches.isEmpty) return null;
    return matches.firstWhere(preferCompletedBy, orElse: () => matches.first);
  }
}
