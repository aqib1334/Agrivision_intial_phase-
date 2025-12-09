import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import '../../services/common/verification_service.dart';
import '../../widgets/common/custom_button.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cnicNameController = TextEditingController();
  final _cnicNumberController = TextEditingController();
  File? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) setState(() => _image = File(picked.path));
    } catch (e) {
      print("Image Picker Error: $e"); // Error ignore kar rahe hain testing ke liye
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 🔴 COMMENTED OUT: Image check hata diya hai testing ke liye
    // if (_image == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload CNIC photo"), backgroundColor: Colors.red));
    //   return;
    // }

    setState(() => _isLoading = true);
    try {
      await VerificationService().submitVerification(
        cnicName: _cnicNameController.text.trim(),
        cnicNumber: _cnicNumberController.text.trim(),
        cnicImage: _image, // 👈 Ab null image bhi chali jayegi
      );
      if(mounted) {
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verification submitted (Test Mode)!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Identity"), backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Identity Verification", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              // Updated Text
              const Text("TESTING MODE: Image upload is optional if gallery crashes.", textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
              const SizedBox(height: 30),

              TextFormField(
                controller: _cnicNameController,
                decoration: InputDecoration(labelText: "Full Name (on CNIC)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Iconsax.user)),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _cnicNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "CNIC Number", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Iconsax.card)),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _image == null
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Iconsax.image, size: 40, color: Colors.green), SizedBox(height: 10), Text("Tap to upload (Optional)")])
                      : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_image!, fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: CustomButton(
                  text: "Submit Verification",
                  isLoading: _isLoading,
                  onPressed: _submit,
                  backgroundColor: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}