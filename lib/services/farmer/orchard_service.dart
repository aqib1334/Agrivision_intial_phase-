// lib/services/farmer/orchard_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/orchard_model.dart';
import '../cloudinary_service.dart';

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
    required String areaUnit, // ✅ Added
    required String fruitType,
    required String variety, // ✅ Added
    required int totalTrees,
    required int treeAge, // ✅ Added
    required String soilType, // ✅ Added
    required String description,
    required List<XFile> newImages,
    List<String>? existingImageUrls,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      String orchardId = id ?? const Uuid().v4();
      List<String> finalImageUrls = existingImageUrls ?? [];

      // Upload New Images via Cloudinary (XFile works on web + mobile)
      for (var image in newImages) {
        String? url = await CloudinaryService.uploadImage(image);
        if (url != null) {
          finalImageUrls.add(url);
        }
      }

      OrchardModel orchard = OrchardModel(
        id: orchardId,
        farmerId: user.uid,
        name: name,
        location: location,
        fruitType: fruitType,
        variety: variety, // ✅ Added
        areaSize: area, // ✅ Now accepts String
        areaUnit: areaUnit, // ✅ Added
        totalTrees: totalTrees,
        treeAge: treeAge, // ✅ Added
        soilType: soilType, // ✅ Added
        imageUrls: finalImageUrls,
        description: description,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('orchards')
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
        .collection('Users')
        .doc(user.uid)
        .collection('orchards')
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
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('orchards')
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
      User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // STEP 1: Check orchard images
      DocumentSnapshot orchardDoc = await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('orchards')
          .doc(orchardId)
          .get();

      if (orchardDoc.exists) {
        final orchardData = orchardDoc.data() as Map<String, dynamic>;
        List<String> imageUrls = List<String>.from(orchardData['imageUrls'] ?? []);

        // Delete orchard images (Only if they are Firebase Storage URLs)
        for (String url in imageUrls) {
          try {
            if (url.contains('firebasestorage')) {
              await _storage.refFromURL(url).delete();
            }
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
      await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('orchards')
          .doc(orchardId).delete();
      
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
          .collection('Users')
          .doc(user.uid)
          .collection('orchards')
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