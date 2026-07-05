/// Shared pacing for feedback that must remain visible long enough for a child
/// to understand what happened before the next question or move is enabled.
abstract final class FeedbackTiming {
  /// Holds the correct state, praise, and celebration before advancing.
  static const successBeat = Duration(milliseconds: 1600);
}
