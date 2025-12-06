//  lib/widgets/farmer/listing_card.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/listing_model.dart';

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkAsDone; // ✅ NEW

  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onMarkAsDone, // ✅ NEW
  });

  Color _getStatusColor() {
    switch (listing.status) {
      case 'available':
        return const Color(0xFF4CAF50);
      case 'sold':
        return const Color(0xFF9E9E9E);
      case 'unavailable':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF757575);
    }
  }

  String _getStatusText() {
    switch (listing.status) {
      case 'available':
        return 'Available';
      case 'sold':
        return 'Sold';
      case 'unavailable':
        return 'Unavailable';
      default:
        return listing.status;
    }
  }

  IconData _getStatusIcon() {
    switch (listing.status) {
      case 'available':
        return Iconsax.box_tick;
      case 'sold':
        return Iconsax.tick_circle;
      case 'unavailable':
        return Iconsax.close_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAvailable = listing.status == 'available';
    bool isSold = listing.status == 'sold';
    bool isExpired = listing.status == 'unavailable';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSold 
                ? Colors.grey.shade300 
                : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
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
            // Image Section with Status Badge
            Stack(
              children: [
                Container(
                  height: 160,
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
                            colorFilter: isSold
                                ? ColorFilter.mode(
                                    Colors.grey.withOpacity(0.3),
                                    BlendMode.saturation,
                                  )
                                : null,
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
                
                // Status Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor().withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Full Orchard Badge
                if (listing.isFullOrchard)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Iconsax.tree, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Full Orchard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSold 
                          ? Colors.grey.shade600 
                          : const Color(0xDE000000),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Fruit Type
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

                  // Quantity & Price Row OR Full Orchard Stats
                  if (!listing.isFullOrchard)
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
                    )
                  else
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
                  const SizedBox(height: 12),

                  // Total Price
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSold
                          ? Colors.grey.shade100
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Price',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSold
                                ? Colors.grey.shade600
                                : const Color(0xFF616161),
                          ),
                        ),
                        Text(
                          'PKR ${listing.totalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSold
                                ? Colors.grey.shade700
                                : const Color(0xFF388E3C),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ Action Buttons - AVAILABLE
                  if (isAvailable && (onEdit != null || onDelete != null)) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (onEdit != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Iconsax.edit, size: 16),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1976D2),
                                side: const BorderSide(
                                  color: Color(0xFF1976D2),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        if (onEdit != null && onDelete != null)
                          const SizedBox(width: 8),
                        if (onDelete != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onDelete,
                              icon: const Icon(Iconsax.trash, size: 16),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFF44336),
                                side: const BorderSide(
                                  color: Color(0xFFF44336),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  // ✅ NEW: Mark as Done Button - SOLD
                  if (isSold && onMarkAsDone != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onMarkAsDone,
                        icon: const Icon(Iconsax.verify, size: 18),
                        label: const Text('Mark as Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ✅ Delete Button - EXPIRED
                  if (isExpired && onDelete != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Iconsax.trash, size: 16),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF44336),
                          side: const BorderSide(
                            color: Color(0xFFF44336),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
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