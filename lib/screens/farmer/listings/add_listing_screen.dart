// lib/screens/farmer/listings/add_listing_screen.dart
// ✅ FINAL: Removed quantity/kg system completely
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../models/orchard_model.dart';
import '../../../models/listing_model.dart';
import '../../../services/farmer/listing_service.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/loading_indicator.dart';

class AddListingScreen extends StatefulWidget {
  final OrchardModel preSelectedOrchard;
  final ListingModel? listing;

  const AddListingScreen({
    super.key,
    required this.preSelectedOrchard,
    this.listing,
  });

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ListingService _listingService = ListingService();

  late TextEditingController _priceController;
  late TextEditingController _descController;

  List<XFile> _newImages = [];
  List<String> _existingImages = [];
  bool _isLoading = false;
  DateTime? _selectedExpiryDate;

  @override
  void initState() {
    super.initState();

    // Initialize with total price (not price per unit)
    _priceController = TextEditingController(
      text: widget.listing?.totalPrice.toString() ?? '',
    );
    _descController = TextEditingController(
      text: widget.listing?.description ?? '',
    );

    if (widget.listing != null) {
      _existingImages = widget.listing!.imageUrls;
      _selectedExpiryDate = widget.listing!.expiryDate;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descController.dispose();
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
      initialDate:
          _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 7)),
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
      setState(() => _selectedExpiryDate = picked);
    }
  }

  void _saveListing() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        double totalPrice = double.parse(_priceController.text.trim());

        await _listingService.saveListing(
          id: widget.listing?.id,
          orchardId: widget.preSelectedOrchard.id,
          orchardName: widget.preSelectedOrchard.name,
          fruitType: widget.preSelectedOrchard.fruitType,
          listingType: 'produce',
          quantity: 1.0, // Dummy value
          unit: 'item', // Dummy value
          pricePerUnit: totalPrice, // Total price as price per unit
          description: _descController.text.trim(),
          newImages: _newImages,
          existingImageUrls: _existingImages,
          location: widget.preSelectedOrchard.location,
          expiryDate: _selectedExpiryDate,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing Saved Successfully!'),
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
    bool isEdit = widget.listing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Listing" : "Create Listing"),
        backgroundColor: const Color(0xFF388E3C),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator(message: "Saving listing..."))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF388E3C).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
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
                                  'Selected Orchard',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF757575),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.preSelectedOrchard.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                Text(
                                  widget.preSelectedOrchard.fruitType,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF388E3C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      "Product Images",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
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
                          const SizedBox(width: 12),
                          ..._existingImages.map(
                            (url) => _buildImagePreview(url, isNetwork: true),
                          ),
                          ..._newImages.map(
                            (file) =>
                                _buildImagePreview(file.path, isNetwork: false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ✅ ONLY TOTAL PRICE FIELD (No quantity, no unit)
                    _buildTextField(
                      "Total Price",
                      _priceController,
                      Iconsax.money,
                      "Enter price in PKR",
                      isNumber: true,
                    ),
                    const SizedBox(height: 16),

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
                                    'Expiry Date (Optional)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedExpiryDate != null
                                        ? DateFormat(
                                            'MMM dd, yyyy',
                                          ).format(_selectedExpiryDate!)
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
                                onPressed: () =>
                                    setState(() => _selectedExpiryDate = null),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      "Description",
                      _descController,
                      Iconsax.document_text,
                      "Describe your product...",
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CustomButton(
                        text: isEdit ? "Update Listing" : "Create Listing",
                        onPressed: _saveListing,
                        backgroundColor: const Color(0xFF388E3C),
                        textColor: Colors.white,
                        icon: isEdit ? Iconsax.edit : Iconsax.add_circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePreview(String path, {required bool isNetwork}) {
    return Stack(
      children: [
        Container(
          width: 100,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: isNetwork
                  ? NetworkImage(path)
                  : (kIsWeb ? NetworkImage(path) : FileImage(File(path)))
                        as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: 14,
          top: 2,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isNetwork) {
                  _existingImages.remove(path);
                } else {
                  _newImages.removeWhere((element) => element.path == path);
                }
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
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF388E3C)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }
}
