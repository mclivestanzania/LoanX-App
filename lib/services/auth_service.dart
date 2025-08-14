import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

/// Handles authentication and user account creation.  After registering with
/// Firebase Authentication, the service writes additional profile details
/// into the `users` collection in Firestore.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Register a new user with email and password.  Additional profile fields
  /// are persisted to Firestore under `users/{uid}`.  The [roles] list
  /// indicates whether the user intends to borrow, lend, or both.
  Future<AppUser> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required List<String> roles,
    required String schoolOrEmployer,
    required String courseOrJob,
    required String address,
    double? latitude,
    double? longitude,
    DateTime? dateOfBirth,
    String? personalId,
  }) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final userDoc = AppUser(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      roles: roles,
      schoolOrEmployer: schoolOrEmployer,
      courseOrJob: courseOrJob,
      address: address,
      latitude: latitude,
      longitude: longitude,
      dateOfBirth: dateOfBirth,
      personalId: personalId,
    );
    await _db.collection('users').doc(uid).set(userDoc.toMap());
    return userDoc;
  }

  /// Sign in an existing user.
  Future<User?> login({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Sign out the currently signed‑in user.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Returns a stream of the authenticated user's profile.  Emits `null`
  /// when no user is signed in.
  Stream<AppUser?> get currentUserProfile {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _db.collection('users').doc(user.uid).get();
      return AppUser.fromDocument(doc);
    });
  }
}
