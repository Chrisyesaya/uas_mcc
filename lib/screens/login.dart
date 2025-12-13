import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:uas_mcc/services/auth_service.dart';
import 'package:uas_mcc/services/firestore_service.dart';
import 'package:uas_mcc/widgets/background_video.dart';
import 'user_register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _isAdmin = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final db = Provider.of<FirestoreService>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundVideo(assetPath: 'assets/video.mp4'),
          ColoredBox(color: Color.fromRGBO(0, 0, 0, _isAdmin ? 0.55 : 0.45)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenWidth > 600 ? 480 : double.infinity,
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tab Navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: _buildTabButton(
                                label: 'User',
                                isSelected: !_isAdmin,
                                icon: Icons.person,
                                onTap: () {
                                  setState(() => _isAdmin = false);
                                  _emailCtrl.clear();
                                  _passCtrl.clear();
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: _buildTabButton(
                                label: 'Admin',
                                isSelected: _isAdmin,
                                icon: Icons.admin_panel_settings,
                                onTap: () {
                                  setState(() => _isAdmin = true);
                                  _emailCtrl.clear();
                                  _passCtrl.clear();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          _isAdmin ? 'Admin Portal' : 'Welcome Back',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(fontSize: 28),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isAdmin
                              ? 'Sign in to manage the gym'
                              : 'Sign in to your account',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        TextField(
                          controller: _emailCtrl,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passCtrl,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
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
                                        if (_isAdmin && role != 'admin') {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'No admin privileges',
                                              ),
                                            ),
                                          );
                                          await auth.signOut();
                                        }
                                      }
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Login failed: $e'),
                                        ),
                                      );
                                    }
                                    if (mounted)
                                      setState(() => _loading = false);
                                  },
                            icon: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    _isAdmin
                                        ? Icons.admin_panel_settings
                                        : Icons.login,
                                  ),
                            label: Text(_isAdmin ? 'Login as Admin' : 'Login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isAdmin
                                  ? Colors.red[700]
                                  : Colors.blue[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_isAdmin)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
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
                                      content: Text(
                                        'Google sign-in failed: $e',
                                      ),
                                    ),
                                  );
                                }
                                if (mounted) setState(() => _loading = false);
                              },
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (!_isAdmin)
                          Center(
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(color: Colors.grey[700]),
                                children: [
                                  TextSpan(
                                    text: 'Register Now',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterUserScreen(),
                                        ),
                                      ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: isSelected
              ? (label == 'Admin' ? Colors.red[700] : Colors.blue[700])
              : Colors.grey[200],
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        (label == 'Admin' ? Colors.red[700] : Colors.blue[700])!
                            .withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
