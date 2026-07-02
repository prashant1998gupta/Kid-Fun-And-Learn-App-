import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/core/services/audio_service.dart';
import 'package:kidverse/features/curriculum/domain/lesson.dart';
import 'package:kidverse/features/curriculum/domain/subject.dart';
import 'package:kidverse/features/games/engines/boss_battle_game.dart';
import 'package:kidverse/features/games/engines/listen_and_tap_game.dart';
import 'package:kidverse/features/games/engines/mole_match_game.dart';
import 'package:kidverse/features/games/engines/tap_choice_game.dart';
import 'package:kidverse/features/gamification/reward_engine.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (_) async => null,
    );
    AudioService.instance
      ..sfxEnabled = false
      ..voiceEnabled = false
      ..hapticsEnabled = false;
  });

  const questions = [
    Question(
      id: 'q1',
      prompt: 'Two plus two?',
      correctIndex: 1,
      options: [AnswerOption(label: '3'), AnswerOption(label: '4')],
    ),
    Question(
      id: 'q2',
      prompt: 'Three plus three?',
      correctIndex: 0,
      options: [AnswerOption(label: '6'), AnswerOption(label: '7')],
    ),
  ];

  testWidgets('tap-choice advances immediately after a correct answer',
      (tester) async {
    const lesson = Lesson(
      id: 'advance',
      title: 'Advance',
      subject: Subject.math,
      grade: GradeLevel.grade4,
      gameType: GameType.tapChoice,
      questions: questions,
    );
    await tester.pumpWidget(MaterialApp(
      home: TapChoiceGame(lesson: lesson, onComplete: (_) {}),
    ));

    expect(find.text('1/2'), findsOneWidget);
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('Three plus three?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('boss battle advances after a correct answer', (tester) async {
    const lesson = Lesson(
      id: 'boss_advance',
      title: 'Boss Advance',
      subject: Subject.math,
      grade: GradeLevel.grade5,
      gameType: GameType.bossBattle,
      questions: questions,
    );
    LessonResult? result;
    await tester.pumpWidget(MaterialApp(
      home:
          BossBattleGame(lesson: lesson, onComplete: (value) => result = value),
    ));

    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 950));
    expect(find.text('Three plus three?'), findsOneWidget);
    expect(result, isNull);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('listen-and-tap advances after a correct picture',
      (tester) async {
    const lesson = Lesson(
      id: 'listen_advance',
      title: 'Listen Advance',
      subject: Subject.english,
      grade: GradeLevel.kg,
      gameType: GameType.listenAndTap,
      questions: questions,
    );
    await tester.pumpWidget(MaterialApp(
      home: ListenAndTapGame(lesson: lesson, onComplete: (_) {}),
    ));

    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Three plus three?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('mole match advances after tapping the correct mole',
      (tester) async {
    const lesson = Lesson(
      id: 'mole_advance',
      title: 'Mole Advance',
      subject: Subject.math,
      grade: GradeLevel.ukg,
      gameType: GameType.moleMatch,
      questions: questions,
    );
    await tester.pumpWidget(MaterialApp(
      home: MoleMatchGame(lesson: lesson, onComplete: (_) {}),
    ));

    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('0-0-2-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Three plus three?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
