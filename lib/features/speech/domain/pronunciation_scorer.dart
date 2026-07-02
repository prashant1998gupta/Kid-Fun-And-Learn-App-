/// Scores how closely a child's spoken words match a target word/phrase.
///
/// Pure (no plugins) so it's fully unit-testable. Deliberately lenient — young
/// kids and phone speech recognition are both imperfect, and the goal is joyful
/// practice, not strict assessment. A near-miss still passes and is celebrated.
class PronunciationScorer {
  const PronunciationScorer({this.passThreshold = 0.6});

  /// Similarity at or above which we treat the attempt as correct.
  final double passThreshold;

  /// Lowercase, strip punctuation, collapse whitespace.
  static String normalize(String s) {
    final cleaned = s
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s']"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  /// Best-match similarity in [0,1] between [target] and the [spoken] phrase
  /// (which may contain several words — we take the best-matching token, and
  /// also reward the whole phrase matching).
  double score(String target, String spoken) {
    final t = normalize(target);
    final s = normalize(spoken);
    if (t.isEmpty || s.isEmpty) return 0;
    if (t == s) return 1;

    // Whole-phrase similarity.
    var best = _similarity(t, s);

    // Best single spoken token vs the target (handles "umm, ball" → "ball").
    for (final token in s.split(' ')) {
      final sim = _similarity(t, token);
      if (sim > best) best = sim;
    }

    // Substring credit: if the target appears within the spoken phrase.
    if (s.contains(t) || t.contains(s)) {
      final containment =
          t.length / (s.length > t.length ? s.length : t.length);
      if (containment > best) best = containment;
    }
    return best;
  }

  bool passes(String target, String spoken) =>
      score(target, spoken) >= passThreshold;

  /// Normalized Levenshtein similarity: 1 - editDistance/maxLen.
  double _similarity(String a, String b) {
    if (a == b) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    final dist = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    return 1 - dist / maxLen;
  }

  int _levenshtein(String a, String b) {
    final m = a.length, n = b.length;
    var prev = List<int>.generate(n + 1, (i) => i);
    var curr = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        final del = prev[j] + 1;
        final ins = curr[j - 1] + 1;
        final sub = prev[j - 1] + cost;
        curr[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[n];
  }
}
