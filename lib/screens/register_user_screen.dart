import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uas_mcc/services/auth_service.dart';
import 'package:uas_mcc/services/firestore_service.dart';
import 'package:uas_mcc/widgets/background_video.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
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
                      'Create Account',
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
                                  final user = await auth.registerWithEmail(
                                    _emailCtrl.text.trim(),
                                    _passCtrl.text.trim(),
                                  );
                                  if (user != null) {
                                    await db.createUserProfile(
                                      user.uid,
                                      user.email ?? '',
                                      'user',
                                    );
                                    navigator.pop();
                                  }
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Register failed: $e'),
                                    ),
                                  );
                                }
                                setState(() => _loading = false);
                              },
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text('Register'),
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
