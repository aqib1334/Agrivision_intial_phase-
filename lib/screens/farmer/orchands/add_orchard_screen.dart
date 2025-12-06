// lib/screens/farmer/orchands/add_orchard_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import '../../../models/orchard_model.dart';
import '../../../services/farmer/orchard_service.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/loading_indicator.dart';

class AddOrchardScreen extends StatefulWidget {
  final OrchardModel? orchard; // Agar null hai to "Add", agar hai to "Edit"

  const AddOrchardScreen({super.key, this.orchard});

  @override
  State<AddOrchardScreen> createState() => _AddOrchardScreenState();
}

class _AddOrchardScreenState extends State<AddOrchardScreen> {
  final _formKey = GlobalKey<FormState>();
  final OrchardService _orchardService = OrchardService();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _fruitTypeController;
  late TextEditingController _locationController;
  late TextEditingController _areaController;
  late TextEditingController _treesController;
  late TextEditingController _priceController;
  late TextEditingController _descController;

  List<XFile> _newImages = [];
  List<String> _existingImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill data if editing
    _nameController = TextEditingController(text: widget.orchard?.name ?? '');
    _fruitTypeController = TextEditingController(
      text: widget.orchard?.fruitType ?? '',
    );
    _locationController = TextEditingController(
      text: widget.orchard?.location ?? '',
    );
    _areaController = TextEditingController(
      text: widget.orchard?.areaSize.toString() ?? '',
    );
    _treesController = TextEditingController(
      text: widget.orchard?.totalTrees.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.orchard?.expectedPrice.toString() ?? '',
    );
    _descController = TextEditingController(
      text: widget.orchard?.description ?? '',
    );
    _existingImages = widget.orchard?.imageUrls ?? [];
  }

  // Image Picker (Camera or Gallery)
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

  void _saveOrchard() async {
    if (_formKey.currentState!.validate()) {
      // if (_newImages.isEmpty && _existingImages.isEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Please add at least one image')),
      //   );
      //   return;
      // }

      setState(() => _isLoading = true);
      try {
        await _orchardService.saveOrchard(
          id: widget.orchard?.id, // Pass ID for edit
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
          area: double.parse(_areaController.text.trim()),
          fruitType: _fruitTypeController.text.trim(),
          totalTrees: int.parse(_treesController.text.trim()),
          expectedPrice: double.parse(_priceController.text.trim()),
          description: _descController.text.trim(),
          newImages: _newImages,
          existingImageUrls: _existingImages,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orchard Saved Successfully!'),
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
        title: Text(widget.orchard == null ? "Add Orchard" : "Edit Orchard"),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator(message: "Saving orchard..."))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Images Section
                    Text(
                      "Orchard Images",
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

                    // Fields
                    _buildTextField(
                      "Orchard Name",
                      _nameController,
                      Iconsax.text_block,
                      "My Mango Farm",
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "Fruit Type",
                      _fruitTypeController,
                      Iconsax.tree,
                      "e.g. Chaunsa Mango, Kinnow",
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "Location",
                      _locationController,
                      Iconsax.location,
                      "e.g. Sargodha",
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Area (Acres)",
                            _areaController,
                            Iconsax.ruler,
                            "50",
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(
                            "Total Trees",
                            _treesController,
                            Iconsax.format_square,
                            "200",
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "Expected Price (Whole Orchard)",
                      _priceController,
                      Iconsax.money,
                      "PKR",
                      isNumber: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "Description",
                      _descController,
                      Iconsax.document,
                      "Details about crop condition...",
                      maxLines: 3,
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CustomButton(
                        text: "Save Orchard",
                        onPressed: _saveOrchard,
                        backgroundColor: const Color(0xFF388E3C),
                        textColor: Colors.white,
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
          margin: const EdgeInsets.only(right: 10),
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
          right: 12,
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
