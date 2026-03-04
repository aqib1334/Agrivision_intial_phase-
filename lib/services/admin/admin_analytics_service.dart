// lib/services/admin/admin_analytics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get Disease Scan Statistics
  Future<Map<String, int>> getDiseaseStats() async {
    try {
      final scans = await _firestore.collection('Disease_Scans').get();
      
      Map<String, int> diseaseCount = {};
      for (var doc in scans.docs) {
        String? disease = doc.data()['detectedDisease'];
        if (disease != null && disease != 'Healthy') {
          diseaseCount[disease] = (diseaseCount[disease] ?? 0) + 1;
        }
      }
      
      return diseaseCount;
    } catch (e) {
      print('Error fetching disease stats: $e');
      return {};
    }
  }

  // Get Regional User Distribution
  Future<Map<String, int>> getRegionalDistribution() async {
    try {
      // Hum Farmers ki location check karenge region ke liye
      final farmers = await _firestore
          .collection('Farmer_Profiles')
          .get();
      
      Map<String, int> regionCount = {};
      for (var doc in farmers.docs) {
        String? location = doc.data()['location'];
        if (location != null && location.isNotEmpty) {
          regionCount[location] = (regionCount[location] ?? 0) + 1;
        }
      }
      
      return regionCount;
    } catch (e) {
      print('Error fetching regional distribution: $e');
      return {};
    }
  }
}