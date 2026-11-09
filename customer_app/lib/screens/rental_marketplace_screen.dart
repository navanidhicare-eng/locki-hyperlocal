import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../core/locations_data.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../utils/location_picker_helper.dart';
import '../utils/image_compress_helper.dart' as img_helper;

class RentalMarketplaceScreen extends StatefulWidget {
  const RentalMarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<RentalMarketplaceScreen> createState() => _RentalMarketplaceScreenState();
}

class _RentalMarketplaceScreenState extends State<RentalMarketplaceScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _rentals = [];

  // Active Main Tab: 0 = Properties (Direct Owner), 1 = Store Rentals (Verified Stores)
  int _activeTabIndex = 0;

  // Sub-filter inside current tab
  String _selectedSubFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Filters for Tab 0: Properties & Real Estate (Direct Owner - Untouched)
  final List<Map<String, String>> _propertyFilters = [
    {'id': 'all', 'name': 'All Properties'},
    {'id': 'my_listings', 'name': '⭐ My Listings'},
    {'id': 'Houses & Flats (1BHK, 2BHK)', 'name': '🏢 Flats & Apartments'},
    {'id': 'Independent House / Villa', 'name': '🏡 Independent Houses'},
    {'id': 'Plots & Open Lands', 'name': '📐 Plots & Lands'},
    {'id': 'Commercial Shops & Godowns', 'name': '🏬 Commercial Shops'},
    {'id': 'PG & Shared Rooms', 'name': '🛏️ Rooms & PG'},
  ];

  // Filters for Tab 1: Store Rentals (Dynamic from Admin Category Management with instant presets)
  List<Map<String, dynamic>> _adminStoreSubCategories = [
    {
      'id': 'sub_422fa86a',
      'name': 'Vehicle Rentals',
      'childCategories': [
        {'id': 'ch_f529ebf4', 'name': 'Self-drive cars / bikes'},
        {'id': 'ch_d73ce9e9', 'name': 'Commercial / Goods'},
        {'id': 'ch_ef9deb5e', 'name': 'Agriculture'},
      ]
    },
    {
      'id': 'sub_7e99c1f8',
      'name': 'Event & Party Supplies',
      'childCategories': [
        {'id': 'ch_ef95861b', 'name': 'Furniture & Tent'},
        {'id': 'ch_7046f475', 'name': 'Audio & Visual'},
        {'id': 'ch_eef6e095', 'name': 'Catering Items'},
      ]
    },
    {
      'id': 'sub_295a5d80',
      'name': 'Construction & Tools Equipment',
      'childCategories': [
        {'id': 'ch_a0309a5c', 'name': 'Power Tools'},
        {'id': 'ch_8aa3aff8', 'name': 'Heavy Machinery'},
        {'id': 'ch_ba538b5a', 'name': 'Building Material'},
      ]
    },
    {
      'id': 'sub_c6d2f7f5',
      'name': 'Electronics & Cameras',
      'childCategories': [
        {'id': 'ch_48adff95', 'name': 'Photography DSLR'},
        {'id': 'ch_c33eed72', 'name': 'Home Appliances'},
        {'id': 'ch_ea67a114', 'name': 'Office Laptops'},
      ]
    },
    {
      'id': 'sub_359cf77b',
      'name': 'Clothing & Jewelry',
      'childCategories': [
        {'id': 'ch_3e281563', 'name': 'Bridal & Groom'},
        {'id': 'ch_954ba312', 'name': 'Jewelry'},
        {'id': 'ch_2b1ece4a', 'name': 'Fancy Dress'},
      ]
    },
  ];
  String _selectedStoreSubCategoryId = 'all';
  String _selectedStoreChildCategoryId = 'all';

  @override
  void initState() {
    super.initState();
    _loadAdminStoreCategories();
    _loadRentals();
  }

  Future<void> _loadAdminStoreCategories() async {
    try {
      final categories = await _api.fetchCategories();
      final rentalCat = categories.firstWhere(
        (c) => c.id == 'cat_ab5c5cd1' || (c.name.toLowerCase().contains('rental') || c.name.toLowerCase().contains('lease')),
        orElse: () => ServiceCategory(
          id: '',
          name: '',
          icon: '',
          color: Colors.transparent,
          description: '',
          servicesCount: 0,
        ),
      );

      if (rentalCat.subCategories.isNotEmpty) {
        // Exclude Property / Real Estate (as that is reserved for Tab 0 Houses & Plots)
        final storeSubs = rentalCat.subCategories.where((sub) {
          final name = (sub['name'] ?? '').toString().toLowerCase();
          return !name.contains('property') && !name.contains('real estate');
        }).toList();

        if (mounted) {
          setState(() {
            _adminStoreSubCategories = storeSubs;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading admin store categories: $e');
    }
  }

  String _getSubCategoryEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('vehicle') || lower.contains('car') || lower.contains('bike')) return '🚗 ';
    if (lower.contains('event') || lower.contains('party') || lower.contains('tent') || lower.contains('supplies')) return '⛺ ';
    if (lower.contains('construction') || lower.contains('tool') || lower.contains('machinery')) return '🚜 ';
    if (lower.contains('electronic') || lower.contains('camera') || lower.contains('appliance')) return '📷 ';
    if (lower.contains('clothing') || lower.contains('jewelry') || lower.contains('dress')) return '👗 ';
    if (lower.contains('furniture') || lower.contains('cot') || lower.contains('bed')) return '🛋️ ';
    return '📦 ';
  }

  Map<String, dynamic>? _getSelectedStoreSubCategory() {
    if (_selectedStoreSubCategoryId == 'all') return null;
    try {
      return _adminStoreSubCategories.firstWhere(
        (s) => s['id'] == _selectedStoreSubCategoryId || s['name'] == _selectedStoreSubCategoryId,
      );
    } catch (_) {
      return null;
    }
  }

  String _getActiveStoreSubCategoryName() {
    final sub = _getSelectedStoreSubCategory();
    return sub?['name']?.toString() ?? 'Items';
  }

  List<Map<String, dynamic>> _getActiveStoreChildCategories() {
    final sub = _getSelectedStoreSubCategory();
    if (sub == null) return [];
    final children = sub['childCategories'];
    if (children is List) {
      return List<Map<String, dynamic>>.from(children);
    }
    return [];
  }

  Future<void> _loadRentals() async {
    setState(() => _loading = true);

    String? catParam;
    String? subCatParam;
    String? childCatParam;
    String? listingTypeParam;

    if (_activeTabIndex == 0) {
      catParam = 'properties';
      listingTypeParam = 'owner';
    } else {
      listingTypeParam = 'store';
      if (_selectedStoreSubCategoryId != 'all') {
        final sub = _getSelectedStoreSubCategory();
        subCatParam = sub?['name']?.toString() ?? _selectedStoreSubCategoryId;
        if (_selectedStoreChildCategoryId != 'all') {
          childCatParam = _selectedStoreChildCategoryId;
        }
      }
    }

    final list = await _api.fetchRentals(
      category: catParam,
      subCategory: subCatParam,
      childCategory: childCatParam,
      listingType: listingTypeParam,
      search: _searchQuery,
    );

    List<Map<String, dynamic>> filtered = list;
    if (_activeTabIndex == 0) {
      if (_selectedSubFilter == 'my_listings') {
        // "My Listings" shows ALL posts of this owner (both Available and Rented)
        filtered = list.where((item) => _isMyPost(item)).toList();
      } else {
        // In "All Properties" and other public category tabs: ONLY show AVAILABLE properties!
        // Already rented out properties are completely hidden from the public feed.
        filtered = list.where((item) {
          final isRented = (item['status'] ?? 'available') == 'rented';
          if (isRented) {
            return false; // Never show rented properties in public listing
          }
          if (_selectedSubFilter != 'all') {
            final sub = (item['subCategory'] ?? '').toString().toLowerCase();
            return sub.contains(_selectedSubFilter.toLowerCase());
          }
          return true;
        }).toList();
      }
    } else {
      // Tab 1: Store Rentals filtering
      if (_selectedStoreSubCategoryId != 'all') {
        final subName = _getActiveStoreSubCategoryName().toLowerCase();
        filtered = filtered.where((item) {
          final iSub = (item['subCategory'] ?? '').toString().toLowerCase();
          final iCat = (item['category'] ?? '').toString().toLowerCase();
          final iCatName = (item['categoryName'] ?? '').toString().toLowerCase();
          final iTitle = (item['title'] ?? '').toString().toLowerCase();

          bool match = iSub.contains(subName) || subName.contains(iSub) ||
                       iCat.contains(subName) || subName.contains(iCat) ||
                       iCatName.contains(subName) || subName.contains(iCatName) ||
                       iTitle.contains(subName);

          if (!match && subName.contains('vehicle')) {
            if (iCat == 'vehicles' || iSub.contains('car') || iTitle.contains('ertiga') || iTitle.contains('car')) {
              match = true;
            }
          }
          if (!match && (subName.contains('event') || subName.contains('party'))) {
            if (iCat == 'events' || iSub.contains('tent') || iTitle.contains('chair') || iTitle.contains('shamiana')) {
              match = true;
            }
          }
          if (!match && (subName.contains('construction') || subName.contains('tool'))) {
            if (iCat == 'construction' || iSub.contains('tool') || iTitle.contains('drill') || iTitle.contains('hammer')) {
              match = true;
            }
          }
          if (!match && (subName.contains('electronic') || subName.contains('camera'))) {
            if (iCat == 'electronics' || iSub.contains('camera') || iTitle.contains('sony') || iTitle.contains('camera')) {
              match = true;
            }
          }
          return match;
        }).toList();

        if (_selectedStoreChildCategoryId != 'all') {
          final cName = _selectedStoreChildCategoryId.toLowerCase().replaceAll(',/', ' ').replaceAll(',', ' ').trim();
          filtered = filtered.where((item) {
            final iChild = (item['childCategory'] ?? '').toString().toLowerCase();
            final iTitle = (item['title'] ?? '').toString().toLowerCase();
            final iDesc = (item['description'] ?? '').toString().toLowerCase();
            final iSub = (item['subCategory'] ?? '').toString().toLowerCase();

            return iChild.contains(cName) || cName.contains(iChild) ||
                   iTitle.contains(cName) || iDesc.contains(cName) || iSub.contains(cName);
          }).toList();
        }
      }
    }

    if (mounted) {
      setState(() {
        _rentals = filtered;
        _loading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Clipboard.setData(ClipboardData(text: cleanPhone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone number $cleanPhone copied to clipboard!'),
            backgroundColor: AppConstants.accentEmerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone, String title) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final msg = Uri.encodeComponent('Hi, I saw your rental listing "$title" on Loki App. Is it still available?');
    final Uri url = Uri.parse('https://wa.me/91$cleanPhone?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _makePhoneCall(phone);
    }
  }

  Future<void> _openDirections(Map<String, dynamic> item) async {
    final dynamic latVal = item['latitude'];
    final dynamic lngVal = item['longitude'];
    final location = item['location'] ?? '';
    final district = item['district'] ?? 'Anakapalli';

    Uri url;
    if (latVal != null && lngVal != null) {
      final double? lat = double.tryParse(latVal.toString());
      final double? lng = double.tryParse(lngVal.toString());
      if (lat != null && lng != null && (lat != 0 || lng != 0)) {
        url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
      } else {
        final q = Uri.encodeComponent('$location, $district, Andhra Pradesh');
        url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$q');
      }
    } else {
      final q = Uri.encodeComponent('$location, $district, Andhra Pradesh');
      url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$q');
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps navigation'),
            backgroundColor: AppConstants.accentRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _isMyPost(Map<String, dynamic> item) {
    // Commercial store rentals are managed strictly by merchants via Partner App, never customer app
    if (item['listingType'] == 'store' || item['postedBy'] == 'partner') {
      return false;
    }
    final myPhone = _api.currentUser?['phone']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
    final postPhone = item['phone']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
    final myId = _api.currentUser?['id']?.toString() ?? '';
    final postUserId = item['userId']?.toString() ?? '';
    if (myPhone.isEmpty && myId.isEmpty) return false;
    return (myPhone.isNotEmpty && postPhone.isNotEmpty && myPhone == postPhone) ||
        (myId.isNotEmpty && postUserId.isNotEmpty && myId == postUserId);
  }

  void _openPostPropertyModal({Map<String, dynamic>? itemToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => _PostPropertyModal(
        itemToEdit: itemToEdit,
        onSuccess: () {
          Navigator.pop(modalCtx);
          setState(() {
            _activeTabIndex = 0;
            if (itemToEdit == null) {
              _selectedSubFilter = 'all';
            }
          });
          _loadRentals();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(itemToEdit != null
                  ? '✅ Property listing updated successfully!'
                  : '🎉 Property listing published successfully! (0% Brokerage)'),
              backgroundColor: AppConstants.accentEmerald,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeletePost(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppConstants.accentRose, size: 24),
            SizedBox(width: 8),
            Text('Delete Listing?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Are you sure you want to permanently delete "${item['title']}"?\n\nThis will remove it from the marketplace immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final id = item['id']?.toString() ?? '';
      final ok = await _api.deleteRentalPost(id);
      if (ok) {
        _loadRentals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🗑️ Property listing deleted permanently'),
              backgroundColor: AppConstants.secondary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete listing. Please check connection and try again.'),
              backgroundColor: AppConstants.accentRose,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleListingStatus(Map<String, dynamic> item) async {
    final currentStatus = item['status'] ?? 'available';
    final newStatus = currentStatus == 'available' ? 'rented' : 'available';
    final id = item['id']?.toString() ?? '';

    final ok = await _api.updateRentalPost(id, {'status': newStatus});
    if (ok) {
      item['status'] = newStatus;
      _loadRentals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'rented'
                ? '🔒 Marked as RENTED OUT. (Hidden from public feed; managed in "⭐ My Listings")'
                : '✅ Marked as AVAILABLE for Rent. (Now visible to all customers)'),
            backgroundColor: newStatus == 'rented' ? const Color(0xFF0F172A) : AppConstants.accentEmerald,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppConstants.secondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lease & Rental Marketplace',
              style: TextStyle(color: AppConstants.secondary, fontSize: 16.5, fontWeight: FontWeight.bold),
            ),
            Text(
              'Houses, Flats & Rentals • 0% Brokerage',
              style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppConstants.primary),
            onPressed: _loadRentals,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPostPropertyModal,
        backgroundColor: AppConstants.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_home_rounded, size: 21),
        label: const Text(
          'Post Property / List Rental',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: Column(
        children: [
          // 1. Dual Main Navigation Segment Switcher: Properties vs Store Rentals
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  // Tab 0: Properties & Houses (Direct Owner)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeTabIndex = 0;
                          _selectedSubFilter = 'all';
                        });
                        _loadRentals();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _activeTabIndex == 0
                              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.home_work_rounded,
                              size: 17,
                              color: _activeTabIndex == 0 ? const Color(0xFF1E40AF) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Houses & Plots',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: _activeTabIndex == 0 ? FontWeight.bold : FontWeight.w600,
                                color: _activeTabIndex == 0 ? const Color(0xFF1E40AF) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: _activeTabIndex == 0 ? const Color(0xFFDBEAFE) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '0% Broker',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: _activeTabIndex == 0 ? const Color(0xFF1D4ED8) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Tab 1: Store Rentals (Verified Stores)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeTabIndex = 1;
                          _selectedSubFilter = 'all';
                        });
                        _loadRentals();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _activeTabIndex == 1
                              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              size: 17,
                              color: _activeTabIndex == 1 ? AppConstants.primary : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Store Rentals',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: _activeTabIndex == 1 ? FontWeight.bold : FontWeight.w600,
                                color: _activeTabIndex == 1 ? AppConstants.primary : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: _activeTabIndex == 1 ? const Color(0xFFFFEDD5) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: _activeTabIndex == 1 ? const Color(0xFFC2410C) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Search Field
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (val) {
                  _searchQuery = val;
                  _loadRentals();
                },
                decoration: InputDecoration(
                  hintText: _activeTabIndex == 0
                      ? 'Search 2BHK flat, individual house, plot, shop...'
                      : 'Search tent house, DJ sound, travel car, AC, mixer...',
                  hintStyle: const TextStyle(color: AppConstants.textDim, fontSize: 12.5),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppConstants.textMuted, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            _loadRentals();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),

          // 3. Sub-filter Chips Carousel
          if (_activeTabIndex == 0)
            // Houses & Plots (Tab 0) - Original Filter Chips (Untouched)
            Container(
              height: 44,
              color: Colors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _propertyFilters.map((f) {
                  final isSelected = _selectedSubFilter == f['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 6),
                    child: FilterChip(
                      label: Text(f['name']!),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 11.5,
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF2563EB),
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      onSelected: (_) {
                        setState(() => _selectedSubFilter = f['id']!);
                        _loadRentals();
                      },
                    ),
                  );
                }).toList(),
              ),
            )
          else ...[
            // Store Rentals (Tab 1) - Level 1: Subcategories Chips
            Container(
              height: 44,
              color: Colors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  // "All Store Rentals" chip
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 6),
                    child: FilterChip(
                      label: const Text('All Store Rentals'),
                      labelStyle: TextStyle(
                        color: _selectedStoreSubCategoryId == 'all' ? Colors.white : const Color(0xFF334155),
                        fontWeight: _selectedStoreSubCategoryId == 'all' ? FontWeight.bold : FontWeight.w600,
                        fontSize: 11.5,
                      ),
                      selected: _selectedStoreSubCategoryId == 'all',
                      selectedColor: AppConstants.primary,
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _selectedStoreSubCategoryId == 'all' ? AppConstants.primary : const Color(0xFFE2E8F0),
                        ),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedStoreSubCategoryId = 'all';
                          _selectedStoreChildCategoryId = 'all';
                        });
                        _loadRentals();
                      },
                    ),
                  ),
                  // Admin Subcategories
                  ..._adminStoreSubCategories.map((sub) {
                    final subId = sub['id']?.toString() ?? sub['name'].toString();
                    final subName = sub['name']?.toString() ?? 'Category';
                    final isSelected = _selectedStoreSubCategoryId == subId || _selectedStoreSubCategoryId == subName;
                    final emoji = _getSubCategoryEmoji(subName);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 6),
                      child: FilterChip(
                        label: Text('$emoji$subName'),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 11.5,
                        ),
                        selected: isSelected,
                        selectedColor: AppConstants.primary,
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? AppConstants.primary : const Color(0xFFE2E8F0),
                          ),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedStoreSubCategoryId = subId;
                            _selectedStoreChildCategoryId = 'all';
                          });
                          _loadRentals();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Store Rentals (Tab 1) - Level 2: Child Categories Chips (When subcategory is chosen)
            if (_selectedStoreSubCategoryId != 'all' && _getActiveStoreChildCategories().isNotEmpty)
              Container(
                height: 40,
                color: const Color(0xFFFFF7ED),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    // All in Subcategory chip
                    Padding(
                      padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
                      child: ChoiceChip(
                        label: Text(
                          'All ${_getActiveStoreSubCategoryName()}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _selectedStoreChildCategoryId == 'all' ? FontWeight.bold : FontWeight.w600,
                            color: _selectedStoreChildCategoryId == 'all' ? Colors.white : const Color(0xFF9A3412),
                          ),
                        ),
                        selected: _selectedStoreChildCategoryId == 'all',
                        selectedColor: const Color(0xFFDE4915),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: _selectedStoreChildCategoryId == 'all' ? const Color(0xFFDE4915) : const Color(0xFFFDBA74),
                          ),
                        ),
                        onSelected: (_) {
                          setState(() => _selectedStoreChildCategoryId = 'all');
                          _loadRentals();
                        },
                      ),
                    ),
                    // Child categories chips
                    ..._getActiveStoreChildCategories().map((ch) {
                      final rawName = ch['name']?.toString() ?? '';
                      final cleanName = rawName.replaceAll(',/', ' / ').replaceAll(':', '').trim();
                      final isSel = _selectedStoreChildCategoryId == rawName || _selectedStoreChildCategoryId == cleanName;

                      return Padding(
                        padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
                        child: ChoiceChip(
                          label: Text(
                            cleanName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.white : const Color(0xFF431407),
                            ),
                          ),
                          selected: isSel,
                          selectedColor: const Color(0xFFDE4915),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSel ? const Color(0xFFDE4915) : const Color(0xFFFDBA74),
                            ),
                          ),
                          onSelected: (_) {
                            setState(() => _selectedStoreChildCategoryId = rawName);
                            _loadRentals();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],

          // 4. Partner App Notice Banner (only in Store Rentals tab)
          if (_activeTabIndex == 1)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_outlined, color: Color(0xFFD97706), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Commercial store rentals (Tent house, sound systems, vehicles, machinery) are managed exclusively by verified merchants via the Partner App.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          // 5. Results Counter & Location Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppConstants.accentRose, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      'Chodavaram & Nearby Regions',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  _selectedSubFilter == 'my_listings'
                      ? '${_rentals.length} Listings (${_rentals.where((r) => (r['status'] ?? 'available') == 'rented').length} Rented)'
                      : '${_rentals.length} Available',
                  style: TextStyle(
                    color: _activeTabIndex == 0 ? const Color(0xFF2563EB) : AppConstants.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 6. Rental Listings List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rentals.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _activeTabIndex == 0 ? Icons.home_outlined : Icons.inventory_2_outlined,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _activeTabIndex == 0 ? 'No property listings found' : 'No store rental listings found',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConstants.secondary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _activeTabIndex == 0
                                    ? 'Be the first owner to post your house, flat or land for rent with 0% brokerage!'
                                    : 'Store owners can list their commercial rental inventories using the Partner App.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: AppConstants.textMuted),
                              ),
                              const SizedBox(height: 16),
                              if (_activeTabIndex == 0)
                                ElevatedButton.icon(
                                  onPressed: _openPostPropertyModal,
                                  icon: const Icon(Icons.add_home_rounded, size: 18),
                                  label: const Text('Post Your Property Free'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRentals,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);
                            final childAspectRatio = width > 600 ? 0.86 : 0.76;

                            return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(10, 6, 10, 90),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: childAspectRatio,
                              ),
                              itemCount: _rentals.length,
                              itemBuilder: (ctx, idx) => _buildRentalGridCard(_rentals[idx]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _openDetailsScreen(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RentalPropertyDetailsScreen(
          item: item,
          isMyPost: _isMyPost(item),
          onDirections: () => _openDirections(item),
          onCall: (phone) => _makePhoneCall(phone),
          onWhatsApp: (phone, title) => _openWhatsApp(phone, title),
          onEdit: () {
            Navigator.pop(context);
            _openPostPropertyModal(itemToEdit: item);
          },
          onDelete: () async {
            Navigator.pop(context);
            await _confirmDeletePost(item);
          },
          onToggleStatus: () => _toggleListingStatus(item),
        ),
      ),
    );
  }

  Widget _buildRentalGridCard(Map<String, dynamic> item) {
    final isStore = item['listingType'] == 'store';
    final isMine = _isMyPost(item);
    final isRented = (item['status'] ?? 'available') == 'rented';
    final rentPrice = item['rentPrice'] ?? 0;
    final rentPeriod = item['rentPeriod'] == 'day' ? '/day' : '/mo';
    final deposit = item['deposit'] ?? 0;

    List<String> images = [];
    if (item['images'] is List) {
      images = (item['images'] as List).map((e) => e.toString()).toList();
    } else if (item['images'] is String && (item['images'] as String).trim().isNotEmpty) {
      images = (item['images'] as String).trim().split(RegExp(r'\s+'));
    }
    final firstImg = images.isNotEmpty ? images.first : '';

    final title = (item['title'] ?? 'Rental Item').toString();
    final location = (item['village'] ?? item['location'] ?? 'Chodavaram').toString();
    final phone = (item['phone'] ?? '').toString();
    final subCategory = (item['subCategory'] ?? item['categoryName'] ?? 'Rental').toString();
    final specs = item['specifications'] as Map<String, dynamic>?;

    // Highlights for card (BHK, Extent or Facing)
    String? highlightTag;
    if (specs != null) {
      if (specs['plotArea'] != null && specs['plotArea'].toString().isNotEmpty) {
        highlightTag = specs['plotArea'].toString();
      } else if (specs['shopArea'] != null && specs['shopArea'].toString().isNotEmpty) {
        highlightTag = specs['shopArea'].toString();
      } else if (specs['bhk'] != null && specs['bhk'].toString().isNotEmpty && specs['bhk'] != 'N/A' && specs['bhk'] != 'Commercial/Open') {
        highlightTag = specs['bhk'].toString();
      }
    }

    return InkWell(
      onTap: () => _openDetailsScreen(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Thumbnail (Compact 105px)
            SizedBox(
              height: 105,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageWidget(firstImg),

                  // Rented Out Overlay Badge
                  if (isRented)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.48),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_rounded, color: Colors.white, size: 10),
                                SizedBox(width: 3),
                                Text(
                                  'RENTED OUT',
                                  style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Multiple Photos badge
                  if (images.length > 1)
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_rounded, color: Colors.white, size: 9),
                            const SizedBox(width: 3),
                            Text(
                              '${images.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Top Left: Direct Owner vs Store vs My Post
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isMine
                            ? const Color(0xFFD97706)
                            : (isStore
                                ? const Color(0xFF0F172A).withOpacity(0.92)
                                : const Color(0xFF1E40AF).withOpacity(0.92)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMine
                                ? Icons.star_rounded
                                : (isStore ? Icons.verified_rounded : Icons.verified_user_rounded),
                            color: isMine ? Colors.yellowAccent : (isStore ? AppConstants.accentGold : const Color(0xFF60A5FA)),
                            size: 9.5,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isMine ? 'My Post' : (isStore ? 'Store' : 'Owner 0%'),
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top Right: Category Tag
                  if (highlightTag != null || subCategory.isNotEmpty)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          highlightTag ??
                              ((item['childCategory'] != null && item['childCategory'].toString().isNotEmpty)
                                  ? item['childCategory'].toString().replaceAll(',/', ' / ').replaceAll(':', '')
                                  : subCategory),
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 9, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Card Content (Compact & Clean)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹$rentPrice',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          ' $rentPeriod',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        const Spacer(),
                        if (deposit > 0)
                          Text(
                            'Dep: ₹${(deposit / 1000).toStringAsFixed(deposit % 1000 == 0 ? 0 : 1)}k',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          ),
                      ],
                    ),

                    // Title (Compact 2 lines)
                    Text(
                      title,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppConstants.secondary, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppConstants.accentRose, size: 11),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Quick Actions Row (View Details vs Owner Edit/Delete)
                    Container(
                      padding: const EdgeInsets.only(top: 3),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 0.8)),
                      ),
                      child: isMine
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () => _toggleListingStatus(item),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isRented ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                                          size: 13,
                                          color: isRented ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          isRented ? 'Available' : 'Rented',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: isRented ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _openPostPropertyModal(itemToEdit: item),
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_note_rounded, size: 13, color: Color(0xFF2563EB)),
                                        SizedBox(width: 1),
                                        Text('Edit', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                      ],
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _confirmDeletePost(item),
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, size: 12, color: AppConstants.accentRose),
                                        SizedBox(width: 1),
                                        Text('Del', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppConstants.accentRose)),
                                      ],
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _openDetailsScreen(item),
                                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF64748B)),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'View Details',
                                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                    ),
                                    Icon(Icons.chevron_right_rounded, size: 13, color: Color(0xFF2563EB)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (phone.isNotEmpty) ...[
                                      InkWell(
                                        onTap: () => _openWhatsApp(phone, title),
                                        borderRadius: BorderRadius.circular(5),
                                        child: Container(
                                          padding: const EdgeInsets.all(3.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF25D366).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: const Icon(Icons.chat_rounded, color: Color(0xFF16A34A), size: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () => _makePhoneCall(phone),
                                        borderRadius: BorderRadius.circular(5),
                                        child: Container(
                                          padding: const EdgeInsets.all(3.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A).withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: const Icon(Icons.call_rounded, color: Color(0xFF0F172A), size: 12),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imgStr) {
    if (imgStr.startsWith('data:image')) {
      try {
        final commaIdx = imgStr.indexOf(',');
        final base64Data = commaIdx != -1 ? imgStr.substring(commaIdx + 1) : imgStr;
        return Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      } catch (_) {
        return _buildPlaceholder();
      }
    } else if (imgStr.isNotEmpty) {
      return Image.network(
        imgStr,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(child: Icon(Icons.home_work_rounded, size: 44, color: Colors.grey)),
    );
  }
}

// ============================================================================
// FULL PAGE PROPERTY & RENTAL DETAILS SCREEN
// ============================================================================
class RentalPropertyDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isMyPost;
  final VoidCallback onDirections;
  final Function(String phone) onCall;
  final Function(String phone, String title) onWhatsApp;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;

  const RentalPropertyDetailsScreen({
    Key? key,
    required this.item,
    this.isMyPost = false,
    required this.onDirections,
    required this.onCall,
    required this.onWhatsApp,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
  }) : super(key: key);

  @override
  State<RentalPropertyDetailsScreen> createState() => _RentalPropertyDetailsScreenState();
}

class _RentalPropertyDetailsScreenState extends State<RentalPropertyDetailsScreen> {
  final PageController _pageController = PageController();
  int _activePhotoIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _shareProperty(String title, String price, String location, String phone) {
    final text = 'Check out this listing on Loki App:\n🏠 $title\n💰 ₹$price\n📍 $location\n📞 Contact: $phone\n0% Brokerage Direct Owner!';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Property details copied to clipboard! You can share it anywhere.'),
        backgroundColor: AppConstants.accentEmerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildImage(String imgStr) {
    if (imgStr.startsWith('data:image')) {
      try {
        final commaIdx = imgStr.indexOf(',');
        final base64Data = commaIdx != -1 ? imgStr.substring(commaIdx + 1) : imgStr;
        return Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      } catch (_) {
        return _buildPlaceholder();
      }
    } else if (imgStr.isNotEmpty) {
      return Image.network(
        imgStr,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(child: Icon(Icons.home_work_rounded, size: 54, color: Colors.grey)),
    );
  }

  Widget _buildHighlightTile({
    required IconData icon,
    required String label,
    required String value,
    Color iconColor = const Color(0xFF2563EB),
    Color bgColor = const Color(0xFFEFF6FF),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isStore = item['listingType'] == 'store';
    final rentPrice = item['rentPrice'] ?? 0;
    final rentPeriod = item['rentPeriod'] == 'day' ? '/ day' : '/ month';
    final deposit = item['deposit'] ?? 0;

    List<String> images = [];
    if (item['images'] is List) {
      images = (item['images'] as List).map((e) => e.toString()).toList();
    } else if (item['images'] is String && (item['images'] as String).trim().isNotEmpty) {
      images = (item['images'] as String).trim().split(RegExp(r'\s+'));
    }

    final title = (item['title'] ?? 'Rental Property').toString();
    final description = (item['description'] ?? 'No description provided.').toString();
    final location = (item['location'] ?? 'Chodavaram, Anakapalli').toString();
    final landmark = (item['landmark'] ?? '').toString();
    final phone = (item['phone'] ?? '').toString();
    final subCategory = (item['subCategory'] ?? item['categoryName'] ?? 'Rental Property').toString();
    final specs = item['specifications'] as Map<String, dynamic>? ?? {};
    final amenities = specs['amenities'] is List
        ? (specs['amenities'] as List).map((e) => e.toString()).toList()
        : <String>[];

    final hasGps = item['latitude'] != null && item['longitude'] != null &&
        (double.tryParse(item['latitude'].toString()) ?? 0) != 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppConstants.secondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isStore ? 'Store Rental Details' : 'Property Details',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.secondary),
        ),
        actions: [
          if (widget.isMyPost) ...[
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 24),
              tooltip: 'Edit Listing',
              onPressed: widget.onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppConstants.accentRose, size: 22),
              tooltip: 'Delete Listing',
              onPressed: widget.onDelete,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Share',
            onPressed: () => _shareProperty(title, '$rentPrice', location, phone),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Photos Gallery Carousel
            Stack(
              children: [
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: images.isEmpty
                      ? _buildPlaceholder()
                      : PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          onPageChanged: (idx) => setState(() => _activePhotoIndex = idx),
                          itemBuilder: (ctx, idx) => _buildImage(images[idx]),
                        ),
                ),

                // Top Left: Direct Owner 0% Brokerage badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isStore ? const Color(0xFF0F172A).withOpacity(0.92) : const Color(0xFF1E40AF).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isStore ? Icons.verified_rounded : Icons.verified_user_rounded,
                          color: isStore ? AppConstants.accentGold : const Color(0xFF60A5FA),
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isStore ? '⭐ Verified Store' : '🏠 Direct Owner (0% Brokerage)',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Right: Category Tag
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      subCategory,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Bottom Right: Photo Counter Badge (e.g. 1 / 2 Photos)
                if (images.length > 1)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            '${_activePhotoIndex + 1} / ${images.length} Photos',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom Center: Dots Indicator
                if (images.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (idx) {
                        final isActive = idx == _activePhotoIndex;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),

            // 2. Price, Deposit & Title Card (Compact)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price & Deposit Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹$rentPrice',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        ' $rentPeriod',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      const Spacer(),
                      if (deposit > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            'Deposit: ₹$deposit',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppConstants.secondary, height: 1.25),
                  ),
                  const SizedBox(height: 5),

                  // Location Tag
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppConstants.accentRose, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Owner Management Controls (Visible only to the post creator)
            if (widget.isMyPost)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_rounded, color: Color(0xFFB45309), size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'My Listing Controls',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: item['status'] == 'rented' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['status'] == 'rented' ? '🔒 RENTED OUT' : '✅ AVAILABLE',
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              widget.onToggleStatus?.call();
                              setState(() {});
                            },
                            icon: Icon(
                              item['status'] == 'rented' ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                              size: 15,
                              color: item['status'] == 'rented' ? const Color(0xFF047857) : const Color(0xFF92400E),
                            ),
                            label: Text(
                              item['status'] == 'rented' ? '🔓 Mark Available' : '🔒 Mark as Rented',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: item['status'] == 'rented' ? const Color(0xFF047857) : const Color(0xFF92400E),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: item['status'] == 'rented' ? const Color(0xFFECFDF5) : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: BorderSide(
                                color: item['status'] == 'rented' ? const Color(0xFF6EE7B7) : const Color(0xFFFCD34D),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onEdit,
                            icon: const Icon(Icons.edit_note_rounded, size: 16),
                            label: const Text('Edit Listing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // 3. Property Overview / Specifications Grid (Compact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Property Overview & Highlights',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppConstants.secondary),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 3.4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // BHK / Layout
                        if (specs['bhk'] != null && specs['bhk'].toString().isNotEmpty && specs['bhk'] != 'N/A' && specs['bhk'] != 'Commercial/Open')
                          _buildHighlightTile(
                            icon: Icons.bed_rounded,
                            label: 'Configuration / Layout',
                            value: specs['bhk'].toString(),
                            iconColor: const Color(0xFF2563EB),
                            bgColor: const Color(0xFFEFF6FF),
                          ),
                        // Facing
                        if (specs['facing'] != null && specs['facing'].toString().isNotEmpty)
                          _buildHighlightTile(
                            icon: Icons.explore_rounded,
                            label: 'Facing Direction',
                            value: '${specs['facing']} Facing',
                            iconColor: const Color(0xFF0D9488),
                            bgColor: const Color(0xFFF0FDFA),
                          ),
                        // Furnishing
                        if (specs['furnishing'] != null && specs['furnishing'].toString().isNotEmpty)
                          _buildHighlightTile(
                            icon: Icons.chair_rounded,
                            label: 'Furnishing State',
                            value: specs['furnishing'].toString(),
                            iconColor: const Color(0xFF7C3AED),
                            bgColor: const Color(0xFFF5F3FF),
                          ),
                        // Preferred Tenant
                        if (specs['preferredTenant'] != null && specs['preferredTenant'].toString().isNotEmpty)
                          _buildHighlightTile(
                            icon: Icons.people_outline_rounded,
                            label: 'Preferred Tenant',
                            value: specs['preferredTenant'].toString(),
                            iconColor: const Color(0xFFEA580C),
                            bgColor: const Color(0xFFFFF7ED),
                          ),
                        // Plot Area
                        if (specs['plotArea'] != null && specs['plotArea'].toString().isNotEmpty)
                          _buildHighlightTile(
                            icon: Icons.square_foot_rounded,
                            label: 'Plot Extent / Area',
                            value: specs['plotArea'].toString(),
                            iconColor: const Color(0xFF059669),
                            bgColor: const Color(0xFFECFDF5),
                          ),
                        // Commercial Shop Area
                        if (specs['shopArea'] != null && specs['shopArea'].toString().isNotEmpty)
                          _buildHighlightTile(
                            icon: Icons.storefront_rounded,
                            label: 'Floor Area',
                            value: specs['shopArea'].toString(),
                            iconColor: const Color(0xFF4F46E5),
                            bgColor: const Color(0xFFEEF2FF),
                          ),
                        // Category Type
                        _buildHighlightTile(
                          icon: Icons.home_work_rounded,
                          label: 'Listing Type',
                          value: isStore ? 'Commercial Store' : 'Direct Owner',
                          iconColor: const Color(0xFF0F172A),
                          bgColor: const Color(0xFFF8FAFC),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 4. Amenities & Facilities (if present)
            if (amenities.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amenities & Facilities',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppConstants.secondary),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: amenities.map((amenity) {
                          IconData aIcon = Icons.check_circle_rounded;
                          if (amenity.contains('Water')) aIcon = Icons.water_drop_rounded;
                          if (amenity.contains('Parking')) aIcon = Icons.local_parking_rounded;
                          if (amenity.contains('Power') || amenity.contains('Inverter')) aIcon = Icons.bolt_rounded;
                          if (amenity.contains('Lift')) aIcon = Icons.elevator_rounded;
                          if (amenity.contains('CCTV') || amenity.contains('Security')) aIcon = Icons.videocam_rounded;
                          if (amenity.contains('Gated')) aIcon = Icons.shield_rounded;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(aIcon, size: 13, color: const Color(0xFF2563EB)),
                                const SizedBox(width: 5),
                                Text(
                                  amenity,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 5. Description Card
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About this Property / Description',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppConstants.secondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.45),
                    ),
                  ],
                ),
              ),
            ),

            // 6. Location & Landmark Card with Google Maps Navigation
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.navigation_rounded, color: Color(0xFF2563EB), size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Location & Landmark',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppConstants.secondary),
                        ),
                        const Spacer(),
                        if (hasGps)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.gps_fixed_rounded, size: 10, color: Color(0xFF059669)),
                                SizedBox(width: 3),
                                Text(
                                  'GPS Verified',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      location,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                    if (landmark.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Landmark: $landmark',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Turn by turn directions button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onDirections,
                        icon: const Icon(Icons.directions_rounded, size: 16),
                        label: const Text(
                          'Get Google Maps Turn-by-Turn Directions',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 7. Direct Owner Zero Brokerage Trust Banner
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF1E40AF), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isStore ? 'Verified Partner Store' : '0% Brokerage • Direct Owner Listing',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isStore
                                ? 'Contact the verified rental business directly for availability and delivery.'
                                : 'Connect directly with the property owner. Zero middleman commission or brokerage fees.',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 110), // Bottom bar padding
          ],
        ),
      ),

      // Pinned Sticky Bottom Bar: Call, WhatsApp & Directions OR Owner Controls
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          child: widget.isMyPost
              ? Row(
                  children: [
                    // Delete Button
                    OutlinedButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppConstants.accentRose),
                      label: const Text('Delete Post', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.accentRose)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        side: const BorderSide(color: Color(0xFFFECDD3), width: 1.2),
                        backgroundColor: const Color(0xFFFFF1F2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Edit Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('Edit Listing Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Directions button (Outlined)
                    OutlinedButton.icon(
                      onPressed: widget.onDirections,
                      icon: const Icon(Icons.directions_rounded, size: 16, color: Color(0xFF2563EB)),
                      label: const Text('Directions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.2),
                        backgroundColor: const Color(0xFFEFF6FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Call Owner / Store button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: phone.isNotEmpty ? () => widget.onCall(phone) : null,
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: Text(
                          isStore ? 'Call Store' : 'Call Owner',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // WhatsApp Chat button
                    InkWell(
                      onTap: phone.isNotEmpty ? () => widget.onWhatsApp(phone, title) : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 5),
                            Text(
                              'Chat',
                              style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Dedicated Property & Real Estate Posting / Editing Modal (Direct Owner)
class _PostPropertyModal extends StatefulWidget {
  final VoidCallback onSuccess;
  final Map<String, dynamic>? itemToEdit;
  const _PostPropertyModal({Key? key, required this.onSuccess, this.itemToEdit}) : super(key: key);

  @override
  State<_PostPropertyModal> createState() => _PostPropertyModalState();
}

class _PostPropertyModalState extends State<_PostPropertyModal> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Property Subcategories
  final List<String> _propertyTypes = [
    'Houses & Flats (1BHK, 2BHK)',
    'Independent House / Villa',
    'Plots & Open Lands',
    'Commercial Shops & Godowns',
    'PG & Shared Rooms',
  ];
  String _selectedPropertyType = 'Houses & Flats (1BHK, 2BHK)';

  // BHK Selection
  final List<String> _bhkList = ['1 RK', '1 BHK', '2 BHK', '3 BHK', '4+ BHK', 'Commercial/Open'];
  String _selectedBhk = '2 BHK';

  // Area Controllers for Plots and Commercial Spaces
  final TextEditingController _plotAreaController = TextEditingController(text: '200 Sq. Yards');
  final TextEditingController _shopAreaController = TextEditingController(text: '450 Sq. Ft');

  // Furnishing
  final List<String> _furnishingList = ['Unfurnished', 'Semi-Furnished', 'Fully Furnished'];
  String _selectedFurnishing = 'Semi-Furnished';

  // Facing
  final List<String> _facingList = ['East', 'North', 'West', 'South'];
  String _selectedFacing = 'East';

  // Preferred Tenants / Suitable For
  String _selectedTenant = 'Family Only';

  // Amenities / Features Multi-Select
  Set<String> _selectedAmenities = {'24x7 Water', 'Car Parking'};

  List<String> get _currentTenantOptions {
    if (_selectedPropertyType.contains('Plots')) {
      return ['Residential House', 'Commercial / Godown', 'Agriculture', 'Open Storage / Yard'];
    } else if (_selectedPropertyType.contains('Commercial')) {
      return ['Retail Shop', 'Office / IT', 'Bank / ATM', 'Godown / Storage', 'Clinic / Pharmacy'];
    }
    return ['Family Only', 'Bachelors Allowed', 'Anyone'];
  }

  List<String> get _currentAmenityOptions {
    if (_selectedPropertyType.contains('Plots')) {
      return [
        'Boundary Wall / Fenced',
        '30ft / 40ft Wide Road',
        'Borewell / Water Supply',
        'Electricity Connection',
        'Corner Plot',
        'Clear Title / DTCP Approved',
      ];
    } else if (_selectedPropertyType.contains('Commercial')) {
      return [
        'Main Road Facing',
        'Rolling Shutter Installed',
        '3-Phase Power',
        'Customer Parking',
        'Washroom Available',
        'CCTV Security',
      ];
    }
    return [
      '24x7 Water',
      'Car Parking',
      'Bike Parking',
      'Power Backup / Inverter',
      'Lift Available',
      'CCTV Security',
      'Gated Community',
    ];
  }

  // Location Hierarchy State
  late List<String> _districts;
  late String _selectedDistrict;

  late List<String> _mandals;
  late String _selectedMandal;

  late List<String> _villages;
  late String _selectedVillage;
  final TextEditingController _customVillageController = TextEditingController();

  final TextEditingController _landmarkController = TextEditingController(text: 'Near Rythu Bazaar');
  final TextEditingController _phoneController = TextEditingController(text: '9010737882');

  // GPS Coordinates State
  double? _latitude;
  double? _longitude;
  bool _fetchingGps = false;

  // Preset default photo fallback if needed
  static const String _defaultPhoto = 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=900';

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();

  // Dual Compressed Photos State (Base64 dataUrls)
  String? _photo1DataUrl;
  int? _photo1SizeKb;
  bool _compressing1 = false;

  String? _photo2DataUrl;
  int? _photo2SizeKb;
  bool _compressing2 = false;

  bool _submitting = false;

  void _pickAndCompress(int slot, String sourceType) {
    setState(() {
      if (slot == 1) _compressing1 = true;
      if (slot == 2) _compressing2 = true;
    });

    // Safety fallback timeout: reset spinner if browser picker closes or fails to respond within 12 seconds
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted) {
        setState(() {
          if (slot == 1 && _photo1DataUrl == null && _compressing1) _compressing1 = false;
          if (slot == 2 && _photo2DataUrl == null && _compressing2) _compressing2 = false;
        });
      }
    });

    img_helper.pickAndCompressImage(sourceType, (result) {
      if (!mounted) return;
      setState(() {
        if (slot == 1) _compressing1 = false;
        if (slot == 2) _compressing2 = false;

        if (result['success'] == true && result['dataUrl'] != null) {
          final dataUrl = result['dataUrl'].toString();
          final sizeKb = result['fileSizeKb'] is int
              ? result['fileSizeKb'] as int
              : int.tryParse(result['fileSizeKb'].toString()) ?? 45;

          if (slot == 1) {
            _photo1DataUrl = dataUrl;
            _photo1SizeKb = sizeKb;
          } else {
            _photo2DataUrl = dataUrl;
            _photo2SizeKb = sizeKb;
          }
        } else if (result['cancelled'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']?.toString() ?? 'Image selection cancelled or failed'),
              backgroundColor: AppConstants.accentRose,
            ),
          );
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();

    final item = widget.itemToEdit;
    if (item != null) {
      _titleController.text = (item['title'] ?? '').toString();
      _descController.text = (item['description'] ?? '').toString();
      _priceController.text = (item['rentPrice'] ?? '').toString();
      _depositController.text = (item['deposit'] ?? '').toString();
      _phoneController.text = (item['phone'] ?? '').toString();
      _selectedPropertyType = (item['subCategory'] ?? 'Houses & Flats (1BHK, 2BHK)').toString();
      if (!_propertyTypes.contains(_selectedPropertyType)) {
        _selectedPropertyType = _propertyTypes.first;
      }

      _landmarkController.text = (item['landmark'] ?? '').toString();
      _latitude = double.tryParse(item['latitude']?.toString() ?? '');
      _longitude = double.tryParse(item['longitude']?.toString() ?? '');

      // Load existing images
      if (item['images'] is List && (item['images'] as List).isNotEmpty) {
        final imgs = item['images'] as List;
        _photo1DataUrl = imgs[0].toString();
        if (imgs.length > 1) _photo2DataUrl = imgs[1].toString();
      }

      // Load specs
      final specs = item['specifications'] as Map<String, dynamic>? ?? {};
      if (specs['bhk'] != null && _bhkList.contains(specs['bhk'])) _selectedBhk = specs['bhk'].toString();
      if (specs['furnishing'] != null && _furnishingList.contains(specs['furnishing'])) _selectedFurnishing = specs['furnishing'].toString();
      if (specs['facing'] != null && _facingList.contains(specs['facing'])) _selectedFacing = specs['facing'].toString();
      if (specs['preferredTenant'] != null) _selectedTenant = specs['preferredTenant'].toString();
      if (specs['plotArea'] != null) _plotAreaController.text = specs['plotArea'].toString();
      if (specs['shopArea'] != null) _shopAreaController.text = specs['shopArea'].toString();
      if (specs['amenities'] is List) {
        _selectedAmenities = (specs['amenities'] as List).map((e) => e.toString()).toSet();
      }

      // Initialize Location Hierarchy with item district/mandal/village
      _districts = kDefaultAddressHierarchy.keys.toList();
      _selectedDistrict = item['district'] ?? (_districts.contains('Anakapalli') ? 'Anakapalli' : _districts.first);
      final mandalMap = kDefaultAddressHierarchy[_selectedDistrict] ?? {};
      _mandals = mandalMap.keys.toList();
      if (_mandals.isEmpty) _mandals = ['Chodavaram'];
      _selectedMandal = item['mandal'] ?? (_mandals.contains('Chodavaram') ? 'Chodavaram' : _mandals.first);
      final villageList = kDefaultAddressHierarchy[_selectedDistrict]?[_selectedMandal] ?? [];
      _villages = List<String>.from(villageList);
      if (!_villages.contains('Other / Custom Area')) _villages.add('Other / Custom Area');
      _selectedVillage = item['village'] ?? (_villages.contains('Chodavaram Town') ? 'Chodavaram Town' : _villages.first);
    } else {
      _titleController.text = 'Spacious 2BHK House for Rent near Main Road';
      _phoneController.text = _api.currentUser?['phone'] ?? '9010737882';

      // Initialize Location Hierarchy
      _districts = kDefaultAddressHierarchy.keys.toList();
      _selectedDistrict = _districts.contains('Anakapalli') ? 'Anakapalli' : _districts.first;
      _updateMandals();
    }
  }

  void _updateMandals() {
    final mandalMap = kDefaultAddressHierarchy[_selectedDistrict] ?? {};
    _mandals = mandalMap.keys.toList();
    if (_mandals.isEmpty) _mandals = ['Chodavaram'];
    _selectedMandal = _mandals.contains('Chodavaram') ? 'Chodavaram' : _mandals.first;
    _updateVillages();
  }

  void _updateVillages() {
    final villageList = kDefaultAddressHierarchy[_selectedDistrict]?[_selectedMandal] ?? [];
    _villages = List<String>.from(villageList);
    if (!_villages.contains('Other / Custom Area')) {
      _villages.add('Other / Custom Area');
    }
    _selectedVillage = _villages.contains('Chodavaram Town') ? 'Chodavaram Town' : _villages.first;
  }

  void _onTypeChanged(String type) {
    setState(() {
      _selectedPropertyType = type;
      if (type.contains('Plots')) {
        _selectedBhk = 'N/A';
        _titleController.text = 'Open Residential Plot / Land for Lease';
        _descController.text = 'Prime clear-title plot with wide road access. Suitable for residential construction or open storage.';
        _selectedTenant = 'Residential House';
        _selectedAmenities = {'Boundary Wall / Fenced', '30ft / 40ft Wide Road'};
      } else if (type.contains('Commercial')) {
        _selectedBhk = 'Commercial/Open';
        _titleController.text = 'Prime Commercial Shop / Office Space';
        _descController.text = 'Main road facing shop with rolling shutter and 3-phase power in a prime market area.';
        _selectedTenant = 'Retail Shop';
        _selectedAmenities = {'Main Road Facing', 'Rolling Shutter Installed'};
      } else if (type.contains('Independent')) {
        _selectedBhk = '2 BHK';
        _titleController.text = 'Independent House / Villa for Rent';
        _descController.text = 'East facing, 24/7 municipal water, dedicated parking, peaceful residential colony.';
        _selectedTenant = 'Family Only';
        _selectedAmenities = {'24x7 Water', 'Car Parking'};
      } else {
        _selectedBhk = '2 BHK';
        _titleController.text = 'Spacious 2BHK House for Rent near Main Road';
        _descController.text = 'Well-ventilated flat with modern amenities, car parking and 24x7 water supply.';
        _selectedTenant = 'Family Only';
        _selectedAmenities = {'24x7 Water', 'Car Parking'};
      }
    });
  }

  Future<void> _detectGpsLocation() async {
    setState(() => _fetchingGps = true);
    try {
      final coords = await getCurrentGpsCoordinates();
      if (coords != null && mounted) {
        setState(() {
          _latitude = coords['lat'];
          _longitude = coords['lng'];
          _fetchingGps = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Exact GPS coordinates tagged: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'),
            backgroundColor: AppConstants.accentEmerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } catch (_) {}

    // Fallback default coordinates for Chodavaram center if browser GPS denied
    if (mounted) {
      setState(() {
        _latitude = 17.8283;
        _longitude = 82.9345;
        _fetchingGps = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS coordinates set to Chodavaram center (17.8283, 82.9345)'),
          backgroundColor: AppConstants.accentEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _previewMapLocation() async {
    if (_latitude == null || _longitude == null) return;
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submitPropertyPost() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid monthly rent amount'), backgroundColor: AppConstants.accentRose),
      );
      return;
    }

    setState(() => _submitting = true);

    final List<String> finalImages = [];
    if (_photo1DataUrl != null && _photo1DataUrl!.isNotEmpty) {
      finalImages.add(_photo1DataUrl!);
    }
    if (_photo2DataUrl != null && _photo2DataUrl!.isNotEmpty) {
      finalImages.add(_photo2DataUrl!);
    }
    if (finalImages.isEmpty) {
      finalImages.add(_defaultPhoto);
    }

    final villageName = _selectedVillage == 'Other / Custom Area'
        ? (_customVillageController.text.trim().isNotEmpty ? _customVillageController.text.trim() : 'Local Area')
        : _selectedVillage;
    final landmark = _landmarkController.text.trim();
    final fullLocation = landmark.isNotEmpty
        ? '$landmark, $villageName, $_selectedMandal'
        : '$villageName, $_selectedMandal';

    final isPlot = _selectedPropertyType.contains('Plots');
    final isCommercial = _selectedPropertyType.contains('Commercial');
    final isResidential = !isPlot && !isCommercial;

    final postData = {
      'listingType': 'owner',
      'category': 'properties',
      'categoryName': 'Properties & Real Estate',
      'subCategory': _selectedPropertyType,
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'rentPrice': price,
      'rentPeriod': 'month',
      'deposit': double.tryParse(_depositController.text.trim()) ?? 0,
      'district': _selectedDistrict,
      'mandal': _selectedMandal,
      'village': villageName,
      'landmark': landmark,
      'location': fullLocation,
      'latitude': _latitude,
      'longitude': _longitude,
      'phone': _phoneController.text.trim(),
      'whatsappPhone': _phoneController.text.trim(),
      'images': finalImages,
      'isAvailable': true,
      'specifications': {
        if (isResidential) 'bhk': _selectedBhk,
        if (isResidential || isCommercial) 'furnishing': _selectedFurnishing,
        if (isPlot) 'plotArea': _plotAreaController.text.trim(),
        if (isCommercial) 'shopArea': _shopAreaController.text.trim(),
        'facing': _selectedFacing,
        'preferredTenant': _selectedTenant,
        'amenities': _selectedAmenities.toList(),
      },
    };

    final isEdit = widget.itemToEdit != null;
    final ok = isEdit
        ? await _api.updateRentalPost(widget.itemToEdit!['id']?.toString() ?? '', postData)
        : await _api.createRentalPost(postData);

    if (mounted) {
      setState(() => _submitting = false);
      if (ok) {
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? 'Failed to update listing. Please try again.'
                : 'Failed to publish listing. Please check your connection and try again.'),
            backgroundColor: AppConstants.accentRose,
          ),
        );
      }
    }
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppConstants.textDim),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
    );
  }

  void _showPhotoSourceBottomSheet(int slot, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Upload $title',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose photo source (Auto-compressed via HTML5):',
              style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(bottomSheetCtx);
                      _pickAndCompress(slot, 'camera');
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 32, color: Color(0xFF2563EB)),
                          SizedBox(height: 8),
                          Text('Camera', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                          SizedBox(height: 2),
                          Text('Take a new photo', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(bottomSheetCtx);
                      _pickAndCompress(slot, 'gallery');
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library_rounded, size: 32, color: Color(0xFF0F172A)),
                          SizedBox(height: 8),
                          Text('Gallery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          SizedBox(height: 2),
                          Text('Choose from files', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                        ],
                      ),
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

  Widget _buildPhotoUploadCard({
    required int slot,
    required String title,
    required String? dataUrl,
    required int? sizeKb,
    required bool isCompressing,
    required VoidCallback onClear,
  }) {
    final hasPhoto = dataUrl != null && dataUrl.isNotEmpty;

    return InkWell(
      onTap: isCompressing ? null : () => _showPhotoSourceBottomSheet(slot, title),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 155,
        decoration: BoxDecoration(
          color: hasPhoto ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasPhoto ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
            width: hasPhoto ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: isCompressing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(height: 8),
                    Text('Compressing...', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              )
            : hasPhoto
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Builder(
                        builder: (_) {
                          if (dataUrl.startsWith('http://') || dataUrl.startsWith('https://')) {
                            return Image.network(
                              dataUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
                              ),
                            );
                          }
                          try {
                            final commaIdx = dataUrl.indexOf(',');
                            final base64Str = commaIdx != -1 ? dataUrl.substring(commaIdx + 1) : dataUrl;
                            return Image.memory(
                              base64Decode(base64Str),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
                              ),
                            );
                          } catch (_) {
                            return const Center(
                              child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
                            );
                          }
                        },
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: InkWell(
                          onTap: onClear,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 15),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          color: Colors.black.withOpacity(0.72),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                (dataUrl.startsWith('http://') || dataUrl.startsWith('https://'))
                                    ? '✓ Current Photo'
                                    : '✓ Compressed (${sizeKb ?? 45} KB)',
                                style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit_rounded, color: Colors.white70, size: 11),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Icon(Icons.add_a_photo_outlined, size: 26, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Tap to choose',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
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
    final isPlot = _selectedPropertyType.contains('Plots');
    final isCommercial = _selectedPropertyType.contains('Commercial');
    final isResidential = !isPlot && !isCommercial;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 18,
        left: 18,
        right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.itemToEdit != null ? Icons.edit_note_rounded : Icons.add_home_work_rounded,
                        color: const Color(0xFF2563EB),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.itemToEdit != null ? 'Edit Property Listing' : 'Post Property for Rent',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppConstants.secondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                widget.itemToEdit != null
                    ? 'Update your property details, pricing, photos or contact information'
                    : 'Enter property details to find tenants without any brokerage charges',
                style: const TextStyle(fontSize: 11.5, color: AppConstants.textMuted),
              ),
              const SizedBox(height: 14),

              // Zero Brokerage Owner Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Direct Owner Listing • 0% Brokerage • Free Ad',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1. Property Type Selector
              const Text('1. Property Type *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedPropertyType,
                decoration: _inputDeco('Select Property Type'),
                items: _propertyTypes.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12.5)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) _onTypeChanged(val);
                },
              ),
              const SizedBox(height: 14),

              // 2. Dynamic Configuration based on Property Type
              if (isResidential) ...[
                const Text('2. Rooms / BHK *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _bhkList.take(5).map((bhk) {
                    final isSel = _selectedBhk == bhk;
                    return ChoiceChip(
                      label: Text(bhk),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                        color: isSel ? Colors.white : const Color(0xFF334155),
                      ),
                      selected: isSel,
                      selectedColor: const Color(0xFF2563EB),
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (_) => setState(() => _selectedBhk = bhk),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Residential Furnishing & Facing
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Furnishing *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 5),
                          DropdownButtonFormField<String>(
                            value: _selectedFurnishing,
                            decoration: _inputDeco('Furnishing'),
                            items: _furnishingList.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedFurnishing = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Facing *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 5),
                          DropdownButtonFormField<String>(
                            value: _selectedFacing,
                            decoration: _inputDeco('Facing'),
                            items: _facingList.map((f) => DropdownMenuItem(value: f, child: Text('$f Facing', style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedFacing = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ] else if (isPlot) ...[
                // Plot Extent & Facing (No Furnishing needed for open lands!)
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Plot Extent / Area *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _plotAreaController,
                            decoration: _inputDeco('e.g. 200 Sq. Yards / 5 Cents / 1 Acre'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter plot area' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Facing *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 5),
                          DropdownButtonFormField<String>(
                            value: _selectedFacing,
                            decoration: _inputDeco('Facing'),
                            items: _facingList.map((f) => DropdownMenuItem(value: f, child: Text('$f Facing', style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedFacing = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ] else if (isCommercial) ...[
                // Commercial Space, Setup & Facing
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Shop / Floor Area *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _shopAreaController,
                            decoration: _inputDeco('e.g. 450 Sq. Ft'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter shop area' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fit-out / Setup *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 5),
                          DropdownButtonFormField<String>(
                            value: _selectedFurnishing,
                            decoration: _inputDeco('Setup'),
                            items: _furnishingList.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedFurnishing = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Facing *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      value: _selectedFacing,
                      decoration: _inputDeco('Facing'),
                      items: _facingList.map((f) => DropdownMenuItem(value: f, child: Text('$f Facing', style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFacing = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // 3. Rent Amount & Security Deposit
              const Text('3. Rent Price & Security Deposit *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco('Rent / Month (₹) e.g. 7500'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter monthly rent' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _depositController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco('Advance Deposit (₹) e.g. 15000'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Preferred Tenants / Suitable For
              Text(
                isPlot
                    ? '4. Suitable For (Plot Usage) *'
                    : (isCommercial ? '4. Suitable For (Business Category) *' : '4. Preferred Tenant *'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _currentTenantOptions.map((t) {
                  final isSel = _selectedTenant == t;
                  return ChoiceChip(
                    label: Text(t),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? Colors.white : const Color(0xFF334155),
                    ),
                    selected: isSel,
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (_) => setState(() => _selectedTenant = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // 5. Amenities / Features
              Text(
                isPlot
                    ? '5. Plot Features & Infrastructure'
                    : (isCommercial ? '5. Commercial Features & Utilities' : '5. Amenities'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _currentAmenityOptions.map((amenity) {
                  final isSel = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    label: Text(amenity),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? Colors.white : const Color(0xFF334155),
                    ),
                    selected: isSel,
                    selectedColor: const Color(0xFF0F172A),
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // 6. Property Photos (Upload 2 Photos via Camera / Gallery with HTML5 Canvas Compression)
              const Row(
                children: [
                  Icon(Icons.add_a_photo_rounded, size: 16, color: Color(0xFF2563EB)),
                  SizedBox(width: 6),
                  Text('6. Upload Property Photos (2 Photos) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.secondary)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Capture live photos using Camera or pick from Gallery. Photos are auto-compressed via HTML5 for fast database storage.',
                style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
              ),
              const SizedBox(height: 10),

              // Two Photo Upload Slots (Photo 1 & Photo 2)
              Row(
                children: [
                  // Photo 1 (Main / Front View)
                  Expanded(
                    child: _buildPhotoUploadCard(
                      slot: 1,
                      title: 'Photo 1 (Front View) *',
                      dataUrl: _photo1DataUrl,
                      sizeKb: _photo1SizeKb,
                      isCompressing: _compressing1,
                      onClear: () => setState(() {
                        _photo1DataUrl = null;
                        _photo1SizeKb = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Photo 2 (Inside / Extra View)
                  Expanded(
                    child: _buildPhotoUploadCard(
                      slot: 2,
                      title: 'Photo 2 (Inside View)',
                      dataUrl: _photo2DataUrl,
                      sizeKb: _photo2SizeKb,
                      isCompressing: _compressing2,
                      onClear: () => setState(() {
                        _photo2DataUrl = null;
                        _photo2SizeKb = null;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 7. Title & Description
              const Text('7. Title & Description *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: _inputDeco('e.g. Spacious 2BHK House for rent near Main Road'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: _inputDeco('Key features, water supply, parking, environment...'),
              ),
              const SizedBox(height: 16),

              // 9. Location Hierarchy: District -> Mandal -> Village Dropdowns + Landmark
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Text('8. Location Details *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.secondary)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // District & Mandal Dropdowns
                    Row(
                      children: [
                        // District Dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('District *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: _selectedDistrict,
                                decoration: _inputDeco('District'),
                                items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (val) {
                                  if (val != null && val != _selectedDistrict) {
                                    setState(() {
                                      _selectedDistrict = val;
                                      _updateMandals();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Mandal Dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mandal *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: _mandals.contains(_selectedMandal) ? _selectedMandal : _mandals.first,
                                decoration: _inputDeco('Mandal'),
                                items: _mandals.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedMandal = val;
                                      _updateVillages();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Village / Ward Dropdown
                    const Text('Village / Ward / Area *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _villages.contains(_selectedVillage) ? _selectedVillage : _villages.first,
                      decoration: _inputDeco('Select Village / Ward'),
                      items: _villages.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedVillage = val);
                      },
                    ),

                    // If "Other / Custom Area" selected, show custom village input
                    if (_selectedVillage == 'Other / Custom Area') ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _customVillageController,
                        decoration: _inputDeco('Enter Village, Ward or Colony name'),
                        validator: (v) => (_selectedVillage == 'Other / Custom Area' && (v == null || v.trim().isEmpty)) ? 'Enter your area name' : null,
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Landmark & Street Address Box
                    const Text('Landmark & Street Address *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _landmarkController,
                      decoration: _inputDeco('e.g. Near Rythu Bazaar, Beside RCM Church, Main Road'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a landmark or street address' : null,
                    ),

                    const SizedBox(height: 12),

                    // GPS Location Picker for Directions Navigation
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _latitude != null ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _latitude != null ? Icons.my_location_rounded : Icons.add_location_alt_outlined,
                                size: 16,
                                color: _latitude != null ? AppConstants.accentEmerald : const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _latitude != null
                                      ? 'GPS Location Tagged (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                                      : 'GPS Pin for Google Maps Directions',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: _latitude != null ? const Color(0xFF166534) : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              if (_latitude != null)
                                InkWell(
                                  onTap: _previewMapLocation,
                                  child: const Text('View on Map', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton.icon(
                            onPressed: _fetchingGps ? null : _detectGpsLocation,
                            icon: _fetchingGps
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.gps_fixed_rounded, size: 14),
                            label: Text(
                              _latitude != null ? 'Re-detect / Update GPS Location' : 'Tag My Current GPS Location',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _latitude != null ? const Color(0xFF0F172A) : const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Enables customers to get 1-click turn-by-turn driving directions to your house via Google Maps.',
                            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 10. Owner Contact Phone
              const Text('9. Owner Contact Phone Number *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDeco('10-Digit Mobile Number (e.g. 9010737882)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter owner contact number' : null,
              ),
              const SizedBox(height: 16),

              // Partner Notice Alert at bottom of modal
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: Commercial rental inventories (tent house, sound systems, vehicles, machinery) must be managed through the Partner App.',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Submit Button
              ElevatedButton(
                onPressed: _submitting ? null : _submitPropertyPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        widget.itemToEdit != null ? '💾 Save Changes / Update' : 'Publish Property Listing',
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
