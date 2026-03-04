// lib/models/disease_history_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DiseaseHistoryModel {
  final String id;
  final String farmerId;
  final String orchardId;
  final String orchardName;
  final String fruitType;
  final String imageUrl;       // local path or Firebase Storage URL
  final String diseaseName;    // e.g. "Citrus Canker", "Healthy", "Unknown"
  final String recommendation; // AI recommendation text
  final String status;         // "healthy" | "disease_detected" | "pending"
  final DateTime scannedAt;

  DiseaseHistoryModel({
    required this.id,
    required this.farmerId,
    required this.orchardId,
    required this.orchardName,
    required this.fruitType,
    required this.imageUrl,
    required this.diseaseName,
    required this.recommendation,
    required this.status,
    required this.scannedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'orchardId': orchardId,
      'orchardName': orchardName,
      'fruitType': fruitType,
      'imageUrl': imageUrl,
      'diseaseName': diseaseName,
      'recommendation': recommendation,
      'status': status,
      'scannedAt': Timestamp.fromDate(scannedAt),
    };
  }

  factory DiseaseHistoryModel.fromMap(
      Map<String, dynamic> map, String docId) {
    return DiseaseHistoryModel(
      id: docId,
      farmerId: map['farmerId'] ?? '',
      orchardId: map['orchardId'] ?? '',
      orchardName: map['orchardName'] ?? '',
      fruitType: map['fruitType'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      diseaseName: map['diseaseName'] ?? 'Unknown',
      recommendation: map['recommendation'] ?? '',
      status: map['status'] ?? 'pending',
      scannedAt: map['scannedAt'] != null
          ? (map['scannedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
