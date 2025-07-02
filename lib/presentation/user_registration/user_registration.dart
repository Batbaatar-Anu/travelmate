import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:travelmate/services/firebase_auth_service.dart';
import '../../core/app_export.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRegistration extends StatefulWidget {
  const UserRegistration({super.key});

  @override
  State<UserRegistration> createState() => _UserRegistrationState();
}

class _UserRegistrationState extends State<UserRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // final _authService = AuthService();
  final _authService = FirebaseAuthService();

  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isTermsAccepted = false;
  bool _isLoading = false;
  bool _isFormValid = false;

  String? _fullNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _setupFormValidation();
    _initializeAuth();
  }

  void _initializeAuth() async {
    try {
      // Remove this line:
      // final _authService = FirebaseAuthService();

      // If you had an initialize method (optional), you'd call it here.
      // await _authService.initialize(); ← Only if such method exists
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    }
  }

  void _setupFormValidation() {
    _fullNameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _fullNameError = _validateFullName(_fullNameController.text);
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
      _confirmPasswordError = _validateConfirmPassword(
        _passwordController.text,
        _confirmPasswordController.text,
      );

      _isFormValid = _fullNameError == null &&
          _emailError == null &&
          _passwordError == null &&
          _confirmPasswordError == null &&
          _fullNameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty &&
          _isTermsAccepted;
    });
  }

  String? _validateFullName(String value) {
    if (value.isEmpty) return null;
    if (value.length < 2) return "Name must be at least 2 characters";
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return "Name can only contain letters and spaces";
    }
    return null;
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return null;
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return "Please enter a valid email address";
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return null;
    if (value.length < 8) return "Password must be at least 8 characters";
    if (!RegExp(
            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]')
        .hasMatch(value)) {
      return "Password must contain uppercase, lowercase, number and special character";
    }
    return null;
  }

  String? _validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) return null;
    if (password != confirmPassword) return "Passwords do not match";
    return null;
  }

  Color _getPasswordStrengthColor() {
    final password = _passwordController.text;
    if (password.length < 4) return AppTheme.lightTheme.colorScheme.error;
    if (password.length < 8) return AppTheme.warningLight;
    if (_validatePassword(password) == null) return AppTheme.successLight;
    return AppTheme.warningLight;
  }

  String _getPasswordStrengthText() {
    final password = _passwordController.text;
    if (password.length < 4) return "Weak";
    if (password.length < 8) return "Fair";
    if (_validatePassword(password) == null) return "Strong";
    return "Good";
  }

  Future<void> _handleRegistration() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final fullName = _fullNameController.text.trim();

      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user != null) {
        if (mounted) {
          _showSuccessDialog();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final errorMessage = _authService.getErrorMessage(e);
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Registration failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.successLight,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text(
              'Welcome to TravelMate!',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
          ],
        ),
        content: Text(
          'Your account has been created successfully. Please check your email to verify your account.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/user-login');
            },
            child: const Text('Continue to Login'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

//   Future<void> _handleSocialRegistrationWithGoogle() async {
//   setState(() {
//     _isLoading = true;
//   });

//   try {
//     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//     if (googleUser == null) {
//       _showErrorSnackBar('Google login cancelled');
//       return;
//     }

//     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//     final credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth.accessToken,
//       idToken: googleAuth.idToken,
//     );

//     final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

//     if (userCredential.user != null && mounted) {
//       _showSuccessDialog();
//     }
//   } catch (e) {
//     if (mounted) {
//       _showErrorSnackBar('Social login failed: ${e.toString()}');
//     }
//   } finally {
//     if (mounted) {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
// }

  void _openTermsAndPrivacy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Terms & Privacy Policy',
                style: AppTheme.lightTheme.textTheme.headlineSmall,
              ),
              SizedBox(height: 2.h),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    '''Terms of Service

Welcome to TravelMate! By creating an account, you agree to our terms of service and privacy policy.

1. Account Security
- Keep your login credentials secure
- Do not share your account with others
- Report suspicious activity immediately

2. Travel Content
- All travel information is provided for reference
- Verify details before making bookings
- We are not responsible for third-party services

3. Privacy Policy
- We protect your personal information
- Location data is used to enhance your experience
- You can control your privacy settings anytime

4. User Conduct
- Be respectful to other travelers
- Do not post inappropriate content
- Follow local laws and regulations

For complete terms, visit our website or contact support.''',
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('I Understand'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and logo
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.lightTheme.shadowColor,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CustomIconWidget(
                        iconName: 'arrow_back',
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'flight_takeoff',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 28,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'TravelMate',
                            style: AppTheme.lightTheme.textTheme.titleLarge
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w), // Balance the back button
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2.h),

                      // Welcome text
                      Text(
                        'Create Your Account',
                        style: AppTheme.lightTheme.textTheme.headlineMedium
                            ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Join thousands of travelers exploring the world with TravelMate',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 4.h),

                      // Full Name Field
                      Text(
                        'Full Name',
                        style: AppTheme.lightTheme.textTheme.labelLarge,
                      ),
                      SizedBox(height: 1.h),
                      TextFormField(
                        controller: _fullNameController,
                        focusNode: _fullNameFocusNode,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(3.w),
                            child: CustomIconWidget(
                              iconName: 'person',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          errorText: _fullNameError,
                        ),
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_emailFocusNode);
                        },
                      ),
                      SizedBox(height: 3.h),

                      // Email Field
                      Text(
                        'Email Address',
                        style: AppTheme.lightTheme.textTheme.labelLarge,
                      ),
                      SizedBox(height: 1.h),
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: 'Enter your email address',
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(3.w),
                            child: CustomIconWidget(
                              iconName: 'email',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          errorText: _emailError,
                        ),
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(_passwordFocusNode);
                        },
                      ),
                      SizedBox(height: 3.h),

                      // Password Field
                      Text(
                        'Password',
                        style: AppTheme.lightTheme.textTheme.labelLarge,
                      ),
                      SizedBox(height: 1.h),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: !_isPasswordVisible,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: 'Create a strong password',
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(3.w),
                            child: CustomIconWidget(
                              iconName: 'lock',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.all(3.w),
                              child: CustomIconWidget(
                                iconName: _isPasswordVisible
                                    ? 'visibility_off'
                                    : 'visibility',
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ),
                          errorText: _passwordError,
                        ),
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(_confirmPasswordFocusNode);
                        },
                      ),

                      // Password strength indicator
                      if (_passwordController.text.isNotEmpty) ...[
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: _passwordController.text.length / 12,
                                backgroundColor:
                                    AppTheme.lightTheme.colorScheme.outline,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getPasswordStrengthColor(),
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              _getPasswordStrengthText(),
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: _getPasswordStrengthColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 3.h),

                      // Confirm Password Field
                      Text(
                        'Confirm Password',
                        style: AppTheme.lightTheme.textTheme.labelLarge,
                      ),
                      SizedBox(height: 1.h),
                      TextFormField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        obscureText: !_isConfirmPasswordVisible,
                        textInputAction: TextInputAction.done,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: 'Confirm your password',
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(3.w),
                            child: CustomIconWidget(
                              iconName: 'lock',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.all(3.w),
                              child: CustomIconWidget(
                                iconName: _isConfirmPasswordVisible
                                    ? 'visibility_off'
                                    : 'visibility',
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ),
                          errorText: _confirmPasswordError,
                        ),
                        onFieldSubmitted: (_) {
                          if (_isFormValid) _handleRegistration();
                        },
                      ),
                      SizedBox(height: 3.h),

                      // Terms and Privacy Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _isTermsAccepted,
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _isTermsAccepted = value ?? false;
                                      _validateForm();
                                    });
                                  },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isTermsAccepted = !_isTermsAccepted;
                                        _validateForm();
                                      });
                                    },
                              child: Padding(
                                padding: EdgeInsets.only(top: 3.w),
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTheme
                                        .lightTheme.textTheme.bodyMedium,
                                    children: [
                                      const TextSpan(text: 'I agree to the '),
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: _openTermsAndPrivacy,
                                          child: Text(
                                            'Terms & Privacy Policy',
                                            style: AppTheme
                                                .lightTheme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: AppTheme.lightTheme
                                                  .colorScheme.primary,
                                              decoration:
                                                  TextDecoration.underline,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),

                      // Create Account Button
                      SizedBox(
                        width: double.infinity,
                        height: 6.h,
                        child: ElevatedButton(
                          onPressed: _isFormValid && !_isLoading
                              ? _handleRegistration
                              : null,
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.lightTheme.colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Create Account',
                                  style: AppTheme
                                      .lightTheme.textTheme.labelLarge
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 3.h),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppTheme.lightTheme.dividerColor,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Text(
                              'Or continue with',
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppTheme.lightTheme.dividerColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),

                      // Social Registration Buttons
//                       Row(
// //   children: [
// //     Expanded(
// //       child: OutlinedButton(
// //         onPressed: _isLoading ? null : _handleGoogleSignIn,
// //         style: OutlinedButton.styleFrom(
// //           padding: EdgeInsets.symmetric(vertical: 2.h),
// //         ),
// //         child: Row(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             CustomIconWidget(
// //               iconName: 'g_translate',
// //               color: AppTheme.lightTheme.colorScheme.primary,
// //               size: 20,
// //             ),
// //             SizedBox(width: 2.w),
// //             Text('Google'),
// //           ],
// //         ),
// //       ),
// //     ),
// //     SizedBox(width: 4.w),
// //     Expanded(
// //       child: OutlinedButton(
// //         onPressed: _isLoading ? null : _handleAppleSignIn,
// //         style: OutlinedButton.styleFrom(
// //           padding: EdgeInsets.symmetric(vertical: 2.h),
// //         ),
// //         child: Row(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             CustomIconWidget(
// //               iconName: 'apple',
// //               color: AppTheme.lightTheme.colorScheme.primary,
// //               size: 20,
// //             ),
// //             SizedBox(width: 2.w),
// //             Text('Apple'),
// //           ],
// //         ),
// //       ),
// //     ),
// //   ],
// // ),

                      SizedBox(height: 4.h),

                      // Sign In Link
                      Center(
                        child: GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                                  Navigator.pushReplacementNamed(
                                      context, '/user-login');
                                },
                          child: RichText(
                            text: TextSpan(
                              style: AppTheme.lightTheme.textTheme.bodyMedium,
                              children: [
                                const TextSpan(
                                    text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Sign In',
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
