import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/progress/progress_controller.dart';

void main() {
  group('ProgressState', () {
    const state = ProgressState({
      'child1|lessonA': 3,
      'child1|lessonB': 1,
      'child2|lessonA': 2,
    });

    test('reads stars for the right child+lesson', () {
      expect(state.starsFor('child1', 'lessonA'), 3);
      expect(state.starsFor('child1', 'lessonB'), 1);
      expect(state.starsFor('child2', 'lessonA'), 2);
      expect(state.starsFor('child1', 'missing'), 0);
    });

    test('completion is stars > 0', () {
      expect(state.isCompleted('child1', 'lessonA'), isTrue);
      expect(state.isCompleted('child1', 'missing'), isFalse);
    });

    test('totalStars sums only that child', () {
      expect(state.totalStars('child1'), 4); // 3 + 1
      expect(state.totalStars('child2'), 2);
      expect(state.totalStars('nobody'), 0);
    });
  });
}
