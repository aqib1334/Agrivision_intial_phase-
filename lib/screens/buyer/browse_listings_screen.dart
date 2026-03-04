// lib/screens/buyer/browse_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/listing_model.dart';
import '../../widgets/buyer/listing_browse_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_widget.dart';
import 'listing_detail_screen.dart';

class BrowseListingsScreen extends StatefulWidget {
  const BrowseListingsScreen({super.key});

  @override
  State<BrowseListingsScreen> createState() => _BrowseListingsScreenState();
}

class _BrowseListingsScreenState extends State<BrowseListingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1B5E20),
                      Color(0xFF388E3C),
                      Color(0xFF66BB6A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Browse Orchards',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find full orchards for sale',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value.toLowerCase());
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by fruit type or location...',
                          prefixIcon: const Icon(
                            Iconsax.search_normal,
                            color: Color(0xFF388E3C),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ✅ REMOVED PRODUCE FILTER - ONLY SHOW ALL AND FULL ORCHARD
                    Row(
                      children: [
                        _buildFilterChip('All', 'all', Iconsax.box),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Full Orchard',
                          'full_orchard',
                          Iconsax.tree,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Orchard_Listings')
                    .where('status', isEqualTo: 'available')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: LoadingIndicator(message: 'Loading listings...'),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Iconsax.warning_2,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: EmptyStateWidget(
                        icon: Iconsax.box,
                        title: 'No Listings Available',
                        message: 'Check back later for orchards',
                      ),
                    );
                  }

                  List<ListingModel> listings = snapshot.data!.docs
                      .map(
                        (doc) => ListingModel.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ),
                      )
                      .where((listing) {
                        if (listing.isExpired) return false;
                        if (listing.status == 'sold') return false;

                        // ✅ ONLY SHOW FULL ORCHARD LISTINGS
                        if (_selectedFilter == 'full_orchard') {
                          if (listing.listingType != 'full_orchard')
                            return false;
                        }

                        if (_searchQuery.isEmpty) return true;
                        return listing.fruitType.toLowerCase().contains(
                              _searchQuery,
                            ) ||
                            listing.orchardName.toLowerCase().contains(
                              _searchQuery,
                            ) ||
                            (listing.location?.toLowerCase().contains(
                                  _searchQuery,
                                ) ??
                                false);
                      })
                      .toList();

                  if (listings.isEmpty) {
                    return Center(
                      child: EmptyStateWidget(
                        icon: Iconsax.search_normal,
                        title: 'No Results Found',
                        message: _searchQuery.isNotEmpty
                            ? 'Try different search terms'
                            : 'No active listings available',
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      return FadeInUp(
                        duration: Duration(milliseconds: 400 + (index * 100)),
                        child: ListingBrowseCard(
                          listing: listing,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ListingDetailScreen(listing: listing),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    bool isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF388E3C) : Colors.white,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF388E3C) : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF388E3C) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
