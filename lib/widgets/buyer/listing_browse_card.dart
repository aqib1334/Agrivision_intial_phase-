// lib/widgets/buyer/listing_browse_card.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/listing_model.dart';

class ListingBrowseCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;

  const ListingBrowseCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    image: listing.imageUrls.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(listing.imageUrls.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: listing.imageUrls.isEmpty
                      ? Center(
                          child: Icon(
                            listing.isFullOrchard ? Iconsax.tree : Iconsax.box,
                            size: 64,
                            color: const Color(0xFF388E3C).withOpacity(0.3),
                          ),
                        )
                      : null,
                ),
                
                // ✅ NEW: Full Orchard Badge (Top Left)
                if (listing.isFullOrchard)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
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
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Iconsax.tree,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Full Orchard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Status Badge (Top Right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Available',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Orchard Name
                  Text(
                    listing.orchardName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xDE000000),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Fruit Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      listing.fruitType,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF388E3C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Location
                  if (listing.location != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Iconsax.location,
                          size: 14,
                          color: Color(0xFF757575),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.location!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF757575),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ✅ CONDITIONAL: Full Orchard Details OR Produce Details
                  if (listing.isFullOrchard) ...[
                    // Full Orchard Stats
                    Row(
                      children: [
                        if (listing.totalTrees != null)
                          Expanded(
                            child: _buildInfoChip(
                              icon: Iconsax.tree,
                              label: '${listing.totalTrees} Trees',
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (listing.areaSize != null)
                          Expanded(
                            child: _buildInfoChip(
                              icon: Iconsax.ruler,
                              label: '${listing.areaSize} Acres',
                              color: const Color(0xFF1976D2),
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    // Produce Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip(
                            icon: Iconsax.weight,
                            label: '${listing.quantity} ${listing.unit}',
                            color: const Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoChip(
                            icon: Iconsax.money,
                            label: 'PKR ${listing.pricePerUnit}/${listing.unit}',
                            color: const Color(0xFFF57C00),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Total Price
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF388E3C).withOpacity(0.1),
                          const Color(0xFF66BB6A).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF388E3C).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          listing.isFullOrchard ? 'Total Price' : 'Total Price',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        Text(
                          'PKR ${listing.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF388E3C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}