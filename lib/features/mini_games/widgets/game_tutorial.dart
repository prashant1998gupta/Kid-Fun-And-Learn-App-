import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/settings_controller.dart';

/// Shows a friendly, voice-guided "how to play" the FIRST time a child opens a
/// mini game — an animated tapping finger + one short spoken instruction, then
/// never again (remembered in prefs). Pre-readers can follow it by sound.
///
/// Call once from a game's `initState` via a post-frame callback.
Future<void> showFirstPlayTutorial(
  BuildContext context,
  WidgetRef ref, {
  required String gameId,
  required String instruction,
  String emoji = '👆',
}) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final key = 'mg_tutorial_$gameId';
  if (prefs.getBool(key) ?? false) return;

  AudioService.instance.speak(instruction);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) => _TutorialDialog(
      instruction: instruction,
      emoji: emoji,
      reducedMotion: ref.read(reducedMotionProvider),
    ),
  );
  await prefs.setBool(key, true);
}

/// Lets the child replay the tutorial from the help button (does not persist).
Future<void> showTutorialAgain(
  BuildContext context, {
  required String instruction,
  String emoji = '👆',
}) {
  AudioService.instance.speak(instruction);
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _TutorialDialog(
      instruction: instruction,
      emoji: emoji,
      reducedMotion: MediaQuery.disableAnimationsOf(context),
    ),
  );
}

class _TutorialDialog extends StatefulWidget {
  const _TutorialDialog({
    required this.instruction,
    required this.emoji,
    required this.reducedMotion,
  });
  final String instruction;
  final String emoji;
  final bool reducedMotion;

  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.reducedMotion) {
      _c.value = 0.5;
    } else {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The animated tapping finger / gesture hint.
              AnimatedBuilder(
                animation: _c,
                builder: (context, child) {
                  final t = Curves.easeInOut.transform(_c.value);
                  return Transform.translate(
                    offset: Offset(0, -10 * t),
                    child: Transform.scale(
                        scale: 1 + 0.12 * (1 - t), child: child),
                  );
                },
                child: Text(widget.emoji, style: const TextStyle(fontSize: 72)),
              ),
              const SizedBox(height: 10),
              Text(
                widget.instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF2D3436),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "Let's Play! 🎉",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
