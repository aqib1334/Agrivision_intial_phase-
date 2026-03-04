// lib/screens/farmer/agroscan/disease_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

import 'package:practice/models/disease_history_model.dart';

class DiseaseHistoryScreen extends StatefulWidget {
  const DiseaseHistoryScreen({super.key});

  @override
  State<DiseaseHistoryScreen> createState() => _DiseaseHistoryScreenState();
}

class _DiseaseHistoryScreenState extends State<DiseaseHistoryScreen>
    with SingleTickerProviderStateMixin {
  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color _green700 = Color(0xFF388E3C);
  static const Color _green800 = Color(0xFF2E7D32);
  static const Color _green900 = Color(0xFF1B5E20);
  static const Color _paleGreen = Color(0xFFE8F5E9);

  late TabController _tabController;
  List<DiseaseHistoryModel> _allRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      // NOTE: Using only .where() without .orderBy() to avoid requiring a
      // composite index (which causes "permission-denied" on new collections).
      // We sort the results in Dart instead.
      final snap = await FirebaseFirestore.instance
          .collection('Disease_History')
          .where('farmerId', isEqualTo: user.uid)
          .get();

      if (mounted) {
        final records = snap.docs
            .map((d) => DiseaseHistoryModel.fromMap(d.data(), d.id))
            .toList();
        // Sort by scannedAt descending in Dart
        records.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
        setState(() {
          _allRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Disease history load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ── Helper getters ──────────────────────────────────────────────────────────
  Map<String, List<DiseaseHistoryModel>> get _byOrchard {
    final map = <String, List<DiseaseHistoryModel>>{};
    for (final r in _allRecords) {
      map.putIfAbsent(r.orchardName, () => []).add(r);
    }
    return map;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ── Premium Rounded Header ─────────────────────────────────────────
          _buildHeader(),

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _allRecords.isEmpty
                    ? _buildEmptyState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAllTab(),
                          _buildByOrchardTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ── Premium Header with Rounded Bottom Edges ───────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_green900, _green800, Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x552E7D32),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top row: back + title + refresh ─────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(12, 12, 16, 0),
              child: Row(
                children: [
                  // Back button — glassmorphic circle
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Iconsax.arrow_left,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Icon badge + Title
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Iconsax.health,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disease History',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          'Orchard health records',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scan count pill + refresh
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => _isLoading = true);
                          _loadHistory();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Iconsax.refresh,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_allRecords.length} scan${_allRecords.length == 1 ? '' : 's'}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Tab bar — inside header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      Colors.white.withValues(alpha: 0.6),
                  indicator: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'All Records'),
                    Tab(text: 'By Orchard'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  // ── All Tab ────────────────────────────────────────────────────────────────
  Widget _buildAllTab() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: _green700,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allRecords.length,
        itemBuilder: (_, i) => FadeInUp(
          duration: Duration(milliseconds: 400 + i * 60),
          child: _buildHistoryCard(_allRecords[i]),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(DiseaseHistoryModel record) {
    final isHealthy = record.status == 'healthy';
    final isDiseased = record.status == 'disease_detected';

    Color statusColor = Colors.grey.shade500;
    IconData statusIcon = Iconsax.clock;
    String statusLabel = 'Pending';

    if (isHealthy) {
      statusColor = Colors.green.shade600;
      statusIcon = Iconsax.tick_circle;
      statusLabel = 'Healthy';
    } else if (isDiseased) {
      statusColor = Colors.red.shade500;
      statusIcon = Iconsax.danger;
      statusLabel = 'Disease Detected';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top section ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Image thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: _paleGreen,
                    child: record.imageUrl.isNotEmpty &&
                            Uri.tryParse(record.imageUrl)?.hasScheme == true
                        ? Image.network(
                            record.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Iconsax.image, color: Color(0xFF2E7D32)),
                          )
                        : const Center(
                            child: Icon(Iconsax.scan,
                                color: Color(0xFF2E7D32), size: 28),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.diseaseName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Iconsax.tree, size: 12,
                              color: Color(0xFF388E3C)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              record.orchardName,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _green700,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Iconsax.clock,
                              size: 11, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a')
                                .format(record.scannedAt),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Recommendation section ────────────────────────────────────────
          if (record.recommendation.isNotEmpty) ...[
            Divider(color: Colors.grey.shade100, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.lamp_on,
                      size: 14, color: Colors.amber.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.recommendation,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── By Orchard Tab ─────────────────────────────────────────────────────────
  Widget _buildByOrchardTab() {
    final map = _byOrchard;
    final orchardNames = map.keys.toList();

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: _green700,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orchardNames.length,
        itemBuilder: (_, i) {
          final name = orchardNames[i];
          final records = map[name]!;
          return FadeInUp(
            duration: Duration(milliseconds: 400 + i * 80),
            child: _buildOrchardGroup(name, records),
          );
        },
      ),
    );
  }

  Widget _buildOrchardGroup(String name, List<DiseaseHistoryModel> records) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _paleGreen),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Orchard header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _paleGreen,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.tree, color: _green700, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _green800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _green700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${records.length} scan${records.length == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Records within this orchard
          ...records.map((r) => _buildCompactCard(r)),
        ],
      ),
    );
  }

  Widget _buildCompactCard(DiseaseHistoryModel record) {
    final isHealthy = record.status == 'healthy';
    final isDiseased = record.status == 'disease_detected';
    Color dot = Colors.grey;
    if (isHealthy) dot = Colors.green.shade500;
    if (isDiseased) dot = Colors.red.shade500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.diseaseName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(record.scannedAt),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Iconsax.arrow_right_3,
              size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _green700),
          const SizedBox(height: 16),
          Text(
            'Loading disease records...',
            style: GoogleFonts.poppins(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeIn(
              duration: const Duration(milliseconds: 600),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_paleGreen, Color(0xFFC8E6C9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.health,
                    size: 52, color: _green700),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Disease Records Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Start scanning your crops with AgroScan.\nLink scans to an orchard to build your disease history.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              icon: const Icon(Iconsax.scan, size: 18),
              label: Text(
                'Go Scan Now',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green700,
                side: const BorderSide(color: _green700, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
