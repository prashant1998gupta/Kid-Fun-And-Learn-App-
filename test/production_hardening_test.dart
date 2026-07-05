import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/art_studio/data/canvas_repository.dart';
import 'package:kidverse/features/profiles/data/profiles_repository.dart';
import 'package:kidverse/features/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('notification consent is off by default and persists parent choice',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = SettingsController(preferences);

    expect(controller.state.notificationsEnabled, isFalse);

    await controller.setNotificationsEnabled(true);

    expect(controller.state.notificationsEnabled, isTrue);
    expect(preferences.getBool('notificationsEnabled'), isTrue);
  });

  test('corrupt profile cache cannot crash application startup', () async {
    SharedPreferences.setMockInitialValues({'child_profiles': '{not-json'});
    final preferences = await SharedPreferences.getInstance();

    expect(ProfilesRepository(preferences).loadAll(), isEmpty);
  });

  test('corrupt drawing cache degrades to an empty gallery', () async {
    SharedPreferences.setMockInitialValues({'saved_drawings': '[broken'});
    final preferences = await SharedPreferences.getInstance();

    expect(CanvasRepository(preferences).loadAll(), isEmpty);
  });
}
