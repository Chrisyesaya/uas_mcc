import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uas_mcc/services/firestore_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<FirestoreService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const Text(
                      'Add News',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: _bodyCtrl,
                      decoration: const InputDecoration(labelText: 'Body'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (_titleCtrl.text.isEmpty) return;
                        await db.addNews(
                          _titleCtrl.text.trim(),
                          _bodyCtrl.text.trim(),
                        );
                        _titleCtrl.clear();
                        _bodyCtrl.clear();
                      },
                      child: const Text('Publish'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Plans editor
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const Text(
                      'Membership Plans',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 140,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: db.plansStream(),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final docs = snap.data!.docs;
                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, i) {
                              final d = docs[i];
                              final planId = d.id;
                              final benefits =
                                  (d.data()
                                      as Map<String, dynamic>)['benefits'] ??
                                  {};
                              return ListTile(
                                title: Text(planId),
                                subtitle: Text(
                                  (benefits as Map).keys.join(', '),
                                ),
                                onTap: () => _showEditPlan(
                                  context,
                                  db,
                                  planId,
                                  Map<String, dynamic>.from(benefits),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: db.usersStream(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final d = docs[i];
                      final uid = d.id;
                      final email = d['email'] ?? '';
                      return ListTile(
                        title: Text(email),
                        subtitle: Text('Role: ${d['role'] ?? 'user'}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'cancel') {
                              await db.cancelMembership(uid);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'cancel',
                              child: Text('Cancel Membership'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlan(
    BuildContext context,
    FirestoreService db,
    String planId,
    Map<String, dynamic> benefits,
  ) {
    final titleCtrl = TextEditingController(text: planId);
    final benefitCtrl = TextEditingController(text: (benefits.keys.join(', ')));
    final parentNavigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Plan ID'),
            ),
            TextField(
              controller: benefitCtrl,
              decoration: const InputDecoration(
                labelText: 'Benefits (comma separated)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final b = benefitCtrl.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              final map = <String, dynamic>{};
              for (var item in b) {
                map[item] = true;
              }
              await db.updateMembershipBenefits(titleCtrl.text.trim(), map);
              parentNavigator.pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
