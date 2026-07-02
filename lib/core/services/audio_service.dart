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

  final AudioPlayer _sfxPlayer = AudioPlayer(playerId: 'sfx')
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'music')
    ..setReleaseMode(ReleaseMode.loop);
  final FlutterTts _tts = FlutterTts();

  bool sfxEnabled = true;
  bool musicEnabled = true;
  bool voiceEnabled = true;
  bool hapticsEnabled = true;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45); // slower, clearer for children
    await _tts.setPitch(1.15); // cheerful
    await _tts.setVolume(1.0);
    await _sfxPlayer.setVolume(0.8);
    await _musicPlayer.setVolume(0.35);
  }

  Future<void> playSfx(Sfx sfx) async {
    if (!sfxEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/${sfx.asset}'));
    } catch (_) {
      // Assets may be absent in early builds; fail silently so the UI is
      // never blocked by a missing sound.
    }
  }

  Future<void> playMusic(MusicTrack track) async {
    if (!musicEnabled) return;
    try {
      await _musicPlayer.play(AssetSource('audio/${track.asset}'));
    } catch (_) {}
  }

  Future<void> stopMusic() => _musicPlayer.stop();

  /// Cheerful voice guidance / narration. Used for praise ("Excellent!"),
  /// instructions, and reading practice.
  Future<void> speak(String text) async {
    if (!voiceEnabled) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stopSpeaking() => _tts.stop();

  void lightHaptic() {
    if (hapticsEnabled) HapticFeedback.lightImpact();
  }

  void successHaptic() {
    if (hapticsEnabled) HapticFeedback.mediumImpact();
  }

  Future<void> dispose() async {
    await _sfxPlayer.dispose();
    await _musicPlayer.dispose();
  }
}

/// A curated set of cheerful praise lines the mascots speak on success.
class PraiseLines {
  PraiseLines._();

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
}
