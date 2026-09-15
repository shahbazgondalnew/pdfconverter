import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:pdfconverter/controllers/theme_controller.dart';
import 'package:pdfconverter/localization/app_translations.dart';
import 'package:pdfconverter/localization/translation_service.dart';
import 'package:pdfconverter/main.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    Get.put(ThemeController(), permanent: true);
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
    expect(find.text('Guest User'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Merge PDF'), findsOneWidget);
  });

  testWidgets('Theme toggles between light and dark', (WidgetTester tester) async {
    final themeController = Get.put(ThemeController(), permanent: true);
    await tester.pumpWidget(const MyApp());
    Get.updateLocale(TranslationService.fallbackLocale);
    await tester.pumpAndSettle();

    expect(themeController.isDarkMode.value, isFalse);
    expect(themeController.themeMode, ThemeMode.light);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(themeController.isDarkMode.value, isTrue);
    expect(themeController.themeMode, ThemeMode.dark);
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
