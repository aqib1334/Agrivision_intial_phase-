// lib/models/listing_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String id;
  final String orchardId;
  final String farmerId;
  final String orchardName;
  final String fruitType;
  
  // ✅ NEW: Listing Type (produce vs full orchard)
  final String listingType; // "produce" or "full_orchard"
  
  // Original fields (for produce)
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final double totalPrice;
  
  // ✅ NEW: Full Orchard Specific Fields
  final int? totalTrees; // Number of trees in orchard
  final String? areaSize; // ✅ CHANGED FROM double? TO String?
  final String? orchardCondition; // "excellent", "good", "fair"
  final String? harvestSeason; // "Summer 2025", "Winter 2025"
  final int? expectedYield; // Expected yield in kg/tons
  
  final List<String> imageUrls;
  final String description;
  final String status; // "available", "sold", "unavailable"
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? location;
  final DateTime? expiryDate;

  ListingModel({
    required this.id,
    required this.orchardId,
    required this.farmerId,
    required this.orchardName,
    required this.fruitType,
    required this.listingType,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.totalPrice,
    this.totalTrees,
    this.areaSize, // ✅ NOW STRING
    this.orchardCondition,
    this.harvestSeason,
    this.expectedYield,
    required this.imageUrls,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.expiryDate,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orchardId': orchardId,
      'farmerId': farmerId,
      'orchardName': orchardName,
      'fruitType': fruitType,
      'listingType': listingType,
      'quantity': quantity,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'totalPrice': totalPrice,
      'totalTrees': totalTrees,
      'areaSize': areaSize, // ✅ NOW STRING
      'orchardCondition': orchardCondition,
      'harvestSeason': harvestSeason,
      'expectedYield': expectedYield,
      'imageUrls': imageUrls,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'location': location,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
    };
  }

  // Create from Firebase Document
  factory ListingModel.fromMap(Map<String, dynamic> map, String docId) {
    return ListingModel(
      id: docId,
      orchardId: map['orchardId'] ?? '',
      farmerId: map['farmerId'] ?? '',
      orchardName: map['orchardName'] ?? '',
      fruitType: map['fruitType'] ?? '',
      listingType: map['listingType'] ?? 'produce',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'kg',
      pricePerUnit: (map['pricePerUnit'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      totalTrees: map['totalTrees'],
      areaSize: map['areaSize']?.toString(), // ✅ CONVERT TO STRING
      orchardCondition: map['orchardCondition'],
      harvestSeason: map['harvestSeason'],
      expectedYield: map['expectedYield'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      description: map['description'] ?? '',
      status: map['status'] ?? 'available',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: map['location'],
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
    );
  }

  // ✅ Check if listing is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  // ✅ Get effective status (auto-expire)
  String get effectiveStatus {
    if (status == 'sold') return 'sold';
    if (isExpired) return 'unavailable';
    return status;
  }

  // ✅ Check if this is a full orchard listing
  bool get isFullOrchard => listingType == 'full_orchard';

  // Helper: Calculate total price
  static double calculateTotalPrice(double quantity, double pricePerUnit) {
    return quantity * pricePerUnit;
  }

  // Copy with method for updates
  ListingModel copyWith({
    String? id,
    String? orchardId,
    String? farmerId,
    String? orchardName,
    String? fruitType,
    String? listingType,
    double? quantity,
    String? unit,
    double? pricePerUnit,
    double? totalPrice,
    int? totalTrees,
    String? areaSize, // ✅ NOW STRING
    String? orchardCondition,
    String? harvestSeason,
    int? expectedYield,
    List<String>? imageUrls,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? location,
    DateTime? expiryDate,
  }) {
    return ListingModel(
      id: id ?? this.id,
      orchardId: orchardId ?? this.orchardId,
      farmerId: farmerId ?? this.farmerId,
      orchardName: orchardName ?? this.orchardName,
      fruitType: fruitType ?? this.fruitType,
      listingType: listingType ?? this.listingType,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalPrice: totalPrice ?? this.totalPrice,
      totalTrees: totalTrees ?? this.totalTrees,
      areaSize: areaSize ?? this.areaSize, // ✅ NOW STRING
      orchardCondition: orchardCondition ?? this.orchardCondition,
      harvestSeason: harvestSeason ?? this.harvestSeason,
      expectedYield: expectedYield ?? this.expectedYield,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}
