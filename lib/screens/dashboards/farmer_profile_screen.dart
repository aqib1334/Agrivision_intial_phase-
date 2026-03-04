// lib/screens/dashboards/farmer_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

import '../../services/cloudinary_service.dart';
import '../../services/common/verification_service.dart';
import '../../screens/common/verification_screen.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  // ── Design Tokens (matching Home/Login screens) ──────────────────────────
  static const Color _green900 = Color(0xFF1B5E20);
  static const Color _green800 = Color(0xFF2E7D32);
  static const Color _green700 = Color(0xFF388E3C);
  static const Color _paleGreen = Color(0xFFE8F5E9);
  static const Color _textDark = Color(0xFF212121);
  static const Color _textGrey = Color(0xFF757575);
  static const Color _border = Color(0xFFE0E0E0);

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  // Profile data
  String name = '';
  String email = '';
  String phoneNumber = '';
  String? profileImage;
  String location = '';
  String totalArea = '';
  String experience = '';
  String bio = '';
  String verificationStatus = 'unverified';

  // Overview stats (fetched from Firestore)
  int _totalOrchards = 0;
  int _totalListings = 0;
  int _totalOrders = 0;
  bool _statsLoaded = false;

  // Controllers
  late TextEditingController phoneController;
  late TextEditingController locationController;
  late TextEditingController areaController;
  late TextEditingController experienceController;
  late TextEditingController bioController;

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController();
    locationController = TextEditingController();
    areaController = TextEditingController();
    experienceController = TextEditingController();
    bioController = TextEditingController();
    _loadAll();
  }

  @override
  void dispose() {
    phoneController.dispose();
    locationController.dispose();
    areaController.dispose();
    experienceController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadProfileData(), _loadStats()]);
  }

  // ── Load Stats ──────────────────────────────────────────────────────────
  Future<void> _loadStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('Orchards')
            .where('farmerId', isEqualTo: user.uid)
            .get(),
        FirebaseFirestore.instance
            .collection('Orchard_Listings')
            .where('farmerId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'available')
            .get(),
        FirebaseFirestore.instance
            .collection('Order_Requests')
            .where('farmerId', isEqualTo: user.uid)
            .get(),
      ]);
      if (mounted) {
        setState(() {
          _totalOrchards = results[0].docs.length;
          _totalListings = results[1].docs.length;
          _totalOrders = results[2].docs.length;
          _statsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Stats error: $e');
      if (mounted) setState(() => _statsLoaded = true);
    }
  }

  // ── Load Profile ────────────────────────────────────────────────────────
  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final status = await VerificationService().getCurrentUserStatus();

      final results = await Future.wait([
        FirebaseFirestore.instance.collection('Users').doc(user.uid).get(),
        FirebaseFirestore.instance
            .collection('Farmer_Profiles')
            .doc(user.uid)
            .get(),
      ]);

      final userDoc = results[0];
      final profileDoc = results[1];

      if (mounted) {
        setState(() {
          verificationStatus = status;
          if (userDoc.exists) {
            final d = userDoc.data() as Map<String, dynamic>;
            name = d['name'] ?? '';
            email = d['email'] ?? '';
            phoneNumber = d['phoneNumber'] ?? '';
            phoneController.text = phoneNumber;
          }
          if (profileDoc.exists) {
            final d = profileDoc.data() as Map<String, dynamic>;
            profileImage = d['profileImage'];
            location = d['location'] ?? '';
            totalArea = d['totalArea'] ?? '';
            experience = d['experience'] ?? '';
            bio = d['bio'] ?? '';
            locationController.text = location;
            areaController.text = totalArea;
            experienceController.text = experience;
            bioController.text = bio;
          } else {
            _createDefaultProfile(user.uid);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createDefaultProfile(String uid) async {
    await FirebaseFirestore.instance.collection('Farmer_Profiles').doc(uid).set(
      {
        'farmerId': uid,
        'profileImage': null,
        'location': '',
        'totalArea': '',
        'experience': '',
        'bio': '',
        'rating': 0.0,
        'totalOrchards': 0,
        'totalListings': 0,
        'joinedDate': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      },
    );
  }

  // ── Cloudinary Photo Upload ─────────────────────────────────────────────
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Profile Photo',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a source to upload your photo',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SourceTile(
                    icon: Iconsax.camera,
                    label: 'Camera',
                    sublabel: 'Take a new photo',
                    color: _green700,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndUpload(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SourceTile(
                    icon: Iconsax.gallery,
                    label: 'Gallery',
                    sublabel: 'Pick from library',
                    color: _green800,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndUpload(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final url = await CloudinaryService.uploadImage(file);
      if (url == null) throw Exception('Upload returned null URL');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('Farmer_Profiles')
            .doc(user.uid)
            .update({
          'profileImage': url,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        setState(() {
          profileImage = url;
          _isUploadingPhoto = false;
        });
        _showSnack('Profile photo updated!', _green700);
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        _showSnack('Failed to upload photo. Please try again.', Colors.red);
      }
    }
  }

  // ── Save Profile ────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('Farmer_Profiles')
          .doc(user.uid)
          .update({
        'location': locationController.text.trim(),
        'totalArea': areaController.text.trim(),
        'experience': experienceController.text.trim(),
        'bio': bioController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (phoneController.text.trim() != phoneNumber) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .update({'phoneNumber': phoneController.text.trim()});
        phoneNumber = phoneController.text.trim();
      }

      if (mounted) {
        _showSnack('Profile updated successfully!', _green700);
        setState(() => _isEditing = false);
        await _loadProfileData();
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.shade50, shape: BoxShape.circle),
              child:
                  Icon(Iconsax.logout, color: Colors.red.shade400, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Logout',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: _green700),
              const SizedBox(height: 16),
              Text('Loading profile...',
                  style: GoogleFonts.poppins(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ── Hero Header (matches Home/Login style) ──────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _green800,
            leading: const SizedBox.shrink(),
            automaticallyImplyLeading: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () =>
                      setState(() => _isEditing = !_isEditing),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      _isEditing ? Iconsax.close_circle : Iconsax.edit_2,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_green900, _green800, _green700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Profile Photo
                      FadeInDown(
                        child: GestureDetector(
                          onTap: _showImageSourceSheet,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 52,
                                  backgroundColor: _paleGreen,
                                  child: ClipOval(
                                    child: _isUploadingPhoto
                                        ? const SizedBox(
                                            width: 104,
                                            height: 104,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: _green700,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : profileImage != null
                                            ? Image.network(
                                                profileImage!,
                                                width: 104,
                                                height: 104,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (_, child, lp) {
                                                  if (lp == null) return child;
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: _green700),
                                                  );
                                                },
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Iconsax.user,
                                                        size: 44,
                                                        color: _green700),
                                              )
                                            : const Icon(Iconsax.user,
                                                size: 44, color: _green700),
                                  ),
                                ),
                              ),
                              // Camera overlay badge
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(Iconsax.camera,
                                    size: 16, color: _green700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Name + Verified badge
                      FadeIn(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name.isNotEmpty ? name : 'Farmer',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (verificationStatus == 'verified') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.verified,
                                    color: _green700, size: 18),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      FadeIn(
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          email,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        FadeIn(
                          delay: const Duration(milliseconds: 150),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.location,
                                  color:
                                      Colors.white.withValues(alpha: 0.8),
                                  size: 13),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: GoogleFonts.poppins(
                                  color:
                                      Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body Content ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── My Overview Cards ─────────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(Iconsax.chart_2, 'My Overview'),
                          const SizedBox(height: 12),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _buildOverviewCard(
                                    icon: Iconsax.tree,
                                    value: _statsLoaded
                                        ? _totalOrchards.toString()
                                        : '...',
                                    label: 'Orchards',
                                    iconBg: const Color(0xFFE8F5E9),
                                    iconColor: _green700,
                                    valueColor: _green800,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildOverviewCard(
                                    icon: Iconsax.box,
                                    value: _statsLoaded
                                        ? _totalListings.toString()
                                        : '...',
                                    label: 'Listings',
                                    iconBg: const Color(0xFFE3F2FD),
                                    iconColor: const Color(0xFF1565C0),
                                    valueColor: const Color(0xFF1565C0),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildOverviewCard(
                                    icon: Iconsax.shopping_cart,
                                    value: _statsLoaded
                                        ? _totalOrders.toString()
                                        : '...',
                                    label: 'Orders',
                                    iconBg: const Color(0xFFFFF3E0),
                                    iconColor: const Color(0xFFE65100),
                                    valueColor: const Color(0xFFE65100),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Verification Banner ───────────────────────────────
                    if (verificationStatus != 'verified')
                      FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 100),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: verificationStatus == 'pending_approval'
                                ? Colors.orange.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: verificationStatus == 'pending_approval'
                                  ? Colors.orange.shade300
                                  : Colors.red.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: verificationStatus == 'pending_approval'
                                      ? Colors.orange.shade100
                                      : Colors.red.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  verificationStatus == 'pending_approval'
                                      ? Iconsax.clock
                                      : Iconsax.shield_security,
                                  color: verificationStatus == 'pending_approval'
                                      ? Colors.orange
                                      : Colors.red,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      verificationStatus == 'pending_approval'
                                          ? 'Verification Pending'
                                          : 'Identity Unverified',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: verificationStatus ==
                                                'pending_approval'
                                            ? Colors.orange.shade800
                                            : Colors.red.shade800,
                                      ),
                                    ),
                                    Text(
                                      verificationStatus == 'pending_approval'
                                          ? 'Admin is reviewing your documents.'
                                          : 'Verify identity to unlock listings.',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              if (verificationStatus != 'pending_approval')
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const VerificationScreen()),
                                  ).then((_) => _loadProfileData()),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.red.shade100,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  child: Text('Verify',
                                      style: GoogleFonts.poppins(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                      ),

                    // ── Profile Information ───────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 150),
                      child: _sectionHeader(
                          Iconsax.user_edit, 'Profile Information'),
                    ),
                    const SizedBox(height: 12),

                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isEditing
                            ? _buildEditForm()
                            : _buildInfoList(),
                      ),
                    ),

                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      FadeInUp(
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveProfile,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(Iconsax.tick_circle,
                                    color: Colors.white),
                            label: Text(
                              _isSaving ? 'Saving...' : 'Save Changes',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green700,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                              shadowColor: _green700.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Logout ────────────────────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 300),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Iconsax.logout, color: Colors.red),
                          label: Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.red.shade300, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── My Overview Card ─────────────────────────────────────────────────────
  Widget _buildOverviewCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconBg,
    required Color iconColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: valueColor,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: _textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info List (read-only) ─────────────────────────────────────────────────
  Widget _buildInfoList() {
    final items = [
      _InfoItem(icon: Iconsax.call, label: 'Phone', value: phoneNumber),
      _InfoItem(icon: Iconsax.location, label: 'Location', value: location),
      _InfoItem(icon: Iconsax.size, label: 'Total Area', value: totalArea),
      _InfoItem(icon: Iconsax.calendar, label: 'Experience', value: experience),
      if (bio.isNotEmpty) _InfoItem(icon: Iconsax.document_text, label: 'Bio', value: bio),
    ];

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _buildInfoTile(items[i]),
          if (i < items.length - 1)
            Divider(
                height: 1,
                thickness: 1,
                color: _border.withValues(alpha: 0.6),
                indent: 56),
        ],
      ],
    );
  }

  Widget _buildInfoTile(_InfoItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _paleGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: _green700, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: _textGrey)),
                const SizedBox(height: 2),
                Text(
                  item.value.isEmpty ? 'Not set' : item.value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: item.value.isEmpty
                        ? Colors.grey.shade400
                        : _textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit Form ──────────────────────────────────────────────────────────────
  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildField(
            label: 'Phone Number',
            controller: phoneController,
            icon: Iconsax.call,
            hint: 'e.g. +92 300 1234567',
            validator: (v) =>
                v == null || v.isEmpty ? 'Phone is required' : null,
          ),
          const SizedBox(height: 14),
          _buildField(
            label: 'Location',
            controller: locationController,
            icon: Iconsax.location,
            hint: 'e.g. Sargodha, Punjab',
          ),
          const SizedBox(height: 14),
          _buildField(
            label: 'Total Farm Area',
            controller: areaController,
            icon: Iconsax.size,
            hint: 'e.g. 50 Acres',
          ),
          const SizedBox(height: 14),
          _buildField(
            label: 'Experience',
            controller: experienceController,
            icon: Iconsax.calendar,
            hint: 'e.g. 10 years',
          ),
          const SizedBox(height: 14),
          _buildField(
            label: 'Bio',
            controller: bioController,
            icon: Iconsax.document_text,
            hint: 'Tell us about your farming background...',
            maxLines: 3,
            isRequired: false,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: isRequired
          ? (validator ??
              (v) => (v == null || v.isEmpty) ? 'Required' : null)
          : null,
      style: GoogleFonts.poppins(fontSize: 14, color: _textDark),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _green700, size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green700, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        floatingLabelStyle: const TextStyle(
            color: _green700, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _paleGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _green700, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _textDark,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ── Data Classes ──────────────────────────────────────────────────────────────
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(
      {required this.icon, required this.label, required this.value});
}

// ── Source Tile for Bottom Sheet ─────────────────────────────────────────────
class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(sublabel,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}