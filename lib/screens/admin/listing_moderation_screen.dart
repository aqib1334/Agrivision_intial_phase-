// lib/screens/admin/listing_moderation_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin/admin_service.dart';
import '../../models/listing_model.dart'; // Make sure this import exists

class ListingModerationScreen extends StatelessWidget {
  const ListingModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminService adminService = AdminService();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Listing Moderation',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<ListingModel>>( // Changed from QuerySnapshot to List<ListingModel>
              stream: adminService.getAllListings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No listings found'));
                }

                final listings = snapshot.data!;

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    final imageUrl = listing.imageUrls.isNotEmpty ? listing.imageUrls[0] : null;

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: imageUrl != null
                                ? Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover)
                                : Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(listing.orchardName, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('PKR ${listing.totalPrice}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      bool? confirm = await showDialog(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text("Delete Listing?"),
                                          content: const Text("Are you sure you want to remove this listing?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                          ],
                                        )
                                      );
                                      if (confirm == true) {
                                        await adminService.deleteListing(listing.id);
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text("Remove Listing"),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}