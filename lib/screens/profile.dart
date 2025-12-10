import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uas_mcc/services/firestore_service.dart';
import 'package:uas_mcc/services/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final db = Provider.of<FirestoreService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text('Email: ${user?.email ?? '—'}'),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Theme:'),
              const SizedBox(width: 8),
              Switch(value: theme.isDark, onChanged: (_) => theme.toggle()),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Membership Status',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder(
            future: db.getMembership(user?.uid ?? ''),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              final doc = snap.data;
              if (doc == null) return const Text('No membership');
              final data = (doc as dynamic).data() as Map<String, dynamic>?;
              return Text(
                'Plan: ${data?['plan'] ?? '-'}\nStatus: ${data?['status'] ?? '-'}',
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async => await FirebaseAuth.instance.signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
