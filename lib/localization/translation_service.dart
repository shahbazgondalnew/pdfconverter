import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Resolves app locale from the device language.
/// Falls back to English when the system language is unsupported.
class TranslationService {
  TranslationService._();

  static const Locale fallbackLocale = Locale('en');

  /// Top 24 languages supported by the app.
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('zh'), // Chinese
    Locale('hi'), // Hindi
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('ar'), // Arabic
    Locale('bn'), // Bengali
    Locale('pt'), // Portuguese
    Locale('ru'), // Russian
    Locale('ur'), // Urdu
    Locale('id'), // Indonesian
    Locale('de'), // German
    Locale('ja'), // Japanese
    Locale('sw'), // Swahili
    Locale('tr'), // Turkish
    Locale('ko'), // Korean
    Locale('vi'), // Vietnamese
    Locale('it'), // Italian
    Locale('th'), // Thai
    Locale('pl'), // Polish
    Locale('nl'), // Dutch
    Locale('ms'), // Malay
    Locale('fa'), // Persian
    Locale('uk'), // Ukrainian
  ];

  static final Set<String> _supportedLanguageCodes = {
    for (final locale in supportedLocales) locale.languageCode,
  };

  /// Picks a supported locale from [deviceLocale], otherwise English.
  static Locale resolveLocale([Locale? deviceLocale]) {
    final locale = deviceLocale ?? Get.deviceLocale;
    if (locale == null) return fallbackLocale;

    if (_supportedLanguageCodes.contains(locale.languageCode)) {
      return Locale(locale.languageCode);
    }

    return fallbackLocale;
  }
}
