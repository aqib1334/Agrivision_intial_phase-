// lib/models/orchard_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrchardModel {
  final String id;
  final String farmerId;
  final String name; // e.g. "Mera Aam ka Bagh"
  final String location;
  final String fruitType; // Ab ye String hoga, Farmer khud likhega
  final double areaSize;
  final int totalTrees;
  final List<String> imageUrls; // Multiple Images
  final double expectedPrice; // Poore bagh ki qeemat
  final String description;
  final DateTime createdAt;

  OrchardModel({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.location,
    required this.fruitType,
    required this.areaSize,
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
      'areaSize': areaSize,
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
      areaSize: (map['areaSize'] ?? 0).toDouble(),
      totalTrees: (map['totalTrees'] ?? 0).toInt(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      expectedPrice: (map['expectedPrice'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

