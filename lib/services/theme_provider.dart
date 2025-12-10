import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'isDark';

  bool _isDark = true; // default dark as requested

  ThemeProvider() {
    _loadFromPrefs();
  }

  bool get isDark => _isDark;

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_key)) {
        _isDark = prefs.getBool(_key) ?? true;
        notifyListeners();
      }
    } catch (_) {}
  }

  void toggle() {
    _isDark = !_isDark;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, _isDark);
    } catch (_) {}
  }

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF0E5A78),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF0E5A78),
      secondary: const Color(0xFF00BFA6),
    ),
    scaffoldBackgroundColor: const Color(0xFF0B0F12),
    useMaterial3: true,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: Color(0xFFE0E0E0),
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(color: Color(0xFFBDBDBD)),
      bodySmall: TextStyle(color: Color(0xFF9E9E9E)),
      labelMedium: TextStyle(color: Color(0xFFBDBDBD)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
      hintStyle: const TextStyle(color: Color(0xFF616161)),
      prefixIconColor: const Color(0xFF9E9E9E),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0E5A78), width: 2),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFF1E1E1E)),
      ),
    ),
  );

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF0E5A78),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF0E5A78),
      secondary: const Color(0xFF00BFA6),
    ),
    scaffoldBackgroundColor: const Color(0xFFF6F8FA),
    useMaterial3: true,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: Color(0xFF212121),
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(color: Color(0xFF424242)),
      bodySmall: TextStyle(color: Color(0xFF757575)),
      labelMedium: TextStyle(color: Color(0xFF616161)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: Color(0xFF616161)),
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
      prefixIconColor: const Color(0xFF757575),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0E5A78), width: 2),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: Color(0xFF616161)),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFFFFFFFF)),
      ),
    ),
  );
}
