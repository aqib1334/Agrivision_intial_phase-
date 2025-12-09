// lib/models/orchard_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
class OrchardModel {
  final String id;
  final String farmerId;
  final String name;
  final String location;
  final String fruitType;
  final String areaSize; // ✅ Changed from double to String
  final int totalTrees;
  final List<String> imageUrls;
  final double expectedPrice;
  final String description;
  final DateTime createdAt;

  OrchardModel({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.location,
    required this.fruitType,
    required this.areaSize, // ✅ String
    required this.totalTrees,
    required this.imageUrls,
    required this.expectedPrice,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmerId': farmerId,
      'name': name,
      'location': location,
      'fruitType': fruitType,
      'areaSize': areaSize, // ✅ String saved
      'totalTrees': totalTrees,
      'imageUrls': imageUrls,
      'expectedPrice': expectedPrice,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory OrchardModel.fromMap(Map<String, dynamic> map, String docId) {
    return OrchardModel(
      id: docId,
      farmerId: map['farmerId'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      fruitType: map['fruitType'] ?? '',
      areaSize: map['areaSize']?.toString() ?? '0', // ✅ Convert to String
      totalTrees: map['totalTrees'] ?? 0,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      expectedPrice: (map['expectedPrice'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
