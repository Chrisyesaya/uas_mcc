import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uas_mcc/services/auth_service.dart';
import 'package:uas_mcc/services/firestore_service.dart';
import 'package:uas_mcc/widgets/background_video.dart';
import 'register_user_screen.dart';
import 'admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final db = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundVideo(assetPath: 'assets/video.mp4'),
          const ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.45)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading
                              ? null
                              : () async {
                                  setState(() => _loading = true);
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  try {
                                    final user = await auth.signInWithEmail(
                                      _emailCtrl.text.trim(),
                                      _passCtrl.text.trim(),
                                    );
                                    if (user != null) {
                                      // ensure profile exists
                                      final role = await db.getUserRole(
                                        user.uid,
                                      );
                                      if (role == null) {
                                        await db.createUserProfile(
                                          user.uid,
                                          user.email ?? '',
                                          'user',
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Login failed: $e'),
                                      ),
                                    );
                                  }
                                  setState(() => _loading = false);
                                },
                          child: _loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Login'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('Sign in with Google'),
                          onPressed: () async {
                            setState(() => _loading = true);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final user = await auth.signInWithGoogle();
                              if (user != null) {
                                final role = await db.getUserRole(user.uid);
                                if (role == null) {
                                  await db.createUserProfile(
                                    user.uid,
                                    user.email ?? '',
                                    'user',
                                  );
                                }
                              }
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Google sign-in failed: $e'),
                                ),
                              );
                            }
                            setState(() => _loading = false);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterUserScreen(),
                              ),
                            ),
                            child: const Text('Register (User)'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminLoginScreen(),
                              ),
                            ),
                            child: const Text('Admin Login'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
