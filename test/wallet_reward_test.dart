import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/curriculum/domain/lesson.dart';
import 'package:kidverse/features/curriculum/domain/subject.dart';
import 'package:kidverse/features/gamification/domain/wallet.dart';
import 'package:kidverse/features/gamification/reward_engine.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';

void main() {
  group('Wallet level curve', () {
    test('starts at level 1 with no xp', () {
      expect(const Wallet().level, 1);
    });

    test('reaches level 2 at 100 xp', () {
      expect(const Wallet(xp: 100).level, 2);
      expect(const Wallet(xp: 99).level, 1);
    });

    test('level progress is within 0..1', () {
      const w = Wallet(xp: 150);
      expect(w.levelProgress, greaterThanOrEqualTo(0));
      expect(w.levelProgress, lessThanOrEqualTo(1));
    });

    test('serialization round-trips', () {
      const w = Wallet(coins: 50, gems: 2, stars: 9, xp: 340, streakDays: 4);
      expect(Wallet.fromMap(w.toMap()), w);
    });
  });

  group('RewardEngine', () {
    Lesson lesson() => const Lesson(
          id: 'l',
          title: 't',
          subject: Subject.math,
          grade: GradeLevel.lkg,
          gameType: GameType.tapChoice,
          questions: [],
          baseCoins: 10,
          baseXp: 20,
        );

    test('flawless run grants 3 stars and a gem', () {
      const engine = RewardEngine();
      final r = engine.compute(
        LessonResult(
          lesson: lesson(),
          correct: 4,
          total: 4,
          firstTryCorrect: 4,
        ),
      );
      expect(r.stars, 3);
      expect(r.gems, 1);
      expect(r.coins, greaterThan(10));
    });

    test('finishing always earns at least 1 star', () {
      const engine = RewardEngine();
      final r = engine.compute(
        LessonResult(
          lesson: lesson(),
          correct: 1,
          total: 4,
          firstTryCorrect: 0,
        ),
      );
      expect(r.stars, 1);
      expect(r.gems, 0);
    });
  });

  group('GradeLevel', () {
    test('suggests grade from age', () {
      expect(GradeLevel.suggestForAge(3), GradeLevel.lkg);
      expect(GradeLevel.suggestForAge(10), GradeLevel.grade5);
    });
  });
}
