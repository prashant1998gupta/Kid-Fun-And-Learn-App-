import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/core/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    AudioService.instance
      ..debugSetAvailableAudioAssets(null)
      ..sfxEnabled = false
      ..musicEnabled = false
      ..voiceEnabled = false
      ..hapticsEnabled = false;
  });

  test('missing bundled SFX are skipped before reaching the audio plugin',
      () async {
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async {
        calls.add(call);
        return null;
      },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        calls.add(call);
        return null;
      },
    );

    AudioService.instance
      ..debugSetAvailableAudioAssets(const {})
      ..sfxEnabled = true
      ..musicEnabled = false
      ..voiceEnabled = false
      ..hapticsEnabled = false;

    await AudioService.instance.playSfx(Sfx.tap);

    expect(calls, isEmpty);
  });
}
