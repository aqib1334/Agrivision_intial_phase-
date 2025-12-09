// lib/screens/farmer/orders/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:practice/screens/farmer/orders/order_detail_screen.dart';
import '../../../models/order_request_model.dart';
import '../../../services/buyer/order_request_service.dart';
import '../../../widgets/farmer/order_card.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../../../widgets/common/empty_state_widget.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final OrderRequestService requestService = OrderRequestService();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.green.shade50,
      endDrawer: _buildHistorySidebar(),
      body: SafeArea(
        child: StreamBuilder<List<OrderRequestModel>>(
          stream: requestService.getFarmerRequests(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: LoadingIndicator(message: 'Loading orders...'),
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

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: EmptyStateWidget(
                  icon: Iconsax.shopping_cart,
                  title: 'No Orders Yet',
                  message: 'Buyer requests will appear here',
                ),
              );
            }

            final orders = snapshot.data!;

            // ✅ FIXED: Updated Status Logic for Grouping
            final pending = orders.where((o) => o.isPending).toList();
            final active = orders.where((o) => o.isConfirmed || o.isPaymentPending).toList();
            final done = orders.where((o) => o.isCompleted).toList();

            return CustomScrollView(
              slivers: [
                // Header with History Button
                SliverToBoxAdapter(
                  child: FadeInDown(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Order Requests',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _scaffoldKey.currentState?.openEndDrawer();
                                },
                                icon: const Icon(
                                  Iconsax.menu,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildHeaderStat(
                                pending.length.toString(),
                                'Pending',
                                Iconsax.clock,
                              ),
                              const SizedBox(width: 12),
                              _buildHeaderStat(
                                active.length.toString(),
                                'Active',
                                Iconsax.truck_fast,
                              ),
                              const SizedBox(width: 12),
                              _buildHeaderStat(
                                done.length.toString(),
                                'Done',
                                Iconsax.tick_circle,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Pending Orders
                if (pending.isNotEmpty) ...[
                  _buildSectionHeader('Pending Requests', Iconsax.clock, const Color(0xFFF57C00), pending.length),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = pending[index];
                          return FadeInUp(
                            duration: Duration(milliseconds: 400 + (index * 100)),
                            child: OrderCard(
                              order: order,
                              onTap: () => _navigateToDetail(order),
                              onAccept: () => _confirmOrder(context, order),
                              onReject: () => _rejectOrder(context, order),
                            ),
                          );
                        },
                        childCount: pending.length,
                      ),
                    ),
                  ),
                ],

                // Active Orders
                if (active.isNotEmpty) ...[
                  _buildSectionHeader('Active Orders', Iconsax.truck_fast, const Color(0xFF2196F3), active.length),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return FadeInUp(
                            duration: Duration(milliseconds: 400 + (index * 100)),
                            child: OrderCard(
                              order: active[index],
                              onTap: () => _navigateToDetail(active[index]),
                            ),
                          );
                        },
                        childCount: active.length,
                      ),
                    ),
                  ),
                ],

                // Done Orders (Recently Completed - Last 3)
                if (done.isNotEmpty) ...[
                  _buildSectionHeader('Completed Orders', Iconsax.verify, const Color(0xFF4CAF50), done.length),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return FadeInUp(
                            duration: Duration(milliseconds: 400 + (index * 100)),
                            child: Opacity(
                              opacity: 0.7,
                              child: OrderCard(
                                order: done[index],
                                onTap: () => _navigateToDetail(done[index]),
                              ),
                            ),
                          );
                        },
                        childCount: done.length > 3 ? 3 : done.length,
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ✅ FIXED: Sidebar with SafeArea and proper scrolling
  Widget _buildHistorySidebar() {
    final OrderRequestService requestService = OrderRequestService();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: SafeArea(
        child: Container(
          color: Colors.white,
          child: StreamBuilder<List<OrderRequestModel>>(
            stream: requestService.getFarmerRequests(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allOrders = snapshot.data!;
              final completed = allOrders.where((o) => o.isCompleted).toList();
              final rejected = allOrders.where((o) => o.isRejected || o.isCancelled).toList();

              return Column(
                children: [
                  // Sidebar Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade700,
                          Colors.green.shade500,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (completed.isNotEmpty)
                            _buildHistorySection('Completed', Iconsax.verify, Colors.green, completed),
                          if (rejected.isNotEmpty)
                            _buildHistorySection('Rejected', Iconsax.close_circle, Colors.red, rejected),
                          if (completed.isEmpty && rejected.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Text('No history yet', style: TextStyle(color: Colors.grey)),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection(
    String title,
    IconData icon,
    Color color,
    List<OrderRequestModel> orders,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${orders.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
        ),
        ...orders.map((order) => _buildHistoryTile(order)),
        const Divider(),
      ],
    );
  }

  Widget _buildHistoryTile(OrderRequestModel order) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8),
          image: order.listingImageUrl.isNotEmpty
              ? DecorationImage(image: NetworkImage(order.listingImageUrl), fit: BoxFit.cover)
              : null,
        ),
        child: order.listingImageUrl.isEmpty
            ? const Icon(Iconsax.box, color: Color(0xFF388E3C), size: 24)
            : null,
      ),
      title: Text(
        order.orchardName,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${order.buyerName} - PKR ${order.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
      onTap: () {
        Navigator.pop(context);
        _navigateToDetail(order);
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
        ],
      ),
    );
  }

  void _navigateToDetail(OrderRequestModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(order: order, isFarmer: true),
      ),
    );
  }

  void _confirmOrder(BuildContext context, OrderRequestModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: const Text('Do you want to confirm this order? Chat will be enabled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await OrderRequestService().confirmOrder(
          requestId: order.id,
          farmerResponse: 'Order confirmed! We will process it soon.',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order confirmed successfully!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _rejectOrder(BuildContext context, OrderRequestModel order) async {
    final reasonController = TextEditingController();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Rejection Reason (Optional)', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await OrderRequestService().rejectOrder(
          requestId: order.id,
          rejectionReason: reasonController.text.isEmpty ? 'Unable to fulfill this order at the moment.' : reasonController.text,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order rejected'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
