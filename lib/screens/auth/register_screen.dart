// screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:practice/widgets/common/loading_indicator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // Controllers and State
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  String? _selectedRole;
  final List<String> _roles = ['Farmer', 'Buyer'];

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  final passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]{8,}$',
  );

  final phoneRegex = RegExp(r'^(\+92|0)?[0-9]{10}$');
  final nameRegex = RegExp(r'^[a-zA-Z\s]+$');

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    _passwordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'\d'));
      _hasSpecialChar = password.contains(RegExp(r'[@$!%*?&#]'));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _storeUserDetails(String uid) async {
    // ✅ MODIFIED: Added verificationStatus
    await FirebaseFirestore.instance.collection('Users').doc(uid).set({
      'uid': uid,
      'name': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phoneNumber': _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      'role': _selectedRole!.toLowerCase(),
      'registration_date': FieldValue.serverTimestamp(),
      'status': 'active',
      'emailVerified': false,
      'verificationStatus': 'unverified', // 👈 New Critical Field
    });
  }

  void _registerUser() async {
    if (_isLoading) return;

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final fullName = _fullNameController.text.trim();

    // Validation
    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Please fill in all required fields and select a role.',
          ),
        ),
      );
      return;
    }

    if (!nameRegex.hasMatch(fullName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Full name can only contain letters and spaces.'),
        ),
      );
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please enter a valid email address.'),
        ),
      );
      return;
    }

    if (phone.isNotEmpty && !phoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Please enter a valid phone number (03XXXXXXXXX or +923XXXXXXXXX).',
          ),
        ),
      );
      return;
    }

    if (!passwordRegex.hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          content: Text(
            'Password must have 8+ chars with uppercase, lowercase, number & special char (@\$!%*?&#)',
          ),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Passwords do not match.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      await _storeUserDetails(uid);

      // Send verification email
      await userCredential.user!.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'Account created! Please check your email to verify.',
            ),
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.pushReplacementNamed(
          context,
          '/emailVerificationSent',
          arguments: email,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak. Use stronger password.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered.';
      } else {
        errorMessage = 'Registration failed: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('An unexpected error occurred.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordValidationTexts() {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();

    bool isAllValid = _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber && _hasSpecialChar;
    if (isAllValid) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_hasMinLength)
            Text('• Must be at least 8 characters', style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontWeight: FontWeight.w500)),
          if (!_hasSpecialChar)
            Text('• Must contain a special character (@\$!%*?&#)', style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontWeight: FontWeight.w500)),
          if (!_hasUppercase || !_hasLowercase)
            Text('• Must contain uppercase & lowercase letters', style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontWeight: FontWeight.w500)),
          if (!_hasNumber)
            Text('• Must contain a number', style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 20.0,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // ✨ Title
                        Text(
                          'Join AgriVision',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ✨ Subtitle
                        Text(
                          'Create your account to\nget started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 48),

                        _AnimatedTextField(
                          controller: _fullNameController,
                          labelText: 'Full Name',
                          icon: Iconsax.user,
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 20),

                        _AnimatedTextField(
                          controller: _emailController,
                          labelText: 'Email',
                          icon: Iconsax.direct,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        _AnimatedTextField(
                          controller: _phoneController,
                          labelText: 'Phone Number (Optional)',
                          hintText: '03XXXXXXXXX',
                          icon: Iconsax.call,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),

                        _AnimatedTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          icon: _isPasswordVisible
                              ? Iconsax.eye
                              : Iconsax.eye_slash,
                          obscureText: !_isPasswordVisible,
                          onIconTap: () => setState(
                            () => _isPasswordVisible =
                                !_isPasswordVisible,
                          ),
                        ),
                        
                        // 🔥 Dynamic Password Validation
                        _buildPasswordValidationTexts(),
                        
                        const SizedBox(height: 20),

                        _AnimatedTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          icon: _isConfirmPasswordVisible
                              ? Iconsax.eye
                              : Iconsax.eye_slash,
                          obscureText: !_isConfirmPasswordVisible,
                          onIconTap: () => setState(
                            () => _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _AnimatedDropdown(
                          value: _selectedRole,
                          items: _roles,
                          onChanged: (value) =>
                              setState(() => _selectedRole = value),
                        ),
                        const SizedBox(height: 32),

                        _AnimatedButton(
                          text: 'Sign up',
                          isLoading: _isLoading,
                          onPressed: _registerUser,
                        ),
                        const SizedBox(height: 24),

                        Center(
                          child: TextButton(
                            onPressed: () =>
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                ),
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Login',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ✨ Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.8),
                child: const LoadingIndicator(
                  message: 'Creating account...',
                  color: Color(0xFF388E3C),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final VoidCallback? onIconTap;

  const _AnimatedTextField({
    required this.controller,
    required this.labelText,
    this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onIconTap,
  });

  @override
  State<_AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<_AnimatedTextField> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
      () => setState(() => _isFocused = _focusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          suffixIcon: widget.onIconTap != null
              ? IconButton(
                  icon: Icon(widget.icon, color: Colors.green.shade600),
                  onPressed: widget.onIconTap,
                )
              : Icon(widget.icon, color: Colors.green.shade600),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.green.shade600, width: 2.0),
          ),
          labelStyle: TextStyle(color: Colors.grey[500]),
          floatingLabelStyle: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
      ),
    );
  }
}

class _AnimatedDropdown extends StatefulWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _AnimatedDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_AnimatedDropdown> createState() => _AnimatedDropdownState();
}

class _AnimatedDropdownState extends State<_AnimatedDropdown> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
      () => setState(() => _isFocused = _focusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: DropdownButtonFormField<String>(
        value: widget.value,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: 'Register as...',
          suffixIcon: Icon(Iconsax.category, color: Colors.green.shade600),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.green.shade600, width: 2.0),
          ),
          labelStyle: TextStyle(color: Colors.grey[500]),
          floatingLabelStyle: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        onChanged: widget.onChanged,
        items: widget.items
            .map(
              (String value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(fontSize: 16)),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;

  const _AnimatedButton({
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade600.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.isLoading ? null : widget.onPressed,
              child: Center(
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
