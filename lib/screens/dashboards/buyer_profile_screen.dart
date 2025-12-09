import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

// ✅ NEW IMPORTS
import '../../services/common/verification_service.dart';
import '../../screens/common/verification_screen.dart';
import '../../widgets/common/loading_indicator.dart'; // Import your custom indicator

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  // COLORS
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryMain = Color(0xFF388E3C);
  static const Color primaryPale = Color(0xFFE8F5E9);
  static const Color textHeading = Color(0xDE000000);
  static const Color textBody = Color(0xFF616161);
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderNormal = Color(0xFFE0E0E0);
  static const Color statusSuccess = Color(0xFF4CAF50);
  static const Color statusWarning = Color(0xFFFFA726);

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  // PROFILE DATA
  String name = "";
  String email = "";
  String phoneNumber = "";
  String? profileImage;
  String location = "";
  String bio = "";
  String businessType = "Individual";
  String companyName = "";

  // 🔥 STATS VARIABLES
  int completedOrders = 0;
  int pendingOrders = 0;

  // ✅ NEW: Verification Status Variable
  String verificationStatus = 'unverified';

  late TextEditingController phoneController;
  late TextEditingController locationController;
  late TextEditingController bioController;
  late TextEditingController companyController;

  final List<String> businessTypes = [
    'Individual',
    'Wholesaler',
    'Exporter',
    'Retailer',
  ];

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController();
    locationController = TextEditingController();
    bioController = TextEditingController();
    companyController = TextEditingController();
    _loadProfileData();
  }

  @override
  void dispose() {
    phoneController.dispose();
    locationController.dispose();
    bioController.dispose();
    companyController.dispose();
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
                _ImageSourceOption(
                  icon: Iconsax.camera,
                  label: 'Camera',
                  color: primaryMain,
                  bgColor: primaryPale,
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                _ImageSourceOption(
                  icon: Iconsax.gallery,
                  label: 'Gallery',
                  color: primaryMain,
                  bgColor: primaryPale,
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
        'buyer_profile_images/${user.uid}.jpg',
      );
      Uint8List imageBytes = await image.readAsBytes();
      await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('Buyer_Profiles')
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
            content: Text('Profile photo updated!'),
            backgroundColor: statusSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 LOAD PROFILE + CALCULATE STATS + VERIFICATION
  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. ✅ Get Verification Status First (Fixes flashing)
      String status = await VerificationService().getCurrentUserStatus();

      // 2. Get User Basic Info (Name/Email/Phone)
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

      // 3. Get Buyer Profile Info
      DocumentSnapshot profileDoc = await FirebaseFirestore.instance
          .collection('Buyer_Profiles')
          .doc(user.uid)
          .get();

      if (profileDoc.exists) {
        final profileData = profileDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            verificationStatus = status; // ✅ Update Status
            profileImage = profileData['profileImage'];
            location = profileData['location'] ?? '';
            bio = profileData['bio'] ?? '';
            businessType = profileData['businessType'] ?? 'Individual';
            companyName = profileData['companyName'] ?? '';

            locationController.text = location;
            bioController.text = bio;
            companyController.text = companyName;
          });
        }
      } else {
        await _createDefaultProfile(user.uid);
      }

      // 4. Calculate Orders
      await _calculateOrderStats(user.uid);
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 LOGIC: Calculate Order Stats
  Future<void> _calculateOrderStats(String buyerId) async {
    try {
      QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('Order_Requests')
          .where('buyerId', isEqualTo: buyerId)
          .get();

      int completed = 0;
      int pending = 0;

      for (var doc in orderSnapshot.docs) {
        String status = (doc['status'] ?? '').toString().toLowerCase();

        if (status == 'delivered' || status == 'completed') {
          completed++;
        } else if (status == 'pending' ||
            status == 'confirmed' ||
            status == 'payment_pending' ||
            status == 'processing' ||
            status == 'shipped') {
          pending++;
        }
      }

      if (mounted) {
        setState(() {
          completedOrders = completed;
          pendingOrders = pending;
        });
      }

      await FirebaseFirestore.instance
          .collection('Buyer_Profiles')
          .doc(buyerId)
          .update({
            'completedOrders': completed,
            'pendingOrders': pending,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error calculating stats: $e');
    }
  }

  Future<void> _createDefaultProfile(String userId) async {
    await FirebaseFirestore.instance
        .collection('Buyer_Profiles')
        .doc(userId)
        .set({
          'buyerId': userId,
          'profileImage': null,
          'location': '',
          'bio': '',
          'businessType': 'Individual',
          'companyName': '',
          'completedOrders': 0,
          'pendingOrders': 0,
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
          .collection('Buyer_Profiles')
          .doc(user.uid)
          .update({
            'location': locationController.text.trim(),
            'bio': bioController.text.trim(),
            'businessType': businessType,
            'companyName': companyController.text.trim(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      if (phoneController.text.trim() != phoneNumber) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .update({'phoneNumber': phoneController.text.trim()});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: statusSuccess,
          ),
        );

        setState(() {
          location = locationController.text.trim();
          bio = bioController.text.trim();
          companyName = companyController.text.trim();
          phoneNumber = phoneController.text.trim();
          _isEditing = false;
          _isSaving = false;
        });

        // Reload data to reflect any changes
        _loadProfileData();
      }
    } catch (e) {
      debugPrint('Error saving: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(color: textHeading, fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
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
      // ✅ CHANGED: Used your custom LoadingIndicator here
      return const Scaffold(
        body: LoadingIndicator(message: 'Loading Profile...'),
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
                                            // ✅ ADDED: Image loading logic similar to Farmer
                                            loadingBuilder:
                                                (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return const SizedBox(
                                                    width: 40,
                                                    height: 40,
                                                    child: LoadingIndicator(
                                                      color: primaryMain,
                                                      // No message to keep it small in the circle
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

                      // ✅ NAME WITH BLUE TICK Logic
                      FadeIn(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (verificationStatus == 'verified') ...[
                              const SizedBox(width: 6),
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  color: Color.fromARGB(255, 24, 220, 80),
                                  size: 20,
                                ),
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
                              icon: Iconsax.tick_circle,
                              label: 'Completed',
                              value: completedOrders.toString(),
                              color: statusSuccess,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Iconsax.timer,
                              label: 'Pending',
                              value: pendingOrders.toString(),
                              color: statusWarning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ✅ VERIFICATION STATUS BANNER (CONDITIONAL)
                    if (verificationStatus != 'verified')
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: verificationStatus == 'pending_approval'
                              ? Colors.orange.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: verificationStatus == 'pending_approval'
                                ? Colors.orange
                                : Colors.red,
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            verificationStatus == 'pending_approval'
                                ? Iconsax.clock
                                : Iconsax.shield_security,
                            color: verificationStatus == 'pending_approval'
                                ? Colors.orange
                                : Colors.red,
                          ),
                          title: Text(
                            verificationStatus == 'pending_approval'
                                ? "Verification Pending"
                                : "Identity Unverified",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            verificationStatus == 'pending_approval'
                                ? "Admin is reviewing your documents."
                                : "Verify identity to place orders.",
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: verificationStatus == 'pending_approval'
                              ? null
                              : ElevatedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const VerificationScreen(),
                                    ),
                                  ).then((_) => _loadProfileData()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                  child: const Text("Verify"),
                                ),
                        ),
                      ),

                    // ✅ END VERIFICATION SECTION

                    const Text(
                      'Buyer Information',
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
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        label: 'City / Location',
                        controller: locationController,
                        icon: Iconsax.location,
                        hint: 'Enter your city',
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Business Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textBody,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: businessType,
                            isExpanded: true,
                            items: businessTypes
                                .map(
                                  (String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (newValue) =>
                                setState(() => businessType = newValue!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        label: 'Company Name (Optional)',
                        controller: companyController,
                        icon: Iconsax.building,
                        hint: 'e.g., Best Fruits Trading',
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        label: 'Bio / Preferences',
                        controller: bioController,
                        icon: Iconsax.document_text,
                        hint: 'What kind of fruits are you looking for?',
                        maxLines: 3,
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
                        icon: Iconsax.briefcase,
                        label: 'Business Type',
                        value: businessType,
                      ),
                      if (companyName.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoTile(
                          icon: Iconsax.building,
                          label: 'Company',
                          value: companyName,
                        ),
                      ],
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoTile(
                          icon: Iconsax.document_text,
                          label: 'Bio / Preferences',
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

class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color bgColor;
  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.bgColor,
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
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
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
                    color: color.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 32, color: color),
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