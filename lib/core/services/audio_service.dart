import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Every sound effect in KidVerse, mapped to its asset path.
///
/// Recommended free/licensable sources for these assets:
/// - Kenney.nl "UI Audio" & "Casual Game SFX" (CC0) — clicks, coins, pops.
/// - Mixkit "Game" pack (free w/ attribution) — level-up, unlock, magic.
/// - Freesound.org (filter CC0) — nature/ambience beds.
/// - Pixabay Music (royalty-free) — calm background loops.
/// Keep every SFX < 400ms and normalized to ~-14 LUFS so nothing startles a child.
enum Sfx {
  tap('sfx/tap.mp3'),
  correct('sfx/correct.mp3'),
  wrong('sfx/wrong.mp3'),
  coin('sfx/coin.mp3'),
  levelUp('sfx/level_up.mp3'),
  star('sfx/star.mp3'),
  unlock('sfx/unlock.mp3'),
  reward('sfx/reward.mp3'),
  celebration('sfx/celebration.mp3'),
  magic('sfx/magic.mp3'),
  pop('sfx/balloon_pop.mp3'),
  puzzleComplete('sfx/puzzle_complete.mp3'),
  whoosh('sfx/whoosh.mp3');

  const Sfx(this.asset);
  final String asset;
}

/// Background music beds for the animated worlds.
enum MusicTrack {
  home('music/home_calm.mp3'),
  forest('music/forest.mp3'),
  ocean('music/ocean.mp3'),
  space('music/space.mp3'),
  rain('music/rain.mp3');

  const MusicTrack(this.asset);
  final String asset;
}

