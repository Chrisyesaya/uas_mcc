import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uas_mcc/services/auth_service.dart';
import 'package:uas_mcc/services/firestore_service.dart';
import 'package:uas_mcc/widgets/background_video.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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
          const ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.55)),
          Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Admin Login',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: _passCtrl,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () async {
                                setState(() => _loading = true);
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);
                                try {
                                  final user = await auth.signInWithEmail(
                                    _emailCtrl.text.trim(),
                                    _passCtrl.text.trim(),
                                  );
                                  if (user != null) {
                                    final role = await db.getUserRole(user.uid);
                                    if (role != 'admin') {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('No admin privileges'),
                                        ),
                                      );
                                      await auth.signOut();
                                      return;
                                    }
                                    navigator.pop();
                                  }
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Login failed: $e')),
                                  );
                                }
                                setState(() => _loading = false);
                              },
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text('Login as Admin'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
