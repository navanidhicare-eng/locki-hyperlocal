import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/anakapalli_locations.dart';
import '../services/partner_api_service.dart';

class AddBusinessProfileScreen extends StatefulWidget {
  final VoidCallback? onBusinessCreated;

  const AddBusinessProfileScreen({Key? key, this.onBusinessCreated}) : super(key: key);

  @override
  State<AddBusinessProfileScreen> createState() => _AddBusinessProfileScreenState();
}

class _AddBusinessProfileScreenState extends State<AddBusinessProfileScreen> {
  final PartnerApiService _api = PartnerApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _customVillageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedBusinessModel = 'retail'; // 'retail' | 'service' | 'rental'
  bool _loadingInitialData = true;
  bool _submitting = false;

  // Categories & Sub-tiers State
  List<dynamic> _categories = [];
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedSubCategory;
  Map<String, dynamic>? _selectedChildCategory;

  // Locations State
  Map<String, Map<String, List<String>>> _locMap = Map.from(kDefaultAddressHierarchy);
  List<String> _districts = [];
  String _selectedDistrict = 'Anakapalli';
  List<String> _mandals = [];
  String _selectedMandal = 'Chodavaram';
  List<String> _villages = [];
  String _selectedVillage = 'Chodavaram Town';

  @override
  void initState() {
    super.initState();
    _phoneController.text = _api.profile?['phone'] ?? '9010737882';
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _landmarkController.dispose();
    _customVillageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loadingInitialData = true);

