// lib/screens/farmer/orchands/orchard_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../../models/orchard_model.dart';
import '../../../services/farmer/orchard_service.dart';
import '../../../services/farmer/listing_service.dart';
import '../../../widgets/common/animated_button.dart';
import 'add_orchard_screen.dart';
import 'add_full_orchard_listing_screen.dart';
import '../../../services/common/verification_service.dart';
import '../../common/verification_screen.dart';

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

  // Image carousel state
  int _currentImageIndex = 0;
  late PageController _pageController;

  static const Color _primaryGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _checkActiveListings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkActiveListings() async {
    try {
      final listings =
          await _listingService.getActiveListingsByOrchard(widget.orchard.id);
      if (mounted) {
        setState(() {
          _hasActiveFullOrchardListing =
              listings.any((l) => l.listingType == 'full_orchard');
          _isCheckingListings = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCheckingListings = false);
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
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const VerificationScreen()));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              child: const Text("Verify Now",
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
    return false;
  }

  void _deleteOrchard(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Iconsax.danger, color: Colors.red.shade600, size: 24),
                  const SizedBox(width: 10),
                  const Text("Delete Orchard?",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                "This action cannot be undone. Are you sure you want to delete this orchard and all its listings?",
                style: TextStyle(height: 1.5, fontSize: 14),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                  child: Text("Cancel",
                      style: TextStyle(
                          fontSize: 15,
                          color: isDeleting ? Colors.grey : Colors.black87)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setState(() => isDeleting = true);
                          try {
                            await OrchardService().deleteOrchard(widget.orchard.id);
                            if (mounted) {
                              Navigator.pop(dialogContext);
                              Navigator.pop(this.context);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text("Orchard deleted successfully"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => isDeleting = false);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                    content: Text("Error: $e"),
                                    backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.red.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text("Delete",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
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
          builder: (context) => AddFullOrchardListingScreen(orchard: widget.orchard)),
    ).then((_) => _checkActiveListings());
  }

  void _showAlreadyListedDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Iconsax.info_circle, color: Colors.orange.shade600, size: 24),
              const SizedBox(width: 10),
              const Flexible(
                child: Text("Active Listing Exists",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: const Text(
            "This orchard already has an active full orchard listing.",
            style: TextStyle(height: 1.5, fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(fontSize: 15)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/all-listings');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("View Listings",
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.orchard.imageUrls;
    final hasImages = images.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ─── Hero Image AppBar ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: _primaryGreen,
            // ✅ Back button visible with white circle bg
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // ✅ Edit & Delete with dark background for visibility
            actions: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: const Icon(Iconsax.edit, color: Colors.white, size: 18),
                    tooltip: 'Edit Orchard',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddOrchardScreen(orchard: widget.orchard),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.red.withValues(alpha: 0.75),
                  child: IconButton(
                    icon: const Icon(Iconsax.trash, color: Colors.white, size: 18),
                    tooltip: 'Delete Orchard',
                    onPressed: () => _deleteOrchard(context),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // ─── Image Carousel ──────────────────────────────────
                  if (hasImages)
                    PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (i) =>
                          setState(() => _currentImageIndex = i),
                      itemBuilder: (context, index) => Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, e, s) => _buildImagePlaceholder(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.green.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: _primaryGreen,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    _buildImagePlaceholder(),

                  // Bottom gradient
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ─── Image dots indicator ──────────────────────────
                  if (images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == i ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == i
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Content ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      widget.orchard.name,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Location
                    Row(
                      children: [
                        Icon(Iconsax.location,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          widget.orchard.location,
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Stat Cards Row 1 ───────────────────────────────
                    _buildSectionLabel('Orchard Overview'),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Iconsax.tree,
                              value: '${widget.orchard.totalTrees}',
                              label: 'Trees',
                              bg: Colors.green.shade50,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatCard(
                              icon: Iconsax.ruler,
                              value:
                                  '${widget.orchard.areaSize} ${widget.orchard.areaUnit}',
                              label: 'Area',
                              bg: Colors.blue.shade50,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatCard(
                              icon: Iconsax.calendar_1,
                              value: '${widget.orchard.treeAge} Yrs',
                              label: 'Tree Age',
                              bg: Colors.orange.shade50,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ─── Stat Cards Row 2 ───────────────────────────────
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Iconsax.category,
                              value: widget.orchard.fruitType.isNotEmpty
                                  ? widget.orchard.fruitType
                                  : 'N/A',
                              label: 'Fruit',
                              bg: Colors.purple.shade50,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatCard(
                              icon: Iconsax.tag,
                              value: widget.orchard.variety.isNotEmpty
                                  ? widget.orchard.variety
                                  : 'N/A',
                              label: 'Variety',
                              bg: Colors.pink.shade50,
                              color: Colors.pink.shade700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatCard(
                              icon: Iconsax.maximize,
                              value: widget.orchard.soilType.isNotEmpty
                                  ? widget.orchard.soilType
                                  : 'Unknown',
                              label: 'Soil',
                              bg: const Color(0xFFF5F0E8),
                              color: const Color(0xFF795548),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Gallery (thumbnails, tappable) ────────────────
                    if (images.length > 1) ...[
                      _buildSectionLabel('Gallery'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            final isSelected = _currentImageIndex == index;
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration:
                                      const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 90,
                                margin:
                                    const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? _primaryGreen
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.1),
                                      blurRadius: 6,
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    images[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ─── Description ───────────────────────────────────
                    if (widget.orchard.description.isNotEmpty) ...[
                      _buildSectionLabel('Description'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Text(
                          widget.orchard.description,
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            height: 1.7,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ─── Sell Button ────────────────────────────────────
                    if (_isCheckingListings)
                      const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF388E3C)))
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

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade300, Colors.green.shade100],
        ),
      ),
      child: const Center(
          child: Icon(Iconsax.tree, size: 80, color: Colors.white)),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Colors.green.shade900,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color bg,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}