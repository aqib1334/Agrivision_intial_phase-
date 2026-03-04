import 'dart:io';
import 'package:flutter/foundation.dart'; // ✅ kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:practice/models/disease_history_model.dart';
import 'package:practice/widgets/farmer/orchard_selector_sheet.dart';
import 'package:practice/services/cloudinary_service.dart';

class AgroScanScreen extends StatefulWidget {
  const AgroScanScreen({super.key});

  @override
  State<AgroScanScreen> createState() => _AgroScanScreenState();
}

class _AgroScanScreenState extends State<AgroScanScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _lightGreen = Color(0xFF66BB6A);

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage; // ✅ Changed from File to XFile (works on web + mobile)
  bool _isAnalyzing = false;
  bool _isSaved = false; // tracks if this scan was saved to history
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Camera permission check then capture ─────────────────────────────────
  Future<void> _handleCameraCapture() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      _captureFromCamera();
    } else if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        _captureFromCamera();
      } else {
        _showPermissionDeniedDialog();
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 90,
      );
      if (image != null && mounted) {
        setState(() => _selectedImage = image); // ✅ Store XFile directly
        _startAnalysis();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 90,
      );
      if (image != null && mounted) {
        setState(() => _selectedImage = image); // ✅ Store XFile directly
        _startAnalysis();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _startAnalysis() {
    setState(() => _isAnalyzing = true);
    // Simulate AI analysis (replace with real API call)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isAnalyzing = false);
    });
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.camera_slash, color: Colors.red.shade400, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Camera Access Required'),
          ],
        ),
        content: Text(
          'AgroScan needs camera access to scan your crops for diseases.\n\n'
          'Please enable camera permission in:\nSettings → Apps → AgriVision → Permissions → Camera',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey.shade500),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Iconsax.setting_2, size: 16, color: Colors.white),
            label: Text(
              'Open Settings',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  void _resetScan() {
    setState(() {
      _selectedImage = null;
      _isAnalyzing = false;
      _isSaved = false;
    });
  }

  /// Shows orchard selector sheet, uploads image to Cloudinary, then saves to Firestore.
  Future<void> _saveToHistory() async {
    final orchard = await showOrchardSelectorSheet(context);
    if (orchard == null) return; // user skipped

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show uploading feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'Uploading image...',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 30), // dismissed manually
        ),
      );
    }

    try {
      // 1️⃣ Upload image to Cloudinary
      String imageUrl = '';
      if (_selectedImage != null) {
        imageUrl = await CloudinaryService.uploadImage(_selectedImage!) ?? '';
      }

      // 2️⃣ Save record to Firestore
      final record = DiseaseHistoryModel(
        id: '',
        farmerId: user.uid,
        orchardId: orchard.id,
        orchardName: orchard.name,
        fruitType: orchard.fruitType,
        imageUrl: imageUrl,
        diseaseName: 'Scan Result', // replace with AI result when integrated
        recommendation:
            'AI analysis pending. Connect to disease detection API for full recommendations.',
        status: 'pending',
        scannedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('Disease_History')
          .add(record.toMap());

      if (mounted) {
        // Dismiss the uploading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saved to "${orchard.name}" disease history!',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e',
                style: GoogleFonts.poppins(fontSize: 12)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.black,
      body: _selectedImage != null
          ? _buildResultView()
          : _buildScannerView(),
    );
  }

  // ── Scanner View (camera scan UI like picture 3) ──────────────────────────
  Widget _buildScannerView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark gradient background (simulates a camera environment)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A1628), Color(0xFF0D2137), Color(0xFF0A1628)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Subtle grid texture overlay
        Opacity(
          opacity: 0.04,
          child: CustomPaint(
            painter: _GridPainter(),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              // ── Top Bar ──────────────────────────────────────────────
              _buildTopBar(),

              const Spacer(),

              // ── Scan Frame ───────────────────────────────────────────
              FadeIn(
                duration: const Duration(milliseconds: 800),
                child: Column(
                  children: [
                    // Label above frame
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🌿', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              'Point at leaf, fruit or crop',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Scan Frame with animated corners
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: 280,
                        height: 280,
                        child: CustomPaint(
                          painter: _ScanFramePainter(color: _lightGreen),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sub-hint below frame
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'Hold steady for best results',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Hint Bar ─────────────────────────────────────────────
              _buildHintBar(),

              const SizedBox(height: 12),

              // ── Bottom Action Buttons ─────────────────────────────────
              _buildBottomActions(),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.arrow_left,
                  color: Colors.white, size: 20),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'AgroScan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          // Flash/info icon placeholder
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.info_circle,
                color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildHintBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: _primaryGreen.withOpacity(0.25),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _lightGreen.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'For best results, take a photo of crops only',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          const Text('🌾', style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gallery button
          FadeInLeft(
            duration: const Duration(milliseconds: 500),
            child: GestureDetector(
              onTap: _pickFromGallery,
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Iconsax.gallery,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gallery',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Capture button (large center)
          FadeIn(
            duration: const Duration(milliseconds: 600),
            child: GestureDetector(
              onTap: _handleCameraCapture,
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _lightGreen.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: _primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Iconsax.camera,
                            color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Scan',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Flip camera button
          FadeInRight(
            duration: const Duration(milliseconds: 500),
            child: GestureDetector(
              onTap: _handleCameraCapture, // flipping is handled by system camera UI
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.flip_camera_android_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Flip',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Result View (after image is selected) ─────────────────────────────────
  Widget _buildResultView() {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _resetScan,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.arrow_left,
                        color: Colors.white, size: 20),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _isAnalyzing ? 'Analyzing...' : 'Scan Result',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
          ),

          // Image display
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Scanned image
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(0)),
                  child: kIsWeb
                      ? Image.network(
                          _selectedImage!.path,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Image.file(
                          File(_selectedImage!.path),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                ),

                // Scan frame overlay on the result
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CustomPaint(
                    painter: _ScanFramePainter(color: _lightGreen),
                  ),
                ),

                // Analyzing overlay
                if (_isAnalyzing)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              color: _lightGreen,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Scanning for diseases...',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Analyzing leaf & fruit patterns',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Scan Complete card + actions (shown after analysis)
                if (!_isAnalyzing)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.9),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Result info card
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: _lightGreen.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _primaryGreen.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isSaved
                                          ? Iconsax.tick_circle
                                          : Iconsax.scan,
                                      color: Colors.greenAccent,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isSaved
                                              ? 'Saved to History ✓'
                                              : 'Scan Complete',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _isSaved
                                              ? 'Disease record linked to your orchard'
                                              : 'Save this scan to an orchard\'s disease history',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white
                                                .withValues(alpha: 0.65),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Save to History button (hidden once saved)
                            if (!_isSaved)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Iconsax.health, size: 18),
                                  label: Text(
                                    'Save to Disease History',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _saveToHistory,
                                ),
                              ),

                            if (!_isSaved) const SizedBox(height: 8),

                            // Scan Again button
                            SizedBox(
                              width: double.infinity,
                              child: _isSaved
                                  ? ElevatedButton.icon(
                                      icon: const Icon(Iconsax.refresh,
                                          size: 18),
                                      label: Text(
                                        'Scan Again',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primaryGreen,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: _resetScan,
                                    )
                                  : OutlinedButton.icon(
                                      icon:
                                          const Icon(Iconsax.refresh, size: 18),
                                      label: Text(
                                        'Scan Again',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(
                                            color: Colors.white
                                                .withValues(alpha: 0.4)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: _resetScan,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painters ──────────────────────────────────────────────────────────

/// Draws the 4-corner bracket scan frame
class _ScanFramePainter extends CustomPainter {
  final Color color;
  _ScanFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 32.0;
    const radius = 16.0;
    final w = size.width;
    final h = size.height;

    // Top-left corner
    canvas.drawLine(
        Offset(radius, 0), Offset(cornerLen + radius, 0), paint);
    canvas.drawLine(Offset(0, radius), Offset(0, cornerLen + radius), paint);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, radius * 2, radius * 2),
      3.14159, // π (left)
      -1.5708, // -π/2
      false, paint,
    );

    // Top-right corner
    canvas.drawLine(
        Offset(w - cornerLen - radius, 0), Offset(w - radius, 0), paint);
    canvas.drawLine(
        Offset(w, radius), Offset(w, cornerLen + radius), paint);
    canvas.drawArc(
      Rect.fromLTWH(w - radius * 2, 0, radius * 2, radius * 2),
      -1.5708, // -π/2
      -1.5708,
      false, paint,
    );

    // Bottom-left corner
    canvas.drawLine(
        Offset(0, h - cornerLen - radius), Offset(0, h - radius), paint);
    canvas.drawLine(
        Offset(radius, h), Offset(cornerLen + radius, h), paint);
    canvas.drawArc(
      Rect.fromLTWH(0, h - radius * 2, radius * 2, radius * 2),
      1.5708, // π/2
      -1.5708,
      false, paint,
    );

    // Bottom-right corner
    canvas.drawLine(
        Offset(w, h - cornerLen - radius), Offset(w, h - radius), paint);
    canvas.drawLine(
        Offset(w - cornerLen - radius, h), Offset(w - radius, h), paint);
    canvas.drawArc(
      Rect.fromLTWH(w - radius * 2, h - radius * 2, radius * 2, radius * 2),
      0,
      -1.5708,
      false, paint,
    );

    // Dim overlay (inside frame is slightly lighter)
    final dimPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), dimPaint);
  }

  @override
  bool shouldRepaint(_ScanFramePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Subtle background grid texture
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 0.5;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}