// ✅ COMPLETE FILE: lib/screens/buyer/listing_detail_screen.dart
// ✅ ULTRA COMPACT PRICE CARDS - Matching screenshot requirement

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';
import '../../models/listing_model.dart';
import '../../services/buyer/order_request_service.dart';
import '../../widgets/common/animated_button.dart';
import '../../services/common/verification_service.dart';
import '../../screens/common/verification_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final ListingModel listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final OrderRequestService _requestService = OrderRequestService();

  bool _isLoading = false;
  bool _hasRequested = false;
  String _buyerName = '';
  String _buyerEmail = '';
  String _buyerPhone = '';

  @override
  void initState() {
    super.initState();
    _loadBuyerData();
    _checkIfRequested();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadBuyerData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            _buyerName = userDoc['name'] ?? '';
            _buyerEmail = userDoc['email'] ?? '';
            _buyerPhone = userDoc['phoneNumber'] ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error loading buyer data: $e');
      }
    }
  }

  Future<void> _checkIfRequested() async {
    try {
      bool hasRequested = await _requestService.hasRequestedListing(
        widget.listing.id,
      );
      if (mounted) {
        setState(() => _hasRequested = hasRequested);
      }
    } catch (e) {
      debugPrint('Error checking request: $e');
    }
  }

  Future<bool> _checkVerification() async {
    String status = await VerificationService().getCurrentUserStatus();

    if (status == 'verified') return true;

    if (!mounted) return false;

    String title = status == 'pending_approval'
        ? "Verification Pending"
        : "Verification Required";
    String msg = status == 'pending_approval'
        ? "Your documents are under review by Admin. You cannot place orders yet."
        : "To ensure trust and safety, you must verify your identity before placing orders.";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(msg),
        actionsAlignment: MainAxisAlignment.end,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          if (status == 'unverified' || status == 'rejected')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VerificationScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "Verify Now",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
    return false;
  }

  // Pura _showRequestDialog function replace karein:

void _showRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          // ✅ Dialog ke Title aur Content ki spacing
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          // ✅ Buttons ki spacing (Taake wo bottom se chipke na hon)
          actionsPadding: const EdgeInsets.fromLTRB(24, 10, 24, 24), 
        
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9), // Light Green bg
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.listing.isFullOrchard
                      ? Iconsax.tree
                      : Iconsax.shopping_cart,
                  color: const Color(0xFF388E3C),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.listing.isFullOrchard
                      ? 'Request Orchard'
                      : 'Request Purchase',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  widget.listing.isFullOrchard
                      ? 'Send an inquiry to purchase this entire orchard.'
                      : 'Send a purchase request to the farmer.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // ✅ Text Field Styling (Filled Grey like screenshot)
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Message (Optional)',
                    hintText: 'Any specific requirements...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5), // Light Grey Fill
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none, // Border hata diya
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF388E3C),
                        width: 1,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Iconsax.message_text,
                      color: Color(0xFF388E3C),
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // ✅ Cancel Button (Purple/Grey Text)
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor:
                    Colors.deepPurple.shade300, // Match screenshot text color
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
            ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            // ✅ Send Request Button (Green Filled)
            ElevatedButton(
              onPressed: _isLoading ? null : _sendRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send Request',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
    

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _requestService.createOrderRequest(
        listing: widget.listing,
        buyerName: _buyerName,
        buyerPhone: _buyerPhone,
        buyerEmail: _buyerEmail,
        message: _messageController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _isLoading = false;
          _hasRequested = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOrchard = widget.listing.isFullOrchard;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.green.shade100,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.listing.imageUrls.isNotEmpty
                      ? Image.network(
                          widget.listing.imageUrls.first,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade300,
                                Colors.green.shade100,
                              ],
                            ),
                          ),
                          child: Icon(
                            isOrchard ? Iconsax.tree : Iconsax.box,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  if (isOrchard)
                    Positioned(
                      top: 60,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade600,
                              Colors.orange.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Iconsax.tree, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Full Orchard Sale',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.listing.orchardName,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.listing.fruitType,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF388E3C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Iconsax.tick_circle,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (widget.listing.location != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Iconsax.location,
                            size: 18,
                            color: Color(0xFF757575),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.listing.location!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ✅ ULTRA COMPACT STAT BOXES
                    FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      child: isOrchard
                          ? _buildOrchardStats()
                          : _buildProduceStats(),
                    ),

                    const SizedBox(height: 12),

                    // ✅ ULTRA COMPACT TOTAL PRICE BANNER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade700,
                            Colors.green.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade200,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Price',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PKR ${widget.listing.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (widget.listing.imageUrls.length > 1) ...[
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gallery',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.listing.imageUrls.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        widget.listing.imageUrls[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (widget.listing.description.isNotEmpty) ...[
                      FadeInUp(
                        duration: const Duration(milliseconds: 900),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.listing.description,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                height: 1.6,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: AnimatedButton(
                        text: _hasRequested
                            ? 'Request Already Sent'
                            : (isOrchard
                                  ? 'Request Full Orchard'
                                  : 'Request Purchase'),
                        icon: _hasRequested
                            ? Iconsax.tick_circle
                            : (isOrchard
                                  ? Iconsax.tree
                                  : Iconsax.shopping_cart),
                        onPressed: _hasRequested
                            ? () {}
                            : () async {
                                if (await _checkVerification()) {
                                  _showRequestDialog();
                                }
                              },
                        backgroundColor: _hasRequested
                            ? Colors.grey.shade400
                            : Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrchardStats() {
    return Row(
      children: [
        if (widget.listing.totalTrees != null)
          Expanded(
            child: _buildStatBox(
              Iconsax.tree,
              '${widget.listing.totalTrees}',
              'Trees',
              Colors.green.shade50,
              Colors.green.shade700,
            ),
          ),
        if (widget.listing.totalTrees != null &&
            widget.listing.areaSize != null)
          const SizedBox(width: 12),
        if (widget.listing.areaSize != null)
          Expanded(
            child: _buildStatBox(
              Iconsax.ruler,
              '${widget.listing.areaSize}',
              'Acres',
              Colors.blue.shade50,
              Colors.blue.shade700,
            ),
          ),
      ],
    );
  }

  Widget _buildProduceStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            Iconsax.weight,
            '${widget.listing.quantity}',
            widget.listing.unit,
            Colors.blue.shade50,
            Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            Iconsax.money,
            'PKR ${widget.listing.pricePerUnit}',
            'per ${widget.listing.unit}',
            Colors.orange.shade50,
            Colors.orange.shade700,
          ),
        ),
      ],
    );
  }

  // ✅ ULTRA COMPACT STAT BOX - Matching screenshot perfectly
  Widget _buildStatBox(
    IconData icon,
    String value,
    String label,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: iconColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
