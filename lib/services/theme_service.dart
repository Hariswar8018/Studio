import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  bool _isDarkMode = false; // Default light mode (matching /app)
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  bool _showFurigana = true;
  bool get showFurigana => _showFurigana;

  bool _isVibrantText = true;
  bool get isVibrantText => _isVibrantText;

  ThemeService() {
    _loadTheme();
  }

  Future<void> init() async {
    await _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('grammar_dark_mode') ?? false;
    _showFurigana = prefs.getBool('grammar_show_furigana') ?? true;
    _isVibrantText = prefs.getBool('grammar_vibrant_text') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('grammar_dark_mode', _isDarkMode);
    notifyListeners();
  }

  Future<void> toggleFurigana() async {
    _showFurigana = !_showFurigana;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('grammar_show_furigana', _showFurigana);
    notifyListeners();
  }

  Future<void> toggleVibrantText() async {
    _isVibrantText = !_isVibrantText;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('grammar_vibrant_text', _isVibrantText);
    notifyListeners();
  }
}
