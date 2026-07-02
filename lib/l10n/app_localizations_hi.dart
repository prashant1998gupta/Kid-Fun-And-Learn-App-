// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'KidVerse';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String greeting(String name) {
    return 'नमस्ते $name!';
  }

  @override
  String get letsGo => 'चलो चलें!';

  @override
  String get learnPrompt => 'आज हम क्या सीखेंगे?';

  @override
  String get soundAndVoice => 'ध्वनि और आवाज़';

  @override
  String get soundEffects => 'ध्वनि प्रभाव';

  @override
  String get backgroundMusic => 'पृष्ठभूमि संगीत';

  @override
  String get voiceGuidance => 'आवाज़ मार्गदर्शन';

  @override
  String get vibration => 'कंपन';

  @override
  String get appearance => 'दिखावट';

  @override
  String get accessibility => 'सुलभता';

  @override
  String get colorBlindFriendly => 'वर्णांध-अनुकूल';

  @override
  String get biggerText => 'बड़ा पाठ';
}
