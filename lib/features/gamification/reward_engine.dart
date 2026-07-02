import '../curriculum/domain/lesson.dart';
import 'domain/wallet.dart';

/// The outcome of playing a lesson: how many were correct, on which questions
/// the child struggled, and how long it took.
class LessonResult {
  const LessonResult({
    required this.lesson,
    required this.correct,
    required this.total,
    required this.firstTryCorrect,
    this.struggledQuestionIds = const [],
    this.durationSeconds = 0,
  });

  final Lesson lesson;
  final int correct;
  final int total;
  final int firstTryCorrect;
  final List<String> struggledQuestionIds;
  final int durationSeconds;

  double get accuracy => total == 0 ? 0 : correct / total;
  double get mastery => total == 0 ? 0 : firstTryCorrect / total;

  /// 0–3 stars, the universal kid-legible score. Generous by design: finishing
  /// always earns at least one star (kids should never feel they "lost").
  int get stars {
    if (mastery >= 0.9) return 3;
    if (mastery >= 0.6) return 2;
    return 1;
  }
}

/// Turns a [LessonResult] into a [RewardBundle]. This is where the coin economy
/// and XP curve are tuned. Keeping it pure & centralized means balancing the
/// whole game is a one-file change.
class RewardEngine {
  const RewardEngine();

  /// Coins scale with base value × star multiplier. XP scales with effort
  /// (attempting) plus a mastery bonus, so persistence is rewarded, not just
  /// raw talent. Gems are rare: only a flawless first-try run grants one.
  RewardBundle compute(LessonResult r) {
    final starMult = switch (r.stars) {
      3 => 1.5,
      2 => 1.2,
      _ => 1.0,
    };
    final coins = (r.lesson.baseCoins * starMult).round();
    final xp = (r.lesson.baseXp * (0.5 + r.mastery)).round();
    final gems = r.mastery >= 1.0 ? 1 : 0;

    return RewardBundle(
      coins: coins,
      xp: xp,
      gems: gems,
      stars: r.stars,
    );
  }
}

/// Detects whether a child leveled up between two wallet states — used to
/// trigger the big level-up celebration.
class LevelUpCheck {
  const LevelUpCheck(this.before, this.after);
  final Wallet before;
  final Wallet after;

  bool get leveledUp => after.level > before.level;
  int get newLevel => after.level;
}