    try {
      // 1. Fetch Categories from Admin
      final cats = await _api.fetchCategories();
      if (cats.isNotEmpty) {
        _categories = cats;
        _selectedCategory = Map<String, dynamic>.from(_categories.first);
        final bType = _selectedCategory?['businessType']?.toString() ?? 'service';
        final catId = _selectedCategory?['id']?.toString() ?? '';
        final catName = _selectedCategory?['name']?.toString().toLowerCase() ?? '';
        if (bType == 'rental' || catId == 'cat_ab5c5cd1' || catName.contains('rental') || catName.contains('lease')) {
          _selectedBusinessModel = 'rental';
        } else if (bType == 'shop' || catId == 'cat_shops' || catName.contains('shop') || catName.contains('kirana')) {
          _selectedBusinessModel = 'retail';
        } else {
          _selectedBusinessModel = 'service';
        }
        final subs = (_selectedCategory!['subCategories'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        if (subs.isNotEmpty) {
          _selectedSubCategory = subs.first;
          final children = (_selectedSubCategory!['childCategories'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
          if (children.isNotEmpty) {
            _selectedChildCategory = children.first;
          }
        }
      }

      // 2. Fetch Locations from Admin
      final locs = await _api.fetchLocations();
      if (locs.isNotEmpty) {
        final Map<String, Map<String, List<String>>> dynamicLocs = {};
        for (final dist in locs) {
          final distName = dist['name']?.toString() ?? '';
          if (distName.isEmpty) continue;
          dynamicLocs[distName] = {};
          final mandalList = dist['mandals'] as List<dynamic>? ?? [];
          for (final m in mandalList) {
            final mandalName = m['name']?.toString() ?? '';
            if (mandalName.isEmpty) continue;
            dynamicLocs[distName]![mandalName] = [];
            final villageList = m['villages'] as List<dynamic>? ?? [];
            for (final v in villageList) {
              final vName = v['name']?.toString() ?? '';
              if (vName.isNotEmpty) {
                dynamicLocs[distName]![mandalName]!.add(vName);
              }
            }
          }
        }
        if (dynamicLocs.isNotEmpty) {
          _locMap = dynamicLocs;
        }
      }

      // Initialize location dropdown selections
      _districts = _locMap.keys.toList();
      if (_districts.isNotEmpty) {
        _selectedDistrict = _districts.contains('Anakapalli') ? 'Anakapalli' : _districts.first;
        _mandals = _locMap[_selectedDistrict]?.keys.toList() ?? [];
        if (_mandals.isNotEmpty) {
          _selectedMandal = _mandals.contains('Chodavaram') ? 'Chodavaram' : _mandals.first;
          _villages = List<String>.from(_locMap[_selectedDistrict]?[_selectedMandal] ?? []);
          if (!_villages.contains('Other / Custom Area')) _villages.add('Other / Custom Area');
          _selectedVillage = _villages.contains('Chodavaram Town') ? 'Chodavaram Town' : (_villages.isNotEmpty ? _villages.first : 'Local Area');
        }
      }
    } catch (e) {
      debugPrint('Error loading initial business onboarding data: $e');
    } finally {
      if (mounted) setState(() => _loadingInitialData = false);
    }
  }

  void _onCategoryChanged(String? catId) {
    if (catId == null) return;
    setState(() {
      _selectedCategory = _categories
          .map((c) => Map<String, dynamic>.from(c))
          .firstWhere((c) => c['id']?.toString() == catId, orElse: () => Map<String, dynamic>.from(_categories.first));
      final subs = (_selectedCategory?['subCategories'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
      _selectedSubCategory = subs.isNotEmpty ? subs.first : null;
      final children = (_selectedSubCategory?['childCategories'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
      _selectedChildCategory = children.isNotEmpty ? children.first : null;

      final bType = _selectedCategory?['businessType']?.toString() ?? 'service';
      final currentCatId = _selectedCategory?['id']?.toString() ?? '';
      final catName = _selectedCategory?['name']?.toString().toLowerCase() ?? '';
      if (bType == 'rental' || currentCatId == 'cat_ab5c5cd1' || catName.contains('rental') || catName.contains('lease')) {
        _selectedBusinessModel = 'rental';
      } else if (bType == 'shop' || currentCatId == 'cat_shops' || catName.contains('shop') || catName.contains('kirana')) {
        _selectedBusinessModel = 'retail';
      } else {
        _selectedBusinessModel = 'service';
      }
    });
  }

  void _onSubCategoryChanged(String? subId) {
    if (subId == null || _selectedCategory == null) return;
    final subs = (_selectedCategory?['subCategories'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    setState(() {
      _selectedSubCategory = subs.firstWhere((s) => s['id']?.toString() == subId, orElse: () => subs.first);
      final children = (_selectedSubCategory?['childCategories'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
      _selectedChildCategory = children.isNotEmpty ? children.first : null;
    });
  }

  void _onDistrictChanged(String? district) {
    if (district == null) return;
    setState(() {
      _selectedDistrict = district;
      _mandals = _locMap[_selectedDistrict]?.keys.toList() ?? [];
      _selectedMandal = _mandals.isNotEmpty ? _mandals.first : 'Local';
      _villages = List<String>.from(_locMap[_selectedDistrict]?[_selectedMandal] ?? []);
      if (!_villages.contains('Other / Custom Area')) _villages.add('Other / Custom Area');
      _selectedVillage = _villages.isNotEmpty ? _villages.first : 'Local Area';
    });
  }

  void _onMandalChanged(String? mandal) {
    if (mandal == null) return;
    setState(() {
      _selectedMandal = mandal;
      _villages = List<String>.from(_locMap[_selectedDistrict]?[_selectedMandal] ?? []);
      if (!_villages.contains('Other / Custom Area')) _villages.add('Other / Custom Area');
      _selectedVillage = _villages.isNotEmpty ? _villages.first : 'Local Area';
    });
  }

  Future<void> _submitBusinessProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final landmark = _landmarkController.text.trim();
    if (landmark.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Landmark / Street Address!'),
          backgroundColor: PartnerConstants.accentRose,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final finalVillage = _selectedVillage == 'Other / Custom Area'
        ? (_customVillageController.text.trim().isNotEmpty ? _customVillageController.text.trim() : 'Local Area')
        : _selectedVillage;

    final fullAddress = '$landmark, $finalVillage, $_selectedMandal, $_selectedDistrict';

    final catName = _selectedCategory?['name']?.toString() ?? 'General';
    final catId = _selectedCategory?['id']?.toString() ?? 'cat_general';
    final subCatName = _selectedSubCategory?['name']?.toString() ?? '';
    final subCatId = _selectedSubCategory?['id']?.toString() ?? '';
    final childCatName = (_selectedChildCategory?['name'] != null && _selectedChildCategory?['id'] != 'ALL_CHILDREN')
        ? _selectedChildCategory!['name'].toString()
        : '';
    final childCatId = (_selectedChildCategory?['id'] != null && _selectedChildCategory?['id'] != 'ALL_CHILDREN')
        ? _selectedChildCategory!['id'].toString()
        : '';

    final isRental = _selectedBusinessModel == 'rental' ||
        catId == 'cat_ab5c5cd1' ||
        catName.toLowerCase().contains('rental') ||
        catName.toLowerCase().contains('lease') ||
        subCatName.toLowerCase().contains('rental');
    final bType = isRental ? 'rental' : (_selectedBusinessModel == 'retail' ? 'shop' : 'service');

    final payload = {
      'businessName': _nameController.text.trim(),
      'name': _nameController.text.trim(),
      'businessType': bType,
      'categoryId': catId,
      'tradeCategory': catId,
      'category': catName,
      'tradeCategoryName': catName,
      'subCategoryId': subCatId,
      'subCategoryName': subCatName,
      'childCategoryId': childCatId,
      'childCategoryName': childCatName,
      'district': _selectedDistrict,
      'mandal': _selectedMandal,
      'village': finalVillage,
      'landmark': landmark,
      'address': fullAddress,
      'shopAddress': fullAddress,
      'phone': _phoneController.text.trim(),
    };

    final ok = await _api.requestNewBusiness(payload);

    if (mounted) {
      setState(() => _submitting = false);
      if (ok) {
        widget.onBusinessCreated?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Business profile submitted! Pending Admin Approval.'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit business request. Please try again.'),
            backgroundColor: PartnerConstants.accentRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  InputDecoration _inputDeco({required String label, String? hint, IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500),
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)) : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: PartnerConstants.primary, width: 1.8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subList = (_selectedCategory?['subCategories'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    final childList = (_selectedSubCategory?['childCategories'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: PartnerConstants.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Business Profile',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
            ),
            Text(
              'Multi-Business Onboarding with Admin Categories',
              style: TextStyle(fontSize: 11, color: PartnerConstants.textMuted),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: _loadingInitialData
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: PartnerConstants.primary),
                  SizedBox(height: 14),
                  Text('Loading Categories & Locations...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Informational Banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.stars_rounded, color: Color(0xFFEA580C), size: 22),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Register a secondary business profile. Once verified by Loki Admin, you can switch between profiles seamlessly from your home screen.',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF9A3412), height: 1.3, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 1: Business Details
                        _buildSectionCard(
                          title: '1. Business Identity & Model',
                          icon: Icons.storefront_rounded,
                          iconColor: const Color(0xFF2563EB),
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: _inputDeco(
                                label: 'Business / Store / Workshop Name *',
                                hint: 'e.g. Sri Lakshmi Tent House & Event Rentals',
                                prefixIcon: Icons.store_rounded,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your business or store name' : null,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Select Business Model *',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 8),

                            // 3 Business Models in a responsive Row
                            Row(
                              children: [
                                _buildModelCard(
                                  title: '1. Retail & Shops',
                                  value: 'retail',
                                  icon: Icons.storefront_rounded,
                                  desc: 'Stores, outlets & showrooms',
                                ),
                                const SizedBox(width: 8),
                                _buildModelCard(
                                  title: '2. Services',
                                  value: 'service',
                                  icon: Icons.home_repair_service_rounded,
                                  desc: 'Technicians & repairs',
                                ),
                                const SizedBox(width: 8),
                                _buildModelCard(
                                  title: '3. Rentals & Leasing',
                                  value: 'rental',
                                  icon: Icons.car_rental_rounded,
                                  desc: 'Vehicles, tents & tool rentals',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Section 2: Category & Services (Admin Configured)
                        _buildSectionCard(
                          title: '2. Category & Specialization',
                          icon: Icons.category_rounded,
                          iconColor: const Color(0xFF059669),
                          children: [
                            const Text(
                              'Category hierarchy configured in Admin Dashboard:',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 10),

                            // 1. Primary Category
                            DropdownButtonFormField<String>(
                              value: _selectedCategory?['id']?.toString() ?? (_categories.isNotEmpty ? _categories.first['id']?.toString() : null),
                              isExpanded: true,
                              decoration: _inputDeco(label: 'Primary Category (Admin) *', prefixIcon: Icons.folder_rounded),
                              items: _categories.map((c) {
                                final catMap = Map<String, dynamic>.from(c);
                                final catId = catMap['id']?.toString() ?? '';
                                final catName = catMap['name']?.toString() ?? 'Category';
                                return DropdownMenuItem<String>(
                                  value: catId,
                                  child: Text(catName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                              onChanged: _onCategoryChanged,
                            ),

                            // 2. Sub-Category
                            if (subList.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                value: _selectedSubCategory?['id']?.toString() ?? (subList.isNotEmpty ? subList.first['id']?.toString() : null),
                                isExpanded: true,
                                decoration: _inputDeco(label: 'Sub-Category (Admin) *', prefixIcon: Icons.folder_open_rounded),
                                items: subList.map((s) {
                                  final subId = s['id']?.toString() ?? '';
                                  final subName = s['name']?.toString() ?? 'Sub-Category';
                                  return DropdownMenuItem<String>(
                                    value: subId,
                                    child: Text(subName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: _onSubCategoryChanged,
                              ),
                            ],

                            // 3. Child Category
                            if (childList.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                value: _selectedChildCategory?['id']?.toString() ?? (childList.isNotEmpty ? childList.first['id']?.toString() : null),
                                isExpanded: true,
                                decoration: _inputDeco(label: 'Child-Category / Specific Service', prefixIcon: Icons.checklist_rounded),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: 'ALL_CHILDREN',
                                    child: Text('All Services under this Sub-Category', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: PartnerConstants.primary)),
                                  ),
                                  ...childList.map((ch) {
                                    final chId = ch['id']?.toString() ?? '';
                                    final chName = ch['name']?.toString() ?? 'Service';
                                    return DropdownMenuItem<String>(
                                      value: chId,
                                      child: Text(chName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                                    );
                                  }),
                                ],
                                onChanged: (chId) {
                                  setState(() {
                                    if (chId == 'ALL_CHILDREN') {
                                      _selectedChildCategory = {'id': 'all', 'name': 'All Services'};
                                    } else {
                                      _selectedChildCategory = childList.firstWhere((c) => c['id']?.toString() == chId, orElse: () => childList.first);
                                    }
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Section 3: Location Details (Admin Location Hierarchy)
                        _buildSectionCard(
                          title: '3. Location & Coverage',
                          icon: Icons.location_on_rounded,
                          iconColor: const Color(0xFFEA580C),
                          children: [
                            const Text(
                              'Service coverage based on Admin Location Management:',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 10),

                            // District & Mandal in a Row
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _districts.contains(_selectedDistrict) ? _selectedDistrict : (_districts.isNotEmpty ? _districts.first : null),
                                    isExpanded: true,
                                    decoration: _inputDeco(label: 'District *'),
                                    items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)))).toList(),
                                    onChanged: _onDistrictChanged,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _mandals.contains(_selectedMandal) ? _selectedMandal : (_mandals.isNotEmpty ? _mandals.first : null),
                                    isExpanded: true,
                                    decoration: _inputDeco(label: 'Mandal *'),
                                    items: _mandals.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)))).toList(),
                                    onChanged: _onMandalChanged,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Village / Ward
                            DropdownButtonFormField<String>(
                              value: _villages.contains(_selectedVillage) ? _selectedVillage : (_villages.isNotEmpty ? _villages.first : null),
                              isExpanded: true,
                              decoration: _inputDeco(label: 'Village / Ward / Area *', prefixIcon: Icons.holiday_village_rounded),
                              items: _villages.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedVillage = v);
                              },
                            ),

                            // Other Village Custom Field
                            if (_selectedVillage == 'Other / Custom Area') ...[
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _customVillageController,
                                decoration: _inputDeco(label: 'Enter Area / Colony Name *', hint: 'e.g. RTC Colony, Bypass Road'),
                              ),
                            ],
                            const SizedBox(height: 14),

                            // Landmark & Street Address
                            TextFormField(
                              controller: _landmarkController,
                              decoration: _inputDeco(
                                label: 'Landmark & Street Address *',
                                hint: 'e.g. Near Rythu Bazaar, Beside SBI Bank, Shop No. 4',
                                prefixIcon: Icons.pin_drop_rounded,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter landmark or street address' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Section 4: Contact Information
                        _buildSectionCard(
                          title: '4. Contact Details',
                          icon: Icons.contact_phone_rounded,
                          iconColor: const Color(0xFF0F766E),
                          children: [
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDeco(
                                label: 'Contact Mobile Number *',
                                hint: '10-Digit Mobile Number',
                                prefixIcon: Icons.phone_rounded,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter contact phone number' : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submitBusinessProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartnerConstants.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    _submitting ? 'Submitting for Approval...' : 'Submit Profile for Admin Approval',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModelCard({
    required String title,
    required String value,
    required IconData icon,
    required String desc,
  }) {
    final selected = _selectedBusinessModel == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedBusinessModel = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? PartnerConstants.primary.withOpacity(0.08) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? PartnerConstants.primary : const Color(0xFFCBD5E1),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? PartnerConstants.primary : const Color(0xFF64748B),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: selected ? PartnerConstants.primary : const Color(0xFF334155),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: selected ? PartnerConstants.primaryDark : const Color(0xFF94A3B8),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

