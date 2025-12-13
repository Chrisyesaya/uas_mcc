import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uas_mcc/services/firestore_service.dart';
import 'package:uas_mcc/widgets/bottom_nav.dart';
import 'package:uas_mcc/screens/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHomeScreen extends StatefulWidget {
  final bool isAdmin;
  const UserHomeScreen({super.key, this.isAdmin = false});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _index = 0;
  final TextEditingController _newsTitleCtrl = TextEditingController();
  final TextEditingController _newsBodyCtrl = TextEditingController();
  // Pagination state for admin user list
  final List<DocumentSnapshot> _pagedUsers = [];
  DocumentSnapshot? _lastUserDoc;
  bool _loadingUsers = false;
  bool _hasMoreUsers = true;
  final int _usersPageSize = 20;

  @override
  void dispose() {
    _newsTitleCtrl.dispose();
    _newsBodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<FirestoreService>(context, listen: false);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isAdmin = widget.isAdmin;

    Widget adminHome() => SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    controller: _newsTitleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: _newsBodyCtrl,
                    decoration: const InputDecoration(labelText: 'Body'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final title = _newsTitleCtrl.text.trim();
                      final body = _newsBodyCtrl.text.trim();
                      if (title.isEmpty) return;
                      await db.addNews(title, body);
                      _newsTitleCtrl.clear();
                      _newsBodyCtrl.clear();
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('News published')),
                      );
                    },
                    child: const Text('Publish'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                              subtitle: Text((benefits as Map).keys.join(', ')),
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
          // Users list with membership — use a single memberships stream to avoid per-item network calls
          StreamBuilder<QuerySnapshot>(
            stream: db.usersStream(),
            builder: (context, usersSnap) {
              if (!usersSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              // Paginated users list — load initial page if empty
              if (_pagedUsers.isEmpty && _hasMoreUsers && !_loadingUsers) {
                _loadMoreUsers(db);
              }
              return Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pagedUsers.length,
                    itemBuilder: (context, i) {
                      final d = _pagedUsers[i];
                      final uid = d.id;
                      final email = d['email'] ?? '';
                      final plan = d['membershipPlan'];
                      final status = d['membershipStatus'];
                      final membershipText = plan == null
                          ? 'No membership'
                          : '$plan · ${status ?? ''}';
                      return ListTile(
                        title: Text(email),
                        subtitle: Text(
                          'Role: ${d['role'] ?? 'user'} — $membershipText',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'cancel') await db.cancelMembership(uid);
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
                  ),
                  if (_loadingUsers)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (!_loadingUsers && _hasMoreUsers)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: () => _loadMoreUsers(db),
                        child: const Text('Load more users'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );

    final pages = [
      // first tab: either news feed or admin dashboard
      if (isAdmin)
        adminHome()
      else
        StreamBuilder<QuerySnapshot>(
          stream: db.newsStream(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
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
      // Membership status / Booking (unchanged)
      Padding(
        padding: const EdgeInsets.all(16),
        child: uid == null
            ? const Center(child: Text('Not signed in'))
            : FutureBuilder<DocumentSnapshot?>(
                future: db.getMembership(uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final doc = snap.data;
                  if (doc == null || !doc.exists) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('You have no active membership.'),
                        SizedBox(height: 8),
                        Text('Tap the + button to request a plan.'),
                      ],
                    );
                  }
                  final data = (doc.data() as Map<String, dynamic>?) ?? {};
                  final plan = data['plan'] ?? 'Unknown';
                  final status = data['status'] ?? 'unknown';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: ListTile(
                          title: Text('Plan: $plan'),
                          subtitle: Text('Status: $status'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<Map<String, dynamic>?>(
                        future: db.getPlanBenefits(plan),
                        builder: (context, bSnap) {
                          if (bSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final benefits = bSnap.data;
                          if (benefits == null || benefits.isEmpty) {
                            return const Text(
                              'No benefits configured for this plan.',
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Benefits:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...benefits.keys.map(
                                (k) => Row(
                                  children: [
                                    const Icon(Icons.check, size: 16),
                                    const SizedBox(width: 8),
                                    Text(k),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
      ),
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

  Future<void> _loadMoreUsers(FirestoreService db) async {
    if (!mounted) return;
    if (_loadingUsers || !_hasMoreUsers) return;
    setState(() => _loadingUsers = true);
    try {
      final snap = await db.fetchUsersPage(
        startAfter: _lastUserDoc,
        limit: _usersPageSize,
      );
      if (snap.docs.isNotEmpty) {
        _pagedUsers.addAll(snap.docs);
        _lastUserDoc = snap.docs.last;
        if (snap.docs.length < _usersPageSize) _hasMoreUsers = false;
      } else {
        _hasMoreUsers = false;
      }
    } catch (_) {
      // ignore errors for now
    }
    if (!mounted) return;
    setState(() => _loadingUsers = false);
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
