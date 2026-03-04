import 'package:cloud_firestore/cloud_firestore.dart';

class DataMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> migrateOldOrchards() async {
    print('🚀 Starting migration of old orchards...');
    
    try {
      // 1. Get all documents from the old root "Orchards" collection
      final oldOrchardsSnapshot = await _firestore.collection('Orchards').get();
      print('📦 Found ${oldOrchardsSnapshot.docs.length} old orchards to migrate.');

      int successCount = 0;
      int errorCount = 0;

      // 2. Loop through each old orchard document
      for (var doc in oldOrchardsSnapshot.docs) {
        try {
          final data = doc.data();
          final String orchardId = doc.id;
          final String farmerId = data['farmerId'] ?? '';

          if (farmerId.isEmpty) {
            print('⚠️ Skipping orchard $orchardId because farmerId is missing.');
            errorCount++;
            continue;
          }

          // 3. Add the missing new fields (variety and soilType) with default values if they don't exist
          data['variety'] = data.containsKey('variety') ? data['variety'] : '';
          data['soilType'] = data.containsKey('soilType') ? data['soilType'] : '';

          // Ensure areaSize is saved as a String
          if (data.containsKey('areaSize') && data['areaSize'] != null) {
              data['areaSize'] = data['areaSize'].toString();
          }

          // 4. Save the upgraded document to the new subcollection
          await _firestore
              .collection('Users')
              .doc(farmerId)
              .collection('orchards')
              .doc(orchardId)
              .set(data);

          // 5. (Optional but Recommended) Delete the old document from root "Orchards"
          // uncomment the next line to delete the old documents after copying them
          // await doc.reference.delete();

          print('✅ Migrated orchard: $orchardId for farmer: $farmerId');
          successCount++;
        } catch (e) {
          print('❌ Error migrating orchard ${doc.id}: $e');
          errorCount++;
        }
      }

      print('🎉 Migration Complete!');
      print('✅ Successfully migrated: $successCount');
      if (errorCount > 0) {
        print('⚠️ Failed to migrate: $errorCount');
      }

    } catch (e) {
      print('🛑 Critical error during migration: $e');
    }
  }
}
