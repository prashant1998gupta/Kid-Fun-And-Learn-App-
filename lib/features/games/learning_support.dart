import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bouncy_button.dart';
import '../curriculum/domain/lesson.dart';
import '../ai/adaptive_engine.dart';

class LearningSupportScope extends InheritedWidget {
  const LearningSupportScope({
    required this.stage,
    required super.child,
    super.key,
  });

  final LearningSupportStage stage;

  static LearningSupportStage stageOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<LearningSupportScope>()
          ?.stage ??
      LearningSupportStage.yourTurn;

  @override
  bool updateShouldNotify(LearningSupportScope oldWidget) =>
      stage != oldWidget.stage;
}

/// Keeps the answer plus one plausible distractor. Engines retain original
/// option indexes, so correctness logic remains unchanged.
List<int> rescueOptionIndexes(Question question, {required bool rescue}) {
  final all = List<int>.generate(question.options.length, (index) => index);
  if (!rescue || question.correctIndex == null || all.length <= 2) return all;
  final correct = question.correctIndex!;
  final wrong = all.firstWhere((index) => index != correct);
  return [correct, wrong]..sort();
}

Future<void> showWatchDemonstration(
  BuildContext context,
  Question question,
) async {
  final answer = question.correctIndex != null &&
          question.correctIndex! >= 0 &&
          question.correctIndex! < question.options.length
      ? question.options[question.correctIndex!].label
      : question.answer ?? 'the highlighted choice';
  final explanation = question.teachingTip ??
      'First look at the clue, then look for the matching answer.';
  final narration = '$explanation The answer in this example is $answer.';
  AudioService.instance.speak(narration);
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('👀 Watch Spark first', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(explanation,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, height: 1.35)),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('✨ $answer',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Now let’s do it together'),
        ),
      ],
    ),
  );
}

Future<void> showLearningRescue(
  BuildContext context,
  Question question,
) async {
  final explanation = question.rescueTip ??
      'Let us slow down, look at the clue, and try with two choices.';
  AudioService.instance.speak(explanation);
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Row(
        children: [
          Text('🦉', style: TextStyle(fontSize: 36)),
          SizedBox(width: 10),
          Expanded(child: Text('Let’s learn it together')),
        ],
      ),
      content: Text(
        explanation,
        style: const TextStyle(fontSize: 18, height: 1.4),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        BouncyButton(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'Try the easier step ✨',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    ),
  );
}
