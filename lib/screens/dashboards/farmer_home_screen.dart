// lib/screens/dashboards/farmer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:practice/models/orchard_model.dart';
import 'package:practice/screens/farmer/agroedu/agroedu_screen.dart';
import 'package:practice/screens/farmer/agroscan/agroscan_screen.dart';
import 'package:practice/screens/farmer/orchands/my_orchards_screen.dart';
import 'package:practice/screens/farmer/orchands/orchard_detail_screen.dart';
import 'package:practice/screens/farmer/orders/orders_screen.dart'; // ✅ NEW IMPORT

// Import custom widgets
import 'package:practice/widgets/farmer/dashboard_feature_card.dart';
import 'package:practice/widgets/farmer/stat_card.dart';
import 'package:practice/widgets/farmer/orchard_card.dart';
import 'package:practice/widgets/common/empty_state_widget.dart';
import 'package:practice/widgets/common/loading_indicator.dart';

// ✅ NEW IMPORT - Listings Screen
import 'package:practice/screens/farmer/listings/all_listings_screen.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  // Color Scheme
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryMain = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color primaryPale = Color(0xFFE8F5E9);
  static const Color accentOrange = Color(0xFFF57C00);
  static const Color textHeading = Color(0xDE000000);
  // static const Color textBody = Color(0xFF616161);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color borderNormal = Color(0xFFE0E0E0);
  static const Color statusInfo = Color(0xFF1976D2);

  String farmerName = "Farmer";
  String farmerEmail = "";
  String? profileImage;
  int _currentIndex = 0;

  // Stats
  int totalOrchards = 0;
  int activeListings = 0;
  int pendingOrders = 0;

  // Recent orchard
  Map<String, dynamic>? recentOrchard;
  bool _isLoadingOrchard = true;

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
    _loadStats();
    _loadRecentOrchard();
  }

  Future<void> _loadFarmerData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        DocumentSnapshot profileDoc = await FirebaseFirestore.instance
            .collection('Farmer_Profiles')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            if (userDoc.exists) {
              farmerName = userDoc['name'] ?? 'Farmer';
              farmerEmail = userDoc['email'] ?? '';
            }
            if (profileDoc.exists) {
              profileImage = profileDoc['profileImage'];
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading farmer data: $e');
      }
    }
  }

  Future<void> _loadStats() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final orchardsSnapshot = await FirebaseFirestore.instance
          .collection('Orchards')
          .where('farmerId', isEqualTo: user.uid)
          .get();

      final listingsSnapshot = await FirebaseFirestore.instance
          .collection('Orchard_Listings')
          .where('farmerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'available')
          .get();

      // ✅ UPDATED - Get pending order requests
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('Order_Requests')
          .where('farmerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (mounted) {
        setState(() {
          totalOrchards = orchardsSnapshot.docs.length;
          activeListings = listingsSnapshot.docs.length;
          pendingOrders = ordersSnapshot.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _loadRecentOrchard() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoadingOrchard = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Orchards')
          .where('farmerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          if (snapshot.docs.isNotEmpty) {
            recentOrchard = snapshot.docs.first.data();
            recentOrchard!['id'] = snapshot.docs.first.id;
          }
          _isLoadingOrchard = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent orchard: $e');
      if (mounted) {
        setState(() => _isLoadingOrchard = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryPale,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          _buildMyListingsPage(),
          _buildOrdersPage(), // ✅ UPDATED
          _buildProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: borderNormal, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: primaryMain,
        unselectedItemColor: textHint,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Colors.transparent,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.home),
            activeIcon: Icon(Iconsax.home_15),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.box),
            activeIcon: Icon(Iconsax.box_15),
            label: 'My Listings',
          ),
          BottomNavigationBarItem(
            icon: pendingOrders > 0
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Iconsax.shopping_cart),
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            pendingOrders.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Icon(Iconsax.shopping_cart),
            activeIcon: const Icon(Iconsax.shopping_cart5),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.user),
            activeIcon: Icon(Iconsax.user_octagon5),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadFarmerData();
          await _loadStats();
          await _loadRecentOrchard();
        },
        color: primaryMain,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Gradient
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryDark, primaryMain, primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryLight,
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back! 👋',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  farmerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/farmerProfile');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: primaryPale,
                                backgroundImage: profileImage != null
                                    ? NetworkImage(profileImage!)
                                    : null,
                                child: profileImage == null
                                    ? const Icon(
                                        Iconsax.user,
                                        color: primaryMain,
                                        size: 26,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Iconsax.tree,
                              count: totalOrchards.toString(),
                              label: 'Orchards',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              icon: Iconsax.box,
                              count: activeListings.toString(),
                              label: 'Listings',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              icon: Iconsax.notification,
                              count: pendingOrders.toString(),
                              label: 'Orders',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions Section
                    FadeInLeft(
                      duration: const Duration(milliseconds: 600),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryPale,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Iconsax.category,
                              color: primaryMain,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textHeading,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Feature Cards Grid
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          DashboardFeatureCard(
                            title: 'AgroScan',
                            icon: Iconsax.scan,
                            startColor: statusInfo,
                            endColor: const Color(0xFF1565C0),
                            imagePath: 'assets/images/agroscan.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AgroScanScreen(),
                                ),
                              );
                            },
                          ),
                          DashboardFeatureCard(
                            title: 'AgroPlan',
                            icon: Iconsax.clipboard_text,
                            startColor: primaryLight,
                            endColor: primaryMain,
                            imagePath: 'assets/images/agroplan.png',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('AgroPlan - Coming Soon'),
                                ),
                              );
                            },
                          ),
                          DashboardFeatureCard(
                            title: 'My Orchards',
                            icon: Iconsax.tree,
                            startColor: const Color(0xFF26A69A),
                            endColor: const Color(0xFF00897B),
                            imagePath: 'assets/images/agroorc.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MyOrchardsScreen(),
                                ),
                              );
                            },
                          ),
                          DashboardFeatureCard(
                            title: 'AgroEdu',
                            icon: Iconsax.book,
                            startColor: accentOrange,
                            endColor: const Color(0xFFE64A19),
                            imagePath: 'assets/images/agroedu.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AgroEduScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Recent Orchard Section
                    if (_isLoadingOrchard)
                      const LoadingIndicator(message: 'Loading orchards...')
                    else if (recentOrchard != null) ...[
                      FadeInLeft(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryPale,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Iconsax.tree,
                                color: primaryMain,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Recent Orchard',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textHeading,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // In farmer_home_screen.dart
                      // Replace the OrchardCard's onTap in _buildDashboard() method (around line 365) with:
                      FadeIn(
                        child: OrchardCard(
                          orchardName: recentOrchard!['name'] ?? 'Unknown',
                          location: recentOrchard!['location'] ?? 'Unknown',
                          area: "${recentOrchard!['areaSize'] ?? 0}",
                          fruitType: recentOrchard!['fruitType'] ?? 'Unknown',
                          imageUrl:
                              (recentOrchard!['imageUrls'] as List?)
                                      ?.isNotEmpty ==
                                  true
                              ? recentOrchard!['imageUrls'][0]
                              : null,
                          totalTrees: recentOrchard!['totalTrees'] ?? 0,
                          onTap: () {
                            // ✅ Convert Map to OrchardModel and navigate
                            final orchardModel = OrchardModel(
                              id: recentOrchard!['id'] ?? '',
                              farmerId: recentOrchard!['farmerId'] ?? '',
                              name: recentOrchard!['name'] ?? 'Unknown',
                              location: recentOrchard!['location'] ?? 'Unknown',
                              areaSize: (recentOrchard!['areaSize'] ?? 0)
                                  .toDouble(),
                              fruitType:
                                  recentOrchard!['fruitType'] ?? 'Unknown',
                              totalTrees: recentOrchard!['totalTrees'] ?? 0,
                              expectedPrice:
                                  (recentOrchard!['expectedPrice'] ?? 0)
                                      .toDouble(),
                              description: recentOrchard!['description'] ?? '',
                              imageUrls: List<String>.from(
                                recentOrchard!['imageUrls'] ?? [],
                              ),
                              createdAt: recentOrchard!['createdAt'] != null
                                  ? (recentOrchard!['createdAt'] as Timestamp)
                                        .toDate()
                                  : DateTime.now(),
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrchardDetailScreen(orchard: orchardModel),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else
                      FadeIn(
                        child: EmptyStateWidget(
                          icon: Iconsax.tree,
                          title: 'No Orchards Yet',
                          message:
                              'Start by adding your first orchard to get started',
                          actionText: 'Add Orchard',
                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyOrchardsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ MODIFIED - Show AllListingsScreen
  Widget _buildMyListingsPage() {
    return const AllListingsScreen();
  }

  // ✅ NEW - Show OrdersScreen
  Widget _buildOrdersPage() {
    return const OrdersScreen();
  }

  Widget _buildProfilePage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentIndex == 3) {
        Navigator.pushNamed(context, '/farmerProfile').then((_) {
          if (mounted) {
            setState(() => _currentIndex = 0);
          }
        });
      }
    });

    return const SizedBox.shrink();
  }
}
