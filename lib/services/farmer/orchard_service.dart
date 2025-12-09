// lib/services/farmer/orchard_service.dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/orchard_model.dart';

class OrchardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. ✅ FIXED: Add or Update Orchard (String area support)
  Future<void> saveOrchard({
    String? id,
    required String name,
    required String location,
    required String area, // ✅ Changed to String
    required String fruitType,
    required int totalTrees,
    required double expectedPrice,
    required String description,
    required List<XFile> newImages,
    List<String>? existingImageUrls,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      String orchardId = id ?? const Uuid().v4();
      List<String> finalImageUrls = existingImageUrls ?? [];

      // Upload New Images
      for (var image in newImages) {
        String imgId = const Uuid().v4();
        final ref = _storage
            .ref()
            .child('orchard_images')
            .child('${user.uid}/$orchardId/$imgId.jpg');

        Uint8List imageBytes = await image.readAsBytes();
        await ref.putData(
          imageBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        String url = await ref.getDownloadURL();
        finalImageUrls.add(url);
      }

      OrchardModel orchard = OrchardModel(
        id: orchardId,
        farmerId: user.uid,
        name: name,
        location: location,
        fruitType: fruitType,
        areaSize: area, // ✅ Now accepts String
        totalTrees: totalTrees,
        imageUrls: finalImageUrls,
        expectedPrice: expectedPrice,
        description: description,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('Orchards')
          .doc(orchardId)
          .set(orchard.toMap());
      
      await _updateProfileStats();
    } catch (e) {
      throw Exception("Failed to save orchard: $e");
    }
  }

  // 2. Get Orchards
  Stream<List<OrchardModel>> getMyOrchards() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('Orchards')
        .where('farmerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrchardModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // 3. Get Single Orchard by ID
  Future<OrchardModel?> getOrchardById(String orchardId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('Orchards')
          .doc(orchardId)
          .get();

      if (doc.exists) {
        return OrchardModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception("Failed to fetch orchard: $e");
    }
  }

  // 4. Delete Orchard WITH All Related Listings
  Future<void> deleteOrchard(String orchardId) async {
    try {
      // STEP 1: Delete orchard images from Storage
      DocumentSnapshot orchardDoc = await _firestore
          .collection('Orchards')
          .doc(orchardId)
          .get();

      if (orchardDoc.exists) {
        final orchardData = orchardDoc.data() as Map<String, dynamic>;
        List<String> imageUrls = List<String>.from(orchardData['imageUrls'] ?? []);

        // Delete orchard images
        for (String url in imageUrls) {
          try {
            await _storage.refFromURL(url).delete();
          } catch (e) {
            print('Failed to delete orchard image: $e');
          }
        }
      }

      // STEP 2: Get all listings related to this orchard
      QuerySnapshot listingsSnapshot = await _firestore
          .collection('Orchard_Listings')
          .where('orchardId', isEqualTo: orchardId)
          .get();

      // STEP 3: Delete each listing and its images
      for (var listingDoc in listingsSnapshot.docs) {
        final listingData = listingDoc.data() as Map<String, dynamic>;
        List<String> listingImages = List<String>.from(listingData['imageUrls'] ?? []);

        // Delete listing images from Storage
        for (String url in listingImages) {
          try {
            await _storage.refFromURL(url).delete();
          } catch (e) {
            print('Failed to delete listing image: $e');
          }
        }

        // Delete listing document
        await listingDoc.reference.delete();
      }

      // STEP 4: Delete orchard document
      await _firestore.collection('Orchards').doc(orchardId).delete();
      
      // STEP 5: Update profile stats
      await _updateProfileStats();
      
      print('✅ Orchard deleted with ${listingsSnapshot.docs.length} listings');
    } catch (e) {
      throw Exception("Failed to delete orchard: $e");
    }
  }

  // Update Profile Stats
  Future<void> _updateProfileStats() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      final orchardsCount = await _firestore
          .collection('Orchards')
          .where('farmerId', isEqualTo: user.uid)
          .get()
          .then((snapshot) => snapshot.docs.length);

      final listingsCount = await _firestore
          .collection('Orchard_Listings')
          .where('farmerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'available')
          .get()
          .then((snapshot) => snapshot.docs.length);

      await _firestore
          .collection('Farmer_Profiles')
          .doc(user.uid)
          .update({
            'totalOrchards': orchardsCount,
            'totalListings': listingsCount,
          });
    } catch (e) {
      print('Failed to update profile stats: $e');
    }
  }
}