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
          ChoiceChip(
            selected: value == difficulty,
            onSelected: (_) => onChanged(difficulty),
            avatar: Text(difficulty.icon),
            label: Text(difficulty.label),
            selectedColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.24),
            labelStyle: TextStyle(
              color: value == difficulty ? AppColors.primary : Colors.white,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
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
