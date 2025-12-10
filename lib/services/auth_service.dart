import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
