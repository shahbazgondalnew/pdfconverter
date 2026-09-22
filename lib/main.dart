import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'bindings/initial_binding.dart';
import 'controllers/theme_controller.dart';
import 'localization/app_translations.dart';
import 'localization/translation_service.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'services/conversion_storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConversionStorage.init();
  Get.put(ThemeController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AllConvert – Image & PDF Converter',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      translations: AppTranslations(),
      locale: TranslationService.resolveLocale(),
      fallbackLocale: TranslationService.fallbackLocale,
      supportedLocales: TranslationService.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: Get.find<ThemeController>().themeMode,
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages,
    );
  }
}
