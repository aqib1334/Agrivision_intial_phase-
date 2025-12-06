// lib/models/order_request_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderRequestModel {
  final String id;
  final String listingId;
  final String orchardId;
  final String farmerId;
  final String buyerId;
  final String orchardName;
  final String fruitType;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final double totalPrice;
  final String listingImageUrl;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final String message;
  final String status; // pending, confirmed, payment_pending, completed, rejected, cancelled
  final DateTime createdAt;
  final String? deliveryAddress;
  
  // Timestamps
  final DateTime? respondedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  
  // Payment Details
  final List<PaymentRecord> payments; // List of all payments
  final double totalPaidAmount;
  final double remainingAmount;
  
  // Chat Metadata
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSender;

  // Farmer Response
  final String? farmerResponse;

  OrderRequestModel({
    required this.id,
    required this.listingId,
    required this.orchardId,
    required this.farmerId,
    required this.buyerId,
    required this.orchardName,
    required this.fruitType,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.listingImageUrl,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerEmail,
    required this.message,
    required this.status,
    required this.createdAt,
    this.deliveryAddress,
    this.respondedAt,
    this.confirmedAt,
    this.completedAt,
    this.payments = const [],
    this.totalPaidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSender,
    this.farmerResponse,
  });

  // Status Helpers
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isPaymentPending => status == 'payment_pending';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  
  bool get isActive => isPending || isConfirmed || isPaymentPending;
  bool get isFullyPaid => remainingAmount <= 0;

  double get paymentProgress => totalPrice > 0 ? (totalPaidAmount / totalPrice) : 0.0;

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'payment_pending': return 'Payment Pending';
      case 'completed': return 'Completed';
      case 'rejected': return 'Rejected';
      case 'cancelled': return 'Cancelled';
      default: return 'Unknown';
    }
  }

  // ✅ ADDED THIS MISSING METHOD
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listingId': listingId,
      'orchardId': orchardId,
      'farmerId': farmerId,
      'buyerId': buyerId,
      'orchardName': orchardName,
      'fruitType': fruitType,
      'quantity': quantity,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'totalPrice': totalPrice,
      'listingImageUrl': listingImageUrl,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerEmail': buyerEmail,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveryAddress': deliveryAddress,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'payments': payments.map((p) => p.toMap()).toList(),
      'totalPaidAmount': totalPaidAmount,
      'remainingAmount': remainingAmount,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'lastMessageSender': lastMessageSender,
      'farmerResponse': farmerResponse,
    };
  }

  factory OrderRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    List<PaymentRecord> paymentsList = [];
    if (map['payments'] != null) {
      paymentsList = (map['payments'] as List)
          .map((p) => PaymentRecord.fromMap(p as Map<String, dynamic>))
          .toList();
    }

    return OrderRequestModel(
      id: docId,
      listingId: map['listingId'] ?? '',
      orchardId: map['orchardId'] ?? '',
      farmerId: map['farmerId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      orchardName: map['orchardName'] ?? '',
      fruitType: map['fruitType'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'kg',
      pricePerUnit: (map['pricePerUnit'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      listingImageUrl: map['listingImageUrl'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      buyerEmail: map['buyerEmail'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveryAddress: map['deliveryAddress'],
      respondedAt: (map['respondedAt'] as Timestamp?)?.toDate(),
      confirmedAt: (map['confirmedAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      payments: paymentsList,
      totalPaidAmount: (map['totalPaidAmount'] ?? 0).toDouble(),
      remainingAmount: (map['remainingAmount'] ?? 0).toDouble(),
      lastMessage: map['lastMessage'],
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate(),
      lastMessageSender: map['lastMessageSender'],
      farmerResponse: map['farmerResponse'],
    );
  }
}

class PaymentRecord {
  final String id;
  final double amount;
  final String paymentType; 
  final String paymentMethod; 
  final String? proofImageUrl;
  final DateTime paidAt;
  final String recordedBy; // 'farmer' or 'buyer'
  final String recordedByName;
  final String? notes;

  PaymentRecord({
    required this.id,
    required this.amount,
    required this.paymentType,
    required this.paymentMethod,
    this.proofImageUrl,
    required this.paidAt,
    required this.recordedBy,
    required this.recordedByName,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'paymentType': paymentType,
      'paymentMethod': paymentMethod,
      'proofImageUrl': proofImageUrl,
      'paidAt': Timestamp.fromDate(paidAt),
      'recordedBy': recordedBy,
      'recordedByName': recordedByName,
      'notes': notes,
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentType: map['paymentType'] ?? 'partial',
      paymentMethod: map['paymentMethod'] ?? 'cash',
      proofImageUrl: map['proofImageUrl'],
      paidAt: (map['paidAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recordedBy: map['recordedBy'] ?? 'buyer',
      recordedByName: map['recordedByName'] ?? '',
      notes: map['notes'],
    );
  }
}


