import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/core/services/audio_service.dart';
import 'package:kidverse/features/mini_games/games/feed_pet_game.dart';
import 'package:kidverse/features/profiles/domain/child_profile.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';
import 'package:kidverse/features/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AudioService.instance
      ..sfxEnabled = false
      ..musicEnabled = false
      ..voiceEnabled = false
      ..hapticsEnabled = false;
  });

  testWidgets('Feed the Pet exposes a shared turn in sibling co-op mode',
      (tester) async {
    const child = ChildProfile(
      id: 'team-child',
      name: 'Mia',
      grade: GradeLevel.kg,
      avatar: AvatarConfig(),
      siblingCoopEnabled: true,
    );
    SharedPreferences.setMockInitialValues({
      'child_profiles': jsonEncode([child.toMap()]),
      'active_child_id': child.id,
      'mg_tutorial_feed-the-pet': true,
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(home: FeedPetGame()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('feed-pet-coop-turn')), findsOneWidget);
    expect(find.text('P1 👋'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
