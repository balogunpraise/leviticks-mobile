import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors `src/context/ThemeContext.tsx` — a manual light/dark toggle
/// persisted locally (there `localStorage`, here `SharedPreferences`).
class ThemeController extends ChangeNotifier {
  static const _key = 'theme';

  ThemeMode mode = ThemeMode.light;

  bool get isDark => mode == ThemeMode.dark;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    mode = prefs.getString(_key) == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggle() async {
    mode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }
}
