// lib/services/admin/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/listing_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Get Dashboard Statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final usersCount = await _firestore.collection('Users').count().get();
      final farmersCount = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'farmer')
          .count()
          .get();
      final buyersCount = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'buyer')
          .count()
          .get();
      final listingsCount = await _firestore
          .collection('Orchard_Listings')
          .count()
          .get();
      final ordersCount = await _firestore
          .collection('Order_Requests')
          .count()
          .get();

      // Fetch Recent Users (Zaroori hai Dashboard table ke liye)
      final recentUsersSnapshot = await _firestore
          .collection('Users')
          .orderBy('registration_date', descending: true)
          .limit(6)
          .get();

      final recentUsers = recentUsersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['name'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'role': data['role'] ?? '',
          'status': data['status'] ?? 'active',
          'registrationDate': data['registration_date'],
        };
      }).toList();

      return {
        'totalUsers': usersCount.count ?? 0,
        'farmers': farmersCount.count ?? 0,
        'buyers': buyersCount.count ?? 0,
        'activeListings': listingsCount.count ?? 0,
        'totalOrders': ordersCount.count ?? 0,
        'recentUsers': recentUsers, // Ye zaroori hai
      };
    } catch (e) {
      print('Stats Error: $e');
      return {};
    }
  }

  // 2. User Management
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore
        .collection('Users')
        .orderBy('registration_date', descending: true)
        .snapshots();
  }

  // ✅ Ye methods zaroori hain UserManagementScreen ke error ko hatane ke liye
  Future<void> suspendUser(String userId) async {
    await _firestore.collection('Users').doc(userId).update({
      'status': 'suspended',
    });
  }

  Future<void> activateUser(String userId) async {
    await _firestore.collection('Users').doc(userId).update({
      'status': 'active',
    });
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('Users').doc(userId).delete();
  }

  // 3. Listings
  Stream<List<ListingModel>> getAllListings() {
    return _firestore
        .collection('Orchard_Listings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> deleteListing(String listingId) async {
    await _firestore.collection('Orchard_Listings').doc(listingId).delete();
  }

  // 4. Orders
  Stream<QuerySnapshot> getAllOrders() {
    return _firestore
        .collection('Order_Requests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
