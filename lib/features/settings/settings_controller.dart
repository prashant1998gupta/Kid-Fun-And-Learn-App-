import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/audio_service.dart';

/// App-wide preferences: theme mode, audio toggles, accessibility.
/// Persisted to [SharedPreferences] so they survive restarts and work offline.
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.sfxEnabled = true,
    this.musicEnabled = true,
    this.voiceEnabled = true,
    this.hapticsEnabled = true,
    this.colorBlindMode = false,
    this.largeText = false,
    this.reducedMotion = false,
    this.notificationsEnabled = false,
    this.locale = 'en',
  });

  final ThemeMode themeMode;
  final bool sfxEnabled;
  final bool musicEnabled;
  final bool voiceEnabled;
  final bool hapticsEnabled;
  final bool colorBlindMode;
  final bool largeText;
  final bool reducedMotion;
  final bool notificationsEnabled;
  final String locale;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? sfxEnabled,
    bool? musicEnabled,
    bool? voiceEnabled,
    bool? hapticsEnabled,
    bool? colorBlindMode,
    bool? largeText,
    bool? reducedMotion,
    bool? notificationsEnabled,
    String? locale,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      colorBlindMode: colorBlindMode ?? this.colorBlindMode,
      largeText: largeText ?? this.largeText,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locale: locale ?? this.locale,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._prefs) : super(const SettingsState()) {
    _load();
  }

  final SharedPreferences _prefs;

  void _load() {
    state = SettingsState(
      themeMode: ThemeMode.values[_prefs.getInt('themeMode') ?? 0],
      sfxEnabled: _prefs.getBool('sfx') ?? true,
      musicEnabled: _prefs.getBool('music') ?? true,
      voiceEnabled: _prefs.getBool('voice') ?? true,
      hapticsEnabled: _prefs.getBool('haptics') ?? true,
      colorBlindMode: _prefs.getBool('colorBlind') ?? false,
      largeText: _prefs.getBool('largeText') ?? false,
      reducedMotion: _prefs.getBool('reducedMotion') ?? false,
      notificationsEnabled: _prefs.getBool('notificationsEnabled') ?? false,
      locale: _prefs.getString('locale') ?? 'en',
    );
    _syncAudio();
  }

  void _syncAudio() {
    AudioService.instance
      ..sfxEnabled = state.sfxEnabled
      ..musicEnabled = state.musicEnabled
      ..voiceEnabled = state.voiceEnabled
      ..hapticsEnabled = state.hapticsEnabled;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt('themeMode', mode.index);
  }

  Future<void> toggleSfx(bool v) async {
    state = state.copyWith(sfxEnabled: v);
    await _prefs.setBool('sfx', v);
    _syncAudio();
  }

  Future<void> toggleMusic(bool v) async {
    state = state.copyWith(musicEnabled: v);
    await _prefs.setBool('music', v);
    _syncAudio();
    if (!v) AudioService.instance.stopMusic();
  }

  Future<void> toggleVoice(bool v) async {
    state = state.copyWith(voiceEnabled: v);
    await _prefs.setBool('voice', v);
    _syncAudio();
  }

  Future<void> toggleHaptics(bool v) async {
    state = state.copyWith(hapticsEnabled: v);
    await _prefs.setBool('haptics', v);
    _syncAudio();
  }

  Future<void> toggleColorBlind(bool v) async {
    state = state.copyWith(colorBlindMode: v);
    await _prefs.setBool('colorBlind', v);
  }

  Future<void> toggleLargeText(bool v) async {
    state = state.copyWith(largeText: v);
    await _prefs.setBool('largeText', v);
  }

  Future<void> toggleReducedMotion(bool v) async {
    state = state.copyWith(reducedMotion: v);
    await _prefs.setBool('reducedMotion', v);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    await _prefs.setBool('notificationsEnabled', value);
  }

  Future<void> setLocale(String code) async {
    state = state.copyWith(locale: code);
    await _prefs.setString('locale', code);
  }
}

/// Overridden in main() once SharedPreferences is available.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialized'),
);

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController(ref.watch(sharedPreferencesProvider));
});

/// Convenience provider that exposes just the reduced-motion flag so animation
/// widgets can watch it without pulling in the full settings state.
final reducedMotionProvider = Provider<bool>((ref) {
  return ref.watch(settingsControllerProvider).reducedMotion;
});
