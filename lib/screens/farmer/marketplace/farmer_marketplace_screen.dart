// lib/screens/farmer/marketplace/farmer_marketplace_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import '../../../models/listing_model.dart';

class FarmerMarketplaceScreen extends StatefulWidget {
  const FarmerMarketplaceScreen({super.key});

  @override
  State<FarmerMarketplaceScreen> createState() =>
      _FarmerMarketplaceScreenState();
}

class _FarmerMarketplaceScreenState
    extends State<FarmerMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  // ── Design Tokens ──────────────────────────────────────────────────────
  static const Color _green900 = Color(0xFF1B5E20);
  static const Color _green800 = Color(0xFF2E7D32);
  static const Color _green700 = Color(0xFF388E3C);
  static const Color _paleGreen = Color(0xFFE8F5E9);

  // ── Filter State ───────────────────────────────────────────────────────
  String _selectedType = 'All'; // All | full_orchard | produce
  String _selectedFruit = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _fruitFilters = [
    'All', 'Mango', 'Citrus', 'Apple', 'Guava', 'Date', 'Apricot', 'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Firestore query (all available listings, not filtered by farmer) ───
  Stream<List<ListingModel>> _listingsStream() {
    return FirebaseFirestore.instance
        .collection('Orchard_Listings')
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ListingModel.fromMap(d.data(), d.id))
            .where((l) => !l.isExpired)
            .toList());
  }

  List<ListingModel> _applyFilters(List<ListingModel> all) {
    return all.where((l) {
      // Type filter
      if (_selectedType == 'full_orchard' && l.listingType != 'full_orchard') {
        return false;
      }
      if (_selectedType == 'produce' && l.listingType != 'produce') {
        return false;
      }
      // Fruit filter
      if (_selectedFruit != 'All' &&
          !l.fruitType.toLowerCase().contains(_selectedFruit.toLowerCase())) {
        return false;
      }
      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return l.orchardName.toLowerCase().contains(q) ||
            l.fruitType.toLowerCase().contains(q) ||
            (l.location?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          // ── Header ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: _green800,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_green900, _green800, _green700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Iconsax.shop,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Marketplace',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Text(
                                  'Browse available orchard listings',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Search + Filters (pinned below header) ─────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeaderDelegate(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar
                    Material(
                      elevation: 0,
                      borderRadius: BorderRadius.circular(14),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.trim()),
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                              'Search by orchard, fruit, location...',
                          hintStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade400),
                          prefixIcon: Icon(Iconsax.search_normal,
                              color: _green700, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      size: 18, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Type chips
                    Row(
                      children: [
                        _typeChip('All', Icons.apps_rounded),
                        const SizedBox(width: 8),
                        _typeChip('full_orchard', Iconsax.tree),
                        const SizedBox(width: 8),
                        _typeChip('produce', Iconsax.box),
                        const Spacer(),
                        // Fruit dropdown
                        _fruitDropdown(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // ── Body ──────────────────────────────────────────────────────────
        body: StreamBuilder<List<ListingModel>>(
          stream: _listingsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: _green700));
            }
            if (snapshot.hasError) {
              return _emptyState(
                icon: Iconsax.danger,
                title: 'Something went wrong',
                subtitle: 'Could not load listings. Please try again.',
                iconColor: Colors.red.shade400,
              );
            }
            final all = snapshot.data ?? [];
            final filtered = _applyFilters(all);

            if (filtered.isEmpty) {
              return _emptyState(
                icon: Iconsax.shop,
                title: 'No listings found',
                subtitle: 'Try adjusting your filters or search.',
                iconColor: Colors.grey.shade400,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return FadeInUp(
                  duration: Duration(milliseconds: 300 + index * 60),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _MarketplaceCard(listing: filtered[index]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _typeChip(String type, IconData icon) {
    final isSelected = _selectedType == type;
    final label = type == 'All'
        ? 'All'
        : type == 'full_orchard'
            ? 'Full Orchard'
            : 'Produce';
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _green700 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? _green700 : Colors.grey.shade300,
              width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fruitDropdown() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _selectedFruit == 'All'
            ? Colors.grey.shade100
            : _paleGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _selectedFruit == 'All'
              ? Colors.grey.shade300
              : _green700,
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFruit,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: _selectedFruit == 'All'
                  ? Colors.grey.shade500
                  : _green700,
              size: 18),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _selectedFruit == 'All'
                ? Colors.grey.shade600
                : _green700,
          ),
          items: _fruitFilters
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (v) => setState(() => _selectedFruit = v ?? 'All'),
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 48),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Persistent Filter Header Delegate ────────────────────────────────────────
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _FilterHeaderDelegate({required this.child});

  @override
  double get minExtent => 110;
  @override
  double get maxExtent => 110;

  @override
  Widget build(_, __, ___) => child;

  @override
  bool shouldRebuild(_FilterHeaderDelegate old) => old.child != child;
}

// ── Marketplace Listing Card ──────────────────────────────────────────────────
class _MarketplaceCard extends StatelessWidget {
  final ListingModel listing;
  const _MarketplaceCard({required this.listing});

  static const Color _green700 = Color(0xFF388E3C);
  static const Color _green800 = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final isFullOrchard = listing.listingType == 'full_orchard';
    final hasImage =
        listing.imageUrls.isNotEmpty && listing.imageUrls.first.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ─────────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                hasImage
                    ? Image.network(
                        listing.imageUrls.first,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, lp) {
                          if (lp == null) return child;
                          return Container(
                            height: 170,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: _green700, strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) =>
                            _placeholder(),
                      )
                    : _placeholder(),

                // Listing type badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isFullOrchard
                          ? _green800.withValues(alpha: 0.88)
                          : const Color(0xFF1565C0).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFullOrchard ? Iconsax.tree : Iconsax.box,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isFullOrchard ? 'Full Orchard' : 'Produce',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Price badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      _formatPrice(listing),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _green800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  listing.orchardName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                if (listing.location != null &&
                    listing.location!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Iconsax.location,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.location!,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                // Chips row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(
                        icon: Iconsax.tree,
                        label: listing.fruitType,
                        bg: const Color(0xFFE8F5E9),
                        color: _green700),
                    if (isFullOrchard && listing.areaSize != null)
                      _chip(
                          icon: Iconsax.ruler,
                          label: listing.areaSize!,
                          bg: const Color(0xFFE3F2FD),
                          color: const Color(0xFF1565C0)),
                    if (isFullOrchard && listing.totalTrees != null)
                      _chip(
                          icon: Iconsax.format_square,
                          label: '${listing.totalTrees} trees',
                          bg: const Color(0xFFF3E5F5),
                          color: const Color(0xFF6A1B9A)),
                    if (!isFullOrchard && listing.quantity > 0)
                      _chip(
                          icon: Iconsax.weight,
                          label:
                              '${listing.quantity.toStringAsFixed(0)} ${listing.unit}',
                          bg: const Color(0xFFFFF3E0),
                          color: const Color(0xFFE65100)),
                    if (listing.orchardCondition != null)
                      _chip(
                          icon: Iconsax.medal_star,
                          label: _capitalize(listing.orchardCondition!),
                          bg: Colors.amber.shade50,
                          color: Colors.amber.shade800),
                  ],
                ),

                if (listing.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    listing.description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // Bottom: date + "View Only" label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _timeAgo(listing.createdAt),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.eye, size: 12, color: _green700),
                          const SizedBox(width: 4),
                          Text('View Only',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: _green700,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.green.shade50],
        ),
      ),
      child: Center(
          child: Icon(Iconsax.tree, size: 56, color: Colors.green.shade300)),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color bg,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  String _formatPrice(ListingModel l) {
    if (l.isFullOrchard) {
      if (l.totalPrice > 0) return 'PKR ${_compact(l.totalPrice)}';
      return 'Price TBD';
    }
    if (l.pricePerUnit > 0) {
      return 'PKR ${_compact(l.pricePerUnit)}/${l.unit}';
    }
    return 'Price TBD';
  }

  String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }
}
