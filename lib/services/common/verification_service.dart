// ✅ COMPLETE FILE: lib/services/common/verification_service.dart
// Enhanced with getRequestsByStatus() for tab filtering

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/verification_request_model.dart';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Submit Request (TESTING MODE: Image is Optional)
  Future<void> submitVerification({
    required String cnicName,
    required String cnicNumber,
    File? cnicImage,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    String downloadUrl;

    // ✅ If image exists, upload; otherwise use dummy URL
    if (cnicImage != null) {
      String fileName = 'cnic_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child('verification_docs/$fileName');
      await ref.putFile(cnicImage);
      downloadUrl = await ref.getDownloadURL();
    } else {
      // 🛠️ DUMMY IMAGE FOR TESTING
      downloadUrl = "https://via.placeholder.com/300x200.png?text=No+Image+Provided";
    }

    // Get User Data
    DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    // Create Request
    String requestId = _firestore.collection('Verification_Requests').doc().id;
    VerificationRequestModel request = VerificationRequestModel(
      id: requestId,
      userId: user.uid,
      userName: userData['name'] ?? 'Unknown',
      userEmail: userData['email'] ?? '',
      userRole: userData['role'] ?? 'user',
      cnicName: cnicName,
      cnicNumber: cnicNumber,
      cnicImageUrl: downloadUrl,
      status: 'pending',
      submittedAt: DateTime.now(),
    );

    // Batch Write
    WriteBatch batch = _firestore.batch();
    batch.set(_firestore.collection('Verification_Requests').doc(requestId), request.toMap());
    
    // Update User Status
    batch.update(_firestore.collection('Users').doc(user.uid), {
      'verificationStatus': 'pending_approval',
    });
    
    await batch.commit();
  }

  // 2. Admin: Get Pending Requests (Legacy - Keep for backward compatibility)
  Stream<List<VerificationRequestModel>> getPendingRequests() {
    return getRequestsByStatus('pending');
  }

  // ✅ NEW: Get Requests by Status (pending, approved, rejected)
  Stream<List<VerificationRequestModel>> getRequestsByStatus(String status) {
    return _firestore
        .collection('Verification_Requests')
        .where('status', isEqualTo: status)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VerificationRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 3. Admin: Approve Request
  Future<void> approveRequest(String requestId, String userId) async {
    WriteBatch batch = _firestore.batch();
    
    // Update request status
    batch.update(
      _firestore.collection('Verification_Requests').doc(requestId),
      {
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(), // Track when it was reviewed
      },
    );
    
    // Update user verification status
    batch.update(
      _firestore.collection('Users').doc(userId),
      {'verificationStatus': 'verified'},
    );
    
    await batch.commit();
  }

  // 4. Admin: Reject Request
  Future<void> rejectRequest(String requestId, String userId) async {
    WriteBatch batch = _firestore.batch();
    
    // Update request status
    batch.update(
      _firestore.collection('Verification_Requests').doc(requestId),
      {
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(), // Track when it was reviewed
      },
    );
    
    // Update user verification status
    batch.update(
      _firestore.collection('Users').doc(userId),
      {'verificationStatus': 'rejected'},
    );
    
    await batch.commit();
  }

  // 5. Check Current User Status
  Future<String> getCurrentUserStatus() async {
    User? user = _auth.currentUser;
    if (user == null) return 'unverified';
    
    DocumentSnapshot doc = await _firestore.collection('Users').doc(user.uid).get();
    
    if (!doc.exists) return 'unverified';
    
    return (doc.data() as Map<String, dynamic>)['verificationStatus'] ?? 'unverified';
  }

  // ✅ NEW: Get All Requests (for admin analytics)
  Stream<List<VerificationRequestModel>> getAllRequests() {
    return _firestore
        .collection('Verification_Requests')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VerificationRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ✅ NEW: Get User's Verification Request (for user to track their own request)
  Stream<VerificationRequestModel?> getUserVerificationRequest() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('Verification_Requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('submittedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return VerificationRequestModel.fromMap(
            snapshot.docs.first.data(),
            snapshot.docs.first.id,
          );
        });
  }

  // ✅ NEW: Delete Request (optional - for admin cleanup)
  Future<void> deleteRequest(String requestId) async {
    await _firestore.collection('Verification_Requests').doc(requestId).delete();
  }
}