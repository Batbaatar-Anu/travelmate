// import 'package:flutter/foundation.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import './supabase_service.dart';

// class AuthService {
//   static final AuthService _instance = AuthService._internal();
//   factory AuthService() => _instance;
//   AuthService._internal();

//   late final SupabaseClient _client;
//   bool _isInitialized = false;

//   // Initialize the service
//   Future<void> initialize() async {
//     if (_isInitialized) return;

//     final supabaseService = SupabaseService();
//     _client = await supabaseService.client;
//     _isInitialized = true;
//   }

//   // Get current user
//   User? get currentUser => _client.auth.currentUser;

//   // Get current session
//   Session? get currentSession => _client.auth.currentSession;

//   // Check if user is signed in
//   bool get isSignedIn => currentUser != null;

//   // Auth state stream
//   Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

//   // Sign up with email and password
//   Future<AuthResponse> signUp({
//     required String email,
//     required String password,
//     required String fullName,
//     String? phone,
//     Map<String, dynamic>? additionalData,
//   }) async {
//     try {
//       final response = await _client.auth.signUp(
//         email: email,
//         password: password,
//         data: {
//           'full_name': fullName,
//           if (phone != null) 'phone': phone,
//           'role': 'traveler',
//           ...?additionalData,
//         },
//       );

//       if (response.user != null && response.session != null) {
//         debugPrint('User signed up successfully: ${response.user!.email}');
//       }

//       return response;
//     } catch (e) {
//       debugPrint('Sign up error: $e');
//       rethrow;
//     }
//   }

//   // Sign in with email and password
//   Future<AuthResponse> signIn({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       final response = await _client.auth.signInWithPassword(
//         email: email,
//         password: password,
//       );

//       if (response.user != null && response.session != null) {
//         debugPrint('User signed in successfully: ${response.user!.email}');
//       }

//       return response;
//     } catch (e) {
//       debugPrint('Sign in error: $e');
//       rethrow;
//     }
//   }

//   // Sign in with OAuth
//   Future<bool> signInWithOAuth(OAuthProvider provider) async {
//     try {
//       final response = await _client.auth.signInWithOAuth(provider);
//       return response;
//     } catch (e) {
//       debugPrint('OAuth sign in error: $e');
//       rethrow;
//     }
//   }

//   // Sign out
//   Future<void> signOut() async {
//     try {
//       await _client.auth.signOut();
//       debugPrint('User signed out successfully');
//     } catch (e) {
//       debugPrint('Sign out error: $e');
//       rethrow;
//     }
//   }

//   // Reset password
//   Future<void> resetPassword(String email) async {
//     try {
//       await _client.auth.resetPasswordForEmail(email);
//       debugPrint('Password reset email sent to: $email');
//     } catch (e) {
//       debugPrint('Reset password error: $e');
//       rethrow;
//     }
//   }

//   // Update user password
//   Future<UserResponse> updatePassword(String newPassword) async {
//     try {
//       final response = await _client.auth.updateUser(
//         UserAttributes(password: newPassword),
//       );
//       debugPrint('Password updated successfully');
//       return response;
//     } catch (e) {
//       debugPrint('Update password error: $e');
//       rethrow;
//     }
//   }

//   // Update user email
//   Future<UserResponse> updateEmail(String newEmail) async {
//     try {
//       final response = await _client.auth.updateUser(
//         UserAttributes(email: newEmail),
//       );
//       debugPrint('Email update initiated');
//       return response;
//     } catch (e) {
//       debugPrint('Update email error: $e');
//       rethrow;
//     }
//   }

//   // Get user profile from user_profiles table
//   Future<Map<String, dynamic>?> getUserProfile() async {
//     try {
//       if (currentUser == null) return null;

//       final response = await _client
//           .from('user_profiles')
//           .select()
//           .eq('id', currentUser!.id)
//           .single();

//       return response;
//     } catch (e) {
//       debugPrint('Get user profile error: $e');
//       return null;
//     }
//   }

//   // Update user profile in user_profiles table
//   Future<Map<String, dynamic>?> updateUserProfile({
//     String? fullName,
//     String? bio,
//     String? location,
//     String? phone,
//     DateTime? dateOfBirth,
//     String? avatarUrl,
//     String? notificationPreferences,
//   }) async {
//     try {
//       if (currentUser == null) return null;

//       final updateData = <String, dynamic>{};
//       if (fullName != null) updateData['full_name'] = fullName;
//       if (bio != null) updateData['bio'] = bio;
//       if (location != null) updateData['location'] = location;
//       if (phone != null) updateData['phone'] = phone;
//       if (dateOfBirth != null) {
//         updateData['date_of_birth'] = dateOfBirth.toIso8601String();
//       }
//       if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
//       if (notificationPreferences != null) {
//         updateData['notification_preferences'] = notificationPreferences;
//       }

//       if (updateData.isEmpty) return null;

//       final response = await _client
//           .from('user_profiles')
//           .update(updateData)
//           .eq('id', currentUser!.id)
//           .select()
//           .single();

//       debugPrint('User profile updated successfully');
//       return response;
//     } catch (e) {
//       debugPrint('Update user profile error: $e');
//       rethrow;
//     }
//   }

//   // Check if profile is complete
//   Future<bool> isProfileComplete() async {
//     try {
//       final profile = await getUserProfile();
//       if (profile == null) return false;

//       return profile['is_profile_complete'] == true;
//     } catch (e) {
//       debugPrint('Check profile complete error: $e');
//       return false;
//     }
//   }

//   // Mark profile as complete
//   Future<void> markProfileComplete() async {
//     try {
//       if (currentUser == null) return;

//       await _client
//           .from('user_profiles')
//           .update({'is_profile_complete': true}).eq('id', currentUser!.id);

//       debugPrint('Profile marked as complete');
//     } catch (e) {
//       debugPrint('Mark profile complete error: $e');
//       rethrow;
//     }
//   }

//   // Get error message from Supabase auth exception
//   String getErrorMessage(dynamic error) {
//     if (error is AuthException) {
//       switch (error.message.toLowerCase()) {
//         case 'invalid login credentials':
//           return 'Invalid email or password. Please check your credentials.';
//         case 'email not confirmed':
//           return 'Please verify your email address before signing in.';
//         case 'user already registered':
//           return 'An account with this email already exists.';
//         case 'weak password':
//           return 'Password is too weak. Please choose a stronger password.';
//         case 'signup disabled':
//           return 'Account registration is currently disabled.';
//         case 'invalid email':
//           return 'Please enter a valid email address.';
//         default:
//           return error.message;
//       }
//     }
//     return error.toString();
//   }
// }
