import 'package:audioplayers/audioplayers.dart';
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

  static const _musicVolume = 0.35;
  static const _narrationMusicVolume = 0.09;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45); // slower, clearer for children
    await _tts.setPitch(1.15); // cheerful
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
    await _uiPlayer.setVolume(0.62);
    await _feedbackPlayer.setVolume(0.78);
    await _musicPlayer.setVolume(_musicVolume);
  }

  Future<void> playSfx(Sfx sfx) async {
    if (!sfxEnabled) return;
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
      final player = isUiSound ? _uiPlayer : _feedbackPlayer;
      await player.stop();
      await player.play(AssetSource('audio/${sfx.asset}'));
    } catch (_) {
      // Assets may be absent in early builds; fail silently so the UI is
      // never blocked by a missing sound.
    }
  }

  Future<void> playMusic(MusicTrack track) async {
    if (!musicEnabled) return;
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
      await _tts.stop();
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
