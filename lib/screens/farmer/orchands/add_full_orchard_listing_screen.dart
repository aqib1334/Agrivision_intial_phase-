// lib/screens/farmer/orchands/add_full_orchard_listing_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../models/orchard_model.dart';
import '../../../services/farmer/listing_service.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/loading_indicator.dart';

class AddFullOrchardListingScreen extends StatefulWidget {
  final OrchardModel orchard;

  const AddFullOrchardListingScreen({super.key, required this.orchard});

  @override
  State<AddFullOrchardListingScreen> createState() =>
      _AddFullOrchardListingScreenState();
}

class _AddFullOrchardListingScreenState
    extends State<AddFullOrchardListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ListingService _listingService = ListingService();

  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _harvestSeasonController;

  String _selectedCondition = 'excellent';
  final List<String> _conditions = ['excellent', 'good', 'fair'];

  List<XFile> _newImages = [];
  bool _isLoading = false;
  DateTime? _selectedExpiryDate;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: '');
    _descController = TextEditingController(
      text: widget.orchard.description,
    );
    _harvestSeasonController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descController.dispose();
    _harvestSeasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);
      if (images.isNotEmpty) {
        setState(() => _newImages.addAll(images));
      }
    } else {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() => _newImages.add(image));
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 150,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSourceIcon(Iconsax.camera, "Camera", ImageSource.camera),
            _buildSourceIcon(Iconsax.gallery, "Gallery", ImageSource.gallery),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceIcon(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _pickImage(source);
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.green.shade50,
            child: Icon(icon, color: Colors.green),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _pickExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF388E3C),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedExpiryDate) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  void _createListing() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _listingService.createFullOrchardListing(
          orchard: widget.orchard,
          totalPrice: double.parse(_priceController.text.trim()),
          description: _descController.text.trim(),
          images: _newImages,
          orchardCondition: _selectedCondition,
          harvestSeason: _harvestSeasonController.text.trim().isNotEmpty
              ? _harvestSeasonController.text.trim()
              : null,
          expectedYield: null, // ✅ REMOVED - Always null now
          expiryDate: _selectedExpiryDate,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Full Orchard Listing Created Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sell Full Orchard"),
        backgroundColor: const Color(0xFF388E3C),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: LoadingIndicator(message: "Creating listing..."),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Orchard Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF388E3C).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Iconsax.tree,
                                  color: Color(0xFF388E3C),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Orchard Details',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF757575),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.orchard.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildInfoBadge(
                                Iconsax.tree,
                                '${widget.orchard.totalTrees} Trees',
                              ),
                              const SizedBox(width: 8),
                              _buildInfoBadge(
                                Iconsax.ruler,
                                '${widget.orchard.areaSize} Acres',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoBadge(
                            Iconsax.location,
                            widget.orchard.location,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Images Section
                    Text(
                      "Additional Images (Optional)",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: const Icon(
                                Iconsax.add,
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ..._newImages.map(
                            (file) => _buildImagePreview(file.path),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Price
                    _buildTextField(
                      "Total Orchard Price",
                      _priceController,
                      Iconsax.money,
                      "PKR",
                      isNumber: true,
                    ),
                    const SizedBox(height: 16),

                    // Condition Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      decoration: InputDecoration(
                        labelText: 'Orchard Condition',
                        prefixIcon: const Icon(
                          Iconsax.shield_tick,
                          color: Color(0xFF388E3C),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _conditions.map((condition) {
                        return DropdownMenuItem(
                          value: condition,
                          child: Text(
                            condition[0].toUpperCase() + condition.substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCondition = value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Harvest Season
                    _buildTextField(
                      "Harvest Season (Optional)",
                      _harvestSeasonController,
                      Iconsax.calendar,
                      "e.g., Summer 2025",
                    ),
                    const SizedBox(height: 16),

                    // ✅ REMOVED: Expected Yield field completely removed

                    // Expiry Date
                    GestureDetector(
                      onTap: _pickExpiryDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBDBDBD)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.calendar,
                              color: Color(0xFF388E3C),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Listing Expiry Date (Optional)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedExpiryDate != null
                                        ? DateFormat('MMM dd, yyyy')
                                            .format(_selectedExpiryDate!)
                                        : 'No expiry date set',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _selectedExpiryDate != null
                                          ? Colors.black87
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedExpiryDate != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() => _selectedExpiryDate = null);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildTextField(
                      "Description",
                      _descController,
                      Iconsax.document_text,
                      "Describe orchard condition, water availability...",
                      maxLines: 4,
                    ),
                    const SizedBox(height: 30),

                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CustomButton(
                        text: "Create Full Orchard Listing",
                        onPressed: _createListing,
                        backgroundColor: const Color(0xFF388E3C),
                        textColor: Colors.white,
                        icon: Iconsax.shop,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF388E3C)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String path) {
    return Stack(
      children: [
        Container(
          width: 100,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: (kIsWeb ? NetworkImage(path) : FileImage(File(path)))
                  as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 2,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _newImages.removeWhere((element) => element.path == path);
              });
            },
            child: const CircleAvatar(
              radius: 10,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF388E3C)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) {
        if (label.contains("Optional")) return null;
        return v!.isEmpty ? 'Required' : null;
      },
    );
  }
}
