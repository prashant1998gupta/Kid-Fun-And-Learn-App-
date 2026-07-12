import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/core/services/audio_service.dart';
import 'package:kidverse/core/widgets/illustrated_object.dart';
import 'package:kidverse/core/widgets/openmoji_view.dart';
import 'package:kidverse/features/preschool_library/preschool_practice_catalog.dart';
import 'package:kidverse/features/preschool_library/preschool_practice_controller.dart';
import 'package:kidverse/features/preschool_library/preschool_practice_screen.dart';
import 'package:kidverse/features/profiles/domain/child_profile.dart';
import 'package:kidverse/features/profiles/domain/grade_level.dart';
import 'package:kidverse/features/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      ..musicEnabled = false
      ..voiceEnabled = false
      ..hapticsEnabled = false;
  });

  test('catalog is complete, unlocked, and safe for preschool profiles', () {
    final pictureCategories = PreschoolPracticeCategory.values
        .where((category) => category.kind == PreschoolPracticeKind.vocabulary)
        .toList();
    expect(pictureCategories, hasLength(30));
    for (final category in pictureCategories) {
      final items = PreschoolPracticeCatalog.itemsFor(category);
      expect(
        items,
        hasLength(30),
        reason: '${category.title} must contain exactly 30 picture words',
      );
      expect(
        items.map((item) => item.name.toLowerCase()).toSet(),
        hasLength(30),
        reason: '${category.title} must not repeat a word',
      );
    }

    expect(
      PreschoolPracticeCatalog.itemsFor(PreschoolPracticeCategory.uppercase),
      hasLength(26),
    );
    expect(
      PreschoolPracticeCatalog.itemsFor(PreschoolPracticeCategory.lowercase),
      hasLength(26),
    );
    expect(
      PreschoolPracticeCatalog.itemsFor(PreschoolPracticeCategory.numbers),
      hasLength(10),
    );
    expect(
      PreschoolPracticeCatalog.itemsFor(
        PreschoolPracticeCategory.hindiVowels,
      ).length,
      greaterThanOrEqualTo(13),
    );
    expect(
      PreschoolPracticeCatalog.itemsFor(
        PreschoolPracticeCategory.hindiConsonants,
      ).length,
      greaterThanOrEqualTo(33),
    );

    final allItems = [
      for (final category in PreschoolPracticeCategory.values)
        ...PreschoolPracticeCatalog.itemsFor(category),
    ];
    expect(
      allItems.map((item) => item.id).toSet(),
      hasLength(allItems.length),
    );
    for (final item in allItems) {
      expect(
        PreschoolPracticeCatalog.byId(item.id),
        same(item),
        reason: '${item.id} should resolve to its stable catalog instance',
      );
    }
    expect(PreschoolPracticeCatalog.byId('missing_item'), isNull);
    expect(allItems.every((item) => item.spoken.trim().isNotEmpty), isTrue);
    expect(allItems.every((item) => item.emoji.trim().isNotEmpty), isTrue);
    final pictureItems = [
      for (final category in pictureCategories)
        ...PreschoolPracticeCatalog.itemsFor(category),
    ];
    expect(pictureItems, hasLength(900));
    expect(
      PreschoolPracticeCatalog.availableFor(GradeLevel.lkg),
      isTrue,
    );
    expect(
      PreschoolPracticeCatalog.availableFor(GradeLevel.ukg),
      isTrue,
    );
    expect(PreschoolPracticeCatalog.availableFor(GradeLevel.kg), isTrue);
    expect(
      PreschoolPracticeCatalog.availableFor(GradeLevel.grade1),
      isFalse,
    );
  });

  test('catalog lists and ids are stable and immutable', () {
    final uppercase =
        PreschoolPracticeCatalog.itemsFor(PreschoolPracticeCategory.uppercase);
    expect(
      identical(
        uppercase,
        PreschoolPracticeCatalog.itemsFor(PreschoolPracticeCategory.uppercase),
      ),
      isTrue,
      reason: 'A-Z trace items should be cached, not rebuilt on every read.',
    );
    expect(
      () => uppercase.add(uppercase.first),
      throwsUnsupportedError,
      reason: 'Catalog callers must not be able to mutate shared trace lists.',
    );

    final numbers =
        PreschoolPracticeCatalog.itemsFor(PreschoolPracticeCategory.numbers);
    expect(() => numbers.clear(), throwsUnsupportedError);

    final fruitIds =
        PreschoolPracticeCatalog.idsFor(PreschoolPracticeCategory.fruits);
    expect(
      identical(
        fruitIds,
        PreschoolPracticeCatalog.idsFor(PreschoolPracticeCategory.fruits),
      ),
      isTrue,
      reason: 'Category progress cards should reuse cached id lists.',
    );
    expect(fruitIds, hasLength(30));
    expect(fruitIds.first, 'fruits_0');
    expect(() => fruitIds.add('oops'), throwsUnsupportedError);
  });

  test('picture words have safe non-generic visuals', () {
    final pictureItems = [
      for (final category in PreschoolPracticeCategory.values)
        if (category.kind == PreschoolPracticeKind.vocabulary)
          ...PreschoolPracticeCatalog.itemsFor(category),
    ];

    final exactOpenMojiCount =
        pictureItems.where((item) => OpenMojiView.has(item.emoji)).length;
    expect(
      exactOpenMojiCount / pictureItems.length,
      greaterThanOrEqualTo(0.98),
      reason: 'Picture Words should mostly use exact bundled art.',
    );

    final unsafe = pictureItems
        .where((item) => !IllustratedObjectView.hasSafeVisual(
              label: item.name,
              emoji: item.emoji,
            ))
        .map((item) => '${item.category.title}: ${item.name} ${item.emoji}')
        .toList();
    expect(
      unsafe,
      isEmpty,
      reason: 'Picture Words must not fall back to a generic smiley blob.',
    );
  });

  test('practice stages persist independently for each child', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = PreschoolPracticeController(preferences, 'child-one');

    expect(controller.state.forItem('uppercase_a').stage,
        PreschoolPracticeStage.newItem);
    await controller.viewed('uppercase_a');
    expect(controller.state.forItem('uppercase_a').stage,
        PreschoolPracticeStage.practising);
    await controller.practised('uppercase_a');
    await controller.practised('uppercase_a');
    await controller.practised('uppercase_a');
    expect(controller.state.forItem('uppercase_a').stage,
        PreschoolPracticeStage.great);

    final restored = PreschoolPracticeController(preferences, 'child-one');
    expect(restored.state.forItem('uppercase_a').practices, 3);
    final sibling = PreschoolPracticeController(preferences, 'child-two');
    expect(sibling.state.forItem('uppercase_a').stage,
        PreschoolPracticeStage.newItem);
  });

  testWidgets('preschool hub exposes separate trace and vocabulary libraries',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferences = await _preschoolPreferences();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(home: PreschoolPracticeScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('My Learn & Trace Library'), findsOneWidget);
    expect(find.text('Capital A–Z'), findsOneWidget);
    expect(find.text('Small a–z'), findsOneWidget);
    expect(find.text('Numbers 0–9'), findsOneWidget);
    expect(find.text('हिंदी स्वर'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Body Parts'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Body Parts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picture-word progress updates only the touched item and section',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferences = await _preschoolPreferences();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(
          home: PreschoolCategoryScreen(
            category: PreschoolPracticeCategory.fruits,
            childId: 'preschool-child',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('New'), findsWidgets);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PreschoolCategoryScreen)),
    );
    await container
        .read(preschoolPracticeControllerProvider('preschool-child').notifier)
        .practised('fruits_0');
    await tester.pump();

    final controller = PreschoolPracticeController(
      preferences,
      'preschool-child',
    );
    expect(controller.state.forItem('fruits_0').practices, 1);
    expect(controller.state.forItem('fruits_1').stage,
        PreschoolPracticeStage.newItem);
    expect(controller.state.forItem('vegetables_0').stage,
        PreschoolPracticeStage.newItem);

    expect(find.text('Practising'), findsOneWidget);
    expect(find.text('New'), findsWidgets);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(home: PreschoolPracticeScreen()),
      ),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Fruits'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Fruits').first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('1 of 30 explored'), findsOneWidget);
    expect(find.text('0 of 30 explored'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a child can trace, celebrate, and immediately practise again',
      (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final item = PreschoolPracticeCatalog.itemsFor(
      PreschoolPracticeCategory.uppercase,
    ).first;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          home: PreschoolTraceScreen(item: item, childId: 'tracer'),
        ),
      ),
    );
    await tester.pump();

    final finish = find.byKey(const ValueKey('finish-tracing'));
    expect(tester.widget<FilledButton>(finish).onPressed, isNull);
    final canvas = find.byKey(const ValueKey('preschool-trace-canvas'));
    final rect = tester.getRect(canvas);
    final gesture = await tester.startGesture(
      Offset(rect.left + 80, rect.top + 100),
    );
    for (var step = 1; step <= 14; step++) {
      await gesture.moveTo(
        Offset(rect.left + 80 + step * 12, rect.top + 100 + step * 8),
      );
    }
    await gesture.up();
    await tester.pump();

    expect(tester.widget<FilledButton>(finish).onPressed, isNotNull);
    await tester.tap(finish);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Beautiful practice!'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('trace-again')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
        find.byKey(const ValueKey('preschool-trace-canvas')), findsOneWidget);
    expect(tester.widget<FilledButton>(finish).onPressed, isNull);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('trace guide stays static when reduced motion is enabled',
      (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final item = PreschoolPracticeCatalog.itemsFor(
      PreschoolPracticeCategory.uppercase,
    ).first;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child ?? const SizedBox.shrink(),
          ),
          home: PreschoolTraceScreen(item: item, childId: 'quiet-tracer'),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(
        find.byKey(const ValueKey('preschool-trace-canvas')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<SharedPreferences> _preschoolPreferences() async {
  const child = ChildProfile(
    id: 'preschool-child',
    name: 'Aarav',
    grade: GradeLevel.kg,
    avatar: AvatarConfig(),
  );
  SharedPreferences.setMockInitialValues({
    'child_profiles': jsonEncode([child.toMap()]),
    'active_child_id': child.id,
  });
  return SharedPreferences.getInstance();
}
