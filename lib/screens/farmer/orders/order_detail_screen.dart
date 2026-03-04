// lib/screens/farmer/orders/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:practice/models/order_request_model.dart';
import 'package:practice/services/buyer/order_request_service.dart';
import 'package:practice/widgets/common/custom_button.dart';
import 'package:practice/screens/chat/order_chat_screen.dart';
import 'package:practice/screens/buyer/add_payment_screen.dart'; // ✅ NEW

class OrderDetailScreen extends StatefulWidget {
  final OrderRequestModel order;
  final bool isFarmer;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.isFarmer,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderRequestService _orderService = OrderRequestService();
  bool _isLoading = false;

  // ✅ Check if chat is available (order confirmed or beyond)
  bool get _isChatAvailable {
    return widget.order.isConfirmed ||
        widget.order.isPaymentPending ||
        widget.order.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order.id.substring(0, 8)}'),
        backgroundColor: const Color(0xFF388E3C),
        foregroundColor: Colors.white,
        actions: [
          if (_isChatAvailable)
            IconButton(
              icon: const Icon(Iconsax.message),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderChatScreen(
                      order: widget.order,
                      isFarmer: widget.isFarmer,
                    ),
                  ),
                );
              },
              tooltip: 'Open Chat',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chat Banner
            if (_isChatAvailable)
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFE3F2FD),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.message,
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chat is available! Discuss details with ${widget.isFarmer ? "buyer" : "farmer"}.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderChatScreen(
                              order: widget.order,
                              isFarmer: widget.isFarmer,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'CHAT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Status Timeline
            _buildStatusTimeline(),
            
            const Divider(height: 1),
            
            // Product Details
            _buildProductDetails(),
            
            const Divider(height: 1),
            
            // ✅ NEW: Payment Summary with History
            _buildPaymentSummary(),
            
            const Divider(height: 1),
            
            // Contact Information
            _buildContactInfo(),
            
            const Divider(height: 1),
            
            // Action Buttons
            if (widget.order.isActive)
              _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status: ${widget.order.statusLabel}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildTimelineItem(
            'Order Requested',
            widget.order.createdAt,
            isCompleted: true,
            icon: Iconsax.document,
          ),
          
          _buildTimelineItem(
            'Confirmed by Farmer',
            widget.order.confirmedAt,
            isCompleted: widget.order.confirmedAt != null,
            icon: Iconsax.tick_circle,
          ),
          
          _buildTimelineItem(
            'Payment Made',
            widget.order.payments.isNotEmpty 
                ? widget.order.payments.last.paidAt 
                : null,
            isCompleted: widget.order.payments.isNotEmpty,
            icon: Iconsax.wallet,
          ),
          
          _buildTimelineItem(
            'Completed',
            widget.order.completedAt,
            isCompleted: widget.order.completedAt != null,
            isLast: true,
            icon: Iconsax.verify,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    DateTime? date,
    {
      required bool isCompleted,
      bool isLast = false,
      required IconData icon,
    }
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF388E3C) : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? const Color(0xFF388E3C) : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                    color: isCompleted ? Colors.black87 : Colors.grey,
                  ),
                ),
                if (date != null)
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          if (widget.order.listingImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.order.listingImageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          
          _buildDetailRow('Orchard', widget.order.orchardName),
          _buildDetailRow('Fruit Type', widget.order.fruitType),
          _buildDetailRow(
            'Quantity',
            '${widget.order.quantity} ${widget.order.unit}',
          ),
          _buildDetailRow(
            'Price per ${widget.order.unit}',
            'PKR ${widget.order.pricePerUnit.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Enhanced Payment Summary with History
  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Total Amount Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Total Amount',
                  'PKR ${widget.order.totalPrice.toStringAsFixed(0)}',
                  isWhite: true,
                ),
                const Divider(color: Colors.white30, height: 24),
                _buildSummaryRow(
                  'Total Paid',
                  'PKR ${widget.order.totalPaidAmount.toStringAsFixed(0)}',
                  isWhite: true,
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Remaining',
                  'PKR ${widget.order.remainingAmount.toStringAsFixed(0)}',
                  isWhite: true,
                  isBold: true,
                ),
              ],
            ),
          ),
          
          // Payment Progress Bar
          if (widget.order.totalPaidAmount > 0) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment Progress',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(widget.order.paymentProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: widget.order.paymentProgress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.green.shade600,
                  ),
                  minHeight: 8,
                ),
              ],
            ),
          ],
          
          // Payment History
          if (widget.order.payments.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Payment History',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.order.payments.map((payment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Iconsax.wallet,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              payment.paymentType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'PKR ${payment.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Method: ${payment.paymentMethod.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy - hh:mm a').format(payment.paidAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    // ✅ NEW: Show who recorded the payment
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: payment.recordedBy == 'farmer' 
                            ? Colors.blue.shade50 
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            payment.recordedBy == 'farmer' 
                                ? Iconsax.user 
                                : Iconsax.wallet,
                            size: 12,
                            color: payment.recordedBy == 'farmer'
                                ? Colors.blue.shade700
                                : Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Recorded by: ${payment.recordedByName} (${payment.recordedBy == "farmer" ? "Farmer" : "Buyer"})',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: payment.recordedBy == 'farmer'
                                  ? Colors.blue.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (payment.proofImageUrl != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          _showImageDialog(payment.proofImageUrl!);
                        },
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.gallery,
                              size: 14,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'View Proof',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Note: ${payment.notes}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Payment Proof'),
              backgroundColor: const Color(0xFF388E3C),
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isFarmer ? 'Buyer Information' : 'Seller Information',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildDetailRow('Name', widget.order.buyerName),
          _buildDetailRow('Phone', widget.order.buyerPhone),
          _buildDetailRow('Email', widget.order.buyerEmail),
          
          if (widget.order.message.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Message:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.order.message,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Chat Button
          if (_isChatAvailable)
            Column(
              children: [
                CustomButton(
                  text: 'Open Chat',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderChatScreen(
                          order: widget.order,
                          isFarmer: widget.isFarmer,
                        ),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF2196F3),
                  icon: Iconsax.message,
                ),
                const SizedBox(height: 12),
              ],
            ),

          if (widget.isFarmer) ..._buildFarmerActions(),
          if (!widget.isFarmer) ..._buildBuyerActions(),
        ],
      ),
    );
  }

  List<Widget> _buildFarmerActions() {
    List<Widget> buttons = [];

    if (widget.order.isPending) {
      buttons.addAll([
        CustomButton(
          text: 'Confirm Order',
          onPressed: () => _showConfirmDialog(),
          backgroundColor: const Color(0xFF388E3C),
          icon: Iconsax.tick_circle,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Reject Order',
          onPressed: () => _showRejectDialog(),
          backgroundColor: Colors.red,
          icon: Iconsax.close_circle,
        ),
      ]);
    } else if (widget.order.isConfirmed || widget.order.isPaymentPending) {
      // ✅ NEW: Farmer can also record payment
      if (widget.order.remainingAmount > 0) {
        buttons.addAll([
          CustomButton(
            text: 'Record Payment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPaymentScreen(
                    order: widget.order,
                    isFarmer: true, // ✅ Farmer mode
                  ),
                ),
              );
            },
            backgroundColor: const Color(0xFF1976D2),
            icon: Iconsax.wallet_add,
          ),
          const SizedBox(height: 12),
        ]);
      }
      
      // ✅ Mark as completed if fully paid
      if (widget.order.isPaymentPending && widget.order.isFullyPaid) {
        buttons.add(
          CustomButton(
            text: 'Mark as Completed',
            onPressed: () => _completeOrder(),
            backgroundColor: const Color(0xFF388E3C),
            icon: Iconsax.verify,
          ),
        );
      }
    }

    return buttons;
  }

  List<Widget> _buildBuyerActions() {
    List<Widget> buttons = [];

    if (widget.order.isConfirmed || widget.order.isPaymentPending) {
      if (widget.order.remainingAmount > 0) {
        buttons.add(
          CustomButton(
            text: 'Add Payment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPaymentScreen(
                    order: widget.order,
                  ),
                ),
              );
            },
            backgroundColor: const Color(0xFF388E3C),
            icon: Iconsax.wallet_add,
          ),
        );
      }
    }

    if (widget.order.isPending) {
      buttons.add(
        CustomButton(
          text: 'Cancel Request',
          onPressed: () => _cancelRequest(),
          backgroundColor: Colors.red,
          icon: Iconsax.close_circle,
        ),
      );
    }

    return buttons;
  }

  Widget _buildDetailRow(String label, String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {
    bool isWhite = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isWhite ? Colors.white.withOpacity(0.9) : Colors.grey,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isWhite ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // Action Methods
  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: const Text('Confirm this order? Chat will be activated for both parties.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmOrder();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmOrder() async {
    setState(() => _isLoading = true);
    try {
      await _orderService.confirmOrder(requestId: widget.order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order confirmed! Chat is now available.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason (Optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _rejectOrder(reasonController.text);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectOrder(String reason) async {
    setState(() => _isLoading = true);
    try {
      await _orderService.rejectOrder(
        requestId: widget.order.id,
        rejectionReason: reason.isEmpty ? null : reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Order'),
        content: const Text(
          'Mark this order as completed? This confirms you have received full payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _orderService.completeOrder(requestId: widget.order.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _orderService.cancelRequest(widget.order.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}