/// Central audio + voice controller. A singleton so any widget (like
/// [BouncyButton]) can trigger feedback without plumbing dependencies.
///
/// Respects user mute settings which are wired in from [SettingsController].
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  late final AudioPlayer _uiPlayer = AudioPlayer(playerId: 'ui-sfx')
    ..setReleaseMode(ReleaseMode.stop);
  late final AudioPlayer _feedbackPlayer = AudioPlayer(playerId: 'feedback-sfx')
    ..setReleaseMode(ReleaseMode.stop);
  late final AudioPlayer _melodyPlayer =
      AudioPlayer(playerId: 'learning-melody')
        ..setReleaseMode(ReleaseMode.stop);
  late final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'music')
    ..setReleaseMode(ReleaseMode.loop);
  late final FlutterTts _tts = FlutterTts();

  bool sfxEnabled = true;
  bool musicEnabled = true;
  bool voiceEnabled = true;
  bool hapticsEnabled = true;
  String _voiceLanguage = 'en-US';
  int _speechGeneration = 0;
  DateTime? _lastUiSoundAt;
  bool _musicStarted = false;
  int _energyLevel = 1;
  int _melodyCursor = 0;
  bool _initialized = false;
  Set<String>? _availableAudioAssets;
  Future<Set<String>>? _availableAudioAssetsLoad;

  static const _narrationMusicVolume = 0.09;
  double get _musicVolume => switch (_energyLevel) {
        0 => 0.27,
        2 => 0.38,
        _ => 0.35,
      };

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45); // slower, clearer for children
    await _tts.setPitch(1.15); // cheerful
    await _tts.setVolume(1.0);
    _tts.setErrorHandler((_) {});
    await _tts.awaitSpeakCompletion(!kIsWeb);
    await _uiPlayer.setVolume(0.62);
    await _feedbackPlayer.setVolume(0.78);
    await _melodyPlayer.setVolume(0.2);
    await _musicPlayer.setVolume(_musicVolume);
    _availableAudioAssetsLoad = _loadAvailableAudioAssets();
    _initialized = true;
  }

  @visibleForTesting
  void debugSetAvailableAudioAssets(Set<String>? assets) {
    _availableAudioAssets = assets;
    _availableAudioAssetsLoad = assets == null ? null : Future.value(assets);
  }

  Future<Set<String>> _loadAvailableAudioAssets() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest
          .listAssets()
          .where((asset) =>
              asset.startsWith('assets/audio/') &&
              !asset.endsWith('/README.md') &&
              !asset.endsWith('/README'))
          .toSet();
    } catch (_) {
      // If the manifest cannot be loaded (for example in a narrow unit test),
      // be conservative and skip asset playback. Generated success tones still
      // keep the app responsive.
      return const {};
    }
  }

  Future<bool> _hasAudioAsset(String relativeAsset) async {
    final assets = _availableAudioAssets ??
        await (_availableAudioAssetsLoad ??= _loadAvailableAudioAssets());
    _availableAudioAssets = assets;
    return assets.contains('assets/audio/$relativeAsset');
  }

  /// Changes sensory presentation without changing question difficulty.
  void configureEnergy(int level) {
    final next = level.clamp(0, 2);
    if (_energyLevel == next) return;
    _energyLevel = next;
    final speechRate = switch (next) { 0 => 0.4, 2 => 0.48, _ => 0.45 };
    _tts.setSpeechRate(speechRate).ignore();
    if (_musicStarted) _musicPlayer.setVolume(_musicVolume).ignore();
  }

  Future<void> playSfx(Sfx sfx) async {
    if (!sfxEnabled) return;
    final assetIsBundled = await _hasAudioAsset(sfx.asset);
    try {
      final isUiSound = sfx == Sfx.tap || sfx == Sfx.whoosh;
      if (isUiSound) {
        final now = DateTime.now();
        if (_lastUiSoundAt != null &&
            now.difference(_lastUiSoundAt!) <
                const Duration(milliseconds: 45)) {
          return;
        }
        _lastUiSoundAt = now;
      }
      if (assetIsBundled) {
        final player = isUiSound ? _uiPlayer : _feedbackPlayer;
        await player.stop();
        await player.play(AssetSource('audio/${sfx.asset}'));
      }
    } catch (_) {
      // Assets may be absent in early builds; fail silently so the UI is
      // never blocked by a missing sound.
    }
    if (sfx == Sfx.correct || sfx == Sfx.star || sfx == Sfx.puzzleComplete) {
      await _playLearningTone();
    } else if (sfx == Sfx.reward ||
        sfx == Sfx.celebration ||
        sfx == Sfx.levelUp) {
      await _playLearningTone(finale: true);
    }
  }

  /// A tiny generated pentatonic melody: no tracking, downloads, licences, or
  /// extra assets. Each success adds the next note; big wins resolve a chord.
  Future<void> _playLearningTone({bool finale = false}) async {
    if (!sfxEnabled || !_initialized) return;
    const notes = [523.25, 587.33, 659.25, 783.99, 880.0];
    final frequency = notes[_melodyCursor++ % notes.length];
    try {
      await _melodyPlayer.stop();
      await _melodyPlayer.play(
        BytesSource(_toneWav(frequency, finale: finale)),
      );
    } catch (_) {
      // Some web/audio backends do not support in-memory sources. The normal
      // success sound remains available, so this enhancement fails safely.
    }
  }

  Uint8List _toneWav(double frequency, {required bool finale}) {
    const sampleRate = 16000;
    final seconds = finale ? 0.34 : 0.14;
    final sampleCount = (sampleRate * seconds).round();
    final dataLength = sampleCount * 2;
    final bytes = Uint8List(44 + dataLength);
    final data = ByteData.sublistView(bytes);

    void ascii(int offset, String value) {
      for (var index = 0; index < value.length; index++) {
        data.setUint8(offset + index, value.codeUnitAt(index));
      }
    }

    ascii(0, 'RIFF');
    data.setUint32(4, 36 + dataLength, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    data.setUint32(40, dataLength, Endian.little);

    for (var sample = 0; sample < sampleCount; sample++) {
      final t = sample / sampleRate;
      final progress = sample / sampleCount;
      final envelope =
          math.min(1.0, progress * 18) * math.min(1.0, (1 - progress) * 9);
      var wave = math.sin(2 * math.pi * frequency * t);
      if (finale) {
        wave += math.sin(2 * math.pi * frequency * 1.25 * t);
        wave += math.sin(2 * math.pi * frequency * 1.5 * t);
        wave /= 3;
      }
      final value = (wave * envelope * 5200).round().clamp(-32768, 32767);
      data.setInt16(44 + sample * 2, value, Endian.little);
    }
    return bytes;
  }

  Future<void> playMusic(MusicTrack track) async {
    if (!musicEnabled) return;
    if (!await _hasAudioAsset(track.asset)) {
      _musicStarted = false;
      return;
    }
    try {
      await _musicPlayer.play(AssetSource('audio/${track.asset}'));
      _musicStarted = true;
    } catch (_) {
      _musicStarted = false;
    }
  }

  Future<void> stopMusic() async {
    if (!_musicStarted) return;
    _musicStarted = false;
    await _musicPlayer.stop();
  }

  /// Cheerful voice guidance / narration. Used for praise ("Excellent!"),
  /// instructions, and reading practice.
  Future<void> speak(String text, {String language = 'en-US'}) async {
    if (!voiceEnabled) return;
    final generation = ++_speechGeneration;
    try {
      if (musicEnabled && _musicStarted) {
        await _musicPlayer.setVolume(_narrationMusicVolume);
      }
      // On web, cancelling the current browser utterance often emits noisy
      // SpeechSynthesisErrorEvent logs. Let short narration finish naturally;
      // new speech is still attempted below and explicit stopSpeaking() remains
      // available for screens that really need cancellation.
      if (!kIsWeb) await _tts.stop();
      if (_voiceLanguage != language) {
        await _tts.setLanguage(language);
        _voiceLanguage = language;
      }
      await _tts.speak(text);
    } catch (_) {
      // TTS availability varies by device. The visual experience remains
      // usable, and music is restored below.
    } finally {
      if (generation == _speechGeneration && musicEnabled && _musicStarted) {
        await _musicPlayer.setVolume(_musicVolume);
      }
    }
  }

  Future<void> stopSpeaking() async {
    _speechGeneration++;
    await _tts.stop();
    if (musicEnabled && _musicStarted) {
      await _musicPlayer.setVolume(_musicVolume);
    }
  }

  void lightHaptic() {
    if (hapticsEnabled) HapticFeedback.lightImpact();
  }

  void successHaptic() {
    if (hapticsEnabled) HapticFeedback.mediumImpact();
  }

  Future<void> dispose() async {
    await _uiPlayer.dispose();
    await _feedbackPlayer.dispose();
    await _melodyPlayer.dispose();
    await _musicPlayer.dispose();
  }
}

