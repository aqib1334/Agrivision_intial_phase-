// screens/farmer/orchards/my_orchards_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import '../../../models/orchard_model.dart';
import '../../../services/farmer/orchard_service.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../../../widgets/common/empty_state_widget.dart';
import 'add_orchard_screen.dart';
import 'orchard_detail_screen.dart';
import '../../dashboards/farmer_home_screen.dart'; // ✅ ADDED

class MyOrchardsScreen extends StatelessWidget {
  const MyOrchardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final OrchardService orchardService = OrchardService();

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green.shade700,
        // ✅ FIXED: Custom back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const FarmerHomeScreen()),
              (route) => false, // Remove all previous routes
            );
          },
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFE8F5E9)],
          ).createShader(bounds),
          child: const Text(
            "My Orchards",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade800, Colors.green.shade600],
            ),
          ),
        ),
      ),
      floatingActionButton: FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddOrchardScreen(),
              ),
            );
          },
          label: const Text(
            "Add Orchard",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
          icon: const Icon(Iconsax.add, size: 20),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
      ),
      body: StreamBuilder<List<OrchardModel>>(
        stream: orchardService.getMyOrchards(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: LoadingIndicator(message: "Loading orchards..."),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.danger,
                    size: 60,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return FadeIn(
              duration: const Duration(milliseconds: 800),
              child: Center(
                child: EmptyStateWidget(
                  icon: Iconsax.tree,
                  title: "No Orchards Found",
                  message: "Add your first orchard to start managing crops.",
                  actionText: "Add Now",
                  onAction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddOrchardScreen(),
                      ),
                    );
                  },
                ),
              ),
            );
          }

          // List of Orchards with Animations
          final orchards = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orchards.length,
            itemBuilder: (context, index) {
              final orchard = orchards[index];
              String? thumbnailImage;
              if (orchard.imageUrls.isNotEmpty) {
                thumbnailImage = orchard.imageUrls.first;
              }

              return FadeInUp(
                duration: Duration(milliseconds: 400 + (index * 100)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _EnhancedOrchardCard(
                    orchard: orchard,
                    thumbnailImage: thumbnailImage,
                    index: index,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ✨ Enhanced Orchard Card Widget
class _EnhancedOrchardCard extends StatelessWidget {
  final OrchardModel orchard;
  final String? thumbnailImage;
  final int index;

  const _EnhancedOrchardCard({
    required this.orchard,
    required this.thumbnailImage,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrchardDetailScreen(orchard: orchard),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade100.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: thumbnailImage != null && thumbnailImage!.isNotEmpty
                  ? Image.network(
                      thumbnailImage!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.green.shade700,
                            ),
                          ),
                        );
                      },
                    )
                  : _buildPlaceholderImage(),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Orchard Name
                  Text(
                    orchard.name.isNotEmpty
                        ? orchard.name
                        : "Orchard ${index + 1}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Iconsax.location,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          orchard.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatChip(
                        Iconsax.ruler,
                        "${orchard.areaSize}", // ✅ Display string as-is
                        Colors.blue.shade50,
                        Colors.blue.shade700,
                      ),
                      const SizedBox(width: 10),
                      _buildStatChip(
                        Iconsax.tree,
                        "${orchard.totalTrees} trees",
                        Colors.green.shade50,
                        Colors.green.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fruit Type Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      orchard.fruitType,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.green.shade50],
        ),
      ),
      child: Center(
        child: Icon(
          Iconsax.tree,
          size: 60,
          color: Colors.green.shade400,
        ),
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String text,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
