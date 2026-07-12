part of 'learning_adventure_game.dart';

/// Structural audit used by tests to exercise every generated learning round,
/// including levels that a short widget test cannot reasonably play through.
class LearningAdventureAudit {
  LearningAdventureAudit._();

  static int correctIndex(LearningAdventureType type, int level, int round) =>
      _AdventureContent.question(type, level, round).correctIndex;

  static String questionIdentity(
    LearningAdventureType type,
    int level,
    int round,
  ) =>
      _AdventureContent.question(type, level, round).identity;

  static List<String> validateAll() {
    final errors = <String>[];
    for (final type in LearningAdventureType.values) {
      for (var level = 1; level <= 50; level++) {
        for (var round = 0; round < 5; round++) {
          try {
            final question = _AdventureContent.question(type, level, round);
            final location = '${type.id} level $level round ${round + 1}';
            if (question.choices.length < 2 || question.choices.length > 3) {
              errors.add('$location has ${question.choices.length} choices');
            }
            if (question.correctIndex < 0 ||
                question.correctIndex >= question.choices.length) {
              errors.add('$location has an invalid correct answer');
            }
            final labels =
                question.choices.map((choice) => choice.label).toSet();
            if (labels.length != question.choices.length) {
              errors.add('$location has duplicate answer labels');
            }
            if (question.prompt.trim().isEmpty ||
                question.spokenPrompt.trim().isEmpty ||
                question.scene.isEmpty) {
              errors.add('$location has incomplete child-facing content');
            }
            // Protect the teach-first progression inside each 50-level game.
            // Later concepts must not leak into the recognition/foundation
            // levels simply because a generator formula changed.
            final skill = question.skill.toLowerCase();
            if (type == LearningAdventureType.numberGarden &&
                level <= 30 &&
                skill.contains('addition')) {
              errors.add('$location introduces addition before level 31');
            }
            if (type == LearningAdventureType.clockAdventure &&
                level <= 25 &&
                skill.contains('half-hour')) {
              errors.add('$location introduces half-hours before level 26');
            }
            if (type == LearningAdventureType.fractionCafe &&
                level <= 18 &&
                (skill.contains('equivalent') || skill.contains('add like'))) {
              errors.add('$location skips basic fraction models');
            }
            if (type == LearningAdventureType.multiplicationKingdom &&
                level <= 18 &&
                (skill.contains('division') ||
                    skill.contains('missing factor'))) {
              errors.add('$location skips equal-group foundations');
            }
            if (type == LearningAdventureType.codeRobot &&
                level <= 18 &&
                (skill.contains('loop') || skill.contains('debug'))) {
              errors.add('$location skips movement-command foundations');
            }
          } catch (error) {
            errors.add('${type.id} level $level round ${round + 1}: $error');
          }
        }
      }
    }
    return errors;
  }
}
