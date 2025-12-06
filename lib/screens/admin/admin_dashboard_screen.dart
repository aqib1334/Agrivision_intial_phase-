// ============================================================================
// FILE: lib/screens/admin/admin_dashboard_screen.dart
// ============================================================================
// Fixed version - All errors resolved

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/admin/admin_service.dart';
import '../../widgets/admin/admin_stat_card.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/revenue_chart.dart';
import '../../widgets/admin/email_sent_chart.dart';
import '../../widgets/admin/user_data_table.dart';
import 'user_management_screen.dart';
import 'listing_moderation_screen.dart';
import 'order_management_screen.dart';
import 'analytics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  int _selectedIndex = 0;
  String? _errorMessage;
  bool _isSidebarCollapsed = false;
  String _searchQuery = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    print('🚀 Admin Dashboard InitState');
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadStats();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    print('📊 Loading Stats...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _adminService.getDashboardStats();
      print('✅ Stats Loaded: $stats');
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('❌ Stats Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load dashboard data: $e';
          _stats = {
            'totalUsers': 0,
            'farmers': 0,
            'buyers': 0,
            'activeListings': 0,
            'totalOrders': 0,
            'recentUsers': [],
          };
        });
      }
    }
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const UserManagementScreen();
      case 2:
        return const ListingModerationScreen();
      case 3:
        return const OrderManagementScreen();
      case 4:
        return const AnalyticsScreen();
      default:
        return _buildDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50.withOpacity(0.3),
              Colors.white,
              Colors.green.shade50.withOpacity(0.2),
            ],
          ),
        ),
        child: Row(
          children: [
            // Left Sidebar with Toggle Animation
            if (!_isSidebarCollapsed)
              SlideInLeft(
                duration: const Duration(milliseconds: 400),
                child: AdminSidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) {
                    print('📍 Menu Selected: $index');
                    setState(() => _selectedIndex = index);
                  },
                ),
              ),
            
            // Right Content Area
            Expanded(
              child: Column(
                children: [
                  // Animated Top Bar with Menu Toggle & Search
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      height: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade200.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Menu Toggle Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isSidebarCollapsed ? Icons.menu : Icons.menu_open,
                                color: Colors.orange.shade700,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isSidebarCollapsed = !_isSidebarCollapsed;
                                });
                              },
                              tooltip: _isSidebarCollapsed ? 'Open Menu' : 'Close Menu',
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Page Title
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.green.shade700,
                                Colors.green.shade500,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              _getPageTitle(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Search Bar
                          // Container(
                          //   width: 300,
                          //   height: 45,
                          //   decoration: BoxDecoration(
                          //     color: Colors.grey.shade100,
                          //     borderRadius: BorderRadius.circular(12),
                          //     border: Border.all(
                          //       color: Colors.grey.shade300,
                          //     ),
                          //   ),
                          //   child: TextField(
                          //     controller: _searchController,
                          //     onChanged: (value) {
                          //       setState(() {
                          //         _searchQuery = value;
                          //       });
                          //     },
                          //     decoration: InputDecoration(
                          //       hintText: 'Search by name or email...',
                          //       hintStyle: TextStyle(
                          //         color: Colors.grey.shade500,
                          //         fontSize: 14,
                          //       ),
                          //       prefixIcon: Icon(
                          //         Icons.search,
                          //         color: Colors.grey.shade600,
                          //       ),
                          //       suffixIcon: _searchQuery.isNotEmpty
                          //           ? IconButton(
                          //               icon: Icon(
                          //                 Icons.clear,
                          //                 color: Colors.grey.shade600,
                          //               ),
                          //               onPressed: () {
                          //                 _searchController.clear();
                          //                 setState(() {
                          //                   _searchQuery = '';
                          //                 });
                          //               },
                                      // )
                                    // : null,
                                // border: InputBorder.none,
                          //       contentPadding: const EdgeInsets.symmetric(
                          //         vertical: 12,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          
                          const SizedBox(width: 12),
                          
                          // Animated Refresh Button
                          Pulse(
                            infinite: false,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.green.shade700,
                                ),
                                onPressed: () {
                                  print('🔄 Refresh Button Clicked');
                                  _loadStats();
                                },
                                tooltip: 'Refresh Data',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Animated Logout Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.logout_rounded,
                                color: Colors.red.shade600,
                              ),
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                if (mounted) {
                                  Navigator.of(context).pushReplacementNamed('/login');
                                }
                              },
                              tooltip: 'Logout',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Main Page Content
                  Expanded(
                    child: _getSelectedScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'User Management';
      case 2:
        return 'Listings';
      case 3:
        return 'Orders';
      case 4:
        return 'Analytics';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildDashboard() {
    print('🏗️ Building Dashboard - Loading: $_isLoading, Stats: $_stats');

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinPerfect(
              infinite: true,
              duration: const Duration(seconds: 2),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  size: 60,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading dashboard...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: FadeIn(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Bounce(
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 100,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Failed to Load Dashboard',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    print('🔄 Retry Button Clicked');
                    _loadStats();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Message with Animation
              FadeInLeft(
                duration: const Duration(milliseconds: 600),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.green.shade800,
                      Colors.green.shade600,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'Welcome, Admin!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInLeft(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Here\'s what\'s happening with your platform',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Top Stat Cards with Staggered Animation
              Row(
                children: [
                  Expanded(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: AdminStatCard(
                        title: 'Total Users',
                        value: '${_stats['totalUsers'] ?? 0}',
                        icon: Icons.people_rounded,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                      child: AdminStatCard(
                        title: 'Farmers',
                        value: '${_stats['farmers'] ?? 0}',
                        icon: Icons.agriculture_rounded,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                      child: AdminStatCard(
                        title: 'Buyers',
                        value: '${_stats['buyers'] ?? 0}',
                        icon: Icons.shopping_cart_rounded,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 500),
                      child: AdminStatCard(
                        title: 'Listings',
                        value: '${_stats['activeListings'] ?? 0}',
                        icon: Icons.store_rounded,
                        color: Colors.purple.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Charts Section with Animation
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 600),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: EmailSentChart()),
                    SizedBox(width: 16),
                    Expanded(child: RevenueChart()),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Recent Users Table with Animation
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 700),
                child: UserDataTable(
                  users: _stats['recentUsers'] ?? [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}