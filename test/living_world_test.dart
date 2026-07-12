import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/games/adventure_intro.dart';
import 'package:kidverse/features/curriculum/domain/lesson.dart';
import 'package:kidverse/features/curriculum/domain/subject.dart';
import 'package:kidverse/features/profiles/domain/child_profile.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';
import 'package:kidverse/features/settings/settings_controller.dart';
import 'package:kidverse/features/world/kid_world_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('living world renders companion and placed rewards',
      (tester) async {
    const child = ChildProfile(
      id: 'world-child',
      name: 'Mia',
      grade: GradeLevel.kg,
      avatar: AvatarConfig(),
      ownedRoomItems: ['room_rainbow'],
      placedRoomItems: ['room_rainbow'],
      companionXp: 40,
      companionName: 'Spark',
      completedAdventures: 4,
    );
    SharedPreferences.setMockInitialValues({
      'child_profiles': jsonEncode([child.toMap()]),
      'active_child_id': child.id,
      'saved_drawings': jsonEncode([
        {
          'id': 'garden-art',
          'name': 'Rainbow Friend',
          'thumbnail':
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
          'createdAt': '2026-01-01T00:00:00.000Z',
        }
      ]),
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(home: KidWorldScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text("Mia's World"), findsOneWidget);
    expect(find.textContaining('Spark'), findsOneWidget);
    expect(find.text('🌈'), findsWidgets);
    expect(find.text('Move!'), findsOneWidget);
    expect(find.byKey(const ValueKey('memory-garden')), findsOneWidget);
    expect(find.byKey(const ValueKey('living-drawing-garden-art')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  test('adventure missions give each subject an emotional goal', () {
    const lesson = Lesson(
      id: 'science-1',
      title: 'Things That Move',
      subject: Subject.science,
      grade: GradeLevel.grade2,
      gameType: GameType.tapChoice,
      questions: [],
    );

    final mission = AdventureMission.forLesson(
      lesson,
      heroName: 'Captain Scribble',
    );

    expect(mission.title, contains('Rocket'));
    expect(mission.story, contains('Captain Scribble'));
  });
}
