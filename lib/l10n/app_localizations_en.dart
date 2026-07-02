// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KidVerse';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get language => 'Language';

  @override
  String greeting(String name) {
    return 'Hi $name!';
  }

  @override
  String get letsGo => 'Let\'s Go!';

  @override
  String get learnPrompt => 'What shall we learn today?';

  @override
  String get soundAndVoice => 'Sound & Voice';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get backgroundMusic => 'Background Music';

  @override
  String get voiceGuidance => 'Voice Guidance';

  @override
  String get vibration => 'Vibration';

  @override
  String get appearance => 'Appearance';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get colorBlindFriendly => 'Color-blind friendly';

  @override
  String get biggerText => 'Bigger Text';
}
