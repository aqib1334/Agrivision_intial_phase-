// lib/services/farmer/listing_service.dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/listing_model.dart';
import '../../models/orchard_model.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ UPDATED: Create or Update Listing (NOW WITH FULL ORCHARD SUPPORT)
  Future<void> saveListing({
    String? id,
    required String orchardId,
    required String orchardName,
    required String fruitType,
    required String listingType, // ✅ "produce" or "full_orchard"
    required double quantity,
    required String unit,
    required double pricePerUnit,
    required String description,
    required List<XFile> newImages,
    List<String>? existingImageUrls,
    String? location,
    DateTime? expiryDate,
    // ✅ NEW: Full Orchard Fields
    int? totalTrees,
    String? areaSize, // ✅ CHANGED TO STRING
    String? orchardCondition,
    String? harvestSeason,
    int? expectedYield,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      String listingId = id ?? const Uuid().v4();
      List<String> finalImageUrls = existingImageUrls ?? [];

      // Upload new images to Firebase Storage
      for (var image in newImages) {
        String imgId = const Uuid().v4();
        final ref = _storage
            .ref()
            .child('listing_images')
            .child('${user.uid}/$listingId/$imgId.jpg');

        Uint8List imageBytes = await image.readAsBytes();
        await ref.putData(
          imageBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        String url = await ref.getDownloadURL();
        finalImageUrls.add(url);
      }

      // Calculate total price
      double totalPrice = quantity * pricePerUnit;

      // Create listing object
      ListingModel listing = ListingModel(
        id: listingId,
        orchardId: orchardId,
        farmerId: user.uid,
        orchardName: orchardName,
        fruitType: fruitType,
        listingType: listingType,
        quantity: quantity,
        unit: unit,
        pricePerUnit: pricePerUnit,
        totalPrice: totalPrice,
        totalTrees: totalTrees,
        areaSize: areaSize, // ✅ NOW STRING
        orchardCondition: orchardCondition,
        harvestSeason: harvestSeason,
        expectedYield: expectedYield,
        imageUrls: finalImageUrls,
        description: description,
        status: 'available',
        createdAt: id == null ? DateTime.now() : DateTime.now(),
        updatedAt: DateTime.now(),
        location: location,
        expiryDate: expiryDate,
      );

      // Save to Firestore
      await _firestore
          .collection('Orchard_Listings')
          .doc(listingId)
          .set(listing.toMap());
      
      await _updateProfileStats();
    } catch (e) {
      throw Exception("Failed to save listing: $e");
    }
  }

  // ✅ FIXED: Quick Create FULL ORCHARD Listing
  Future<void> createFullOrchardListing({
    required OrchardModel orchard,
    required double totalPrice,
    required String description,
    required List<XFile> images,
    String? orchardCondition,
    String? harvestSeason,
    int? expectedYield,
    DateTime? expiryDate,
  }) async {
    await saveListing(
      orchardId: orchard.id,
      orchardName: orchard.name,
      fruitType: orchard.fruitType,
      listingType: 'full_orchard',
      quantity: 1,
      unit: 'orchard',
      pricePerUnit: totalPrice,
      description: description,
      newImages: images,
      location: orchard.location,
      totalTrees: orchard.totalTrees,
      areaSize: orchard.areaSize, // ✅ NOW STRING - NO ERROR!
      orchardCondition: orchardCondition,
      harvestSeason: harvestSeason,
      expectedYield: expectedYield,
      expiryDate: expiryDate,
    );
  }

  // Get All Listings for Current Farmer
  Stream<List<ListingModel>> getMyListings() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('Orchard_Listings')
        .where('farmerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ListingModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get Listings for Specific Orchard
  Stream<List<ListingModel>> getListingsByOrchard(String orchardId) {
    return _firestore
        .collection('Orchard_Listings')
        .where('orchardId', isEqualTo: orchardId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ListingModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get Single Listing by ID
  Future<ListingModel?> getListingById(String listingId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('Orchard_Listings')
          .doc(listingId)
          .get();

      if (doc.exists) {
        return ListingModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception("Failed to fetch listing: $e");
    }
  }

  // Update Listing Status
  Future<void> updateListingStatus(String listingId, String status) async {
    try {
      await _firestore.collection('Orchard_Listings').doc(listingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await _updateProfileStats();
    } catch (e) {
      throw Exception("Failed to update status: $e");
    }
  }

  // Delete Listing
  Future<void> deleteListing(String listingId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('Orchard_Listings')
          .doc(listingId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        List<String> imageUrls = List<String>.from(data['imageUrls'] ?? []);

        for (String url in imageUrls) {
          try {
            await _storage.refFromURL(url).delete();
          } catch (e) {
            print('Failed to delete image: $e');
          }
        }
      }

      await _firestore.collection('Orchard_Listings').doc(listingId).delete();
      await _updateProfileStats();
    } catch (e) {
      throw Exception("Failed to delete listing: $e");
    }
  }

  // ✅ NEW: Get active listings for a specific orchard
  Future<List<ListingModel>> getActiveListingsByOrchard(
    String orchardId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Orchard_Listings')
          .where('orchardId', isEqualTo: orchardId)
          .where('status', isEqualTo: 'available')
          .get();

      List<ListingModel> listings = [];

      for (var doc in snapshot.docs) {
        ListingModel listing = ListingModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // Check if not expired
        if (!listing.isExpired) {
          listings.add(listing);
        }
      }

      return listings;
    } catch (e) {
      throw Exception("Failed to fetch active listings: $e");
    }
  }

  // Get Available Listings Count for Dashboard
  Future<int> getActiveListingsCount() async {
    User? user = _auth.currentUser;
    if (user == null) return 0;

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Orchard_Listings')
          .where('farmerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'available')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
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