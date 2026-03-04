// lib/models/orchard_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
class OrchardModel {
  final String id;
  final String farmerId;
  final String name;
  final String location;
  final String fruitType;
  final String variety; // ✅ Added
  final String areaSize; // ✅ String
  final String areaUnit; // ✅ Added (e.g., Acre, Kanal)
  final int totalTrees;
  final int treeAge; // ✅ Added
  final String soilType; // ✅ Added
  final List<String> imageUrls;
  final String description;
  final DateTime createdAt;

  OrchardModel({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.location,
    required this.fruitType,
    required this.variety, // ✅ Added
    required this.areaSize, // ✅ String
    required this.areaUnit, // ✅ Added
    required this.totalTrees,
    required this.treeAge, // ✅ Added
    required this.soilType, // ✅ Added
    required this.imageUrls,
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
      'variety': variety, // ✅ Added
      'areaSize': areaSize, // ✅ String saved
      'areaUnit': areaUnit, // ✅ Added
      'totalTrees': totalTrees,
      'treeAge': treeAge, // ✅ Added
      'soilType': soilType, // ✅ Added
      'imageUrls': imageUrls,
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
      variety: map['variety'] ?? '', // ✅ Added
      areaSize: map['areaSize']?.toString() ?? '0', // ✅ Convert to String
      areaUnit: map['areaUnit'] ?? 'Acre', // ✅ Added
      totalTrees: map['totalTrees'] ?? 0,
      treeAge: map['treeAge'] ?? 0, // ✅ Added
      soilType: map['soilType'] ?? '', // ✅ Added
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
