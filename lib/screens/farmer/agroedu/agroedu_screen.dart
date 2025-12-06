// lib/screens/farmer/agroedu/agroedu_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

class AgroEduScreen extends StatefulWidget {
  const AgroEduScreen({super.key});

  @override
  State<AgroEduScreen> createState() => _AgroEduScreenState();
}

class _AgroEduScreenState extends State<AgroEduScreen> {
  // Color Scheme
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryMain = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color primaryPale = Color(0xFFE8F5E9);
  static const Color accentOrange = Color(0xFFF57C00);
  static const Color textHeading = Color(0xDE000000);
  static const Color textBody = Color(0xFF616161);
  static const Color borderNormal = Color(0xFFE0E0E0);
  static const Color warningRed = Color(0xFFD32F2F);
  static const Color statusInfo = Color(0xFF1976D2);

  int _selectedCategory = 0;

  final List<Map<String, dynamic>> categories = [
    {
      'title': 'Disease Management',
      'icon': Iconsax.health,
      'color': Color(0xFFE53935),
    },
    {
      'title': 'Spray Guidelines',
      'icon': Iconsax.colorfilter,
      'color': statusInfo,
    },
    {
      'title': 'Safety Tips',
      'icon': Iconsax.shield_tick,
      'color': accentOrange,
    },
    {
      'title': 'Best Practices',
      'icon': Iconsax.star,
      'color': primaryMain,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryPale,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryMain,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AgroEdu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDark, primaryMain, primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Category Tabs
          _buildCategoryTabs(),
          
          // Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 100,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == index;
          
          return FadeInDown(
            delay: Duration(milliseconds: 100 * index),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = index),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [category['color'], category['color'].withOpacity(0.7)],
                        )
                      : null,
                  color: isSelected ? null : primaryPale,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? category['color'] : borderNormal,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'],
                      color: isSelected ? Colors.white : textBody,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category['title'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : textBody,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedCategory) {
      case 0:
        return _buildDiseaseManagement();
      case 1:
        return _buildSprayGuidelines();
      case 2:
        return _buildSafetyTips();
      case 3:
        return _buildBestPractices();
      default:
        return const SizedBox();
    }
  }

  // ===================== DISEASE MANAGEMENT =====================
  Widget _buildDiseaseManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInLeft(
          child: _buildSectionTitle('Common Citrus Diseases', Iconsax.health),
        ),
        const SizedBox(height: 16),
        
        _buildDiseaseCard(
          name: 'Citrus Canker',
          symptoms: 'Raised brown spots on leaves, fruits, and stems with yellow halos',
          causes: 'Bacterial infection (Xanthomonas citri)',
          treatment: 'Remove infected parts, apply copper-based fungicides',
          prevention: 'Use disease-free plants, maintain proper spacing',
          imagePath: 'assets/images/citrus_canker.png',
        ),
        
        _buildDiseaseCard(
          name: 'Black Spot',
          symptoms: 'Dark black/brown spots on fruits and leaves',
          causes: 'Fungal infection in humid conditions',
          treatment: 'Apply fungicides like Mancozeb or Copper oxychloride',
          prevention: 'Improve air circulation, avoid overhead watering',
          imagePath: 'assets/images/black_spot.png',
        ),
        
