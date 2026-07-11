part of 'learning_adventure_game.dart';

/// Structural audit used by tests to exercise every generated learning round,
/// including levels that a short widget test cannot reasonably play through.
class LearningAdventureAudit {
  LearningAdventureAudit._();

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
          } catch (error) {
            errors.add('${type.id} level $level round ${round + 1}: $error');
          }
        }
      }
    }
    return errors;
  }
}
