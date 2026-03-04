// screens/dashboards/buyer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:practice/screens/buyer/browse_listings_screen.dart';
import 'package:practice/screens/buyer/my_requests_screen.dart';
import 'package:practice/screens/dashboards/buyer_profile_screen.dart';


class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int _currentIndex = 0;

  // ✅ FIXED: Removed the placeholder, connected the real screen
  final List<Widget> _screens = [
    const BrowseListingsScreen(),
    const MyRequestsScreen(),
    const BuyerProfileScreen(), // This is now at Index 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0xFFE0E0E0),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF1976D2), // Blue for Buyer Theme
          unselectedItemColor: const Color(0xFFBDBDBD),
          selectedFontSize: 12,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Iconsax.shop),
              activeIcon: Icon(Iconsax.shop5),
              label: 'Browse',
            ),
            BottomNavigationBarItem(
              icon: Icon(Iconsax.shopping_cart),
              activeIcon: Icon(Iconsax.shopping_cart5),
              label: 'My Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Iconsax.user),
              activeIcon: Icon(Iconsax.user_octagon5),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}