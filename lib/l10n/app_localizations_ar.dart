// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'KidVerse';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String greeting(String name) {
    return 'مرحبا $name!';
  }

  @override
  String get letsGo => 'هيا بنا!';

  @override
  String get learnPrompt => 'ماذا سنتعلم اليوم؟';

  @override
  String get soundAndVoice => 'الصوت والإرشاد';

  @override
  String get soundEffects => 'المؤثرات الصوتية';

  @override
  String get backgroundMusic => 'موسيقى الخلفية';

  @override
  String get voiceGuidance => 'الإرشاد الصوتي';

  @override
  String get vibration => 'الاهتزاز';

  @override
  String get appearance => 'المظهر';

  @override
  String get accessibility => 'إمكانية الوصول';

  @override
  String get colorBlindFriendly => 'ملائم لعمى الألوان';

  @override
  String get biggerText => 'نص أكبر';
}
