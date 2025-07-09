import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  // 🔁 Singleton instance
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔐 Current user
  User? get currentUser => _auth.currentUser;

  // 🔄 Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isSignedIn => currentUser != null;

  /// ✅ Sign Up
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ Update display name
      await credential.user?.updateDisplayName(fullName);
      await credential.user?.reload();

      // ✅ Send email verification
      await credential.user?.sendEmailVerification();

      // ✅ Save profile to Firestore
      await _firestore
          .collection('user_profiles')
          .doc(credential.user!.uid)
          .set({
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': 'traveler',
        'is_profile_complete': false,
        'created_at': FieldValue.serverTimestamp(),
        ...?additionalData,
      });

      return credential;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  /// ✅ Sign In
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  /// ✅ Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 🔑 Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// 🔑 Update password
  Future<void> updatePassword(String newPassword) async {
    await currentUser?.updatePassword(newPassword);
  }

  /// ✉️ Update email
  Future<void> updateEmail(String newEmail) async {
    await currentUser?.updateEmail(newEmail);
  }

  /// 📄 Get Firestore user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;

    final doc = await _firestore
        .collection('user_profiles')
        .doc(currentUser!.uid)
        .get();
    return doc.exists ? doc.data() : null;
  }

  /// ✏️ Update Firestore user profile
  Future<void> updateUserProfile({
    String? fullName,
    String? bio,
    String? location,
    String? phone,
    DateTime? dateOfBirth,
    String? avatarUrl,
    String? notificationPreferences,
  }) async {
    if (currentUser == null) return;

    final Map<String, dynamic> updateData = {
      if (fullName != null) 'full_name': fullName,
      if (bio != null) 'bio': bio,
      if (location != null) 'location': location,
      if (phone != null) 'phone': phone,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (notificationPreferences != null)
        'notification_preferences': notificationPreferences,
    };

    if (updateData.isNotEmpty) {
      await _firestore
          .collection('user_profiles')
          .doc(currentUser!.uid)
          .update(updateData);
    }
  }

  /// ✅ Check if user profile is complete
  Future<bool> isProfileComplete() async {
    final profile = await getUserProfile();
    return profile?['is_profile_complete'] == true;
  }

  /// ✅ Mark profile as complete
  Future<void> markProfileComplete() async {
    if (currentUser == null) return;
    await _firestore
        .collection('user_profiles')
        .doc(currentUser!.uid)
        .update({'is_profile_complete': true});
  }

  /// 🚨 Firebase error message mapper
  String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
          return 'Invalid email or password.';
        case 'user-not-found':
          return 'No account found for this email.';
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'invalid-email':
          return 'Invalid email address.';
        default:
          return error.message ?? 'An unknown error occurred.';
      }
    }
    return error.toString();
  }
}
