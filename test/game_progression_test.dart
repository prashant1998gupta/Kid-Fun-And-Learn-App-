import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/core/services/audio_service.dart';
import 'package:kidverse/features/curriculum/domain/lesson.dart';
import 'package:kidverse/features/curriculum/domain/subject.dart';
import 'package:kidverse/features/games/engines/boss_battle_game.dart';
import 'package:kidverse/features/games/engines/feed_pet_game.dart';
import 'package:kidverse/features/games/engines/listen_and_tap_game.dart';
import 'package:kidverse/features/games/engines/memory_match_game.dart';
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

  testWidgets('tap-choice holds success feedback before advancing',
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
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('Three plus three?'), findsNothing);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('Three plus three?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('two wrong attempts explain and reduce answer choices',
      (tester) async {
    const lesson = Lesson(
      id: 'rescue',
      title: 'Rescue',
      subject: Subject.math,
      grade: GradeLevel.grade2,
      gameType: GameType.tapChoice,
      questions: [
        Question(
          id: 'rescue-q',
          prompt: 'Three groups of two?',
          correctIndex: 2,
          options: [
            AnswerOption(label: '5'),
            AnswerOption(label: '7'),
            AnswerOption(label: '6'),
          ],
          skillId: 'math.multiplication',
          teachingTip: 'Multiplication means equal groups.',
          rescueTip:
              'Three equal groups of two make six. Try with two choices.',
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp(
      home: TapChoiceGame(lesson: lesson, onComplete: (_) {}),
    ));

    await tester.tap(find.text('7'));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.tap(find.text('7'));
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('Let’s learn it together'), findsOneWidget);
    expect(find.textContaining('Three equal groups'), findsOneWidget);
    await tester.tap(find.text('Try the easier step ✨'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('6'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('7'), findsNothing);
  });

  testWidgets('boss battle holds success feedback before advancing',
      (tester) async {
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
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Two plus two?'), findsOneWidget);
    expect(find.text('Three plus three?'), findsNothing);
    expect(result, isNull);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Three plus three?'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('listen-and-tap holds success feedback before advancing',
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
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Two plus two?'), findsOneWidget);
    expect(find.text('Three plus three?'), findsNothing);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Three plus three?'), findsOneWidget);
    // Flush the zero-delay entrance animation scheduled by the new option
    // cards before the widget test disposes the tree.
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('mole match holds success feedback before advancing',
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
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Two plus two?'), findsOneWidget);
    expect(find.text('Three plus three?'), findsNothing);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Three plus three?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('feed-the-pet holds success feedback before advancing',
      (tester) async {
    const lesson = Lesson(
      id: 'feed_advance',
      title: 'Feed Advance',
      subject: Subject.evs,
      grade: GradeLevel.lkg,
      gameType: GameType.feedPet,
      questions: questions,
    );
    await tester.pumpWidget(MaterialApp(
      home: FeedPetGame(lesson: lesson, onComplete: (_) {}),
    ));

    await tester.tap(find.byKey(const ValueKey('feed-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Two plus two?'), findsOneWidget);
    expect(find.text('Three plus three?'), findsNothing);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Three plus three?'), findsOneWidget);
  });

  testWidgets('memory match holds the final pair before completing',
      (tester) async {
    const lesson = Lesson(
      id: 'memory_hold',
      title: 'Memory Hold',
      subject: Subject.english,
      grade: GradeLevel.kg,
      gameType: GameType.memoryMatch,
      questions: [
        Question(
          id: 'pair',
          prompt: 'Match',
          correctIndex: 0,
          options: [AnswerOption(label: 'Star', emoji: '⭐')],
        ),
      ],
    );
    LessonResult? result;
    await tester.pumpWidget(MaterialApp(
      home: MemoryMatchGame(
          lesson: lesson, onComplete: (value) => result = value),
    ));

    await tester.tap(find.byIcon(Icons.question_mark_rounded).first);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.question_mark_rounded).first);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(result, isNull);
    expect(find.byIcon(Icons.question_mark_rounded), findsNothing);

    await tester.pump(const Duration(milliseconds: 150));
    expect(result, isNotNull);
  });
}
