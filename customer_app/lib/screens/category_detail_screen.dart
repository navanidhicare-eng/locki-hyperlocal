import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/service_model.dart';
import '../services/api_service.dart';
import 'order_tracking_screen.dart';
import 'quick_request_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final ServiceCategory category;

  const CategoryDetailScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  List<ServiceItem> _services = [];
  List<Map<String, dynamic>> _providers = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _api.fetchServices(categoryId: widget.category.id),
      _api.fetchProvidersByCategory(widget.category.id, mandal: 'Chodavaram'),
    ]);

    if (!mounted) return;
    setState(() {
      _services = results[0] as List<ServiceItem>;
      _providers = results[1] as List<Map<String, dynamic>>;
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
                  const Text('Call Technician', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              'You can speak directly with the verified technician to discuss your issue, inspection timings, and get service done:',
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
            label: const Text('Hire Technician Directly', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

  void _showBookingBottomSheet(ServiceItem service) {
    String selectedPayment = 'Cash on Delivery / UPI';
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Confirm Instant Booking',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppConstants.secondary),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Duration: ${service.duration}', style: const TextStyle(fontSize: 12, color: AppConstants.textMuted)),
                        ],
                      ),
                    ),
                    Text(
                      '₹${service.basePrice.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppConstants.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Address: Station Road, Chodavaram Town, Anakapalli', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          final res = await _api.submitQuickRequest(
                            categoryId: widget.category.id,
                            problemDescription: service.name,
                            customerAddress: 'Station Road, Chodavaram Town',
                            customerMandal: 'Chodavaram',
                            amount: service.basePrice,
                          );
                          setModalState(() => isSubmitting = false);

                          if (res != null && res['order'] != null) {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: OrderModel.fromJson(res['order']))),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to place booking. Please check connection.')),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Confirm & Book Specialist (₹${service.basePrice.toInt()})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primary))
          : Column(
              children: [
                // Category Banner & Quick Request Bar
                _buildHeaderQuickBar(),

                // Two Tabs: 1. Verified Technicians, 2. Standard Packages
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppConstants.primary,
                    indicatorWeight: 3,
                    labelColor: AppConstants.primary,
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: [
                      Tab(text: '👷 Verified Specialists (${_providers.length})'),
                      Tab(text: '📋 Standard Services (${_services.length})'),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Technicians Directory
                      _buildTechniciansTab(),

                      // Tab 2: Standard Services Grid
                      _buildServicesTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderQuickBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppConstants.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need Quick Service? (అర్బన్ రిక్వెస్ట్)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF9A3412)),
                  ),
                  Text(
                    'Post request to all nearby ${widget.category.name} specialists',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFC2410C)),
                  ),
                ],
              ),
            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Post Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechniciansTab() {
    if (_providers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.engineering_rounded, size: 54, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 12),
              Text(
                'No specialists currently listed in this category.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              const Text(
                'You can still send a Quick Request, and nearby specialists will be alerted!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QuickRequestScreen(preselectedCategory: widget.category)),
                  );
                },
                icon: const Icon(Icons.flash_on_rounded, size: 16),
                label: const Text('Send Quick Request'),
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _providers.length,
      itemBuilder: (ctx, idx) => _buildTechnicianCard(_providers[idx]),
    );
  }

  Widget _buildTechnicianCard(Map<String, dynamic> provider) {
    final name = provider['name']?.toString() ?? 'Specialist';
    final phone = provider['phone']?.toString() ?? '';
    final subName = provider['subCategoryName']?.toString() ?? provider['categoryName']?.toString() ?? '';
    final shop = provider['shopName']?.toString();
    final isOnline = provider['isOnline'] == true;
    final rating = (provider['rating'] as num?)?.toDouble() ?? 4.9;
    final jobs = provider['jobsCompleted'] ?? 18;
    final mandal = provider['mandal']?.toString() ?? 'Chodavaram';
    final exp = provider['experience']?.toString() ?? '3-5 Years';
    final radius = provider['serviceRadius']?.toString() ?? '25 KM';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name + Trade + Duty Badge
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppConstants.primary.withOpacity(0.12),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppConstants.primary),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOnline ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isOnline ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              isOnline ? '🟢 On-Duty' : '⚪ Offline',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isOnline ? const Color(0xFF065F46) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subName.isNotEmpty ? subName : widget.category.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.primary),
                      ),
                      if (shop != null && shop.isNotEmpty)
                        Text(
                          '🏪 $shop',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Middle Row: Rating, Experience, Location
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppConstants.accentGold, size: 16),
                      const SizedBox(width: 3),
                      Text(
                        '$rating',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                      ),
                      Text(' ($jobs Jobs)', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                  Text('• $exp', style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                  Text('📍 $mandal ($radius)', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Bottom Actions: 1. Call Now, 2. Book Directly
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDirectCallDialog(provider),
                    icon: const Icon(Icons.call_rounded, size: 16, color: Color(0xFF059669)),
                    label: Text(
                      '📞 Call ($phone)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                      backgroundColor: const Color(0xFFECFDF5),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
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
                    label: const Text('⚡ Book Directly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildServicesTab() {
    if (_services.isEmpty) {
      return const Center(child: Text('No standard packages configured yet.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.98,
      ),
      itemCount: _services.length,
      itemBuilder: (ctx, idx) {
        final s = _services[idx];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${s.basePrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppConstants.primary)),
                    ElevatedButton(
                      onPressed: () => _showBookingBottomSheet(s),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Book', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
