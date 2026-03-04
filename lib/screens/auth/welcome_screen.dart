// screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                        const SizedBox(height: 40),

                        // ✨ Animated Logo
                        ElasticIn(
                          duration: const Duration(milliseconds: 1500),
                          child: Center(
                            child: Container(
                              height: 250,
                              width: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.shade900.withValues(
                                      alpha: 0.15,
                                    ),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Container(
                                  color: Colors.white,
                                  child: Transform.scale(
                                    scale: 1.25,
                                    child: Image.asset(
                                      'assets/images/clean_logo.png',
                                      fit: BoxFit.contain,
                                      // Fallback icon if image is missing
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.agriculture_outlined,
                                          size: 120,
                                          color: Colors.green.shade700,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),

                        // ✨ App Title with Animation
                        FadeInDown(
                          duration: const Duration(milliseconds: 1000),
                          delay: const Duration(milliseconds: 300),
                          child: Text(
                            'AgriVision',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ✨ Subtitle
                        FadeInUp(
                          duration: const Duration(milliseconds: 1000),
                          delay: const Duration(milliseconds: 500),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'An all-in-one digital platform for modernized fruit production, diagnostics, and commerce.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // ✨ Buttons Row
                        FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          delay: const Duration(milliseconds: 900),
                          child: Row(
                            children: [
                              Expanded(
                                child: _AnimatedButton(
                                  text: 'Login',
                                  isPrimary: true,
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/login'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _AnimatedButton(
                                  text: 'Register',
                                  isPrimary: false,
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/register'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ✨ Animated Button Widget
class _AnimatedButton extends StatefulWidget {
  final String text;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _AnimatedButton({
    required this.text,
    required this.isPrimary,
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
          height: 60,
          decoration: BoxDecoration(
            color: widget.isPrimary ? Colors.green.shade600 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: widget.isPrimary
                ? null
                : Border.all(color: Colors.transparent, width: 0),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: Colors.green.shade600.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onPressed,
              child: Center(
                child: Text(
                  widget.text,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isPrimary
                        ? Colors.white
                        : Colors.black87,
                    letterSpacing: 0.5,
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
