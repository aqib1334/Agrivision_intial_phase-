// lib/screens/dashboards/farmer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:practice/models/orchard_model.dart';
import 'package:practice/models/weather_model.dart';
import 'package:practice/services/weather_service.dart';
import 'package:practice/services/common/permission_service.dart';
import 'package:practice/screens/farmer/agroedu/agroedu_screen.dart';
import 'package:practice/screens/farmer/agroscan/agroscan_screen.dart';
import 'package:practice/screens/farmer/agroscan/disease_history_screen.dart';
import 'package:practice/screens/farmer/orchands/my_orchards_screen.dart';
import 'package:practice/screens/farmer/orchands/orchard_detail_screen.dart';
import 'package:practice/screens/farmer/orders/orders_screen.dart';
import 'package:practice/screens/farmer/listings/all_listings_screen.dart';
import 'package:practice/screens/farmer/marketplace/farmer_marketplace_screen.dart';
import 'package:practice/widgets/farmer/orchard_card.dart';
import 'package:practice/widgets/common/empty_state_widget.dart';
import 'package:practice/widgets/common/loading_indicator.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Design Tokens ──────────────────────────────────────────────────────────
  static const Color _green700 = Color(0xFF388E3C);
  static const Color _green800 = Color(0xFF2E7D32);
  static const Color _green900 = Color(0xFF1B5E20);
  static const Color _paleGreen = Color(0xFFE8F5E9);
  static const Color _bgColor = Colors.white;

  // ── State ──────────────────────────────────────────────────────────────────
  String _farmerName = 'Farmer';
  String _farmerEmail = '';
  String? _profileImage;
  int _currentIndex = 0;

  int _totalOrchards = 0;
  int _activeListings = 0;
  int _pendingOrders = 0;

  Map<String, dynamic>? _recentOrchard;
  bool _isLoadingOrchard = true;

  WeatherData? _weatherData;
  bool _isLoadingWeather = true;
  String _weatherError = '';

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
    _loadStats();
    _loadRecentOrchard();
    // Run permissions + weather AFTER the first frame so context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestPermissionsAndLoadWeather();
    });
  }

  // ── Permissions + Weather ──────────────────────────────────────────────────
  Future<void> _requestPermissionsAndLoadWeather() async {
    try {
      final result = await PermissionService.requestAllPermissions(context);

      WeatherData? weather;
      if (result.locationGranted && result.latitude != null) {
        weather = await WeatherService.fetchWeatherByCoords(
          result.latitude!,
          result.longitude!,
        );
      }

      // Fallback to Lahore if location denied or fetch failed
      weather ??= await WeatherService.fetchWeatherByCity('Lahore');

      if (mounted) {
        setState(() {
          _weatherData = weather;
          _weatherError = weather == null ? 'Unable to load weather' : '';
        });
      }
    } catch (e) {
      debugPrint('❌ Permission/weather error: $e');
      if (mounted) {
        setState(() => _weatherError = 'Weather unavailable');
      }
    } finally {
      // ✅ Always stop the loader no matter what happens
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }

  // ── Firebase Data ──────────────────────────────────────────────────────────
  Future<void> _loadFarmerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      final profileDoc = await FirebaseFirestore.instance
          .collection('Farmer_Profiles')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          if (userDoc.exists) _farmerName = userDoc['name'] ?? 'Farmer';
          if (profileDoc.exists) _profileImage = profileDoc['profileImage'];
          _farmerEmail = user.email ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading farmer data: $e');
    }
  }

  Future<void> _loadStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final orchardsSnap = await FirebaseFirestore.instance
          .collection('Orchards')
          .where('farmerId', isEqualTo: user.uid)
          .get();
      final listingsSnap = await FirebaseFirestore.instance
          .collection('Orchard_Listings')
          .where('farmerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'available')
          .get();
      final ordersSnap = await FirebaseFirestore.instance
          .collection('Order_Requests')
          .where('farmerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();
      if (mounted) {
        setState(() {
          _totalOrchards = orchardsSnap.docs.length;
          _activeListings = listingsSnap.docs.length;
          _pendingOrders = ordersSnap.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _loadRecentOrchard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isLoadingOrchard = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Orchards')
          .where('farmerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (mounted) {
        setState(() {
          if (snap.docs.isNotEmpty) {
            _recentOrchard = snap.docs.first.data();
            _recentOrchard!['id'] = snap.docs.first.id;
          }
          _isLoadingOrchard = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOrchard = false);
    }
  }

  // ── AgroScan — Camera Permission Flow ─────────────────────────────────────
  Future<void> _openAgroScan() async {
    try {
      final status = await Permission.camera.status;

      if (status.isGranted) {
        // Permission already granted — open screen directly
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgroScanScreen()),
          );
        }
      } else if (status.isDenied) {
        // Ask the user for permission
        final result = await Permission.camera.request();
        if (result.isGranted && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgroScanScreen()),
          );
        } else if (!result.isGranted && mounted) {
          _showCameraPermissionDialog();
        }
      } else if (status.isPermanentlyDenied) {
        // Must go to Settings
        if (mounted) _showCameraPermissionDialog();
      }
    } catch (e) {
      // Fallback: open screen and let it handle permission itself
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AgroScanScreen()),
        );
      }
    }
  }

  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt_rounded,
                  color: Colors.red.shade400, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Camera Access Required',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'AgroScan needs camera access to detect crop diseases.\n\n'
          'Please go to:\nSettings → Apps → AgriVision → Permissions → Camera → Allow',
          style: GoogleFonts.poppins(
              fontSize: 13, color: Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.grey.shade500)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings_rounded,
                size: 16, color: Colors.white),
            label: Text(
              'Open Settings',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // Opens Android/iOS App Settings directly
            },
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      // ── Left-side Profile Drawer ────────────────────────────────────────
      drawer: _buildProfileDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          _buildMyListingsPage(),
          _buildOrdersPage(),
          const FarmerMarketplaceScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Bottom Navigation ──────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: _green700,
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
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
            icon: _pendingOrders > 0
                ? Stack(clipBehavior: Clip.none, children: [
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
                          _pendingOrders.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ])
                : const Icon(Iconsax.shopping_cart),
            activeIcon: const Icon(Iconsax.shopping_cart5),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.shop),
            activeIcon: Icon(Iconsax.shop5),
            label: 'Marketplace',
          ),
        ],
      ),
    );
  }

  // ── Dashboard ──────────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadFarmerData(),
            _loadStats(),
            _loadRecentOrchard(),
            _requestPermissionsAndLoadWeather(),
          ]);
        },
        color: _green700,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Header (extra bottom padding makes room for overlap) ───
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: _buildHeroHeader(),
              ),

              // ── Weather Card overlaps the header by 40px ─────────────────
              Transform.translate(
                offset: const Offset(0, -40),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 150),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildWeatherCard(),
                  ),
                ),
              ),

              // ── Quick Actions + Recent Orchard (no stats row) ────────────
              Transform.translate(
                offset: const Offset(0, -32),
                child: Column(
                  children: [
                    // ── Quick Actions ──────────────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildQuickActions(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Recent Orchard ─────────────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildRecentOrchard(),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Header ────────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_green900, _green800, _green700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting + Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _greeting(),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('🌿', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _farmerName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formattedDate(),
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Avatar → opens profile drawer
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: _paleGreen,
                      child: ClipOval(
                        child: _profileImage != null
                            ? Image.network(
                                _profileImage!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Iconsax.user,
                                    color: _green700,
                                    size: 26),
                              )
                            : const Icon(Iconsax.user,
                                color: _green700, size: 26),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = days[now.weekday - 1];
    return '$dayName, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  // ── Weather Card (white, auth-screen style) ────────────────────────────────
  Widget _buildWeatherCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _isLoadingWeather
          ? _buildWeatherLoading()
          : _weatherData != null
              ? _buildWeatherContent(_weatherData!)
              : _buildWeatherError(),
    );
  }

  Widget _buildWeatherLoading() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: _green700,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Fetching weather...',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(WeatherData w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top section: location + icon + temp ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.location, color: _green700, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${w.city}, ${w.country}',
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  // Dynamic icon based on weather condition
                  _weatherIconWidget(w.iconCode),
                ],
              ),

              const SizedBox(height: 6),

              // Temp + condition + H/L
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${w.temperature.round()}°C',
                    style: GoogleFonts.poppins(
                      color: _green800,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.conditionCapitalized,
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Feels like ${w.feelsLike.round()}°C',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'H: ${w.tempMax.round()}°C',
                              style: GoogleFonts.poppins(
                                color: _green700,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'L: ${w.tempMin.round()}°C',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Stats strip (light green tint) ───────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // 4-stat row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _weatherStat(Iconsax.drop, '${w.humidity}%', 'Humidity'),
                  _vDivider(),
                  _weatherStat(
                    Iconsax.cloud_drizzle,
                    '${w.precipitation.toStringAsFixed(1)} ml',
                    'Precip.',
                  ),
                  _vDivider(),
                  _weatherStat(
                    Icons.compress_rounded,
                    '${w.pressure.round()} hPa',
                    'Pressure',
                  ),
                  _vDivider(),
                  _weatherStat(
                    Iconsax.wind,
                    '${w.windSpeed.toStringAsFixed(1)} m/s',
                    'Wind',
                  ),
                ],
              ),

              // Sunrise / Sunset
              if (w.sunrise != null || w.sunset != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(
                    color: Colors.green.shade200,
                    thickness: 1,
                    height: 16,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      const Icon(Icons.wb_twilight_rounded,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        w.sunriseDisplay,
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sunrise',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.nights_stay_rounded,
                          color: Color(0xFF5C6BC0), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        w.sunsetDisplay,
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sunset',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _weatherStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: _green700, size: 17),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey.shade500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _vDivider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.green.shade200,
    );
  }

  Widget _buildWeatherError() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.grey.shade400, size: 26),
          const SizedBox(width: 12),
          Text(
            'Weather unavailable',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }


  // ── Weather Icon: condition-mapped icon + color ─────────────────────────────
  Widget _weatherIconWidget(String iconCode) {
    // Strip day/night suffix to simplify matching
    final code = iconCode.replaceAll(RegExp(r'[dn]$'), '');

    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (code) {
      case '01': // Clear sky
        icon = Icons.wb_sunny_rounded;
        iconColor = Colors.amber.shade600;
        bgColor = Colors.amber.shade50;
        break;
      case '02': // Few clouds (sun + cloud)
        icon = Icons.wb_cloudy_rounded;
        iconColor = Colors.amber.shade400;
        bgColor = Colors.amber.shade50;
        break;
      case '03': // Scattered clouds
        icon = Icons.cloud_rounded;
        iconColor = Colors.blueGrey.shade400;
        bgColor = Colors.blueGrey.shade50;
        break;
      case '04': // Broken / overcast clouds
        icon = Icons.cloud_queue_rounded;
        iconColor = Colors.blueGrey.shade600;
        bgColor = Colors.blueGrey.shade50;
        break;
      case '09': // Shower / drizzle
        icon = Icons.grain_rounded;
        iconColor = Colors.blue.shade400;
        bgColor = Colors.blue.shade50;
        break;
      case '10': // Rain
        icon = Icons.water_drop_rounded;
        iconColor = Colors.blue.shade600;
        bgColor = Colors.blue.shade50;
        break;
      case '11': // Thunderstorm
        icon = Icons.thunderstorm_rounded;
        iconColor = Colors.deepPurple.shade400;
        bgColor = Colors.deepPurple.shade50;
        break;
      case '13': // Snow
        icon = Icons.ac_unit_rounded;
        iconColor = Colors.lightBlue.shade300;
        bgColor = Colors.lightBlue.shade50;
        break;
      case '50': // Mist / haze / fog
        icon = Icons.blur_on_rounded;
        iconColor = Colors.blueGrey.shade300;
        bgColor = Colors.blueGrey.shade50;
        break;
      default:
        icon = Icons.wb_sunny_rounded;
        iconColor = Colors.amber.shade500;
        bgColor = Colors.amber.shade50;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 30),
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Iconsax.chart_1, 'My Overview'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statTile(
                icon: Iconsax.tree,
                count: _totalOrchards.toString(),
                label: 'Orchards',
                color: _green700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile(
                icon: Iconsax.box,
                count: _activeListings.toString(),
                label: 'Listings',
                color: const Color(0xFF1976D2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile(
                icon: Iconsax.shopping_cart,
                count: _pendingOrders.toString(),
                label: 'Orders',
                color: const Color(0xFFF57C00),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Iconsax.category, 'Quick Actions'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.75,
          children: [
            _actionCard(
              title: 'AgroScan',
              subtitle: 'Disease detection',
              icon: Iconsax.scan,
              gradientColors: [const Color(0xFF1565C0), const Color(0xFF1976D2)],
              imagePath: 'assets/images/agroscan.png',
              onTap: _openAgroScan,
            ),
            _actionCard(
              title: 'Disease History',
              subtitle: 'Past diagnoses',
              icon: Iconsax.health,
              gradientColors: [const Color(0xFF2E7D32), const Color(0xFF43A047)],
              imagePath: 'assets/images/agroplan.png',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiseaseHistoryScreen()),
              ),
            ),

            _actionCard(
              title: 'My Orchards',
              subtitle: 'Manage farms',
              icon: Iconsax.tree,
              gradientColors: [const Color(0xFF00695C), const Color(0xFF26A69A)],
              imagePath: 'assets/images/agroorc.png',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrchardsScreen()),
              ),
            ),
            _actionCard(
              title: 'AgroEdu',
              subtitle: 'Learn & grow',
              icon: Iconsax.book,
              gradientColors: [const Color(0xFFE64A19), const Color(0xFFF57C00)],
              imagePath: 'assets/images/agroedu.png',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AgroEduScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: Colors.white, size: 17),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Feature Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      imagePath,
                      width: 38,
                      height: 38,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Recent Orchard ─────────────────────────────────────────────────────────
  Widget _buildRecentOrchard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Iconsax.tree, 'Recent Orchard'),
        const SizedBox(height: 12),
        if (_isLoadingOrchard)
          const LoadingIndicator(message: 'Loading orchards...')
        else if (_recentOrchard != null)
          OrchardCard(
            orchardName: _recentOrchard!['name'] ?? 'Unknown',
            location: _recentOrchard!['location'] ?? 'Unknown',
            area: '${_recentOrchard!['areaSize'] ?? 0}',
            fruitType: _recentOrchard!['fruitType'] ?? 'Unknown',
            imageUrl: (_recentOrchard!['imageUrls'] as List?)?.isNotEmpty == true
                ? _recentOrchard!['imageUrls'][0]
                : null,
            totalTrees: _recentOrchard!['totalTrees'] ?? 0,
            onTap: () {
              final orchardModel = OrchardModel(
                id: _recentOrchard!['id'] ?? '',
                farmerId: _recentOrchard!['farmerId'] ?? '',
                name: _recentOrchard!['name'] ?? 'Unknown',
                location: _recentOrchard!['location'] ?? 'Unknown',
                areaSize: _recentOrchard!['areaSize']?.toString() ?? '0',
                areaUnit: _recentOrchard!['areaUnit'] ?? 'Acre',
                fruitType: _recentOrchard!['fruitType'] ?? 'Unknown',
                variety: _recentOrchard!['variety'] ?? '',
                totalTrees: _recentOrchard!['totalTrees'] ?? 0,
                treeAge: _recentOrchard!['treeAge'] ?? 0,
                soilType: _recentOrchard!['soilType'] ?? '',
                description: _recentOrchard!['description'] ?? '',
                imageUrls:
                    List<String>.from(_recentOrchard!['imageUrls'] ?? []),
                createdAt: _recentOrchard!['createdAt'] != null
                    ? (_recentOrchard!['createdAt'] as Timestamp).toDate()
                    : DateTime.now(),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrchardDetailScreen(orchard: orchardModel),
                ),
              );
            },
          )
        else
          EmptyStateWidget(
            icon: Iconsax.tree,
            title: 'No Orchards Yet',
            message: 'Start by adding your first orchard to get started',
            actionText: 'Add Orchard',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyOrchardsScreen()),
            ),
          ),
      ],
    );
  }

  // ── Section Title Helper ───────────────────────────────────────────────────
  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _paleGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _green700, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── Sub Pages ──────────────────────────────────────────────────────────────
  Widget _buildMyListingsPage() => const AllListingsScreen();
  Widget _buildOrdersPage() => const OrdersScreen();

  // ── Profile Drawer (X / Instagram style) ────────────────────────────────────
  Widget _buildProfileDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Container(
          color: Colors.white,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── X-style compact white header ──────────────────────────────
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar left, face fully visible
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/farmerProfile')
                              .then((_) {
                            if (mounted) _loadFarmerData();
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _green700.withValues(alpha: 0.3),
                                width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: _paleGreen,
                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.network(
                                      _profileImage!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Iconsax.user,
                                        color: _green700,
                                        size: 26,
                                      ),
                                    )
                                  : Icon(Iconsax.user,
                                      color: _green700, size: 26),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Close button top-right
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              color: Colors.grey.shade600, size: 17),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _farmerName,
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _farmerEmail.isNotEmpty ? _farmerEmail : 'Orchard Farmer',
                    style: GoogleFonts.poppins(
                        color: Colors.grey.shade500, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade200, thickness: 1, height: 1),

            // ── Menu Items ──────────────────────────────────────────
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                children: [
                  _drawerItem(
                    icon: Iconsax.user_edit,
                    label: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/farmerProfile')
                          .then((_) {
                        if (mounted) _loadFarmerData();
                      });
                    },
                  ),
                  _drawerItem(
                    icon: Iconsax.tree,
                    label: 'My Orchards',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyOrchardsScreen()),
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Divider(
                        color: Colors.grey.shade200,
                        thickness: 1,
                        height: 1),
                  ),

                  // ── Preferences (placeholders) ────────────────────────
                  _drawerItem(
                    icon: Iconsax.paintbucket,
                    label: 'Theme',
                    trailing: _pill('Light', _paleGreen, _green700),
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon('Theme');
                    },
                  ),
                  _drawerItem(
                    icon: Iconsax.language_square,
                    label: 'Language',
                    trailing:
                        _pill('English', Colors.blue.shade50, Colors.blue.shade700),
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon('Language');
                    },
                  ),
                  _drawerItem(
                    icon: Iconsax.notification,
                    label: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon('Notifications');
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Divider(
                        color: Colors.grey.shade200,
                        thickness: 1,
                        height: 1),
                  ),

                  _drawerItem(
                    icon: Iconsax.info_circle,
                    label: 'About AgriVision',
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon('About');
                    },
                  ),
                  _drawerItem(
                    icon: Iconsax.message_question,
                    label: 'Help Centre',
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon('Help Centre');
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Divider(
                        color: Colors.grey.shade200,
                        thickness: 1,
                        height: 1),
                  ),

                  _drawerItem(
                    icon: Iconsax.logout,
                    label: 'Logout',
                    iconColor: Colors.red.shade400,
                    labelColor: Colors.red.shade600,
                    onTap: () async {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (_) => false);
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Footer ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Text('AgriVision v1.0',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey.shade400)),
            ),
          ],
        ),
      ),
    ),
  );
}

  // ── Coming Soon snack ─────────────────────────────────────────────────
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Iconsax.clock, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Text('$feature — Coming Soon!',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w500)),
      ]),
      backgroundColor: _green700,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Pill badge helper ───────────────────────────────────────────────
  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }

  // ── Drawer row ──────────────────────────────────────────────────────
  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
    Widget? trailing,
  }) {
    final iColor = iconColor ?? _green700;
    final lColor = labelColor ?? Colors.black87;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: iColor, size: 22),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: lColor,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}
