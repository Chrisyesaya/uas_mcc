import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<User?> registerWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<User?> signInWithGoogle() async {
    // Use Firebase popup on web; mobile Google Sign-In via package may need
    // the google_sign_in plugin which has changed APIs across versions.
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final userCred = await _auth.signInWithPopup(provider);
      return userCred.user;
    }
    // Mobile Google Sign-In not implemented here to avoid plugin API mismatches.
    // Fallback: return null so callers can fall back to email/password.
    return null;
  }

  Future<void> signOut() => _auth.signOut();
}

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
  );
}
