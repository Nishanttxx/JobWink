import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_web_helper.dart';

class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const String _key = 'user_theme_mode';
  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_key);
      if (savedTheme == 'dark') {
        themeModeNotifier.value = ThemeMode.dark;
        setBrowserThemeAttribute('dark');
      } else if (savedTheme == 'light') {
        themeModeNotifier.value = ThemeMode.light;
        setBrowserThemeAttribute('light');
      } else {
        // Fallback to system setting if no preference is saved
        final brightness = getBrowserIsDarkMode();
        final initialMode = brightness ? ThemeMode.dark : ThemeMode.light;
        themeModeNotifier.value = initialMode;
        setBrowserThemeAttribute(brightness ? 'dark' : 'light');
      }
    } catch (e) {
      debugPrint('ThemeService init error: $e');
    }
  }

  Future<void> toggleTheme() async {
    final nextMode =
        isDarkMode ? ThemeMode.light : ThemeMode.dark;
    themeModeNotifier.value = nextMode;
    final themeStr = nextMode == ThemeMode.dark ? 'dark' : 'light';
    setBrowserThemeAttribute(themeStr);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, themeStr);
    } catch (e) {
      debugPrint('ThemeService save error: $e');
    }
  }
}
