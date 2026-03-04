// lib/screens/farmer/orchands/add_orchard_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../models/orchard_model.dart';
import '../../../services/farmer/orchard_service.dart';
import '../../../widgets/common/loading_indicator.dart';

class AddOrchardScreen extends StatefulWidget {
  final OrchardModel? orchard;

  const AddOrchardScreen({super.key, this.orchard});

  @override
  State<AddOrchardScreen> createState() => _AddOrchardScreenState();
}

class _AddOrchardScreenState extends State<AddOrchardScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final OrchardService _orchardService = OrchardService();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _areaController;
  late TextEditingController _treesController;
  late TextEditingController _treeAgeController;
  late TextEditingController _descController;

  // Dropdown Data
  final List<String> _fruitTypes = [
    'Mango', 'Citrus', 'Apple', 'Guava', 'Date', 'Apricot', 'Other'
  ];

  final Map<String, List<String>> _varietiesMap = {
    'Mango': ['Chaunsa', 'Sindhri', 'Anwar Ratol', 'Langra', 'Dusehri', 'Fajri', 'Other'],
    'Citrus': ['Kinnow', 'Musambi', 'Fruiter', 'Grapefruit', 'Lemon', 'Orange', 'Other'],
    'Apple': ['Kala Kulu', 'Gacha', 'Amri', 'Golden Delicious', 'Red Delicious', 'Mashhadi', 'Other'],
    'Guava': ['Safeda', 'Allahabadi', 'Karela', 'Seedless', 'Other'],
    'Date': ['Aseel', 'Dhakki', 'Begum Jangi', 'Halawi', 'Fasli', 'Other'],
    'Apricot': ['Halman', 'Marghulam', 'Khapalu', 'Other'],
    'Other': ['Other'],
  };

  final List<String> _soilTypes = [
    'Clay', 'Silt', 'Sand', 'Loam', 'Sandy Loam', 'Clay Loam', 'Other'
  ];

  final List<String> _areaUnits = [
    'Acre', 'Kanal', 'Marla', 'Hectare', 'Square Meter'
  ];

  String? _selectedFruitType;
  String? _selectedVariety;
  String? _selectedSoilType;
  String? _selectedAreaUnit;

  final List<XFile> _newImages = [];
  List<String> _existingImages = [];
  bool _isLoading = false;
  bool _isGettingLocation = false;

  // Design constants matching login/signup screens
  static const Color _primaryGreen = Color(0xFF388E3C);
  static const Color _lightGreen = Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();

    _nameController = TextEditingController(text: widget.orchard?.name ?? '');
    _locationController = TextEditingController(text: widget.orchard?.location ?? '');

    _selectedFruitType = widget.orchard?.fruitType;
    if (_selectedFruitType != null && _selectedFruitType!.isNotEmpty && !_fruitTypes.contains(_selectedFruitType)) {
      _fruitTypes.add(_selectedFruitType!);
    }

    _selectedVariety = widget.orchard?.variety;
    if (_selectedFruitType != null && _selectedVariety != null && _selectedVariety!.isNotEmpty) {
      if (!(_varietiesMap[_selectedFruitType!] ?? []).contains(_selectedVariety)) {
        _varietiesMap[_selectedFruitType!] ??= [];
        _varietiesMap[_selectedFruitType!]!.add(_selectedVariety!);
      }
    }

    _selectedSoilType = widget.orchard?.soilType;
    if (_selectedSoilType != null && _selectedSoilType!.isNotEmpty && !_soilTypes.contains(_selectedSoilType)) {
      _soilTypes.add(_selectedSoilType!);
    }

    _selectedAreaUnit = widget.orchard?.areaUnit ?? 'Acre';
    if (!_areaUnits.contains(_selectedAreaUnit)) {
      _areaUnits.add(_selectedAreaUnit!);
    }

    _areaController = TextEditingController(text: widget.orchard?.areaSize.toString() ?? '');
    _treesController = TextEditingController(text: widget.orchard?.totalTrees.toString() ?? '');
    _treeAgeController = TextEditingController(text: widget.orchard?.treeAge.toString() ?? '');
    _descController = TextEditingController(text: widget.orchard?.description ?? '');
    _existingImages = widget.orchard?.imageUrls ?? [];
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _areaController.dispose();
    _treesController.dispose();
    _treeAgeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    int total = _newImages.length + _existingImages.length;
    if (total >= 3) {
      _showSnack('Maximum 3 images allowed', Colors.orange);
      return;
    }
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final List<XFile> images = await picker.pickMultiImage(imageQuality: 80);
      if (images.isNotEmpty) {
        int slots = 3 - (_newImages.length + _existingImages.length);
        setState(() => _newImages.addAll(images.take(slots)));
      }
    } else {
      final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
      if (image != null) setState(() => _newImages.add(image));
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services are disabled.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception("Location permissions are denied");
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
        _locationController.text = address.replaceAll(RegExp(r'^, |,$'), '').trim();
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to get location: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

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
              'Add Orchard Photo',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              'Choose a source to upload your photo',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ImageSourceTile(
                    icon: Iconsax.camera,
                    label: 'Camera',
                    sublabel: 'Take a new photo',
                    color: _primaryGreen,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ImageSourceTile(
                    icon: Iconsax.gallery,
                    label: 'Gallery',
                    sublabel: 'Pick from library',
                    color: _lightGreen,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
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

  void _saveOrchard() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _orchardService.saveOrchard(
          id: widget.orchard?.id,
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
          area: _areaController.text.trim(),
          areaUnit: _selectedAreaUnit ?? 'Acre',
          fruitType: _selectedFruitType ?? '',
          variety: _selectedVariety ?? '',
          totalTrees: int.tryParse(_treesController.text.trim()) ?? 0,
          treeAge: int.tryParse(_treeAgeController.text.trim()) ?? 0,
          soilType: _selectedSoilType ?? '',
          description: _descController.text.trim(),
          newImages: _newImages,
          existingImageUrls: _existingImages,
        );

        if (mounted) {
          Navigator.pop(context);
          _showSnack('Orchard saved successfully! 🌿', Colors.green);
        }
      } catch (e) {
        if (mounted) _showSnack('Error: $e', Colors.red);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.orchard == null ? 'Add Orchard' : 'Edit Orchard';
    final String subtitle = widget.orchard == null
        ? 'Fill in your orchard details below'
        : 'Update your orchard information';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x551B5E20),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 14),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 18),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            colors: [Colors.white, Color(0xFFE8F5E9)],
                          ).createShader(bounds),
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator(message: 'Saving orchard...'))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Image Section ─────────────────────────────────
                      _buildSectionLabel('Orchard Photos', Iconsax.image),
                      const SizedBox(height: 12),
                      _buildImageSection(),
                      const SizedBox(height: 28),

                      // ─── Orchard Info ──────────────────────────────────
                      _buildSectionLabel('Orchard Information', Iconsax.building_3),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: 'Orchard Name',
                        controller: _nameController,
                        icon: Iconsax.text_block,
                        hint: 'e.g. My Mango Farm',
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Fruit Type',
                        items: _fruitTypes,
                        value: _selectedFruitType,
                        icon: Iconsax.tree,
                        onChanged: (val) => setState(() {
                          _selectedFruitType = val;
                          _selectedVariety = null;
                        }),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Variety',
                        items: _selectedFruitType != null
                            ? (_varietiesMap[_selectedFruitType!] ?? ['Other'])
                            : [],
                        value: _selectedVariety,
                        icon: Iconsax.category,
                        onChanged: (val) => setState(() => _selectedVariety = val),
                      ),
                      const SizedBox(height: 28),

                      // ─── Location ──────────────────────────────────────
                      _buildSectionLabel('Location & Area', Iconsax.location),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Location',
                              controller: _locationController,
                              icon: Iconsax.location,
                              hint: 'e.g. Sargodha, Punjab',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: InkWell(
                              onTap: _isGettingLocation ? null : _getCurrentLocation,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 58,
                                width: 58,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.green.shade200, width: 1.5),
                                ),
                                child: _isGettingLocation
                                    ? Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _primaryGreen,
                                          ),
                                        ),
                                      )
                                    : Icon(Iconsax.gps, color: _primaryGreen, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Area Size',
                              controller: _areaController,
                              icon: Iconsax.ruler,
                              hint: 'e.g. 50',
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Area Unit',
                              items: _areaUnits,
                              value: _selectedAreaUnit,
                              icon: Iconsax.maximize_circle,
                              onChanged: (val) => setState(() => _selectedAreaUnit = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ─── Tree Details ──────────────────────────────────
                      _buildSectionLabel('Tree Details', Iconsax.tree),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Total Trees',
                              controller: _treesController,
                              icon: Iconsax.format_square,
                              hint: '200',
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              label: 'Tree Age (Yrs)',
                              controller: _treeAgeController,
                              icon: Iconsax.calendar_1,
                              hint: 'e.g. 5',
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Soil Type',
                        items: _soilTypes,
                        value: _selectedSoilType,
                        icon: Iconsax.maximize,
                        onChanged: (val) => setState(() => _selectedSoilType = val),
                      ),
                      const SizedBox(height: 28),

                      // ─── Description ───────────────────────────────────
                      _buildSectionLabel('Description', Iconsax.document),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Description',
                        controller: _descController,
                        icon: Iconsax.document,
                        hint: 'Details about crop condition, irrigation, etc...',
                        maxLines: 3,
                        isRequired: false,
                      ),
                      const SizedBox(height: 32),

                      // ─── Save Button ───────────────────────────────────
                      _SaveButton(onPressed: _saveOrchard),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ─── Image Section Widget ────────────────────────────────────────────────
  Widget _buildImageSection() {
    // Collect all image paths (existing URLs + new local paths)
    final List<_ImageEntry> allImages = [
      ..._existingImages.map((url) => _ImageEntry(path: url, isNetwork: true)),
      ..._newImages.map((f) => _ImageEntry(path: f.path, isNetwork: false)),
    ];
    final int totalImages = allImages.length;
    final bool canAdd = totalImages < 3;

    // Determine layout based on count (0 → just add, 1 → full-width, 2 → side-by-side, 3 → 2+1 grid)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Counter badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: totalImages == 0
                    ? Colors.grey.shade100
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: totalImages == 0
                      ? Colors.grey.shade300
                      : Colors.green.shade200,
                ),
              ),
              child: Text(
                '$totalImages / 3 photos',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: totalImages == 0
                      ? Colors.grey.shade600
                      : Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── 0 images: large add-photo placeholder ──────────────────────
        if (totalImages == 0)
          _buildAddTile(fullWidth: true),

        // ── 1 image: full-width with small add button ──────────────────
        if (totalImages == 1)
          Row(
            children: [
              Expanded(flex: 3, child: _buildImageTile(allImages[0], height: 140)),
              const SizedBox(width: 10),
              Expanded(flex: 1, child: _buildAddTile(height: 140)),
            ],
          ),

        // ── 2 images: side-by-side + add button ────────────────────────
        if (totalImages == 2)
          Row(
            children: [
              Expanded(child: _buildImageTile(allImages[0], height: 140)),
              const SizedBox(width: 10),
              Expanded(child: _buildImageTile(allImages[1], height: 140)),
              const SizedBox(width: 10),
              SizedBox(width: 70, child: _buildAddTile(height: 140)),
            ],
          ),

        // ── 3 images: professional 2+1 grid (no add button) ───────────
        if (totalImages == 3)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildImageTile(allImages[0], height: 170),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildImageTile(allImages[1], height: 80),
                        const SizedBox(height: 10),
                        _buildImageTile(allImages[2], height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  /// A single image tile with a remove button
  Widget _buildImageTile(_ImageEntry entry, {required double height}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: entry.isNetwork
                ? Image.network(entry.path, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(Iconsax.image, color: Colors.grey.shade400)))
                : (kIsWeb
                    ? Image.network(entry.path, fit: BoxFit.cover)
                    : Image.file(File(entry.path), fit: BoxFit.cover)),
          ),
        ),
        // Remove button
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (entry.isNetwork) {
                  _existingImages.remove(entry.path);
                } else {
                  _newImages.removeWhere((e) => e.path == entry.path);
                }
              });
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// The "Add Photo" placeholder tile
  Widget _buildAddTile({bool fullWidth = false, double height = 140}) {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.green.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.add_circle, color: _primaryGreen, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              'Add Photo',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ─── Section Label ────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primaryGreen, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  // ─── Text Field (matches login_screen.dart style) ─────────────────────────
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isNumber = false,
    bool isRequired = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.multiline,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _primaryGreen, size: 20),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        floatingLabelStyle: TextStyle(
          color: Colors.green.shade700,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      validator: isRequired ? (v) => (v == null || v.isEmpty) ? 'This field is required' : null : null,
    );
  }

  // ─── Dropdown (matches login_screen.dart style) ────────────────────────────
  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String? value,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: GoogleFonts.poppins(fontSize: 14)),
              ))
          .toList(),
      onChanged: onChanged,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryGreen, size: 20),
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
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        floatingLabelStyle: TextStyle(
          color: Colors.green.shade700,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Please select an option' : null,
      isExpanded: true,
      dropdownColor: Colors.white,
    );
  }
}

// ─── Professional Image Source Tile ──────────────────────────────────────────
class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _ImageSourceTile({
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Save Orchard Button (matches login_screen.dart style) ───────────────────
class _SaveButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _SaveButton({required this.onPressed});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
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
        transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF388E3C),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF388E3C).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onPressed,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Save Orchard',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
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

/// Simple data class to hold image path + whether it's a network image
class _ImageEntry {
  final String path;
  final bool isNetwork;
  const _ImageEntry({required this.path, required this.isNetwork});
}
