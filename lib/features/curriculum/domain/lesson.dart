import 'package:equatable/equatable.dart';

import '../../profiles/domain/grade_level.dart';
import 'subject.dart';

/// The kind of interactive activity a lesson renders as. The [GameRegistry]
/// maps each to a concrete playable screen. This enum is the contract between
/// curriculum content (data) and game engines (code).
enum GameType {
  tapChoice, // pick the right answer among options
  memoryMatch, // flip & match pairs
  dragDrop, // drag items to targets
  tracing, // trace a letter/number/shape
  bubblePop, // pop the correct bubbles
  sorting, // sort items into buckets
  sequence, // order items correctly
  wordBuilder, // build a word from letters
  countCatch, // count moving objects
  spotMatch, // match shadow/pair
  speak, // say the word aloud (speech recognition)
  bossBattle, // multi-question challenge with a visible boss health bar
}

/// One curriculum unit — a "chapter" grouping many lessons.
class Unit extends Equatable {
  const Unit({
    required this.id,
    required this.title,
    required this.subject,
    required this.grade,
    required this.lessonIds,
    this.emoji = '📚',
  });

  final String id;
  final String title;
  final Subject subject;
  final GradeLevel grade;
  final List<String> lessonIds;
  final String emoji;

  @override
  List<Object?> get props => [id, title, subject, grade];
}

/// A single playable lesson: metadata + a bank of questions/steps that the
/// matching [GameType] engine consumes.
class Lesson extends Equatable {
  const Lesson({
    required this.id,
    required this.title,
    required this.subject,
    required this.grade,
    required this.gameType,
    required this.questions,
    this.emoji = '⭐',
    this.instruction = '',
    this.baseCoins = 10,
    this.baseXp = 20,
  });

  final String id;
  final String title;
  final Subject subject;
  final GradeLevel grade;
  final GameType gameType;
  final List<Question> questions;
  final String emoji;
  final String instruction;
  final int baseCoins;
  final int baseXp;

  @override
  List<Object?> get props => [id, gameType, questions.length];
}

/// A generic question/step. Different [GameType]s read different fields, but
/// keeping one flexible shape lets all content live in the same JSON schema.
class Question extends Equatable {
  const Question({
    required this.id,
    required this.prompt,
    this.promptEmoji,
    this.promptImage,
    this.options = const [],
    this.correctIndex,
    this.correctIndices = const [],
    this.pairs = const [],
    this.answer,
    this.speak,
  });

  final String id;

  /// Spoken/shown prompt, e.g. "Which one is the letter A?"
  final String prompt;
  final String? promptEmoji;
  final String? promptImage;

  /// Choice options (for tapChoice/bubblePop) as display strings/emojis.
  final List<AnswerOption> options;
  final int? correctIndex;
  final List<int> correctIndices;

  /// For memoryMatch: list of pair keys.
  final List<String> pairs;

  /// For wordBuilder/tracing: the target answer.
  final String? answer;

  /// Optional voice line to speak when the question appears.
  final String? speak;

  @override
  List<Object?> get props => [id, prompt, correctIndex];
}

class AnswerOption extends Equatable {
  const AnswerOption({required this.label, this.emoji, this.image});
  final String label;
  final String? emoji;
  final String? image;

  factory AnswerOption.fromJson(Map<String, dynamic> j) => AnswerOption(
        label: j['label'] as String? ?? '',
        emoji: j['emoji'] as String?,
        image: j['image'] as String?,
      );

  @override
  List<Object?> get props => [label, emoji, image];
}
