// ✅ COMPLETE FILE: lib/screens/farmer/orchard_detail_screen.dart
// ✅ UPDATED: Uses Custom LoadingIndicator inside Delete Button

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';
import '../../../models/orchard_model.dart';
import '../../../services/farmer/orchard_service.dart';
import '../../../services/farmer/listing_service.dart';
import '../../../widgets/common/animated_button.dart';
import 'add_orchard_screen.dart';
import 'add_full_orchard_listing_screen.dart';
import '../../../services/common/verification_service.dart';
import '../../common/verification_screen.dart';
import '../../../widgets/common/loading_indicator.dart'; // ✅ Imported Custom Indicator

class OrchardDetailScreen extends StatefulWidget {
  final OrchardModel orchard;

  const OrchardDetailScreen({super.key, required this.orchard});

  @override
  State<OrchardDetailScreen> createState() => _OrchardDetailScreenState();
}

class _OrchardDetailScreenState extends State<OrchardDetailScreen> {
  final ListingService _listingService = ListingService();
  bool _hasActiveFullOrchardListing = false;
  bool _isCheckingListings = true;

  @override
  void initState() {
    super.initState();
    _checkActiveListings();
  }

  Future<void> _checkActiveListings() async {
    try {
      final listings = await _listingService.getActiveListingsByOrchard(
        widget.orchard.id,
      );

      if (mounted) {
        setState(() {
          _hasActiveFullOrchardListing = listings.any(
            (listing) => listing.listingType == 'full_orchard',
          );
          _isCheckingListings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingListings = false);
      }
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
        ? "Your documents are under review by Admin."
        : "You must verify your identity to create listings.";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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
                backgroundColor: Colors.green,
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

  // ✅ UPDATED DELETE FUNCTION: Uses Custom LoadingIndicator
  void _deleteOrchard(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Icon(Iconsax.danger, color: Colors.red.shade600, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      "Delete Orchard?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  "This action cannot be undone. Are you sure you want to delete this orchard?",
                  style: TextStyle(height: 1.5, fontSize: 14),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                actions: [
                  TextButton(
                    onPressed: isDeleting
                        ? null
                        : () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 15,
                        color: isDeleting ? Colors.grey : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // ✅ DELETE BUTTON with Custom Loading Indicator
                  ElevatedButton(
                    onPressed: isDeleting
                        ? null
                        : () async {
                            setState(() {
                              isDeleting = true;
                            });

                            try {
                              await OrchardService().deleteOrchard(
                                widget.orchard.id,
                              );

                              if (mounted) {
                                Navigator.pop(dialogContext);
                                Navigator.pop(this.context);

                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Orchard deleted successfully",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() {
                                  isDeleting = false;
                                });
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.red.shade300,
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isDeleting
                        ? const SizedBox(
                            width: 24, // Thoda size adjust kiya taake fit ho
                            height: 24,
                            child: FittedBox(
                              // ✅ Custom Loading Indicator Used Here
                              child: LoadingIndicator(color: Colors.white),
                            ),
                          )
                        : const Text(
                            "Delete",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _createFullOrchardListing() async {
    if (!await _checkVerification()) return;

    if (_hasActiveFullOrchardListing) {
      _showAlreadyListedDialog();
      return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddFullOrchardListingScreen(orchard: widget.orchard),
      ),
    ).then((_) => _checkActiveListings());
  }

  void _showAlreadyListedDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Iconsax.info_circle,
                color: Colors.orange.shade600,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  "Active Listing Exists",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            "This orchard already has an active full orchard listing. Please wait for it to expire or delete it before creating a new one.",
            style: TextStyle(height: 1.5, fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text("OK", style: TextStyle(fontSize: 15)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/all-listings');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "View Listings",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color.fromARGB(255, 157, 214, 159),
            actions: [
              FadeIn(
                duration: const Duration(milliseconds: 600),
                child: IconButton(
                  icon: const Icon(Iconsax.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddOrchardScreen(orchard: widget.orchard),
                      ),
                    );
                  },
                ),
              ),
              FadeIn(
                duration: const Duration(milliseconds: 800),
                child: IconButton(
                  icon: const Icon(Iconsax.trash, color: Colors.redAccent),
                  onPressed: () => _deleteOrchard(context),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.orchard.imageUrls.isNotEmpty
                      ? Image.network(
                          widget.orchard.imageUrls.first,
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
                          child: const Icon(
                            Iconsax.tree,
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
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.orchard.name,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade700,
                                Colors.green.shade500,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.shade200,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "PKR ${widget.orchard.expectedPrice.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                "Estimated",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
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
                        Icon(
                          Iconsax.location,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.orchard.location,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatBox(
                              Iconsax.tree,
                              "${widget.orchard.totalTrees}",
                              "Trees",
                              Colors.green.shade50,
                              Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatBox(
                              Iconsax.ruler,
                              "${widget.orchard.areaSize}",
                              "Area",
                              Colors.blue.shade50,
                              Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatBox(
                              Iconsax.shield_tick,
                              "Healthy",
                              "Status",
                              Colors.orange.shade50,
                              const Color.fromARGB(255, 8, 192, 23),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (widget.orchard.imageUrls.length > 1) ...[
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Gallery",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.orchard.imageUrls.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 100,
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.shade300,
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Image.network(
                                          widget.orchard.imageUrls[index],
                                          fit: BoxFit.cover,
                                        ),
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

                    FadeInUp(
                      duration: const Duration(milliseconds: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Description",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.orchard.description,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.6,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    if (_isCheckingListings)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF388E3C),
                        ),
                      )
                    else
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        child: AnimatedButton(
                          text: _hasActiveFullOrchardListing
                              ? "Full Orchard Listed"
                              : "Sell Full Orchard",
                          icon: _hasActiveFullOrchardListing
                              ? Iconsax.tick_circle
                              : Iconsax.shop,
                          onPressed: _createFullOrchardListing,
                          backgroundColor: _hasActiveFullOrchardListing
                              ? Colors.grey.shade400
                              : Colors.green.shade700,
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    IconData icon,
    String value,
    String label,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}