import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maize_hub/utils/validations.dart';
import 'package:maize_hub/widgets/user_image_picker.dart';

final _firebaseAuth = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  File? _selectedImage;
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _animationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    if (mounted) {
      setState(() {
        _isLogin = !_isLogin;
      });

      // Reset form validation when switching modes
      _formKey.currentState?.reset();
    }
  }

  Future<void> _submitForm() async {
    if (_isLoading) return; // Add haptic feedback
    HapticFeedback.lightImpact();

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    final isValid = _formKey.currentState!.validate();
    if (!isValid || !_isLogin && _selectedImage == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      if (_isLogin) {
        final userCredentials = await _firebaseAuth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        print('User logged in:✅ ${userCredentials.user}');
      } else {
        final userCredentials = await _firebaseAuth
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();
        print('User created: 😂 $imageUrl');
      }

      // Success feedback
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  _isLogin ? 'Welcome back!' : 'Account created successfully!',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      // Error feedback
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    error.message ?? 'Authentication failed.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // String _getErrorMessage(String errorCode) {
  //   switch (errorCode) {
  //     case 'weak-password':
  //       return 'The password provided is too weak.';
  //     case 'email-already-in-use':
  //       return 'An account already exists for that email.';
  //     case 'invalid-email':
  //       return 'The email address is not valid.';
  //     case 'user-not-found':
  //       return 'No user found for that email.';
  //     case 'wrong-password':
  //       return 'Wrong password provided.';
  //     case 'too-many-requests':
  //       return 'Too many attempts. Please try again later.';
  //     default:
  //       return 'Authentication failed. Please try again.';
  //   }
  // }

  String? _validateEmail(String? value) {
    return Validations.validateEmail(value);
  }

  String? _validatePassword(String? value) {
    return Validations.validatePassword(value);
  }

  String? _validateName(String? value) {
    if (!_isLogin) {
      return Validations.validateName(value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF1B5E20),
                    const Color(0xFF2E7D32),
                    const Color(0xFF388E3C),
                  ]
                : [
                    const Color(0xFF81C784),
                    const Color(0xFF4CAF50),
                    const Color(0xFF2E7D32),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: size.width > 600 ? (size.width - 500) / 2 : 24.0,
                vertical: 20.0,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and title section
                      _buildHeaderSection(),
                      const SizedBox(height: 30),

                      // Auth form card
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildAuthCard(size, theme),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        // Animated logo container
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(70),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 15),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(70),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50),
                          const Color(0xFF66BB6A),
                        ],
                      ),
                    ),
                    child: const Icon(Icons.eco, size: 70, color: Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // // App title with animation
        // TweenAnimationBuilder<double>(
        //   duration: const Duration(milliseconds: 1000),
        //   tween: Tween(begin: 0.0, end: 1.0),
        //   builder: (context, value, child) {
        //     return Opacity(
        //       opacity: value,
        //       child: Transform.translate(
        //         offset: Offset(0, 20 * (1 - value)),
        //         child:
        //       ),
        //     );
        //   },
        // ),
        Column(
          children: [
            const Text(
              'Maize Hub',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _isLogin ? 'Welcome back!' : 'Join our community!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAuthCard(Size size, ThemeData theme) {
    return Card(
      elevation: 20,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(32.0),
        constraints: BoxConstraints(
          maxWidth: size.width > 500 ? 450 : size.width - 48,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image picker for registration
              _buildImagePicker(),

              // Name field for registration
              _buildNameField(),

              // Email field
              _buildEmailField(),
              const SizedBox(height: 20),

              // Password field
              _buildPasswordField(),
              const SizedBox(height: 32),

              // Submit button
              _buildSubmitButton(),
              const SizedBox(height: 24),

              // Toggle auth mode
              _buildToggleButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: _isLogin ? 0 : 100,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isLogin ? 0 : 1,
        child: _isLogin
            ? const SizedBox.shrink()
            : Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: UserImagePicker(
                  onImagePicked: (pickedImage) {
                    _selectedImage = pickedImage;
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildNameField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: _isLogin ? 0 : 100,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isLogin ? 0 : 1,
        child: _isLogin
            ? const SizedBox.shrink()
            : Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: TextFormField(
                  controller: _nameController,
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                  decoration: _buildInputDecoration(
                    'Full Name',
                    Icons.person_outline,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      validator: _validateEmail,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: _buildInputDecoration('Email Address', Icons.email_outlined),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      validator: _validatePassword,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submitForm(),
      decoration: _buildInputDecoration(
        'Password',
        Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF4CAF50),
          ),
          onPressed: () {
            if (mounted) {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            }
            HapticFeedback.lightImpact();
          },
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: Colors.grey.shade700),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          shadowColor: const Color(0xFF4CAF50).withOpacity(0.4),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isLogin ? Icons.login : Icons.person_add, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isLogin ? 'Sign In' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: _toggleAuthMode,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          children: [
            TextSpan(
              text: _isLogin
                  ? "Don't have an account? "
                  : "Already have an account? ",
            ),
            TextSpan(
              text: _isLogin ? 'Sign Up' : 'Sign In',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
