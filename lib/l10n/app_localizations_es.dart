// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'KidVerse';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String greeting(String name) {
    return '¡Hola $name!';
  }

  @override
  String get letsGo => '¡Vamos!';

  @override
  String get learnPrompt => '¿Qué aprendemos hoy?';

  @override
  String get soundAndVoice => 'Sonido y voz';

  @override
  String get soundEffects => 'Efectos de sonido';

  @override
  String get backgroundMusic => 'Música de fondo';

  @override
  String get voiceGuidance => 'Guía de voz';

  @override
  String get vibration => 'Vibración';

  @override
  String get appearance => 'Apariencia';

  @override
  String get accessibility => 'Accesibilidad';

  @override
  String get colorBlindFriendly => 'Modo para daltonismo';

  @override
  String get biggerText => 'Texto más grande';
}
