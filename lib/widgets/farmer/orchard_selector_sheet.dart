// lib/widgets/farmer/orchard_selector_sheet.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import 'package:practice/models/orchard_model.dart';

/// Shows a bottom sheet listing the farmer's orchards.
/// Returns the selected [OrchardModel] or null if skipped.
Future<OrchardModel?> showOrchardSelectorSheet(BuildContext context) {
  return showModalBottomSheet<OrchardModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _OrchardSelectorSheet(),
  );
}

class _OrchardSelectorSheet extends StatefulWidget {
  const _OrchardSelectorSheet();

  @override
  State<_OrchardSelectorSheet> createState() => _OrchardSelectorSheetState();
}

class _OrchardSelectorSheetState extends State<_OrchardSelectorSheet> {
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _paleGreen = Color(0xFFE8F5E9);

  List<OrchardModel> _orchards = [];
  bool _isLoading = true;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _loadOrchards();
  }

  Future<void> _loadOrchards() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Orchards')
          .where('farmerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _orchards = snap.docs
              .map((d) => OrchardModel.fromMap(d.data(), d.id))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fruitEmoji(String fruit) {
    final f = fruit.toLowerCase();
    if (f.contains('orange') || f.contains('citrus')) return '🍊';
    if (f.contains('mango')) return '🥭';
    if (f.contains('apple')) return '🍎';
    if (f.contains('guava')) return '🍈';
    if (f.contains('banana')) return '🍌';
    if (f.contains('grape')) return '🍇';
    if (f.contains('lemon') || f.contains('lime')) return '🍋';
    return '🌿';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── Handle bar ──────────────────────────────────────
              _buildHandle(),

              // ── Header ──────────────────────────────────────────
              _buildHeader(),

              const SizedBox(height: 4),

              // ── Orchard list or states ───────────────────────────
              Expanded(
                child: _isLoading
                    ? _buildLoading()
                    : _orchards.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _orchards.length,
                            itemBuilder: (_, i) =>
                                _buildOrchardTile(_orchards[i]),
                          ),
              ),

              // ── Bottom actions ────────────────────────────────────
              _buildBottomActions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _paleGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.tree, color: _primaryGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Link to Orchard',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Select the orchard this scan belongs to',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildOrchardTile(OrchardModel orchard) {
    final isSelected = _selectedId == orchard.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedId = orchard.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _paleGreen : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _primaryGreen : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Fruit emoji badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? _primaryGreen.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Text(
                  _fruitEmoji(orchard.fruitType),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orchard.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? _primaryGreen : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Iconsax.location, size: 12,
                          color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          orchard.location,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primaryGreen.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      orchard.fruitType,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isSelected ? _primaryGreen : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: _primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF2E7D32)),
          const SizedBox(height: 14),
          Text(
            'Loading your orchards...',
            style: GoogleFonts.poppins(
                color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _paleGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.tree, color: _primaryGreen, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'No Orchards Added',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add an orchard first to link this scan result to disease history.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final selectedOrchard = _selectedId != null
        ? _orchards.firstWhere((o) => o.id == _selectedId)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Save button (active when orchard selected)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.tick_circle, size: 18),
              label: Text(
                selectedOrchard != null
                    ? 'Save to "${selectedOrchard.name}"'
                    : 'Select an orchard to save',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedOrchard != null
                    ? _primaryGreen
                    : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: selectedOrchard != null
                  ? () => Navigator.pop(context, selectedOrchard)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          // Skip — don't save
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              'Skip — Don\'t save this scan',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
