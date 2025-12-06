// lib/widgets/buyer/buyer_request_card.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../models/order_request_model.dart';

class BuyerRequestCard extends StatelessWidget {
  final OrderRequestModel request;
  final VoidCallback onTap;

  const BuyerRequestCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  Color _getStatusColor() {
    if (request.isPending) return const Color(0xFFF57C00); // Orange
    if (request.isConfirmed) return const Color(0xFF2196F3); // Blue
    if (request.isPaymentPending) return const Color(0xFF9C27B0); // Purple
    if (request.isCompleted) return const Color(0xFF4CAF50); // Green
    if (request.isRejected || request.isCancelled) return const Color(0xFFF44336); // Red
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (request.isPending) return Iconsax.clock;
    if (request.isConfirmed) return Iconsax.tick_circle;
    if (request.isPaymentPending) return Iconsax.wallet;
    if (request.isCompleted) return Iconsax.verify;
    if (request.isRejected || request.isCancelled) return Iconsax.close_circle;
    return Iconsax.info_circle;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Image & Status
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: request.listingImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(request.listingImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey.shade200,
                  ),
                  child: request.listingImageUrl.isEmpty
                      ? const Center(child: Icon(Iconsax.image, size: 40, color: Colors.grey))
                      : null,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(), size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          request.statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          request.orchardName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd').format(request.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Details Row
                  Row(
                    children: [
                      _buildDetailChip(
                        Iconsax.weight,
                        '${request.quantity} ${request.unit}',
                      ),
                      const SizedBox(width: 12),
                      _buildDetailChip(
                        Iconsax.money,
                        'PKR ${request.totalPrice.toStringAsFixed(0)}',
                      ),
                    ],
                  ),

                  // Payment Progress (if any payment made)
                  if (request.totalPaidAmount > 0) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: request.paymentProgress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paid: PKR ${request.totalPaidAmount.toStringAsFixed(0)} / ${request.totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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

  Widget _buildDetailChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}