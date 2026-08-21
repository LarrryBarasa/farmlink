import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<String> registerWithEmail({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'phone': phone,
      'email': email,
      'role': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return uid;
  }

  // Saves role-specific profile data and marks the role on the main user doc.
  // collectionName should be "consumers", "farmers", or "riders".
  Future<void> saveRoleProfile({
    required String uid,
    required String role,
    required String collectionName,
    required Map<String, dynamic> profileData,
  }) async {
    await _firestore.collection('users').doc(uid).update({'role': role});

    await _firestore.collection(collectionName).doc(uid).set({
      ...profileData,
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role'] as String?;
  }
}
