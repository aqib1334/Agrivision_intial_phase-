// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:practice/screens/admin/admin_dashboard_screen.dart';
import 'package:practice/screens/auth/email_verification_sent_screen.dart';
import 'package:practice/screens/auth/forgot_password_screen.dart';
import 'package:practice/screens/auth/login_screen.dart';
import 'package:practice/screens/auth/password_reset_success_screen.dart';
import 'package:practice/screens/auth/register_screen.dart';
import 'package:practice/screens/auth/welcome_screen.dart';

// Auth Screens


// import 'screens/confirm_passkey_screen.dart';


// Dashboards
import 'screens/dashboards/farmer_home_screen.dart';
import 'screens/dashboards/buyer_home_screen.dart';
// Farmer Profile
import 'package:practice/screens/dashboards/farmer_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyC7BeUbcrL81gMpnwGA8Yyq4nrS3-6xKWA",
        authDomain: "setup-2d1f6.firebaseapp.com",
        projectId: "setup-2d1f6",
        storageBucket: "setup-2d1f6.firebasestorage.app",
        messagingSenderId: "123822045493",
        appId: "1:123822045493:web:65f0d54901620b41b7b47c",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const AgriVisionApp());
}

class AgriVisionApp extends StatelessWidget {
  const AgriVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green.shade700;
    final Color lightGreen = Colors.green.shade50;
    final Color mediumGreen = Colors.green.shade600;

    return MaterialApp(
      title: 'AgriVision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: lightGreen,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: mediumGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          hintStyle: TextStyle(color: Colors.grey.shade500),
          labelStyle: TextStyle(color: Colors.grey[600]),
          floatingLabelStyle: const TextStyle(color: Colors.black87),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 14,
          ),
        ),
      ),

      home: const WelcomeScreen(),

      routes: {
        // ==================== AUTH ROUTES ====================
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/passwordSuccess': (context) => const PasswordResetSuccessScreen(),
        '/emailVerificationSent': (context) => const EmailVerificationSentScreen(),

        // ==================== DASHBOARD ROUTES ====================
        '/farmerHome': (context) => const FarmerHomeScreen(),
        '/buyerHome': (context) => const BuyerHomeScreen(),
    

        // ==================== FARMER PROFILE ====================
        '/farmerProfile': (context) => const FarmerProfileScreen(),
        '/adminHome': (context) => const AdminDashboardScreen(),
      },
    );
  }
}
