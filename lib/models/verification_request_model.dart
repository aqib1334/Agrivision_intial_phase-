// ✅ COMPLETE FILE: lib/models/verification_request_model.dart
// Enhanced with reviewedAt timestamp

import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userRole;
  final String cnicName;
  final String cnicNumber;
  final String cnicImageUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime submittedAt;
  final DateTime? reviewedAt; // ✅ NEW: When admin reviewed it

  VerificationRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.cnicName,
    required this.cnicNumber,
    required this.cnicImageUrl,
    required this.status,
    required this.submittedAt,
    this.reviewedAt, // Optional
  });

  // Getters for convenience
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userRole': userRole,
      'cnicName': cnicName,
      'cnicNumber': cnicNumber,
      'cnicImageUrl': cnicImageUrl,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
    };
  }

  factory VerificationRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return VerificationRequestModel(
      id: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userRole: map['userRole'] ?? '',
      cnicName: map['cnicName'] ?? '',
      cnicNumber: map['cnicNumber'] ?? '',
      cnicImageUrl: map['cnicImageUrl'] ?? '',
      status: map['status'] ?? 'pending',
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      reviewedAt: map['reviewedAt'] != null 
          ? (map['reviewedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Copy with method for easy updates
  VerificationRequestModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? userRole,
    String? cnicName,
    String? cnicNumber,
    String? cnicImageUrl,
    String? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
  }) {
    return VerificationRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userRole: userRole ?? this.userRole,
      cnicName: cnicName ?? this.cnicName,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      cnicImageUrl: cnicImageUrl ?? this.cnicImageUrl,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}