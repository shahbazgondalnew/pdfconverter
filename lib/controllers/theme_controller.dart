import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/locale_keys.dart';

enum AppThemePreference {
  system,
  light,
  dark;

  static AppThemePreference fromStorage(String? value) {
    switch (value) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
        return AppThemePreference.dark;
      case 'system':
      default:
        return AppThemePreference.system;
    }
  }

  String get storageValue {
    switch (this) {
      case AppThemePreference.system:
        return 'system';
      case AppThemePreference.light:
        return 'light';
      case AppThemePreference.dark:
        return 'dark';
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case AppThemePreference.system:
        return ThemeMode.system;
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  String get label {
    switch (this) {
      case AppThemePreference.system:
        return LocaleKeys.themeSystem.tr;
      case AppThemePreference.light:
        return LocaleKeys.themeLight.tr;
      case AppThemePreference.dark:
        return LocaleKeys.themeDark.tr;
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemePreference.system:
        return Icons.brightness_auto_rounded;
      case AppThemePreference.light:
        return Icons.light_mode_rounded;
      case AppThemePreference.dark:
        return Icons.dark_mode_rounded;
    }
  }
}

class ThemeController extends GetxController {
  static const _prefsKey = 'theme_preference';

  final preference = AppThemePreference.system.obs;
  var _loaded = false;

  ThemeMode get themeMode => preference.value.themeMode;

  String get themeLabel => preference.value.label;

  /// Effective dark flag for UI that needs the current brightness.
  bool get isDarkMode {
    switch (preference.value) {
      case AppThemePreference.light:
        return false;
      case AppThemePreference.dark:
        return true;
      case AppThemePreference.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    }
  }

  /// Loads persisted preference. First run (no saved value) uses system.
  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKey);
      preference.value = AppThemePreference.fromStorage(stored);
    } catch (_) {
      preference.value = AppThemePreference.system;
    } finally {
      _loaded = true;
    }
  }

  Future<void> setPreference(AppThemePreference value) async {
    if (preference.value == value) return;
    preference.value = value;
    Get.changeThemeMode(themeMode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, value.storageValue);
    } catch (_) {}
  }

  /// Kept for older call sites; maps a dark toggle onto light/dark.
  void toggleTheme(bool dark) {
    setPreference(
      dark ? AppThemePreference.dark : AppThemePreference.light,
    );
  }

  void switchTheme() {
    toggleTheme(!isDarkMode);
  }
}
