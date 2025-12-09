import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uas_mcc/services/firestore_service.dart';
import 'package:uas_mcc/widgets/bottom_nav.dart';
import 'package:uas_mcc/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<FirestoreService>(context, listen: false);

    final pages = [
      // Home / News & Booking
      StreamBuilder<QuerySnapshot>(
        stream: db.newsStream(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              return ListTile(
                title: Text(d['title'] ?? ''),
                subtitle: Text(d['body'] ?? ''),
              );
            },
          );
        },
      ),
      const Center(child: Text('Booking (tap to choose plan)')),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Gym Membership')),
      body: pages[_index],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => _PlanSheet(db: db),
              ),
              label: const Text('Book Membership'),
              icon: const Icon(Icons.add_card),
            )
          : null,
    );
  }
}

class _PlanSheet extends StatefulWidget {
  final FirestoreService db;
  const _PlanSheet({required this.db});

  @override
  State<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<_PlanSheet> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async => await _book('Silver'),
                  child: const Text('Silver'),
                ),
                ElevatedButton(
                  onPressed: () async => await _book('Gold'),
                  child: const Text('Gold'),
                ),
                ElevatedButton(
                  onPressed: () async => await _book('Platinum'),
                  child: const Text('Platinum'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _book(String plan) async {
    if (!mounted) return;
    Navigator.pop(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }
    await widget.db.createMembership(uid, plan);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Membership requested: $plan')));
  }
}
