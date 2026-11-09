import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import 'shop_detail_screen.dart';

class ShopMarketplaceScreen extends StatefulWidget {
  final ServiceCategory? category;

  const ShopMarketplaceScreen({Key? key, this.category}) : super(key: key);

  @override
  State<ShopMarketplaceScreen> createState() => _ShopMarketplaceScreenState();
}

class _ShopMarketplaceScreenState extends State<ShopMarketplaceScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _stores = [];

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedSubFilter = 'all';

  final List<Map<String, String>> _shopFilters = [
    {'id': 'all', 'name': 'All Stores'},
    {'id': 'groceries', 'name': '🌾 Rice & Grains'},
    {'id': 'oil', 'name': '🌻 Oils & Ghee'},
    {'id': 'snacks', 'name': '🍪 Snacks & Biscuits'},
    {'id': 'essentials', 'name': '🧼 Daily Essentials'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final stores = await _api.fetchProvidersByCategory('cat_shops', mandal: 'Chodavaram');

      if (mounted) {
        setState(() {
          _stores = stores;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showDirectCallDialog(Map<String, dynamic> store) {
    final phone = store['phone']?.toString() ?? '9010737882';
    final storeName = store['shopName'] ?? store['name'] ?? 'Local Store';
    final address = store['shopAddress'] ?? 'Chodavaram, Anakapalli';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.phone_in_talk_rounded, color: Color(0xFF059669), size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        address,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Call directly to place your grocery order, inquire product availability, or arrange home delivery:',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Color(0xFF059669)),
                      const SizedBox(width: 8),
                      Text(
                        phone,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const Text('Verified Store', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final uri = Uri.parse('tel:$phone');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.call, size: 16, color: Colors.white),
                    label: const Text('Call Now', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToShopDetail(Map<String, dynamic> store) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShopDetailScreen(store: store)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStores = _stores.where((store) {
      final name = (store['shopName'] ?? store['name'] ?? '').toString().toLowerCase();
      final address = (store['shopAddress'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      if (q.isNotEmpty && !name.contains(q) && !address.contains(q)) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Local Stores & Kirana',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            Row(
              children: const [
                Icon(Icons.location_on, size: 12, color: Color(0xFFDE4915)),
                SizedBox(width: 3),
                Text(
                  'Chodavaram, Anakapalli',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFDE4915)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFFDE4915),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(
                          hintText: 'Search stores or items (e.g. Rice, Oil)...',
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          icon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Filter Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _shopFilters.map((f) {
                          final isSelected = _selectedSubFilter == f['id'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(f['name']!),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedSubFilter = f['id']!),
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                              selectedColor: const Color(0xFFDE4915),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: isSelected ? const Color(0xFFDE4915) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Store Directory Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Verified Stores (${filteredStores.length})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const Text(
                          'Direct Store Call',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    if (filteredStores.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: const [
                            Text('🏪', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text(
                              'No stores found in this area',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'New neighborhood stores are being onboarded daily',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredStores.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemBuilder: (ctx, i) {
                          final store = filteredStores[i];
                          final storeName = store['shopName'] ?? store['name'] ?? 'Local Store';
                          final address = store['shopAddress'] ?? 'Chodavaram, Anakapalli';
                          final timings = store['shopTimings'];
                          final openTime = timings?['open'] ?? '07:00 AM';
                          final closeTime = timings?['close'] ?? '09:30 PM';

                          final photoUrl = (store['shopPhotoUrl'] ?? store['avatarUrl'] ?? '').toString();
                          final effectivePhoto = photoUrl.isNotEmpty
                              ? photoUrl
                              : 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=800&auto=format&fit=crop&q=80';

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _navigateToShopDetail(store),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 1. Store Photo Banner (Fills top area with rich photo)
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: Image.network(
                                                effectivePhoto,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  color: const Color(0xFFF1F5F9),
                                                  child: const Center(
                                                    child: Icon(Icons.storefront, size: 36, color: Color(0xFF94A3B8)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.black.withOpacity(0.2),
                                                      Colors.transparent,
                                                      Colors.black.withOpacity(0.55),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Top-Left: Verified Badge
                                            Positioned(
                                              top: 8,
                                              left: 8,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF059669),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(Icons.verified, size: 10, color: Colors.white),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'VERIFIED',
                                                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Top-Right: Open Pill
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.95),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'OPEN',
                                                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 2. Store Info Body (Compact & Tight - Zero Empty Space)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              storeName,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), height: 1.2),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on, size: 11, color: Color(0xFFDE4915)),
                                                const SizedBox(width: 2),
                                                Expanded(
                                                  child: Text(
                                                    address,
                                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.access_time, size: 10, color: Color(0xFF059669)),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(
                                                    '$openTime - $closeTime',
                                                    style: const TextStyle(fontSize: 9.5, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // Action Buttons Row
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () => _navigateToShopDetail(store),
                                                    style: OutlinedButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                    child: const Text('Catalog', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                InkWell(
                                                  onTap: () => _showDirectCallDialog(store),
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(7),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF059669),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(Icons.call, size: 15, color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
