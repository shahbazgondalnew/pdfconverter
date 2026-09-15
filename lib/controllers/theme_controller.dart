import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';

class ThemeController extends GetxController {
  final isDarkMode = false.obs;

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  String get themeLabel =>
      isDarkMode.value ? LocaleKeys.themeDark.tr : LocaleKeys.themeLight.tr;

  void toggleTheme(bool value) {
    isDarkMode.value = value;
    Get.changeThemeMode(themeMode);
  }

  void switchTheme() {
    toggleTheme(!isDarkMode.value);
  }
}
