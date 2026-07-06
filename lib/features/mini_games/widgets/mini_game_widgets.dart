import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bouncy_button.dart';

enum MiniGameDifficulty {
  easy('Easy', '🌱'),
  normal('Normal', '⭐'),
  challenge('Challenge', '🔥');

  const MiniGameDifficulty(this.label, this.icon);
  final String label;
  final String icon;
}

/// Child-friendly play choices. Difficulty is intentionally absent: games
/// adapt quietly so children never have to judge their own ability.
enum MiniGamePlayMode {
  solo('Just me', '🌟'),
  together('Together', '👫'),
  creative('Create', '🎨');

  const MiniGamePlayMode(this.label, this.icon);
  final String label;
  final String icon;
}

class PlayModePicker extends StatelessWidget {
  const PlayModePicker({
    required this.value,
    required this.onChanged,
    this.showCreative = false,
    super.key,
  });

  final MiniGamePlayMode value;
  final ValueChanged<MiniGamePlayMode> onChanged;
  final bool showCreative;

  @override
  Widget build(BuildContext context) {
    final modes = [
      MiniGamePlayMode.solo,
      MiniGamePlayMode.together,
      if (showCreative) MiniGamePlayMode.creative,
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        for (final mode in modes)
          _ContrastChip(
            selected: value == mode,
            icon: mode.icon,
            label: mode.label,
            onSelected: () => onChanged(mode),
          ),
      ],
    );
  }
}

/// A pill that stays legible on ANY backdrop — light, dark, or a colored game
/// gradient. Selected: solid brand fill + white text. Unselected: solid white
/// fill + brand text. Never white-on-white, never relies on the background for
/// contrast (the old translucent-white + white-text chips vanished on pale
/// surfaces).
class _ContrastChip extends StatelessWidget {
  const _ContrastChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onSelected,
  });

  final bool selected;
  final String icon;
  final String label;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      avatar: Text(icon),
      label: Text(label),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.primary,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(
        color: selected
            ? Colors.transparent
            : AppColors.primary.withValues(alpha: 0.35),
        width: 1.5,
      ),
    );
  }
}

class StoryGoalCard extends StatelessWidget {
  const StoryGoalCard({
    required this.emoji,
    required this.goal,
    this.progress,
    this.progressColor = const Color(0xFFFFC048),
    super.key,
  });

  final String emoji;
  final String goal;
  final double? progress;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: goal,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 25)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal,
                    style: const TextStyle(
                      color: Color(0xFF2D3436),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress!.clamp(0, 1),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: const Color(0xFFE9E6F7),
                      color: progressColor,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerTurnBadge extends StatelessWidget {
  const PlayerTurnBadge({required this.player, super.key});
  final int player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: player == 1 ? const Color(0xFFFFE66D) : const Color(0xFF74B9FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Player $player ${player == 1 ? '🧒' : '👧'}',
        style: const TextStyle(
          color: Color(0xFF2D3436),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class DifficultyPicker extends StatelessWidget {
  const DifficultyPicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final MiniGameDifficulty value;
  final ValueChanged<MiniGameDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        for (final difficulty in MiniGameDifficulty.values)
          _ContrastChip(
            selected: value == difficulty,
            icon: difficulty.icon,
            label: difficulty.label,
            onSelected: () => onChanged(difficulty),
          ),
      ],
    );
  }
}

class GameCircleButton extends StatelessWidget {
  const GameCircleButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: BouncyButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}

class MascotMessage extends StatelessWidget {
  const MascotMessage({
    required this.message,
    this.icon = '🐼',
    super.key,
  });

  final String message;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(message),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF2D3436),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showMiniGameHelp(
  BuildContext context, {
  required String title,
  required List<String> steps,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('${i + 1}. ${steps[i]}'),
            ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Let’s play!'),
        ),
      ],
    ),
  );
}

void showMiniGameReward(BuildContext context, int score) {
  final coins = 3 + (score ~/ 100).clamp(0, 7);
  final xp = 5 + (score ~/ 50).clamp(0, 15);
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6C5CE7),
        duration: const Duration(seconds: 3),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(
              '+$coins 🪙   +$xp ⚡   Pet fed! 💖',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
}
