import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections: users, memberships, news
  Future<void> createUserProfile(String uid, String email, String role) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role'] as String?;
  }

  Stream<QuerySnapshot> newsStream() =>
      _db.collection('news').orderBy('createdAt', descending: true).snapshots();

  Future<void> addNews(String title, String body) async {
    await _db.collection('news').add({
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createMembership(String uid, String plan) async {
    await _db.collection('memberships').doc(uid).set({
      'plan': plan,
      'status': 'pending',
      'startedAt': FieldValue.serverTimestamp(),
    });
    // Denormalize: store membership summary on the user's document for faster reads
    await _db.collection('users').doc(uid).set({
      'membershipPlan': plan,
      'membershipStatus': 'pending',
      'membershipUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot?> getMembership(String uid) async {
    try {
      final doc = await _db.collection('memberships').doc(uid).get();
      return doc.exists ? doc : null;
    } on FirebaseException catch (_) {
      // Fallback to cache if offline
      final doc = await _db
          .collection('memberships')
          .doc(uid)
          .get(GetOptions(source: Source.cache));
      return doc.exists ? doc : null;
    }
  }

  Stream<QuerySnapshot> usersStream() => _db.collection('users').snapshots();

  Stream<QuerySnapshot> membershipsStream() =>
      _db.collection('memberships').snapshots();

  Future<void> updateMembershipBenefits(
    String plan,
    Map<String, dynamic> benefits,
  ) async {
    // store plans collection
    await _db.collection('plans').doc(plan).set({
      'benefits': benefits,
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> plansStream() => _db.collection('plans').snapshots();

  Future<Map<String, dynamic>?> getPlanBenefits(String plan) async {
    final doc = await _db.collection('plans').doc(plan).get();
    if (!doc.exists) return null;
    return doc.data()?['benefits'] as Map<String, dynamic>?;
  }

  Future<void> cancelMembership(String uid) async {
    await _db.collection('memberships').doc(uid).update({
      'status': 'cancelled',
    });
    // Keep users doc denormalized state in sync
    await _db.collection('users').doc(uid).set({
      'membershipStatus': 'cancelled',
      'membershipUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Fetch a page of users ordered by `createdAt`. If [startAfter] is provided,
  /// the query will start after that document (useful for pagination).
  Future<QuerySnapshot> fetchUsersPage({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    var q = _db.collection('users').orderBy('createdAt');
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    try {
      return await q.limit(limit).get();
    } on FirebaseException catch (_) {
      // If offline, try to read from cache
      return await q.limit(limit).get(const GetOptions(source: Source.cache));
    }
  }

  // Save account data to "accounts" parent collection
  Future<void> saveAccountData({
    required String uid,
    required String email,
    required String nama,
    required String jenisKelamin,
    required String tanggalLahir,
    required String alamat,
  }) async {
    await _db.collection('accounts').doc(uid).set({
      'email': email,
      'nama': nama,
      'jenisKelamin': jenisKelamin,
      'tanggalLahir': tanggalLahir,
      'alamat': alamat,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

class AppUser {
  final String uid;
  final String email;
  final String role;

  AppUser({required this.uid, required this.email, required this.role});

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
    );
  }
}
