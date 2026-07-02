import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thin, crash-proof wrapper around `speech_to_text` for the pronunciation
/// game. Speech recognition isn't available everywhere (no mic permission,
/// desktop/web, some devices), so every method degrades gracefully and the game
/// offers a tap-to-pass fallback when [isAvailable] is false — keeping every
/// lesson completable, offline-first.
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final SpeechToText _stt = SpeechToText();
  bool _available = false;
  bool _initTried = false;
  VoidCallback? _onDone;

  bool get isAvailable => _available;
  bool get isListening => _stt.isListening;

  /// Initializes recognition (asks for mic permission on first call). Returns
  /// whether speech is usable. Safe to call repeatedly.
  Future<bool> ensureReady() async {
    if (_initTried) return _available;
    _initTried = true;
    try {
      _available = await _stt.initialize(
        onError: (e) {
          if (kDebugMode) debugPrint('[SpeechService] error: ${e.errorMsg}');
        },
        onStatus: (status) {
          if (status == SpeechToText.doneStatus ||
              status == SpeechToText.notListeningStatus) {
            _finishSession();
          }
        },
      );
    } catch (e) {
      _available = false;
      if (kDebugMode) debugPrint('[SpeechService] unavailable: $e');
    }
    return _available;
  }

  /// Starts a listening session. [onResult] fires with the recognized text and
  /// whether it's the final result; [onDone] fires when the session ends.
  Future<void> listen({
    required void Function(String words, bool isFinal) onResult,
    required VoidCallback onDone,
    String localeId = 'en_US',
  }) async {
    if (!_available) return;
    _onDone = onDone;
    try {
      await _stt.listen(
        onResult: (r) {
          onResult(r.recognizedWords, r.finalResult);
          if (r.finalResult) _finishSession();
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 6),
          pauseFor: const Duration(seconds: 3),
          localeId: localeId,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[SpeechService] listen failed: $e');
      _finishSession();
    }
  }

  void _finishSession() {
    final callback = _onDone;
    _onDone = null;
    callback?.call();
  }

  Future<void> stop() async {
    if (!_available) {
      _finishSession();
      return;
    }
    try {
      await _stt.stop();
    } catch (_) {
      // A stopped or unavailable recognizer is already the desired state.
    } finally {
      _finishSession();
    }
  }
}
