import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePreference {
  system,  // Ikuti tema perangkat
  light,   // Selalu terang
  dark,    // Selalu gelap
}

class ThemeProvider extends ChangeNotifier {
  ThemePreference _themePreference = ThemePreference.system;
  bool _isDarkMode = false;

  ThemePreference get themePreference => _themePreference;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  /// Get the current system brightness
  bool get _isSystemDarkMode {
    final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPreference = prefs.getString('themePreference') ?? 'system';
    
    switch (savedPreference) {
      case 'light':
        _themePreference = ThemePreference.light;
        _isDarkMode = false;
        break;
      case 'dark':
        _themePreference = ThemePreference.dark;
        _isDarkMode = true;
        break;
      case 'system':
      default:
        _themePreference = ThemePreference.system;
        _isDarkMode = _isSystemDarkMode;
        break;
    }
    notifyListeners();
  }

  /// Set theme preference
  Future<void> setThemePreference(ThemePreference preference) async {
    _themePreference = preference;
    
    switch (preference) {
      case ThemePreference.light:
        _isDarkMode = false;
        break;
      case ThemePreference.dark:
        _isDarkMode = true;
        break;
      case ThemePreference.system:
        _isDarkMode = _isSystemDarkMode;
        break;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themePreference', preference.name);
    notifyListeners();
  }

  /// Toggle between light and dark (for backward compatibility with switch)
  Future<void> toggleTheme() async {
    if (_isDarkMode) {
      await setThemePreference(ThemePreference.light);
    } else {
      await setThemePreference(ThemePreference.dark);
    }
  }

  /// Update theme when system theme changes
  void updateSystemTheme() {
    if (_themePreference == ThemePreference.system) {
      _isDarkMode = _isSystemDarkMode;
      notifyListeners();
    }
  }

  /// Get theme mode for MaterialApp
  ThemeMode get themeMode {
    switch (_themePreference) {
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
      case ThemePreference.system:
        return ThemeMode.system;
    }
  }
}
