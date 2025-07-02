// lib/services/firebase_auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isSignedIn => currentUser != null;

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

      // ✅ Имэйл баталгаажуулах имэйл илгээх
      await credential.user?.sendEmailVerification();

      // ✅ Firestore дээр хэрэглэгчийн профайл хадгалах
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

  // Sign in
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    await currentUser?.updatePassword(newPassword);
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    await currentUser?.updateEmail(newEmail);
  }

  // Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;
    final doc = await _firestore
        .collection('user_profiles')
        .doc(currentUser!.uid)
        .get();
    return doc.exists ? doc.data() : null;
  }

  // Update user profile
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

    final updateData = <String, dynamic>{};
    if (fullName != null) updateData['full_name'] = fullName;
    if (bio != null) updateData['bio'] = bio;
    if (location != null) updateData['location'] = location;
    if (phone != null) updateData['phone'] = phone;
    if (dateOfBirth != null)
      updateData['date_of_birth'] = dateOfBirth.toIso8601String();
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
    if (notificationPreferences != null) {
      updateData['notification_preferences'] = notificationPreferences;
    }

    if (updateData.isNotEmpty) {
      await _firestore
          .collection('user_profiles')
          .doc(currentUser!.uid)
          .update(updateData);
    }
  }

  Future<bool> isProfileComplete() async {
    final profile = await getUserProfile();
    return profile?['is_profile_complete'] == true;
  }

  Future<void> markProfileComplete() async {
    if (currentUser == null) return;
    await _firestore
        .collection('user_profiles')
        .doc(currentUser!.uid)
        .update({'is_profile_complete': true});
  }

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
