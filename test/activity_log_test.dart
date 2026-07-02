import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/progress/activity_log.dart';

void main() {
  const child = 'c1';
  const today = 2000; // arbitrary epoch-day for deterministic tests

  group('ActivityLog aggregation', () {
    test('record folds lessons/stars/xp into the same day', () {
      var log = ActivityLog.empty();
      log = log.record(child, today, stars: 3, xp: 30);
      log = log.record(child, today, stars: 2, xp: 20);

      final day = log.lastNDays(child, 1, today).single;
      expect(day.lessons, 2);
      expect(day.stars, 5);
      expect(day.xp, 50);
    });

    test('lastNDays fills empty days with zeros, oldest first', () {
      var log = ActivityLog.empty();
      log = log.record(child, today, stars: 1); // only today

      final week = log.lastNDays(child, 7, today);
      expect(week.length, 7);
      expect(week.first.day, today - 6);
      expect(week.last.day, today);
      expect(week.first.isActive, isFalse);
      expect(week.last.isActive, isTrue);
    });

    test('weekly totals and active days sum the 7-day window', () {
      var log = ActivityLog.empty();
      log = log.record(child, today, stars: 3, xp: 30);
      log = log.record(child, today - 2, stars: 2, xp: 20);
      log = log.record(child, today - 9, stars: 5, xp: 99); // outside window

      expect(log.weeklyLessons(child, today), 2);
      expect(log.weeklyStars(child, today), 5);
      expect(log.weeklyXp(child, today), 50);
      expect(log.activeDays(child, today), 2);
    });

    test('currentStreak counts consecutive active days back from today', () {
      var log = ActivityLog.empty();
      log = log.record(child, today);
      log = log.record(child, today - 1);
      log = log.record(child, today - 2);
      // gap at today-3
      log = log.record(child, today - 4);

      expect(log.currentStreak(child, today), 3);
    });

    test('streak is zero when today is inactive', () {
      var log = ActivityLog.empty();
      log = log.record(child, today - 1);
      expect(log.currentStreak(child, today), 0);
    });

    test('per-child isolation', () {
      var log = ActivityLog.empty();
      log = log.record('a', today, stars: 3);
      log = log.record('b', today, stars: 1);
      expect(log.weeklyStars('a', today), 3);
      expect(log.weeklyStars('b', today), 1);
    });
  });

  group('ActivityLog serialization', () {
    test('toJson → fromJson round-trips', () {
      var log = ActivityLog.empty();
      log = log.record(child, today, stars: 3, xp: 30);
      log = log.record(child, today - 1, stars: 1, xp: 10);

      final restored = ActivityLog.fromJson(log.toJson());
      expect(restored, log);
      expect(restored.weeklyStars(child, today), 4);
    });
  });
}
