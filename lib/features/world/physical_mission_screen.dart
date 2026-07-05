import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/speech_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/celebration_overlay.dart';
import '../gamification/domain/wallet.dart';
import '../profiles/profiles_controller.dart';

class PhysicalMissionScreen extends ConsumerStatefulWidget {
  const PhysicalMissionScreen({super.key});

  @override
  ConsumerState<PhysicalMissionScreen> createState() =>
      _PhysicalMissionScreenState();
}

class _PhysicalMissionScreenState extends ConsumerState<PhysicalMissionScreen> {
  final _celebration = CelebrationController();
  StreamSubscription<AccelerometerEvent>? _motion;
  int _step = 0;
  int _shakes = 0;
  bool _listening = false;
  String _heard = '';
  DateTime? _leftTap;
  DateTime? _rightTap;
  bool _rewarded = false;

  @override
  void initState() {
    super.initState();
    _motion = accelerometerEventStream().listen(
      _onMotion,
      onError: (_) {},
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => AudioService.instance.speak('Shake the stars awake!'),
    );
  }

  void _onMotion(AccelerometerEvent event) {
    if (_step != 0 || !mounted) return;
    final force =
        math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    if (force < 15) return;
    setState(() => _shakes = (_shakes + 1).clamp(0, 5));
    AudioService.instance.playSfx(Sfx.pop);
    if (_shakes >= 5) _completeStep();
  }

  Future<void> _listen() async {
    final ready = await SpeechService.instance.ensureReady();
    if (!mounted) return;
    if (!ready) {
      _completeStep();
      return;
    }
    setState(() => _listening = true);
    await SpeechService.instance.listen(
      onResult: (words, _) {
        if (mounted) setState(() => _heard = words);
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _listening = false);
        if (_heard.trim().isNotEmpty) _completeStep();
      },
    );
  }

  void _familyTap(bool left) {
    final now = DateTime.now();
    setState(() {
      if (left) {
        _leftTap = now;
      } else {
        _rightTap = now;
      }
    });
    if (_leftTap != null &&
        _rightTap != null &&
        _leftTap!.difference(_rightTap!).abs() <
            const Duration(milliseconds: 900)) {
      _finish();
    }
  }

  void _completeStep() {
    if (!mounted || _step >= 2) return;
    _celebration.celebrate();
    setState(() => _step++);
    AudioService.instance.speak(
      _step == 1
          ? 'Now say: We are a great team!'
          : 'Find a partner and tap both hands together!',
    );
  }

  Future<void> _finish() async {
    if (_rewarded) return;
    _rewarded = true;
    _celebration.fireworks();
    AudioService.instance.speak('Teamwork magic! Your world earned a rocket!');
    final profiles = ref.read(profilesControllerProvider.notifier);
    await profiles.grantRoomItem('room_rocket');
    await profiles.addCompanionXp(20,
        memory: 'Our movement mission made me zoom with joy!');
    await profiles.applyReward(const RewardBundle(coins: 10, xp: 10));
    if (mounted) setState(() => _step = 3);
  }

  @override
  void dispose() {
    _motion?.cancel();
    SpeechService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CelebrationOverlay(
      controller: _celebration,
      child: Scaffold(
        body: AnimatedBackground(
          theme: WorldTheme.jungle,
          child: SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(child: Center(child: _mission(context))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            BouncyButton(
              onTap: () => Navigator.of(context).pop(),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.close_rounded),
              ),
            ),
            const SizedBox(width: 12),
            const Text('🏃 Move Together!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );

  Widget _mission(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: switch (_step) {
        0 => _centered(
            '✨',
            'Shake the stars awake!',
            Column(
              children: [
                LinearProgressIndicator(value: _shakes / 5),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _completeStep,
                  child: const Text('No motion sensor? Tap here'),
                ),
              ],
            ),
          ),
        1 => _centered(
            '🗣️',
            'Say “We are a great team!”',
            BouncyButton(
              onTap: _listen,
              child: _pill(_listening ? 'Listening…' : 'Tap and speak'),
            ),
          ),
        2 => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🙌', style: TextStyle(fontSize: 80)),
              const Text('Partner high-five!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                    child: GestureDetector(
                  onTap: () => _familyTap(true),
                  child: _hand('LEFT', _leftTap != null),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: GestureDetector(
                  onTap: () => _familyTap(false),
                  child: _hand('RIGHT', _rightTap != null),
                )),
              ]),
            ],
          ),
        _ => _centered(
            '🚀',
            'Teamwork mission complete!',
            BouncyButton(
              onTap: () => Navigator.of(context).pop(),
              child: _pill('Put rocket in my world'),
            ),
          ),
      },
    );
  }

  Widget _centered(String emoji, String title, Widget action) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 88)),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          action,
        ],
      );

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
            color: AppColors.success, borderRadius: BorderRadius.circular(30)),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900)),
      );

  Widget _hand(String label, bool active) => Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.star : AppColors.sky,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text('✋\n$label',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
      );
}
