// ========================================
// FILE 1: lib/services/buyer/order_request_service.dart
// ========================================
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/order_request_model.dart';
import '../../models/listing_model.dart';

class OrderRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if buyer already requested this listing
  Future<bool> hasRequestedListing(String listingId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final query = await _firestore
        .collection('Order_Requests')
        .where('buyerId', isEqualTo: user.uid)
        .where('listingId', isEqualTo: listingId)
        .where('status', isNotEqualTo: 'cancelled')
        .get();

    return query.docs.isNotEmpty;
  }

  // Get Requests for FARMER (Orders received)
  Stream<List<OrderRequestModel>> getFarmerRequests() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('Order_Requests')
        .where('farmerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderRequestModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get Requests for BUYER (My Orders)
  Stream<List<OrderRequestModel>> getBuyerRequests() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('Order_Requests')
        .where('buyerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderRequestModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Create New Request
  Future<void> createOrderRequest({
    required ListingModel listing,
    required String buyerName,
    required String buyerPhone,
    required String buyerEmail,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final order = OrderRequestModel(
      id: '',
      listingId: listing.id,
      orchardId: listing.orchardId,
      farmerId: listing.farmerId,
      buyerId: user.uid,
      orchardName: listing.orchardName,
      fruitType: listing.fruitType,
      quantity: listing.quantity,
      unit: listing.unit,
      pricePerUnit: listing.pricePerUnit,
      totalPrice: listing.totalPrice,
      listingImageUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerEmail: buyerEmail,
      message: message,
      status: 'pending',
      createdAt: DateTime.now(),
      payments: [],
      totalPaidAmount: 0.0,
      remainingAmount: listing.totalPrice,
    );

    await _firestore.collection('Order_Requests').add(order.toMap());
  }

  // Confirm Order (Farmer)
  Future<void> confirmOrder({required String requestId, String? farmerResponse}) async {
    await _firestore.collection('Order_Requests').doc(requestId).update({
      'status': 'confirmed',
      'confirmedAt': FieldValue.serverTimestamp(),
      if (farmerResponse != null) 'farmerResponse': farmerResponse,
    });
  }

  // Reject Order (Farmer)
  Future<void> rejectOrder({required String requestId, String? rejectionReason}) async {
    await _firestore.collection('Order_Requests').doc(requestId).update({
      'status': 'rejected',
      'farmerResponse': rejectionReason,
    });
  }

  // Add Payment (Both Buyer & Farmer)
  Future<void> addPayment({
    required String requestId,
    required double amount,
    required String paymentType,
    required String paymentMethod,
    required String recordedBy,
    required String recordedByName,
    String? buyerName,
    XFile? proofImage,
    String? notes,
  }) async {
    String? proofUrl;

    if (proofImage != null) {
      String fileName = 'payment_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child('payment_proofs/$requestId/$fileName');
      await ref.putFile(File(proofImage.path));
      proofUrl = await ref.getDownloadURL();
    }

    final paymentRecord = PaymentRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      paymentType: paymentType,
      paymentMethod: paymentMethod,
      proofImageUrl: proofUrl,
      paidAt: DateTime.now(),
      recordedBy: recordedBy,
      recordedByName: recordedByName,
      notes: notes,
    );

    DocumentReference docRef = _firestore.collection('Order_Requests').doc(requestId);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      double currentPaid = (data['totalPaidAmount'] ?? 0).toDouble();
      double totalOrderPrice = (data['totalPrice'] ?? 0).toDouble();
      
      double newTotalPaid = currentPaid + amount;
      double newRemaining = totalOrderPrice - newTotalPaid;

      String currentStatus = data['status'];
      String newStatus = currentStatus;
      
      if (currentStatus == 'confirmed') {
        newStatus = 'payment_pending';
      }

      transaction.update(docRef, {
        'status': newStatus,
        'payments': FieldValue.arrayUnion([paymentRecord.toMap()]),
        'totalPaidAmount': newTotalPaid,
        'remainingAmount': newRemaining,
      });
    });
  }

  // ✅ CRITICAL FIX: Complete Order - Marks Listing as SOLD
  Future<void> completeOrder({required String requestId}) async {
    try {
      DocumentSnapshot orderDoc = await _firestore
          .collection('Order_Requests')
          .doc(requestId)
          .get();
      
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
      String listingId = orderData['listingId'] ?? '';

      // Update order status to completed
      await _firestore.collection('Order_Requests').doc(requestId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // ✅ CRITICAL: Mark listing as SOLD
      if (listingId.isNotEmpty) {
        await _firestore.collection('Orchard_Listings').doc(listingId).update({
          'status': 'sold',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to complete order: $e');
    }
  }

  // Cancel Request (Buyer)
  Future<void> cancelRequest(String requestId) async {
    await _firestore.collection('Order_Requests').doc(requestId).update({
      'status': 'cancelled',
    });
  }
}