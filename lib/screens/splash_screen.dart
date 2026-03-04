import 'package:flutter/material.dart';
import 'package:practice/widgets/common/loading_indicator.dart';
import 'package:practice/screens/onboarding/onboarding_screen.dart';
import 'package:animate_do/animate_do.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for 2.5 seconds
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             FadeInDown(
              child: Image.asset(
                'assets/images/clean_logo.png',
                width: 180,
                height: 180,
              ),
            ),
            const SizedBox(height: 48),
            // Loading Indicator reused from the app
            const LoadingIndicator(
              message: 'Loading...',
              color: Color(0xFF388E3C), // Primary green
            ),
          ],
        ),
      ),
    );
  }
}
