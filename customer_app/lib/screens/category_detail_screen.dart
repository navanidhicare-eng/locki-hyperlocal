import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import 'coming_soon_screen.dart';
import 'quick_request_screen.dart';
import 'technician_detail_screen.dart';
import 'rental_marketplace_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final ServiceCategory category;

  const CategoryDetailScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _providers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSpecialists();
  }

  Future<void> _loadSpecialists() async {
    setState(() => _loading = true);
    final list = await _api.fetchProvidersByCategory(widget.category.id, mandal: 'Chodavaram');
    if (!mounted) return;
    setState(() {
      _providers = list;
      _loading = false;
    });
  }

  void _showDirectCallDialog(Map<String, dynamic> provider) {
    final phone = provider['phone']?.toString() ?? '9010737882';
    final name = provider['name']?.toString() ?? 'Specialist';
    final shop = provider['shopName']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF15803D), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Call Specialist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(name, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (shop != null && shop.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Shop: $shop', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              ),
            const Text(
              'Speak directly with the verified specialist to discuss your issue, visit timing, and service requirements:',
              style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.call, color: AppConstants.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '+91 $phone',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuickRequestScreen(
                    preselectedCategory: widget.category,
                    preselectedProvider: provider,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.flash_on_rounded, size: 16),
            label: const Text('Book Directly', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(widget.category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          foregroundColor: AppConstants.secondary,
          elevation: 0.5,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppConstants.primary)),
      );
    }

    // Special redirect for Lease & Rental marketplace
    final isLeaseRental = widget.category.id == 'cat_ab5c5cd1' ||
        widget.category.name.toLowerCase().contains('lease') ||
        widget.category.name.toLowerCase().contains('rent');
    if (isLeaseRental) {
      return const RentalMarketplaceScreen();
    }

    // When there are no specialists in this category, show Coming Soon screen with no booking options
    if (_providers.isEmpty) {
      return ComingSoonScreen(category: widget.category);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.secondary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: AppConstants.primary),
            tooltip: 'Quick Request',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuickRequestScreen(preselectedCategory: widget.category)),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSpecialists,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Quick Request Banner (Pure English, No Telugu)
            _buildQuickRequestBanner(),

            const SizedBox(height: 18),

            // 2. Specialists Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Verified Specialists (${_providers.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.secondary,
                  ),
                ),
                const Text(
                  'Tap for full details',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 3. Specialists List
            ..._providers.map((p) => _buildCleanSpecialistCard(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRequestBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDBA74)),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConstants.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need Quick Service?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF9A3412)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Broadcast request to all nearby ${widget.category.name} specialists',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFC2410C)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuickRequestScreen(preselectedCategory: widget.category)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Post Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanSpecialistCard(Map<String, dynamic> provider) {
    final name = provider['name']?.toString() ?? 'Specialist';
    final subName = provider['subCategoryName']?.toString() ?? provider['categoryName']?.toString() ?? widget.category.name;
    final shop = provider['shopName']?.toString();
    final isOnline = provider['isOnline'] == true;
    final rating = (provider['rating'] as num?)?.toDouble() ?? 4.9;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Open clean Full Details Page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TechnicianDetailScreen(
                  provider: provider,
                  category: widget.category,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Avatar with Live Status Dot
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: AppConstants.primary.withOpacity(0.12),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppConstants.primary),
                      ),
                    ),
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.2),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // 2. Middle Details (Name, Skill, Shop/Rating)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2563EB)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      if (shop != null && shop.isNotEmpty)
                        Text(
                          '🏪 $shop',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: AppConstants.accentGold),
                            const SizedBox(width: 3),
                            Text(
                              '$rating',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                            const SizedBox(width: 4),
                            const Text('• Verified Specialist', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // 3. Right Action Column (Neatly Aligned: Top = Duty Pill, Bottom = Call Button)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // On-Duty Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isOnline ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4.5),
                          Text(
                            isOnline ? 'On-Duty' : 'Offline',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isOnline ? const Color(0xFF065F46) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Modern Call Button
                    InkWell(
                      onTap: () => _showDirectCallDialog(provider),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.call_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              'Call',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