/// A curated set of cheerful praise lines the mascots speak on success.
class PraiseLines {
  PraiseLines._();

  static int _successCursor = 0;
  static int _reactionCursor = 0;

  static const List<String> success = [
    'Excellent!',
    'Awesome!',
    'You did it!',
    'Great job!',
    "You're amazing!",
    'Fantastic!',
    'Superstar!',
    'Way to go!',
  ];

  /// Returns varied praise without mutating the const [success] catalog.
  static String nextSuccess() {
    final line = success[_successCursor % success.length];
    _successCursor++;
    return line;
  }

  static const List<String> encourage = [
    'Try again!',
    'Almost there!',
    'You can do it!',
    "Let's give it another go!",
  ];

  static const List<String> greeting = [
    "Let's play!",
    'Ready for fun?',
    "Let's learn together!",
  ];

  static const List<String> playfulRetry = [
    'Oops, banana slipped!',
    "Let's try one more!",
    'Almost! Pick another one!',
    'That was silly. Try again!',
  ];

  static const List<String> rescue = [
    'You saved the puppy!',
    'The pet is so happy!',
    'Yum yum, great feeding!',
    'Happy pet, happy learner!',
  ];

  static const List<String> rewardReveal = [
    'Treasure time!',
    'You found a surprise!',
    'A reward popped out!',
    'Open your prize!',
  ];

  static String nextRetry() => _next(playfulRetry);
  static String nextRescue() => _next(rescue);
  static String nextRewardReveal() => _next(rewardReveal);

  static String _next(List<String> lines) {
    final line = lines[_reactionCursor % lines.length];
    _reactionCursor++;
    return line;
  }
}
