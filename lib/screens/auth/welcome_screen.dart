// screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade800,
              Colors.green.shade600,
              Colors.green.shade400,
              Colors.green.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),

                          // ✨ Animated Logo
                          ElasticIn(
                            duration: const Duration(milliseconds: 1500),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Container(
                                    width: 130,
                                    height: 130,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.agriculture_outlined,
                                      size: 80,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ✨ App Title with Animation
                          FadeInDown(
                            duration: const Duration(milliseconds: 1000),
                            delay: const Duration(milliseconds: 300),
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.white, Color(0xFFE0E0E0)],
                              ).createShader(bounds),
                              child: Text(
                                'AgriVision',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ✨ Subtitle
                          FadeInUp(
                            duration: const Duration(milliseconds: 1000),
                            delay: const Duration(milliseconds: 500),
                            child: Text(
                              'Your Orchard\'s AI Partner',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ✨ Feature Pills
                          FadeInUp(
                            duration: const Duration(milliseconds: 1000),
                            delay: const Duration(milliseconds: 700),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildFeaturePill('🌱 Disease Detection'),
                                _buildFeaturePill('📊 Smart Analytics'),
                                _buildFeaturePill('🛒 Marketplace'),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // ✨ Login Button
                          FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 900),
                            child: _AnimatedButton(
                              text: 'Login',
                              isPrimary: true,
                              icon: Icons.login,
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/login'),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ✨ Register Button
                          FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 1000),
                            child: _AnimatedButton(
                              text: 'Register',
                              isPrimary: false,
                              icon: Icons.person_add,
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/register'),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ✨ Footer Text
                          FadeIn(
                            duration: const Duration(milliseconds: 1000),
                            delay: const Duration(milliseconds: 1200),
                            child: Text(
                              'Powered by AI & Cloud Technology',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ✨ Animated Button Widget
class _AnimatedButton extends StatefulWidget {
  final String text;
  final bool isPrimary;
  final IconData? icon;
  final VoidCallback onPressed;

  const _AnimatedButton({
    required this.text,
    required this.isPrimary,
    this.icon,
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
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? LinearGradient(colors: [Colors.white, Colors.grey.shade100])
                : null,
            color: widget.isPrimary
                ? null
                : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: widget.isPrimary
                ? null
                : Border.all(color: Colors.white, width: 2),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onPressed,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.isPrimary
                            ? Colors.green.shade700
                            : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.isPrimary
                            ? Colors.green.shade700
                            : Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
