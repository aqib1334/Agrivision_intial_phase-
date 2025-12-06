// lib/screens/buyer/my_requests_screen.dart
// ✅ PADDING FIXED - Logic unchanged
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:practice/screens/farmer/orders/order_detail_screen.dart';
import '../../models/order_request_model.dart';
import '../../services/buyer/order_request_service.dart';
import '../../widgets/buyer/buyer_request_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_widget.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final OrderRequestService requestService = OrderRequestService();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      endDrawer: _buildHistorySidebar(),
      body: StreamBuilder<List<OrderRequestModel>>(
        stream: requestService.getBuyerRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: LoadingIndicator(message: 'Loading requests...'),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.warning_2, size: 64, color: Colors.red),
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
                title: 'No Requests Yet',
                message: 'Browse listings and send purchase requests',
              ),
            );
          }

          final requests = snapshot.data!;
          final pending = requests.where((r) => r.isPending).toList();
          final accepted = requests
              .where((r) => r.isConfirmed || r.isPaymentPending)
              .toList();

          return CustomScrollView(
            slivers: [
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
                              'My Requests',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _scaffoldKey.currentState?.openEndDrawer(),
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
                            ),
                            const SizedBox(width: 16),
                            _buildHeaderStat(
                              accepted.length.toString(),
                              'Accepted',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (pending.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9C4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Iconsax.clock,
                            color: Color(0xFFF57C00),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Pending Requests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return FadeInUp(
                        duration: Duration(milliseconds: 400 + (index * 100)),
                        child: BuyerRequestCard(
                          request: pending[index],
                          onTap: () => _navigateToDetail(pending[index]),
                        ),
                      );
                    }, childCount: pending.length),
                  ),
                ),
              ],

              if (accepted.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Iconsax.tick_circle,
                            color: Color(0xFF4CAF50),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Accepted Requests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return FadeInUp(
                        duration: Duration(milliseconds: 400 + (index * 100)),
                        child: BuyerRequestCard(
                          request: accepted[index],
                          onTap: () => _navigateToDetail(accepted[index]),
                        ),
                      );
                    }, childCount: accepted.length),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistorySidebar() {
    final OrderRequestService requestService = OrderRequestService();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: SafeArea(
        child: Container(
          color: Colors.white,
          child: StreamBuilder<List<OrderRequestModel>>(
            stream: requestService.getBuyerRequests(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allRequests = snapshot.data!;
              final completed = allRequests
                  .where((r) => r.isCompleted)
                  .toList();
              final rejected = allRequests
                  .where((r) => r.isRejected || r.isCancelled)
                  .toList();

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade700, Colors.green.shade500],
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (completed.isNotEmpty)
                            _buildSidebarSection(
                              'Completed',
                              Iconsax.verify,
                              Colors.green,
                              completed,
                            ),
                          if (rejected.isNotEmpty)
                            _buildSidebarSection(
                              'Rejected / Cancelled',
                              Iconsax.close_circle,
                              Colors.red,
                              rejected,
                            ),
                          if (completed.isEmpty && rejected.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No history yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          const SizedBox(height: 16),
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

  Widget _buildSidebarSection(
    String title,
    IconData icon,
    Color color,
    List<OrderRequestModel> requests,
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${requests.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...requests.map((request) => _buildSidebarTile(request)),
        const Divider(),
      ],
    );
  }

  Widget _buildSidebarTile(OrderRequestModel request) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8),
          image: request.listingImageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(request.listingImageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: request.listingImageUrl.isEmpty
            ? const Icon(Iconsax.box, color: Color(0xFF388E3C), size: 24)
            : null,
      ),
      title: Text(
        request.orchardName,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'PKR ${request.totalPrice.toStringAsFixed(0)}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey.shade400,
      ),
      onTap: () {
        Navigator.pop(context);
        _navigateToDetail(request);
      },
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
        ),
      ],
    );
  }

  void _navigateToDetail(OrderRequestModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(order: order, isFarmer: false),
      ),
    );
  }
}
