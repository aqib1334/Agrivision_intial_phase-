// lib/screens/buyer/add_payment_screen.dart
// ✅ PADDING FIXED - Logic unchanged
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_request_model.dart';
import '../../services/buyer/order_request_service.dart';
import '../../widgets/common/custom_button.dart';

class AddPaymentScreen extends StatefulWidget {
  final OrderRequestModel order;
  final bool isFarmer;

  const AddPaymentScreen({
    super.key,
    required this.order,
    this.isFarmer = false,
  });

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final OrderRequestService _orderService = OrderRequestService();
  final ImagePicker _picker = ImagePicker();

  String _paymentType = 'advance';
  String _paymentMethod = 'cash';
  XFile? _proofImage;
  bool _isLoading = false;

  String _currentUserName = '';
  String _recordedBy = 'buyer';

  @override
  void initState() {
    super.initState();
    _initializePaymentType();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            _currentUserName = userDoc['name'] ?? '';
            _recordedBy = widget.isFarmer ? 'farmer' : 'buyer';
          });
        }
      } catch (e) {
        debugPrint('Error loading user: $e');
      }
    }
  }

  void _initializePaymentType() {
    double remaining = widget.order.remainingAmount;

    if (widget.order.payments.isEmpty) {
      _paymentType = 'advance';
      _amountController.text = (widget.order.totalPrice * 0.3).toStringAsFixed(
        0,
      );
    } else if (remaining > 0 && remaining < widget.order.totalPrice) {
      _paymentType = 'partial';
      _amountController.text = remaining.toStringAsFixed(0);
    } else {
      _paymentType = 'final';
      _amountController.text = remaining.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() => _proofImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Payment Proof',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  Iconsax.camera,
                  'Camera',
                  ImageSource.camera,
                ),
                _buildSourceOption(
                  Iconsax.gallery,
                  'Gallery',
                  ImageSource.gallery,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _pickImage(source);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: const Color(0xFF388E3C)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    double amount = double.parse(_amountController.text.trim());

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount > widget.order.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount cannot exceed remaining balance (PKR ${widget.order.remainingAmount.toStringAsFixed(0)})',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _orderService.addPayment(
        requestId: widget.order.id,
        amount: amount,
        paymentType: _paymentType,
        paymentMethod: _paymentMethod,
        recordedBy: _recordedBy,
        recordedByName: _currentUserName,
        buyerName: widget.order.buyerName,
        proofImage: _proofImage,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isFarmer
                  ? 'Payment recorded successfully!'
                  : 'Payment added successfully!',
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFarmer ? 'Record Payment' : 'Add Payment'),
        backgroundColor: const Color(0xFF388E3C),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF388E3C)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isFarmer
                            ? const Color(0xFFE3F2FD)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.isFarmer ? Iconsax.user : Iconsax.wallet,
                            color: widget.isFarmer
                                ? Colors.blue.shade700
                                : Colors.green.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.isFarmer
                                  ? 'Recording payment received from buyer'
                                  : 'Adding your payment details',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: widget.isFarmer
                                    ? Colors.blue.shade900
                                    : Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payment Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade700,
                            Colors.green.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            'Total Amount',
                            'PKR ${widget.order.totalPrice.toStringAsFixed(0)}',
                          ),
                          const Divider(color: Colors.white30, height: 20),
                          _buildSummaryRow(
                            'Already Paid',
                            'PKR ${widget.order.totalPaidAmount.toStringAsFixed(0)}',
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Remaining Balance',
                            'PKR ${widget.order.remainingAmount.toStringAsFixed(0)}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payment Type Selection
                    const Text(
                      'Payment Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPaymentTypeChip(
                            'Advance (30%)',
                            'advance',
                            Iconsax.wallet,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPaymentTypeChip(
                            'Partial',
                            'partial',
                            Iconsax.money_send,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPaymentTypeChip(
                            'Full',
                            'final',
                            Iconsax.tick_circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Amount Input
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Payment Amount (PKR)',
                        hintText: 'Enter amount',
                        prefixIcon: const Icon(
                          Iconsax.money,
                          color: Color(0xFF388E3C),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null)
                          return 'Enter valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Payment Method
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: const Icon(
                          Iconsax.card,
                          color: Color(0xFF388E3C),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        _buildDropdownItem('cash', 'Cash'),
                        _buildDropdownItem('bank_transfer', 'Bank Transfer'),
                        _buildDropdownItem('easypaisa', 'Easypaisa'),
                        _buildDropdownItem('jazzcash', 'JazzCash'),
                      ],
                      onChanged: (value) =>
                          setState(() => _paymentMethod = value!),
                    ),
                    const SizedBox(height: 16),

                    // Payment Proof Image
                    const Text(
                      'Payment Proof (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: _proofImage != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: kIsWeb
                                        ? Image.network(
                                            _proofImage!.path,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(_proofImage!.path),
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _proofImage = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.camera,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Add Payment Proof',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Receipt, Cash Photo, Screenshot',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Add any notes about this payment...',
                        prefixIcon: const Icon(
                          Iconsax.document_text,
                          color: Color(0xFF388E3C),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CustomButton(
                        text: widget.isFarmer
                            ? 'Record Payment'
                            : 'Add Payment',
                        onPressed: _submitPayment,
                        backgroundColor: const Color(0xFF388E3C),
                        icon: Iconsax.wallet_add,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTypeChip(String label, String value, IconData icon) {
    bool isSelected = _paymentType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentType = value;
          if (value == 'advance') {
            _amountController.text = (widget.order.totalPrice * 0.3)
                .toStringAsFixed(0);
          } else if (value == 'final') {
            _amountController.text = widget.order.remainingAmount
                .toStringAsFixed(0);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF388E3C) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF388E3C) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(String value, String label) {
    return DropdownMenuItem(value: value, child: Text(label));
  }
}
