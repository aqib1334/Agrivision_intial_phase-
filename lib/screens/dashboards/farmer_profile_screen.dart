// lib/screens/dashboards/farmer_profile_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  // Color Scheme
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryMain = Color(0xFF388E3C);
  static const Color primaryPale = Color(0xFFE8F5E9);
  static const Color textHeading = Color(0xDE000000);
  static const Color textBody = Color(0xFF616161);
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderNormal = Color(0xFFE0E0E0);
  static const Color statusSuccess = Color(0xFF4CAF50);
  static const Color statusInfo = Color(0xFF1976D2);

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  String name = "";
  String email = "";
  String phoneNumber = "";
  String? profileImage;
  String location = "";
  String totalArea = "";
  String experience = "";
  String bio = "";
  double rating = 0.0;
  int totalOrchards = 0;
  int totalListings = 0;

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
    _loadProfileData();
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

  // ✨ Show Camera/Gallery Options Bottom Sheet
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textHeading,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera Option
                _ImageSourceOption(
                  icon: Iconsax.camera,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                // Gallery Option
                _ImageSourceOption(
                  icon: Iconsax.gallery,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- UNIVERSAL UPLOAD FUNCTION (Updated to accept ImageSource) ---
  Future<void> _pickAndUploadImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final storageRef = FirebaseStorage.instance.ref().child(
        'farmer_profile_images/${user.uid}.jpg',
      );

      Uint8List imageBytes = await image.readAsBytes();

      await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('Farmer_Profiles')
          .doc(user.uid)
          .update({
            'profileImage': downloadUrl,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        setState(() {
          profileImage = downloadUrl;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: statusSuccess,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    }
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Fetch from Users Collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        name = userData['name'] ?? '';
        email = userData['email'] ?? '';
        phoneNumber = userData['phoneNumber'] ?? '';
        phoneController.text = phoneNumber;
      }

      // Fetch from Farmer_Profiles Collection
      DocumentSnapshot profileDoc = await FirebaseFirestore.instance
          .collection('Farmer_Profiles')
          .doc(user.uid)
          .get();

      if (profileDoc.exists) {
        final profileData = profileDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            profileImage = profileData['profileImage'];
            location = profileData['location'] ?? '';
            totalArea = profileData['totalArea'] ?? '';
            experience = profileData['experience'] ?? '';
            bio = profileData['bio'] ?? '';
            rating = (profileData['rating'] ?? 0.0).toDouble();
            totalOrchards = profileData['totalOrchards'] ?? 0;
            totalListings = profileData['totalListings'] ?? 0;

            locationController.text = location;
            areaController.text = totalArea;
            experienceController.text = experience;
            bioController.text = bio;
          });
        }
      } else {
        await _createDefaultProfile(user.uid);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createDefaultProfile(String userId) async {
    await FirebaseFirestore.instance
        .collection('Farmer_Profiles')
        .doc(userId)
        .set({
          'farmerId': userId,
          'profileImage': null,
          'location': '',
          'totalArea': '',
          'experience': '',
          'specialization': [],
          'bio': '',
          'rating': 0.0,
          'totalOrchards': 0,
          'totalListings': 0,
          'joinedDate': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: statusSuccess,
          ),
        );
        setState(() => _isEditing = false);
        await _loadProfileData();
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: textHeading, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: textSecondary, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: CircularProgressIndicator(color: primaryMain),
        ),
      );
    }

    return Scaffold(
      backgroundColor: primaryPale,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: primaryMain,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryDark, primaryMain],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      FadeInDown(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: primaryPale,
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 110,
                                    height: 110,
                                    child: profileImage != null
                                        ? Image.network(
                                            profileImage!,
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  );
                                                },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.error,
                                                    color: Colors.red,
                                                    size: 40,
                                                  );
                                                },
                                          )
                                        : const Icon(
                                            Iconsax.user,
                                            size: 45,
                                            color: primaryMain,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showImageSourceOptions,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Iconsax.camera,
                                    size: 18,
                                    color: primaryMain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeIn(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FadeIn(
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => setState(() => _isEditing = !_isEditing),
                icon: Icon(_isEditing ? Iconsax.close_circle : Iconsax.edit),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInUp(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Iconsax.tree,
                              label: 'Orchards',
                              value: totalOrchards.toString(),
                              color: statusSuccess,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Iconsax.box,
                              label: 'Listings',
                              value: totalListings.toString(),
                              color: statusInfo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textHeading,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isEditing) ...[
                      _buildEditableField(
                        label: 'Phone Number',
                        controller: phoneController,
                        icon: Iconsax.call,
                        hint: 'Enter phone number',
                        validator: (val) =>
                            val!.isEmpty ? 'Phone is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        label: 'Location',
                        controller: locationController,
                        icon: Iconsax.location,
                        hint: 'Enter your location',
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        label: 'Total Farm Area',
                        controller: areaController,
                        icon: Iconsax.size,
                        hint: 'e.g., 50 acres',
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        label: 'Experience',
                        controller: experienceController,
                        icon: Iconsax.calendar,
                        hint: 'e.g., 10 years',
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        label: 'Bio',
                        controller: bioController,
                        icon: Iconsax.document_text,
                        hint: 'Tell us about yourself',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Iconsax.tick_circle),
                          label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryMain,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ] else ...[
                      _buildInfoTile(
                        icon: Iconsax.call,
                        label: 'Phone Number',
                        value: phoneNumber,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoTile(
                        icon: Iconsax.location,
                        label: 'Location',
                        value: location.isEmpty ? 'Not set' : location,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoTile(
                        icon: Iconsax.size,
                        label: 'Total Area',
                        value: totalArea.isEmpty ? 'Not set' : totalArea,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoTile(
                        icon: Iconsax.calendar,
                        label: 'Experience',
                        value: experience.isEmpty ? 'Not set' : experience,
                      ),
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoTile(
                          icon: Iconsax.document_text,
                          label: 'Bio',
                          value: bio,
                        ),
                      ],
                    ],

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Iconsax.logout, color: Colors.red),
                        label: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 24,
                          ),
                          side: const BorderSide(color: Colors.red, width: 2),
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderNormal, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderNormal),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryPale,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryMain, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textBody,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textBody,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryMain),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ✨ Custom Widget for Image Source Option
class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF388E3C).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF388E3C).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 32, color: const Color(0xFF388E3C)),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}