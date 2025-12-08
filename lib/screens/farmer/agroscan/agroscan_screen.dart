// lib/screens/farmer/agroscan/agroscan_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

class AgroScanScreen extends StatefulWidget {
  const AgroScanScreen({super.key});

  @override
  State<AgroScanScreen> createState() => _AgroScanScreenState();
}

class _AgroScanScreenState extends State<AgroScanScreen> {
  // Colors
  // static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryMain = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color primaryPale = Color(0xFFE8F5E9);
  static const Color statusInfo = Color(0xFF1976D2);
  static const Color textHeading = Color(0xDE000000);
  static const Color textBody = Color(0xFF616161);

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  // Camera se photo lene ke liye
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured successfully!'),
            backgroundColor: primaryMain,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Gallery se image select karne ke liye
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected successfully!'),
            backgroundColor: primaryMain,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryPale,
      appBar: AppBar(
        backgroundColor: primaryMain,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AgroScan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Info Card
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusInfo, statusInfo.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: statusInfo.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Iconsax.information, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Take a clear photo of the affected leaf or fruit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Selected Image Display (agar koi image select ki ho)
              if (_selectedImage != null) ...[
                FadeIn(
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryMain.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Clear Image Button
                FadeInUp(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                    icon: const Icon(Iconsax.trash),
                    label: const Text(
                      'Remove Image',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              const Spacer(),

              // Main Action Buttons
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _buildOptionButton(
                  title: 'Take Photo',
                  subtitle: 'Use camera to capture image',
                  icon: Iconsax.camera,
                  gradient: const LinearGradient(
                    colors: [primaryMain, primaryLight],
                  ),
                  onTap: _takePhoto,
                ),
              ),

              const SizedBox(height: 16),

              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: _buildOptionButton(
                  title: 'Upload from Gallery',
                  subtitle: 'Choose image from your device',
                  icon: Iconsax.gallery,
                  gradient: LinearGradient(
                    colors: [statusInfo, statusInfo.withOpacity(0.8)],
                  ),
                  onTap: _pickFromGallery,
                ),
              ),

              const SizedBox(height: 30),

              // Tips Section
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryLight.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Iconsax.lamp_on, color: primaryMain, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Tips for Best Results',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textHeading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildTipItem('Ensure good lighting'),
                      _buildTipItem('Focus clearly on affected area'),
                      _buildTipItem('Avoid blurry images'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryMain.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Iconsax.arrow_right_3,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Iconsax.tick_circle, color: primaryMain, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}