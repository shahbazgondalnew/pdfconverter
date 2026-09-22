import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pdfconverter/controllers/theme_controller.dart';
import 'package:pdfconverter/localization/app_translations.dart';
import 'package:pdfconverter/localization/translation_service.dart';
import 'package:pdfconverter/main.dart';
import 'package:pdfconverter/services/conversion_storage.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await ConversionStorage.init(forTest: true);
  });

  setUp(() {
    Get.reset();
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    final themeController = ThemeController();
    await themeController.load();
    Get.put(themeController, permanent: true);
    await tester.pumpWidget(const MyApp());
    Get.updateLocale(TranslationService.fallbackLocale);
    await tester.pumpAndSettle();
  }

  testWidgets('Home shows sectioned tools menu', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('Choose a tool to get started'), findsOneWidget);
    expect(find.text('Convert to PDF'), findsOneWidget);
    expect(find.text('Convert from PDF'), findsOneWidget);
    expect(find.text('Organize PDF'), findsOneWidget);
    expect(find.text('Image tools'), findsOneWidget);
    expect(find.text('Protect & edit'), findsOneWidget);
    expect(find.text('Image to PDF'), findsOneWidget);
    expect(find.text('PDF to Image'), findsOneWidget);
    expect(find.text('Merge PDF'), findsOneWidget);
    expect(find.text('PNG to JPG'), findsOneWidget);
    expect(find.text('Scan to PDF'), findsOneWidget);
    expect(find.text('Lock PDF'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches tabs', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('Image to PDF'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('No conversions yet'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('AllConvert'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Merge PDF'), findsOneWidget);
  });

  testWidgets('Theme defaults to system and can switch modes',
      (WidgetTester tester) async {
    final themeController = ThemeController();
    await themeController.load();
    Get.put(themeController, permanent: true);
    await tester.pumpWidget(const MyApp());
    Get.updateLocale(TranslationService.fallbackLocale);
    await tester.pumpAndSettle();

    expect(themeController.preference.value, AppThemePreference.system);
    expect(themeController.themeMode, ThemeMode.system);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(themeController.preference.value, AppThemePreference.dark);
    expect(themeController.themeMode, ThemeMode.dark);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(themeController.preference.value, AppThemePreference.light);
    expect(themeController.themeMode, ThemeMode.light);

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(themeController.preference.value, AppThemePreference.system);
    expect(themeController.themeMode, ThemeMode.system);
  });

  test('Resolves supported device language', () {
    expect(
      TranslationService.resolveLocale(const Locale('fr', 'FR')),
      const Locale('fr'),
    );
    expect(
      TranslationService.resolveLocale(const Locale('ja', 'JP')),
      const Locale('ja'),
    );
  });

  test('Falls back to English for unsupported language', () {
    expect(
      TranslationService.resolveLocale(const Locale('sv', 'SE')),
      TranslationService.fallbackLocale,
    );
    expect(
      TranslationService.resolveLocale(const Locale('fi')),
      const Locale('en'),
    );
  });

  test('Supports exactly 24 languages', () {
    expect(TranslationService.supportedLocales, hasLength(24));
    expect(AppTranslations().keys.keys, hasLength(24));
  });
}
