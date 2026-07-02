import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/speech/domain/pronunciation_scorer.dart';

void main() {
  const scorer = PronunciationScorer();

  group('normalize', () {
    test('lowercases, strips punctuation, collapses spaces', () {
      expect(PronunciationScorer.normalize('  Hello, WORLD!! '), 'hello world');
    });
  });

  group('score', () {
    test('exact match scores 1.0', () {
      expect(scorer.score('cat', 'cat'), 1.0);
    });

    test('case and punctuation are ignored', () {
      expect(scorer.score('cat', 'Cat.'), 1.0);
    });

    test('picks the best-matching token from a noisy phrase', () {
      // Recognition often prepends filler; the target token should still win.
      expect(scorer.passes('ball', 'umm the ball'), isTrue);
    });

    test('near-miss stays above the lenient pass threshold', () {
      // "aple" vs "apple": edit distance 1 / 5 = 0.8 similarity.
      expect(scorer.score('apple', 'aple'), greaterThanOrEqualTo(0.6));
      expect(scorer.passes('apple', 'aple'), isTrue);
    });

    test('a clearly different word fails', () {
      expect(scorer.passes('cat', 'elephant'), isFalse);
    });

    test('empty input scores 0 and fails', () {
      expect(scorer.score('cat', ''), 0.0);
      expect(scorer.passes('cat', ''), isFalse);
    });
  });

  group('threshold is configurable', () {
    test('a stricter scorer rejects a marginal match', () {
      const strict = PronunciationScorer(passThreshold: 0.95);
      expect(strict.passes('apple', 'aple'), isFalse);
    });
  });
}