        _buildDiseaseCard(
          name: 'Citrus Greening (HLB)',
          symptoms: 'Yellow shoots, blotchy mottling, small misshapen fruits',
          causes: 'Bacterial disease spread by Asian citrus psyllid',
          treatment: 'No cure - remove infected trees immediately',
          prevention: 'Control psyllid population, use certified disease-free plants',
          imagePath: 'assets/images/greening.png',
        ),
      ],
    );
  }

  Widget _buildDiseaseCard({
    required String name,
    required String symptoms,
    required String causes,
    required String treatment,
    required String prevention,
    required String imagePath,
  }) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disease Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                imagePath,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: primaryPale,
                  child: const Icon(Iconsax.gallery, size: 60, color: primaryMain),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textHeading,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildInfoRow(Iconsax.eye, 'Symptoms', symptoms, warningRed),
                  const Divider(height: 24),
                  
                  _buildInfoRow(Iconsax.danger, 'Causes', causes, accentOrange),
                  const Divider(height: 24),
                  
                  _buildInfoRow(Iconsax.health, 'Treatment', treatment, primaryMain),
                  const Divider(height: 24),
                  
                  _buildInfoRow(Iconsax.shield_tick, 'Prevention', prevention, statusInfo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== SPRAY GUIDELINES =====================
  Widget _buildSprayGuidelines() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInLeft(
          child: _buildSectionTitle('Proper Spray Application', Iconsax.colorfilter),
        ),
        const SizedBox(height: 16),
        
        _buildGuidelineCard(
          title: 'When to Spray',
          icon: Iconsax.clock,
          color: statusInfo,
          steps: [
            'Early morning (6-9 AM) or late evening (4-7 PM)',
            'Avoid spraying during windy conditions (>10 km/h)',
            'No rain expected within 24 hours',
            'Temperature should be below 30°C',
            'Spray when first symptoms appear',
          ],
        ),
        
        _buildGuidelineCard(
          title: 'How to Spray',
          icon: Iconsax.setting_2,
          color: primaryMain,
          steps: [
            'Wear protective equipment (mask, gloves, full clothes)',
            'Mix chemicals as per label instructions',
            'Use clean water (filtered if possible)',
            'Spray uniformly covering both leaf surfaces',
            'Maintain proper nozzle distance (30-40 cm)',
            'Spray until leaves are wet but not dripping',
          ],
        ),
        
        _buildGuidelineCard(
          title: 'Common Fungicides',
          icon: Iconsax.health,
          color: accentOrange,
          steps: [
            'Copper Oxychloride: 3g per liter',
            'Mancozeb: 2.5g per liter',
            'Carbendazim: 1g per liter',
            'Bordeaux mixture: 1% solution',
            'Repeat spray after 15-20 days',
          ],
        ),
        
        _buildGuidelineCard(
          title: 'Equipment Care',
          icon: Iconsax.car,
          color: Color(0xFF7B1FA2),
          steps: [
            'Clean sprayer thoroughly after each use',
            'Check nozzles for blockage regularly',
            'Store in cool, dry place',
            'Calibrate sprayer before use',
            'Replace worn-out parts immediately',
          ],
        ),
      ],
    );
  }

  Widget _buildGuidelineCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> steps,
  }) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textHeading,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textBody,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ===================== SAFETY TIPS =====================
  Widget _buildSafetyTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInLeft(
          child: _buildSectionTitle('Safety Precautions', Iconsax.shield_tick),
        ),
        const SizedBox(height: 16),
        
        _buildSafetyCard(
          title: 'Personal Protection',
          icon: Iconsax.user,
          color: warningRed,
          tips: [
            'Always wear protective mask covering nose and mouth',
            'Use chemical-resistant gloves',
            'Wear full-sleeve clothes and long pants',
            'Use safety goggles to protect eyes',
            'Wear boots to protect feet',
            'Take bath immediately after spraying',
          ],
        ),
        
        _buildSafetyCard(
          title: 'Chemical Handling',
          icon: Iconsax.danger,
          color: accentOrange,
          tips: [
            'Store chemicals in original containers',
            'Keep away from children and pets',
            'Never eat, drink or smoke while handling',
            'Read label instructions carefully',
            'Mix in well-ventilated area',
            'Dispose of empty containers safely',
          ],
        ),
        
        _buildSafetyCard(
          title: 'Emergency Response',
          icon: Iconsax.heart,
          color: Color(0xFFE53935),
          tips: [
            'In case of skin contact: wash with soap and water',
            'If swallowed: drink plenty of water, seek medical help',
            'Eye contact: rinse with clean water for 15 minutes',
            'Breathing problems: move to fresh air immediately',
            'Keep emergency numbers handy',
            'Know location of nearest hospital',
          ],
        ),
        
        _buildSafetyCard(
          title: 'Environmental Care',
          icon: Iconsax.tree,
          color: primaryMain,
          tips: [
            'Avoid spraying near water sources',
            'Do not spray on windy days',
            'Keep animals away from sprayed area',
            'Wait 7-10 days before harvesting',
            'Do not spray during flowering period',
            'Dispose chemical waste properly',
          ],
        ),
      ],
    );
  }

  Widget _buildSafetyCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> tips,
  }) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: tips.map((tip) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Iconsax.tick_circle,
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(
                              fontSize: 14,
                              color: textBody,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== BEST PRACTICES =====================
  Widget _buildBestPractices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInLeft(
          child: _buildSectionTitle('Orchard Best Practices', Iconsax.star),
        ),
        const SizedBox(height: 16),
        
        _buildPracticeCard(
          title: 'Regular Monitoring',
          icon: Iconsax.search_normal,
          color: statusInfo,
          description: 'Inspect your orchard at least twice a week for early disease detection',
          practices: [
            'Check both sides of leaves',
            'Look for unusual spots or discoloration',
            'Monitor fruit development',
            'Keep records of observations',
          ],
        ),
        
        _buildPracticeCard(
          title: 'Proper Irrigation',
          icon: Iconsax.drop,
          color: Color(0xFF1976D2),
          description: 'Water management is crucial for disease prevention',
          practices: [
            'Water early morning or evening',
            'Avoid overhead irrigation',
            'Ensure proper drainage',
            'Adjust watering based on season',
          ],
        ),
        
        _buildPracticeCard(
          title: 'Nutrition Management',
          icon: Iconsax.activity,
          color: primaryMain,
          description: 'Healthy trees are more resistant to diseases',
          practices: [
            'Apply balanced fertilizers regularly',
            'Use organic matter to improve soil',
            'Monitor leaf color for deficiencies',
            'Conduct soil testing annually',
          ],
        ),
        
        _buildPracticeCard(
          title: 'Pruning & Sanitation',
          icon: Iconsax.scissor,
          color: accentOrange,
          description: 'Keep orchard clean and well-maintained',
          practices: [
            'Remove dead and diseased branches',
            'Prune to improve air circulation',
            'Clean fallen leaves regularly',
            'Disinfect pruning tools',
          ],
        ),
        
        _buildPracticeCard(
          title: 'Integrated Pest Management',
          icon: Iconsax.security,
          color: Color(0xFF7B1FA2),
          description: 'Combine multiple strategies for effective control',
          practices: [
            'Use biological control agents',
            'Plant disease-resistant varieties',
            'Rotate chemical sprays',
            'Maintain beneficial insects',
          ],
        ),
      ],
    );
  }

  Widget _buildPracticeCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required List<String> practices,
  }) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textHeading,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: textBody,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            ...practices.map((practice) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        practice,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textBody,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ===================== HELPER WIDGETS =====================
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryMain.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryMain, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textHeading,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: textBody,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}