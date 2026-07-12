import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/core/widgets/celebration_overlay.dart';
import 'package:kidverse/core/widgets/kid_experience_layer.dart';

void main() {
  testWidgets('Wonder Touch responds briefly without blocking child input',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: KidExperienceLayer(
          reducedMotion: false,
          child: Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => taps++,
                child: const Text('Play'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Play'));
    await tester.pump(const Duration(milliseconds: 40));
    expect(taps, 1);
    expect(
      find.byKey(const ValueKey('kid-wonder-touch-burst')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('kid-wonder-touch-burst')),
      findsNothing,
    );
  });

  testWidgets('Wonder Touch creates no motion when reduced motion is enabled',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: KidExperienceLayer(
          reducedMotion: true,
          child: Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    await tester.tapAt(const Offset(100, 100));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('kid-wonder-touch-burst')),
      findsNothing,
    );
  });

  testWidgets('reduced-motion celebrations keep a clear static success moment',
      (tester) async {
    final controller = CelebrationController();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: CelebrationOverlay(
            controller: controller,
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    );

    controller.celebrate(sound: false);
    await tester.pump();
    expect(find.text('⭐'), findsOneWidget);
    expect(find.text('You did it!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
