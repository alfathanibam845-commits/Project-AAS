
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _themeKey = 'itemshop-dark-mode';

  bool _isDark = false;

  bool get isDark => _isDark;

  // LOAD THEME SAAT APLIKASI DIBUKA
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    _isDark = prefs.getBool(_themeKey) ?? false;

    notifyListeners();
  }

  // TOGGLE DARK MODE
  Future<void> toggleTheme(bool value) async {
    _isDark = value;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
  }
}
