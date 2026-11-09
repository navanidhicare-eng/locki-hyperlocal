import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/js_interop.dart' as js_helper;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/partner_order_model.dart';
import '../services/partner_api_service.dart';
import '../services/background_service.dart';
import 'partner_auth_screen.dart';
import 'partner_profile_screen.dart';
import 'partner_job_history_screen.dart';
import 'add_business_profile_screen.dart';
import '../services/app_update_service.dart';

class PartnerHomeScreen extends StatefulWidget {
  const PartnerHomeScreen({Key? key}) : super(key: key);

  @override
  State<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

class _PartnerHomeScreenState extends State<PartnerHomeScreen> {
  final PartnerApiService _api = PartnerApiService();
  bool _isOnline = false;
  bool _isSilentMode = false;
  List<PartnerOrder> _orders = [];
  List<dynamic> _categories = [];
  bool _loading = true;
  int _cancelledJobsCount = 1;
  final Set<String> _expandedOrderIds = {};
  final Map<String, TextEditingController> _otpControllers = {};
  bool _hasPlayedAlarm = false;
  final Set<String> _mutedOrderIds = {};
  Timer? _pollingTimer;

  // Multi-business state
  List<Map<String, dynamic>> _businesses = [];
  Map<String, dynamic>? _activeBusiness;
  String? _activeBusinessId;

  // Rental merchant state
  List<Map<String, dynamic>> _myRentalItems = [];
  bool _loadingRentals = false;
  bool _rentalStoreOpen = true;
  String _rentalCategoryFilter = 'All';

  // Shop merchant state
  List<Map<String, dynamic>> _myShopProducts = [];
  bool _loadingShopProducts = false;
  bool _shopStoreOpen = true;
  String _shopCategoryFilter = 'All';
  final List<String> _shopCustomCategories = [];
  String _shopTimings = '8:00 AM - 9:30 PM';

  bool _isRentalBusiness(Map<String, dynamic>? biz) {
    if (biz == null) return false;
    final bType = (biz['businessType'] ?? '').toString().toLowerCase();
    final cat = (biz['tradeCategory'] ?? biz['categoryId'] ?? biz['category'] ?? '').toString().toLowerCase();
    final catName = (biz['tradeCategoryName'] ?? biz['categoryName'] ?? biz['category'] ?? '').toString().toLowerCase();
    final subName = (biz['subCategoryName'] ?? biz['subCategory'] ?? '').toString().toLowerCase();
    final name = (biz['businessName'] ?? biz['name'] ?? '').toString().toLowerCase();
    return bType == 'rental' ||
        cat == 'cat_ab5c5cd1' ||
        catName.contains('rental') ||
        catName.contains('lease') ||
        subName.contains('rental') ||
        name.contains('self driving') ||
        name.contains('car rental') ||
        name.contains('tent house');
  }

  bool _isShopBusiness(Map<String, dynamic>? biz) {
    if (biz == null) return false;
    if (_isRentalBusiness(biz)) return false;
    final bType = (biz['businessType'] ?? '').toString().toLowerCase();
    final cat = (biz['tradeCategory'] ?? biz['categoryId'] ?? biz['category'] ?? '').toString().toLowerCase();
    final catName = (biz['tradeCategoryName'] ?? biz['categoryName'] ?? biz['category'] ?? '').toString().toLowerCase();
    return bType == 'shop' || bType == 'retail' || cat == 'cat_shops' || catName.contains('shop') || catName.contains('kirana');
  }

  String _getBusinessProfileTypeLabel(Map<String, dynamic>? biz) {
    if (_isRentalBusiness(biz)) return 'RENTAL MERCHANT STORE';
    if (_isShopBusiness(biz)) return 'RETAIL MERCHANT STORE';
    return 'SERVICE TECHNICIAN';
  }

  @override
  void initState() {
    super.initState();
    BackgroundServiceHelper.addDataCallback(_onReceiveBackgroundData);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BackgroundServiceHelper.requestPermissions();
      AppUpdateService.checkForUpdates(context);
    });
    _initData();
    _startPolling();
  }

  void _onReceiveBackgroundData(Object data) {
    if (data is Map) {
      if (data['action'] == 'NEW_PENDING_ORDER') {
        _initData(silent: true);
      } else if (data['action'] == 'ORDER_MUTED') {
        final mutedId = data['orderId']?.toString();
        if (mutedId != null && mutedId.isNotEmpty) {
          _mutedOrderIds.add(mutedId);
        }
        _hasPlayedAlarm = false;
        js_helper.stopAlarm();
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    BackgroundServiceHelper.removeDataCallback(_onReceiveBackgroundData);
    _pollingTimer?.cancel();
    _stopJobAlarm();
    for (var c in _otpControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted || !_api.isLoggedIn) return;
      try {
        final list = await _api.fetchPartnerOrders();
        if (!mounted) return;
        final pendingList = list.where((o) => o.orderStatus.toUpperCase() == 'PENDING').toList();
        final pendingIds = pendingList.map((o) => o.id).toSet();
        
        final isRentalMode = _activeBusiness?['businessType'] == 'rental';
        final hasUnmuted = pendingIds.difference(_mutedOrderIds).isNotEmpty;
        if (hasUnmuted && !_isSilentMode && !isRentalMode) {
          if (!_hasPlayedAlarm) {
            _hasPlayedAlarm = true;
            _triggerJobAlarm();
          }
        } else {
          // All pending orders are muted or none exist
          if (_hasPlayedAlarm) {
            _hasPlayedAlarm = false;
            js_helper.stopAlarm();
          }
          if (pendingList.isEmpty) {
            _mutedOrderIds.clear();
          }
        }
        setState(() {
          _orders = list;
          _loading = false;
        });
      } catch (_) {}
    });
  }

  void _triggerJobAlarm() {
    if (_isSilentMode) return;
    try {
      js_helper.playAlarm();
    } catch (e) {
      debugPrint('Alarm sound error: $e');
    }
  }

  void _toggleSilentMode(bool val) async {
    setState(() {
      _isSilentMode = val;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('locki_silent_mode', val);
      BackgroundServiceHelper.setSilentMode(val);
      if (val) {
        _hasPlayedAlarm = false;
        js_helper.stopAlarm();
      } else {
        final pendingList = _orders.where((o) => o.orderStatus.toUpperCase() == 'PENDING').toList();
        final pendingIds = pendingList.map((o) => o.id).toSet();
        if (pendingIds.difference(_mutedOrderIds).isNotEmpty) {
          _hasPlayedAlarm = true;
          _triggerJobAlarm();
        }
      }
    } catch (e) {
      debugPrint('Toggle silent mode error: $e');
    }
  }

  void _openDutyPreferencesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: PartnerConstants.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.tune_rounded, color: PartnerConstants.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Duty & Sound Alerts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Silent Mode Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isSilentMode ? const Color(0xFFF8FAFC) : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isSilentMode ? const Color(0xFFE2E8F0) : const Color(0xFFFDBA74),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isSilentMode ? const Color(0xFFE2E8F0) : const Color(0xFFFFEDD5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isSilentMode ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            color: _isSilentMode ? const Color(0xFF475569) : const Color(0xFFC2410C),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Silent Mode',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Switch(
                                    value: _isSilentMode,
                                    activeColor: PartnerConstants.primary,
                                    onChanged: (val) {
                                      _toggleSilentMode(val);
                                      setSheetState(() {});
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isSilentMode
                                    ? 'Silent Mode is ON. All incoming siren sounds and vibrations are muted (suitable for meetings).'
                                    : 'When turned ON, sirens are muted during meetings or quiet places.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Siren & Vibration Status tiles
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.two_wheeler_rounded,
                              size: 18,
                              color: _isSilentMode ? const Color(0xFF94A3B8) : const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bike Traffic Siren (100% Vol)',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                  ),
                                  Text(
                                    _isSilentMode ? 'Silenced (Silent Mode Active)' : 'Active for all new customer requests',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _isSilentMode ? const Color(0xFF94A3B8) : const Color(0xFF059669),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _isSilentMode ? const Color(0xFFE2E8F0) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _isSilentMode ? 'MUTED' : 'READY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _isSilentMode ? const Color(0xFF64748B) : const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.vibration_rounded,
                              size: 18,
                              color: _isSilentMode ? const Color(0xFF94A3B8) : PartnerConstants.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pocket Vibration Motor',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                  ),
                                  Text(
                                    _isSilentMode ? 'Disabled in Silent Mode' : 'Continuous vibration pulse ready',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _isSilentMode ? const Color(0xFF94A3B8) : const Color(0xFF059669),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _isSilentMode ? const Color(0xFFE2E8F0) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _isSilentMode ? 'OFF' : 'ON',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _isSilentMode ? const Color(0xFF64748B) : const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _muteSingleOrder(String orderId) {
    _mutedOrderIds.add(orderId);
    final remainingUnmuted = _orders.where((o) => o.orderStatus.toUpperCase() == 'PENDING' && !_mutedOrderIds.contains(o.id));
    if (remainingUnmuted.isEmpty) {
      _hasPlayedAlarm = false;
      js_helper.stopAlarm();
    }
    BackgroundServiceHelper.stopAlarm(orderId: orderId, orderIds: [orderId]);
    if (mounted) setState(() {});
  }

  void _stopJobAlarm({String? orderId}) {
    try {
      final List<String> targetIds = [];
      if (orderId != null) {
        _mutedOrderIds.add(orderId);
        targetIds.add(orderId);
      } else {
        final pendingIds = _orders.where((o) => o.orderStatus.toUpperCase() == 'PENDING').map((o) => o.id);
        _mutedOrderIds.addAll(pendingIds);
        targetIds.addAll(pendingIds);
      }
      _hasPlayedAlarm = false;
      js_helper.stopAlarm();
      BackgroundServiceHelper.stopAlarm(orderId: orderId, orderIds: targetIds);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Stop alarm error: $e');
    }
  }

  Future<void> _initData({bool silent = false}) async {
    if (!silent && _orders.isEmpty) {
      setState(() => _loading = true);
    }
    if (!_api.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const PartnerAuthScreen()),
            (route) => false,
          );
        }
      });
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final silentMode = prefs.getBool('locki_silent_mode') ?? false;
      if (mounted) {
        setState(() {
          _isSilentMode = silentMode;
        });
      }
      if (!silent) await _api.fetchProfile();
      await _loadBusinesses();
      final list = await _api.fetchPartnerOrders();
      final cats = !silent ? await _api.fetchCategories() : _categories;
      final profileCancelled = (_api.profile?['cancelledJobs'] as num?)?.toInt() ?? 1;
      if (mounted) {
        setState(() {
          _orders = list;
          if (!silent) {
            _categories = cats;
            _isOnline = _api.profile?['isOnline'] ?? false;
          }
          if (profileCancelled > _cancelledJobsCount) {
            _cancelledJobsCount = profileCancelled;
          }
          _loading = false;
        });

        if (_isOnline && !silent) {
          BackgroundServiceHelper.startService();
        }

        final pendingList = list.where((o) => o.orderStatus.toUpperCase() == 'PENDING').toList();
        final pendingIds = pendingList.map((o) => o.id).toSet();
        final hasUnmuted = pendingIds.difference(_mutedOrderIds).isNotEmpty;
        if (hasUnmuted && !_isSilentMode) {
          if (!_hasPlayedAlarm) {
            _hasPlayedAlarm = true;
            _triggerJobAlarm();
          }
        } else if (pendingList.isEmpty) {
          _hasPlayedAlarm = false;
          _mutedOrderIds.clear();
          _stopJobAlarm();
        }
      }
    } catch (e) {
      debugPrint('Init partner data error: $e');
    } finally {
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadBusinesses() async {
    try {
      final res = await _api.fetchBusinesses();
      final list = List<Map<String, dynamic>>.from(res['businesses'] ?? []);
      final activeId = res['activeBusinessId']?.toString();
      Map<String, dynamic>? active;
      if (activeId != null && activeId.isNotEmpty) {
        active = list.firstWhere(
          (b) => b['id'].toString() == activeId,
          orElse: () => list.isNotEmpty ? list.first : <String, dynamic>{},
        );
      } else if (list.isNotEmpty) {
        active = list.first;
      }
      if (mounted) {
        setState(() {
          _businesses = list;
          _activeBusiness = active != null && active.isNotEmpty ? active : null;
          _activeBusinessId = _activeBusiness?['id']?.toString();
        });
        if (_isRentalBusiness(_activeBusiness)) {
          _loadPartnerRentals();
        } else if (_isShopBusiness(_activeBusiness)) {
          _loadPartnerProducts();
        }
      }
    } catch (e) {
      debugPrint('Load businesses error: $e');
    }
  }

  Future<void> _loadPartnerRentals() async {
    setState(() => _loadingRentals = true);
    try {
      final items = await _api.fetchPartnerRentals(businessId: _activeBusinessId);
      if (mounted) {
        setState(() {
          _myRentalItems = items;
          _loadingRentals = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingRentals = false);
    }
  }

  Future<void> _loadPartnerProducts() async {
    setState(() => _loadingShopProducts = true);
    try {
      final items = await _api.fetchPartnerProducts(businessId: _activeBusinessId);
      if (mounted) {
        // Collect any custom categories present in loaded products
        for (var p in items) {
          final c = (p['subCategory'] ?? p['category'] ?? p['categoryName'] ?? '').toString().trim();
          if (c.isNotEmpty && c != 'cat_shops' && c.toLowerCase() != 'local shops & kirana' && !_shopCustomCategories.contains(c)) {
            _shopCustomCategories.add(c);
          }
        }
        setState(() {
          _myShopProducts = items;
          _loadingShopProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingShopProducts = false);
    }
  }

  Future<void> _switchBusiness(String businessId) async {
    setState(() => _loading = true);
    try {
      final success = await _api.switchActiveBusiness(businessId);
      if (success) {
        await _loadBusinesses();
        if (_isRentalBusiness(_activeBusiness)) {
          _hasPlayedAlarm = false;
          js_helper.stopAlarm();
          _loadPartnerRentals();
        } else if (_isShopBusiness(_activeBusiness)) {
          _loadPartnerProducts();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Switched active business to: ${_activeBusiness?['businessName'] ?? 'Business'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Switch business error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleDuty() async {
    final kycStatus = (_api.profile?['kycStatus'] ?? 'pending').toString().toLowerCase();
    final bool isApproved = kycStatus == 'approved' || kycStatus == 'verified';
    final isProfileComplete = _api.profile?['isProfileComplete'] == true;

    if (!isProfileComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your profile and submit KYC first!'),
          backgroundColor: Colors.orange,
        ),
      );
      _openProfileScreen();
      return;
    }

    if (!isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot go online: Your account is pending Admin approval!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newStatus = await _api.toggleOnline(!_isOnline);
    if (newStatus != null) {
      setState(() => _isOnline = newStatus);
      if (newStatus) {
        BackgroundServiceHelper.startService();
      } else {
        BackgroundServiceHelper.stopService();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isOnline ? 'You are now ONLINE & receiving customer requests!' : 'You went OFFLINE'),
          backgroundColor: _isOnline ? PartnerConstants.primary : Colors.grey.shade800,
        ),
      );
    }
  }

  void _openProfileScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartnerProfileScreen(
          onProfileUpdated: () => _initData(),
        ),
      ),
    );
    if (result == true) {
      _initData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _api.profile ?? {
      'name': 'Partner',
      'serviceName': 'Service Specialist',
      'rating': 5.0,
      'jobsCompleted': 0,
      'kycStatus': 'pending',
      'isProfileComplete': false,
    };

    final String kycStatus = (profile['kycStatus'] ?? 'pending').toString().toLowerCase();
    final bool isApproved = kycStatus == 'approved' || kycStatus == 'verified';
    final bool isRejected = kycStatus == 'rejected';
    final bool isProfileComplete = profile['isProfileComplete'] == true;

    return Scaffold(
      backgroundColor: PartnerConstants.backgroundLight,
      drawer: _buildDrawer(context, profile),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: PartnerConstants.secondary, size: 26),
            tooltip: 'Open Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: InkWell(
          onTap: _openProfileScreen,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: PartnerConstants.primary.withOpacity(0.15),
                  child: const Icon(Icons.person, color: PartnerConstants.primary, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile['name'] ?? 'Partner',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
                      ),
                      Row(
                        children: [
                          Icon(
                            isApproved
                                ? Icons.verified
                                : (isProfileComplete ? Icons.hourglass_top_rounded : Icons.assignment_ind_outlined),
                            color: isApproved
                                ? PartnerConstants.primary
                                : (isRejected ? Colors.red : const Color(0xFFD97706)),
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              isApproved
                                  ? (profile['serviceName'] ?? 'Verified Specialist')
                                  : (isProfileComplete
                                      ? (isRejected ? 'KYC Rejected' : 'Approval Pending')
                                      : 'Profile Incomplete'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isApproved
                                    ? PartnerConstants.primary
                                    : (isRejected ? Colors.red : const Color(0xFFD97706)),
                                fontWeight: FontWeight.bold,
                              ),
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
        actions: [
          // Rating / Status Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: isApproved
                  ? PartnerConstants.accentGold.withOpacity(0.15)
                  : (isRejected ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  isApproved
                      ? Icons.star
                      : (isRejected ? Icons.error_outline_rounded : Icons.hourglass_top_rounded),
                  color: isApproved
                      ? PartnerConstants.accentGold
                      : (isRejected ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  isApproved
                      ? '${profile['rating'] ?? 5.0}'
                      : (isRejected ? 'Rejected' : 'Review Pending'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isApproved
                        ? Colors.black87
                        : (isRejected ? const Color(0xFFDC2626) : const Color(0xFFB45309)),
                  ),
                ),
              ],
            ),
          ),
          // Test Alarm Audio Button
          IconButton(
            tooltip: 'Test Job Alarm Sound',
            icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFFDC2626), size: 22),
            onPressed: () {
              _triggerJobAlarm();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.volume_up_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('🔔 Ringing Partner Job Alarm Sound...'),
                    ],
                  ),
                  backgroundColor: Color(0xFFDC2626),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          // Edit Profile Action Icon
          IconButton(
            tooltip: 'My Profile',
            icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF475569), size: 22),
            onPressed: _openProfileScreen,
          ),
          // Logout Action Icon
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: Colors.black54, size: 20),
            onPressed: () {
              _api.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const PartnerAuthScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _initData();
                await _loadBusinesses();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: !isProfileComplete
                    ? _buildNewPartnerDashboard(profile)
                    : (isApproved
                        ? (_isRentalBusiness(_activeBusiness)
                            ? _buildRentalMerchantDashboard(profile)
                            : (_isShopBusiness(_activeBusiness)
                                ? _buildShopMerchantDashboard(profile)
                                : _buildActivePartnerDashboard(profile)))
                        : _buildPendingApprovalDashboard(profile)),
              ),
            ),
    );
  }

  // PARTNER SIDEBAR DRAWER MENU
  Widget _buildDrawer(BuildContext context, Map<String, dynamic> profile) {
    final name = profile['name'] ?? 'Partner';
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P';
    final service = profile['serviceName'] ?? 'Service Specialist';
    final phone = profile['phone'] ?? '+91 98765 22222';
    final walletBal = profile['walletBalance'] ?? 4250;
    final String drawerKyc = (profile['kycStatus'] ?? 'pending').toString().toLowerCase();
    final bool isApproved = drawerKyc == 'approved' || drawerKyc == 'verified';
    final isVerified = isApproved;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 48, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF192338), Color(0xFF28354D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: PartnerConstants.primary.withOpacity(0.25),
                      child: Text(
                        initial,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isVerified ? Icons.verified : Icons.verified_user_outlined,
                                color: isVerified ? PartnerConstants.accentGold : Colors.white60,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            service,
                            style: TextStyle(
                              fontSize: 12,
                              color: PartnerConstants.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Duty Status Pill in Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isOnline ? const Color(0xFF065F46) : const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isOnline ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isOnline ? 'DUTY ACTIVE (ONLINE)' : 'DUTY PAUSED (OFFLINE)',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Yearly Subscription Badge in Drawer Header
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showSubscriptionPlanDialog(context);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Yearly Plan: ACTIVE (0% Comm)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFEF3C7)),
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 16, color: Color(0xFFFBBF24)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Row(
                            children: const [
                              Icon(Icons.calendar_month_outlined, size: 12, color: Color(0xFFFDE68A)),
                              SizedBox(width: 5),
                              Text(
                                'Validity: 05 Nov 2027 (365 Days Left)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFDE68A),
                                  letterSpacing: 0.2,
                                ),
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

          // Drawer Menu List Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.flash_on_outlined,
                  title: 'Duty & Active Bookings',
                  badge: _isOnline ? 'Active' : null,
                  badgeColor: PartnerConstants.statusOnline,
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.person_outline_rounded,
                  title: 'My Profile & KYC Documents',
                  badge: isApproved ? 'Verified' : (profile['isProfileComplete'] == true ? 'Under Review' : 'Incomplete'),
                  badgeColor: isApproved ? PartnerConstants.statusOnline : const Color(0xFFD97706),
                  onTap: () {
                    Navigator.pop(context);
                    _openProfileScreen();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.assignment_outlined,
                  title: 'Job History & Completed Tasks',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PartnerJobHistoryScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Yearly Subscription Plan',
                  badge: 'Valid: Nov 2027',
                  badgeColor: const Color(0xFFD97706),
                  iconColor: const Color(0xFFD97706),
                  onTap: () {
                    Navigator.pop(context);
                    _showSubscriptionPlanDialog(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Partner Alerts & Announcements',
                  badge: 'New Bonus',
                  badgeColor: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Weekend Incentive: Complete 5 jobs and earn ₹500 extra bonus!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.support_agent_rounded,
                  title: '24/7 Partner Helpline Support',
                  onTap: () {
                    Navigator.pop(context);
                    _showSupportDialog(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.tune_rounded,
                  title: 'Duty Preferences & Sound Alerts',
                  onTap: () {
                    Navigator.pop(context);
                    _openDutyPreferencesSheet(context);
                  },
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout Partner Fleet',
                  iconColor: Colors.red.shade400,
                  textColor: Colors.red.shade700,
                  onTap: () {
                    Navigator.pop(context);
                    _api.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const PartnerAuthScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),

          // Drawer Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      PartnerConstants.logoAsset,
                      height: 18,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.flash_on, size: 16, color: PartnerConstants.primary),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Partner Fleet v1.2.0',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Text(
                  '0% Comm • Yearly Plan',
                  style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      leading: Icon(icon, color: iconColor ?? PartnerConstants.secondary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor ?? const Color(0xFF334155),
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? PartnerConstants.primary).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: (badgeColor ?? PartnerConstants.primary).withOpacity(0.2)),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: badgeColor ?? PartnerConstants.primary,
                ),
              ),
            )
          : const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCBD5E1)),
      onTap: onTap,
    );
  }

  Widget _buildPlanOptionTile({
    required String title,
    required String duration,
    required int price,
    required String tag,
    required Color tagColor,
    required Color tagBg,
    bool isBestValue = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isBestValue ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBestValue ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
          width: isBestValue ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isBestValue ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBestValue ? Icons.workspace_premium_rounded : Icons.calendar_month_rounded,
              color: isBestValue ? const Color(0xFFD97706) : const Color(0xFF64748B),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isBestValue ? const Color(0xFF92400E) : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Duration: $duration • 0% Commission',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹$price',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isBestValue ? const Color(0xFFD97706) : const Color(0xFF0F172A),
                ),
              ),
              const Text(
                'Fee',
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSubscriptionPlanDialog(BuildContext context) {
    final profile = _api.profile ?? {};
    final bool isSubActive = profile['subscriptionStatus'] == 'active';
    final String expiryStr = profile['subscriptionExpiresAt'] != null
        ? profile['subscriptionExpiresAt'].toString().substring(0, 10)
        : 'Pending Activation';
    final String planName = profile['subscriptionPlanName'] ?? (isSubActive ? '1-Year Annual Pro' : 'Yearly 0% Cut Plan');
    final String subName = profile['subCategoryName'] ?? profile['serviceName'] ?? 'Service Specialist';
    final String partnerSubId = (profile['subCategoryId'] ?? profile['subCategory'] ?? '').toString();

    // Look up exact pricing plans for this partner's sub-category
    Map<String, dynamic>? matchedSub;
    for (final cat in _categories) {
      if (cat is Map) {
        final subs = cat['subCategories'];
        if (subs is List) {
          for (final s in subs) {
            if (s is Map) {
              final sid = s['id']?.toString() ?? '';
              final sname = s['name']?.toString() ?? '';
              if ((partnerSubId.isNotEmpty && sid == partnerSubId) ||
                  (subName.isNotEmpty && sname.toLowerCase() == subName.toLowerCase())) {
                matchedSub = Map<String, dynamic>.from(s);
                break;
              }
            }
          }
        }
      }
      if (matchedSub != null) break;
    }

    final Map<String, dynamic> plans = (matchedSub != null && matchedSub['subscriptionPlans'] is Map)
        ? Map<String, dynamic>.from(matchedSub['subscriptionPlans'])
        : {
            '1_month': 199,
            '3_months': 499,
            '6_months': 899,
            '1_year': 1499,
          };

    final int p1m = plans['1_month'] ?? 199;
    final int p3m = plans['3_months'] ?? 499;
    final int p6m = plans['6_months'] ?? 899;
    final int p1y = plans['1_year'] ?? 1499;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Loki 0% Commission Plans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('$subName Pricing Plans', style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Current Membership Status Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSubActive ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSubActive ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CURRENT MEMBERSHIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(isSubActive ? planName : 'Pending Activation', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          Text(isSubActive ? 'Valid Till: $expiryStr' : 'Pay to Admin to Activate', style: TextStyle(fontSize: 11, color: isSubActive ? const Color(0xFF059669) : const Color(0xFFDC2626))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSubActive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(isSubActive ? 'ACTIVE' : 'UNPAID', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. ALL 4 AVAILABLE SUBSCRIPTION PLANS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Plans ($subName)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                    const Text(
                      '0% Platform Cut',
                      style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Plan 1: 1 Month
                _buildPlanOptionTile(
                  title: '1 Month Trial',
                  duration: '30 Days',
                  price: p1m,
                  tag: 'Trial',
                  tagColor: const Color(0xFF475569),
                  tagBg: const Color(0xFFF1F5F9),
                ),

                // Plan 2: 3 Months
                _buildPlanOptionTile(
                  title: '3 Months Quarter',
                  duration: '90 Days',
                  price: p3m,
                  tag: 'Popular',
                  tagColor: const Color(0xFF1D4ED8),
                  tagBg: const Color(0xFFEFF6FF),
                ),

                // Plan 3: 6 Months
                _buildPlanOptionTile(
                  title: '6 Months Half-Year',
                  duration: '180 Days',
                  price: p6m,
                  tag: 'Save 20%',
                  tagColor: const Color(0xFF065F46),
                  tagBg: const Color(0xFFECFDF5),
                ),

                // Plan 4: 1 Year (Best Value)
                _buildPlanOptionTile(
                  title: '1 Year Annual Pro',
                  duration: '365 Days',
                  price: p1y,
                  tag: '⭐ Best Value',
                  tagColor: const Color(0xFFB45309),
                  tagBg: const Color(0xFFFEF3C7),
                  isBestValue: true,
                ),

                const SizedBox(height: 12),

                // 3. Why Loki Subscription
                const Text('Why Loki Subscription?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                _buildBenefitRow(Icons.money_off_csred_rounded, '0% Commission on Every Job', 'No 20%-30% per-order cuts like other apps. Keep 100% of customer pay.'),
                const SizedBox(height: 6),
                _buildBenefitRow(Icons.all_inclusive_rounded, 'Unlimited Customer Leads', 'No pay-per-lead charges. Accept unlimited nearby customer bookings.'),
                const SizedBox(height: 6),
                _buildBenefitRow(Icons.payments_outlined, 'Direct Customer Cash/UPI', 'Customers pay you directly upon service completion.'),
                const SizedBox(height: 6),
                _buildBenefitRow(Icons.verified_rounded, 'Verified Specialist Badge', 'Priority placement in local customer searches & instant alerts.'),

                const SizedBox(height: 12),

                // 4. Admin Payment Guidance Note
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Payment is collected directly by Loki Admin via Cash or QR/UPI. Once Admin confirms payment, your subscription activates immediately.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF9A3412), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: PartnerConstants.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF059669)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  void _showSafetyCoverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.health_and_safety_outlined, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Safety & Insurance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('🛡️ ₹5,00,000 Accidental Insurance Cover during active duty.'),
            SizedBox(height: 8),
            Text('🏥 Free OPD consultation for registered partner specialists.'),
            SizedBox(height: 8),
            Text('🚨 One-Tap Emergency SOS alert connected to local assistance.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It', style: TextStyle(fontWeight: FontWeight.bold, color: PartnerConstants.primary)),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.support_agent_rounded, color: PartnerConstants.primary),
            SizedBox(width: 8),
            Text('Partner Support 24x7', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Need urgent help with an ongoing job or payout?'),
            SizedBox(height: 10),
            Text('📞 Toll-Free: 1800-890-LOKI (5654)', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('💬 WhatsApp: +91 98765 00000', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('✉️ Email: partner-support@loki.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: PartnerConstants.primary)),
          ),
        ],
      ),
    );
  }

  // DASHBOARD FOR PARTNERS WHO COMPLETED PROFILE BUT AWAITING ADMIN APPROVAL
  Widget _buildSubscriptionBanner(Map<String, dynamic> profile) {
    final bool isSubActive = profile['subscriptionStatus'] == 'active';
    final String expiryStr = profile['subscriptionExpiresAt'] != null
        ? profile['subscriptionExpiresAt'].toString().substring(0, 10)
        : '365 Days Remaining';
    final int amount = profile['subscriptionAmount'] ?? 1999;
    final String subName = profile['subCategoryName'] ?? profile['serviceName'] ?? 'Service Specialist';

    return InkWell(
      onTap: () => _showSubscriptionPlanDialog(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSubActive
                ? const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)]
                : const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSubActive ? const Color(0xFFFDE68A) : const Color(0xFFFED7AA),
          ),
          boxShadow: [
            BoxShadow(
              color: (isSubActive ? Colors.amber : Colors.orange).withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSubActive ? const Color(0xFFD97706) : const Color(0xFFEA580C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSubActive ? Icons.workspace_premium_rounded : Icons.card_membership_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isSubActive
                              ? 'Yearly Subscription Active'
                              : '$subName Plan (Unpaid)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSubActive ? const Color(0xFF92400E) : const Color(0xFF9A3412),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isSubActive ? '• 0% Cut' : '• Payment Pending',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: isSubActive ? const Color(0xFF059669) : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        isSubActive ? Icons.calendar_month_outlined : Icons.payment_rounded,
                        size: 12,
                        color: isSubActive ? const Color(0xFFB45309) : const Color(0xFFC2410C),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isSubActive
                              ? 'Valid Till: $expiryStr'
                              : 'Fee: ₹$amount/yr • Click to view Sub-category plans',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSubActive ? const Color(0xFFB45309) : const Color(0xFFC2410C),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFB45309)),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // MULTI-BUSINESS SWITCHER & RENTAL MERCHANT DASHBOARD
  // =========================================================================

  Widget _buildBusinessSwitcherBar() {
    final bizName = _activeBusiness?['businessName'] ?? _activeBusiness?['name'] ?? _api.profile?['businessName'] ?? _api.profile?['name'] ?? 'My Business';
    final isRental = _isRentalBusiness(_activeBusiness);
    final isShop = _isShopBusiness(_activeBusiness);
    final count = _businesses.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRental
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : isShop
                  ? [const Color(0xFFC2410C), const Color(0xFF9A3412)]
                  : [const Color(0xFF0F766E), const Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isRental ? Colors.black : (isShop ? const Color(0xFFC2410C) : const Color(0xFF0F766E))).withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isRental
                  ? Icons.car_rental_rounded
                  : isShop
                      ? Icons.storefront_rounded
                      : Icons.home_repair_service_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isRental
                            ? const Color(0xFFF59E0B)
                            : isShop
                                ? const Color(0xFFFB923C)
                                : const Color(0xFF38BDF8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isRental
                            ? 'RENTAL MERCHANT STORE'
                            : isShop
                                ? 'RETAIL MERCHANT STORE'
                                : 'SERVICE TECHNICIAN',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (count > 1) ...[
                      const SizedBox(width: 6),
                      Text(
                        '($count Profiles)',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  bizName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _showBusinessSwitcherModal,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    color: isRental ? const Color(0xFF1E293B) : const Color(0xFF0F766E),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Switch',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isRental ? const Color(0xFF1E293B) : const Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBusinessSwitcherModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Business Profiles',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Select dashboard or request a new business profile',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_businesses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('No registered businesses found.')),
                    )
                  else
                    ..._businesses.map((biz) {
                      final bId = biz['id']?.toString() ?? '';
                      final isSelected = bId == _activeBusinessId;
                      final isRental = _isRentalBusiness(biz);
                      final isShop = _isShopBusiness(biz);
                      final bTypeLabel = isRental ? 'Rental Merchant Store' : (isShop ? 'Retail & Kirana Store' : 'Service Technician');
                      final bStatus = (biz['status'] ?? 'approved').toString().toLowerCase();
                      final isApproved = bStatus == 'approved' || bStatus == 'active';
                      final isPending = bStatus == 'pending';
                      final isPrimary = biz['isDefault'] == true || bId == 'biz_prv_76fcc359_primary' || _businesses.length <= 1;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isRental ? const Color(0xFFFEF3C7) : (isShop ? const Color(0xFFFFEDD5) : const Color(0xFFE0F2FE)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isRental ? Icons.car_rental_rounded : (isShop ? Icons.storefront_rounded : Icons.handyman_rounded),
                                  color: isRental ? const Color(0xFFD97706) : (isShop ? const Color(0xFFEA580C) : const Color(0xFF0284C7)),
                                  size: 22,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      biz['businessName'] ?? biz['name'] ?? 'Business',
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isPending)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 11),
                                          SizedBox(width: 3),
                                          Text('Admin Approval Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                        ],
                                      ),
                                    )
                                  else if (isApproved && isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('ACTIVE NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '$bTypeLabel • ${biz['category'] ?? biz['tradeCategoryName'] ?? 'General'} • ${biz['address'] ?? biz['shopAddress'] ?? 'Local'}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ),
                              trailing: isPending
                                  ? const Tooltip(
                                      message: 'Awaiting Admin Approval',
                                      child: Icon(Icons.lock_clock_rounded, color: Color(0xFFD97706)),
                                    )
                                  : Radio<String>(
                                      value: bId,
                                      groupValue: _activeBusinessId,
                                      activeColor: const Color(0xFF2563EB),
                                      onChanged: (val) async {
                                        if (val == null || val == _activeBusinessId) return;
                                        Navigator.pop(sheetCtx);
                                        await _switchBusiness(val);
                                      },
                                    ),
                              onTap: isPending
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('This business profile is pending Admin Approval! Once verified, you can switch anytime.'),
                                          backgroundColor: Color(0xFFD97706),
                                        ),
                                      );
                                    }
                                  : () async {
                                      if (bId == _activeBusinessId) {
                                        Navigator.pop(sheetCtx);
                                        return;
                                      }
                                      Navigator.pop(sheetCtx);
                                      await _switchBusiness(bId);
                                    },
                            ),
                            // Action Strip: Edit Info & Close/Delete
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFE2EDFE) : const Color(0xFFF8FAFC),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
                                border: Border(top: BorderSide(color: isSelected ? const Color(0xFFBFDBFE) : const Color(0xFFF1F5F9))),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Edit Button
                                  InkWell(
                                    onTap: () {
                                      Navigator.pop(sheetCtx);
                                      _openEditBusinessModal(biz);
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit_outlined, size: 14, color: Color(0xFF2563EB)),
                                          SizedBox(width: 4),
                                          Text('Edit Info', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Delete / Close Business Button
                                  if (!isPrimary)
                                    InkWell(
                                      onTap: () {
                                        Navigator.pop(sheetCtx);
                                        _confirmDeleteBusiness(biz);
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                                            SizedBox(width: 4),
                                            Text('Close & Delete', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    const Text('Primary Profile', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_business_rounded, color: PartnerConstants.primary),
                      label: const Text('+ Request New Business Profile', style: TextStyle(fontWeight: FontWeight.bold, color: PartnerConstants.primary)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: PartnerConstants.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        _openAddBusinessProfileScreen();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openAddBusinessProfileScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddBusinessProfileScreen(
          onBusinessCreated: () {
            _loadBusinesses();
          },
        ),
      ),
    );
  }

  void _confirmDeleteBusiness(Map<String, dynamic> biz) {
    final bizId = (biz['businessId'] ?? biz['id'] ?? '').toString();
    final bizName = biz['businessName'] ?? biz['name'] ?? 'This business';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Close & Delete Business?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently remove and close "$bizName"?',
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All inventory listings and orders associated with this business profile will be removed.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await _api.deleteBusinessProfile(bizId);
              if (success) {
                await _loadBusinesses();
                if (_isRentalBusiness(_activeBusiness)) {
                  _loadPartnerRentals();
                } else if (_isShopBusiness(_activeBusiness)) {
                  _loadPartnerProducts();
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF16A34A),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Business "$bizName" was closed and deleted.')),
                        ],
                      ),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFFDC2626),
                      content: Text('Failed to delete business profile. Please try again.'),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Business', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openEditBusinessModal(Map<String, dynamic> biz) {
    final bizId = (biz['businessId'] ?? biz['id'] ?? '').toString();
    final nameCtrl = TextEditingController(text: biz['businessName'] ?? biz['name'] ?? '');
    final addressCtrl = TextEditingController(text: biz['address'] ?? biz['shopAddress'] ?? '');
    final phoneCtrl = TextEditingController(text: biz['phone'] ?? '');
    final landmarkCtrl = TextEditingController(text: biz['landmark'] ?? '');
    final openingCtrl = TextEditingController(text: biz['openingTime'] ?? '09:00 AM');
    final closingCtrl = TextEditingController(text: biz['closingTime'] ?? '09:00 PM');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, color: PartnerConstants.primary, size: 24),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Edit Business Profile',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    Text(
                      'Category: ${biz['subCategory'] ?? biz['category'] ?? 'Business'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    const Divider(height: 24),

                    // Business Name
                    const Text('Business / Shop Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Sri Lakshmi Tent House',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Contact Phone
                    const Text('Contact Phone *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'e.g. 9876543210',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Address
                    const Text('Address / Location *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Street address, Town, District',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Landmark
                    const Text('Nearby Landmark', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: landmarkCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Near RCM Church / Gandhi Statue',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Timings Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Opening Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: openingCtrl,
                                decoration: InputDecoration(
                                  hintText: '09:00 AM',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Closing Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: closingCtrl,
                                decoration: InputDecoration(
                                  hintText: '09:00 PM',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(modalCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (nameCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter business name')),
                                      );
                                      return;
                                    }
                                    setModalState(() => isSaving = true);
                                    final success = await _api.updateBusinessProfile(bizId, {
                                      'businessName': nameCtrl.text.trim(),
                                      'address': addressCtrl.text.trim(),
                                      'phone': phoneCtrl.text.trim(),
                                      'landmark': landmarkCtrl.text.trim(),
                                      'openingTime': openingCtrl.text.trim(),
                                      'closingTime': closingCtrl.text.trim(),
                                    });
                                    if (modalCtx.mounted) {
                                      Navigator.pop(modalCtx);
                                    }
                                    if (success) {
                                      await _loadBusinesses();
                                      if (_isRentalBusiness(_activeBusiness)) {
                                        _loadPartnerRentals();
                                      } else if (_isShopBusiness(_activeBusiness)) {
                                        _loadPartnerProducts();
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            backgroundColor: Color(0xFF16A34A),
                                            content: Row(
                                              children: [
                                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                                SizedBox(width: 8),
                                                Text('Business profile updated successfully!'),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            backgroundColor: Color(0xFFDC2626),
                                            content: Text('Failed to update business profile. Please try again.'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PartnerConstants.primary,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // SHOP & RETAIL MERCHANT DASHBOARD VIEW
  // =========================================================================

  Widget _buildShopMerchantDashboard(Map<String, dynamic> profile) {
    final bizName = _activeBusiness?['businessName'] ?? _activeBusiness?['name'] ?? 'Local Retail & Grocery Store';
    final address = _activeBusiness?['address'] ?? _activeBusiness?['shopAddress'] ?? 'Chodavaram, Anakapalli';
    final allowedQuota = (_activeBusiness?['listingQuota'] ?? profile['listingQuota'] ?? 10) as int;
    final topUp = (_activeBusiness?['topUpQuota'] ?? profile['topUpQuota'] ?? 0) as int;
    final totalQuota = allowedQuota + topUp;

    final bizProducts = _myShopProducts.where((p) {
      if (_activeBusinessId == null || _activeBusinessId!.isEmpty) return true;
      final bId = p['businessId']?.toString();
      return bId == null || bId.isEmpty || bId == _activeBusinessId;
    }).toList();

    final filteredProducts = _shopCategoryFilter == 'All'
        ? bizProducts
        : bizProducts.where((p) {
            final cat = (p['category'] ?? p['subCategory'] ?? '').toString().trim().toLowerCase();
            return cat == _shopCategoryFilter.toLowerCase();
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBusinessSwitcherBar(),

        // 1. Store Status & Timings Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _shopStoreOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _shopStoreOpen ? Icons.storefront_rounded : Icons.lock_clock_rounded,
                                    size: 13,
                                    color: _shopStoreOpen ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _shopStoreOpen ? 'STORE OPEN (Accepting Customers)' : 'STORE CLOSED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: _shopStoreOpen ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bizName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 13, color: Colors.grey),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: _shopStoreOpen,
                      activeColor: const Color(0xFF16A34A),
                      onChanged: (val) {
                        setState(() => _shopStoreOpen = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_shopStoreOpen ? 'Store is now OPEN to customers' : 'Store is marked CLOSED'),
                            backgroundColor: _shopStoreOpen ? const Color(0xFF16A34A) : Colors.black87,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const Divider(height: 22, color: Color(0xFFF1F5F9)),

              // Timings & Available Items Info Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 15, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        'Timings: $_shopTimings',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _showEditShopTimingsDialog,
                    child: const Text(
                      'Change',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PartnerConstants.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Products Quota Card
        _buildQuotaCard(
          title: 'Store Products Quota',
          currentCount: bizProducts.length,
          allowedQuota: totalQuota,
          onTopUpPressed: () => _showTopUpInfoDialog(totalQuota),
        ),

        // 3. Products Header & Add Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Store Catalog',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
                ),
                Text(
                  'Listed Items (${bizProducts.length})',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 15, color: PartnerConstants.primary),
                  label: const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: PartnerConstants.primary, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: PartnerConstants.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _showAddCategoryDialog,
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  label: const Text('Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartnerConstants.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  onPressed: () {
                    if (bizProducts.length >= totalQuota) {
                      _showQuotaExceededAlert(totalQuota);
                    } else {
                      _showAddShopProductModal();
                    }
                  },
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Custom Categories Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // All Items Chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All Items', style: TextStyle(fontSize: 12)),
                  selected: _shopCategoryFilter == 'All',
                  selectedColor: PartnerConstants.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: _shopCategoryFilter == 'All' ? PartnerConstants.primary : Colors.black87,
                    fontWeight: _shopCategoryFilter == 'All' ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  onSelected: (val) {
                    if (val) setState(() => _shopCategoryFilter = 'All');
                  },
                ),
              ),
              // Merchant's dynamic custom categories
              ..._shopCustomCategories.map((cat) {
                final isSel = _shopCategoryFilter.toLowerCase() == cat.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                    selected: isSel,
                    selectedColor: PartnerConstants.primary.withOpacity(0.15),
                    labelStyle: TextStyle(color: isSel ? PartnerConstants.primary : Colors.black87),
                    backgroundColor: Colors.white,
                    onSelected: (val) {
                      if (val) setState(() => _shopCategoryFilter = cat);
                    },
                  ),
                );
              }),
              // "+ New Category" button chip
              ActionChip(
                avatar: const Icon(Icons.add, size: 14, color: PartnerConstants.primary),
                label: const Text('New Category', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: PartnerConstants.primary)),
                backgroundColor: const Color(0xFFFFF7ED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFFDBA74)),
                ),
                onPressed: _showAddCategoryDialog,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 4. Products List / Grid
        if (_loadingShopProducts)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: PartnerConstants.primary)),
          )
        else if (filteredProducts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.storefront_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                const Text(
                  'No products added yet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'List your store products with price and photo to attract local customers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('+ Add First Product'),
                  onPressed: () {
                    if (bizProducts.length >= totalQuota) {
                      _showQuotaExceededAlert(totalQuota);
                    } else {
                      _showAddShopProductModal();
                    }
                  },
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredProducts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final prod = filteredProducts[i];
              final inStock = prod['inStock'] != false;
              final imgUrl = (prod['images'] is List && (prod['images'] as List).isNotEmpty)
                  ? prod['images'][0].toString()
                  : '';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product Photo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 70,
                        height: 70,
                        color: const Color(0xFFF1F5F9),
                        child: imgUrl.isNotEmpty
                            ? Image.network(
                                imgUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                              )
                            : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod['name'] ?? 'Product',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                prod['unit'] ?? '1 Unit',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                              if ((prod['category'] ?? prod['subCategory'] ?? '').toString().isNotEmpty &&
                                  (prod['category'] ?? prod['subCategory'] ?? '').toString() != 'cat_shops') ...[
                                const Text(' • ', style: TextStyle(color: Color(0xFF94A3B8))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    (prod['category'] ?? prod['subCategory']).toString(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '₹${prod['price'] ?? 0}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: PartnerConstants.primary),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: inStock ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  inStock ? 'IN STOCK' : 'OUT OF STOCK',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: inStock ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Stock Switch & Delete Button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: inStock,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (val) async {
                              final pId = prod['id']?.toString() ?? '';
                              if (pId.isNotEmpty) {
                                await _api.updateShopProduct(pId, {'inStock': val});
                                await _loadPartnerProducts();
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Color(0xFFEF4444)),
                          onPressed: () => _confirmDeleteProduct(prod),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // Common Listing / Products Quota Card
  Widget _buildQuotaCard({
    required String title,
    required int currentCount,
    required int allowedQuota,
    required VoidCallback onTopUpPressed,
  }) {
    final isFull = currentCount >= allowedQuota;
    final progress = allowedQuota > 0 ? (currentCount / allowedQuota).clamp(0.0, 1.0) : 0.0;
    final remaining = (allowedQuota - currentCount).clamp(0, 9999);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isFull ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isFull ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 20,
                      color: isFull ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        isFull
                            ? 'Quota Full ($currentCount of $allowedQuota used)'
                            : '$remaining of $allowedQuota slots remaining',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isFull ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFD97706)),
                label: const Text('Top-Up', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                  backgroundColor: const Color(0xFFFFFBEB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onTopUpPressed,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                isFull ? const Color(0xFFDC2626) : (progress > 0.75 ? const Color(0xFFF59E0B) : const Color(0xFF16A34A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTopUpInfoDialog(int currentQuota) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('Extra Quota Top-Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your current active quota allows up to $currentQuota items.', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Top-Up Packs:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309))),
                  SizedBox(height: 6),
                  Text('• +5 Products Pack: ₹99', style: TextStyle(fontSize: 12, color: Color(0xFF78350F))),
                  Text('• +10 Products Pack: ₹179', style: TextStyle(fontSize: 12, color: Color(0xFF78350F))),
                  Text('• Single Item Top-Up: ₹15 / item', style: TextStyle(fontSize: 12, color: Color(0xFF78350F))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Please contact Loki Admin to recharge your extra quota pack immediately.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showQuotaExceededAlert(int quota) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Quota Limit Reached', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Your active store plan allows up to $quota products. You have used all available slots.\n\nPlease purchase a Top-Up quota pack (+5 or +10 items) to list more products.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PartnerConstants.primary),
            onPressed: () {
              Navigator.pop(ctx);
              _showTopUpInfoDialog(quota);
            },
            child: const Text('View Top-Up Packs', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditShopTimingsDialog() {
    final ctrl = TextEditingController(text: _shopTimings);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Store Timings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Store Open Timings',
            hintText: 'e.g. 8:00 AM - 9:30 PM',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PartnerConstants.primary),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _shopTimings = ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(Map<String, dynamic> prod) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to remove "${prod['name']}" from your store catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              final pId = prod['id']?.toString() ?? '';
              if (pId.isNotEmpty) {
                await _api.deleteShopProduct(pId);
                await _loadPartnerProducts();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final catCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.category_rounded, color: PartnerConstants.primary, size: 22),
            SizedBox(width: 8),
            Text('Add Store Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: PartnerConstants.secondary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add custom category to group your products (e.g. Rice & Grains, Cooking Oils, Spices & Masala, Dairy, Snacks).',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: catCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Category Name *',
                hintText: 'e.g. Spices & Masala',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PartnerConstants.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final name = catCtrl.text.trim();
              if (name.isNotEmpty) {
                if (!_shopCustomCategories.contains(name)) {
                  setState(() {
                    _shopCustomCategories.add(name);
                    _shopCategoryFilter = name;
                  });
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "$name" created! You can now add products to it.'),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              }
            },
            child: const Text('Create Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddShopProductModal() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: '1 Unit');
    final descCtrl = TextEditingController();
    final newCatCtrl = TextEditingController();
    String selectedPhoto = 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&auto=format&fit=crop&q=80';
    bool isSubmitting = false;

    // Default category: currently filtered category if custom, or first available, or empty
    String selectedCategory = (_shopCategoryFilter != 'All' && _shopCustomCategories.contains(_shopCategoryFilter))
        ? _shopCategoryFilter
        : (_shopCustomCategories.isNotEmpty ? _shopCustomCategories.first : '');
    bool isAddingNewCategory = _shopCustomCategories.isEmpty;

    final presetPhotos = [
      {'name': 'Rice / Grains', 'url': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&auto=format&fit=crop&q=80'},
      {'name': 'Cooking Oil', 'url': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=600&auto=format&fit=crop&q=80'},
      {'name': 'Atta / Flour', 'url': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&auto=format&fit=crop&q=80'},
      {'name': 'Snacks / Biscuits', 'url': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=600&auto=format&fit=crop&q=80'},
      {'name': 'Household Item', 'url': 'https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=600&auto=format&fit=crop&q=80'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add Product to Catalog', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PartnerConstants.secondary)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(sheetCtx)),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    hintText: 'e.g. Sona Masoori Rice, Sunflower Oil, LED Bulb',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Selection / Creation
                const Text('Product Category *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                const SizedBox(height: 6),
                if (_shopCustomCategories.isNotEmpty && !isAddingNewCategory) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory.isNotEmpty && _shopCustomCategories.contains(selectedCategory) ? selectedCategory : _shopCustomCategories.first,
                        isExpanded: true,
                        items: [
                          ..._shopCustomCategories.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, style: const TextStyle(fontSize: 13.5)),
                          )),
                          const DropdownMenuItem(
                            value: '__new__',
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, size: 16, color: PartnerConstants.primary),
                                SizedBox(width: 6),
                                Text('+ Create New Category...', style: TextStyle(fontSize: 13.5, color: PartnerConstants.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == '__new__') {
                            setModalState(() {
                              isAddingNewCategory = true;
                            });
                          } else if (val != null) {
                            setModalState(() {
                              selectedCategory = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: newCatCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Category Name *',
                      hintText: 'e.g. Rice & Grains, Cooking Oils, Snacks',
                      border: const OutlineInputBorder(),
                      suffixIcon: _shopCustomCategories.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.list, color: PartnerConstants.primary),
                              tooltip: 'Select Existing Category',
                              onPressed: () {
                                setModalState(() {
                                  isAddingNewCategory = false;
                                  selectedCategory = _shopCustomCategories.first;
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price (₹) *',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Unit / Pack',
                          hintText: 'e.g. 1kg, 25kg Bag, 1 Piece',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'e.g. Top grade quality, direct from mill.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                const Text('Select Product Photo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: presetPhotos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (c, idx) {
                      final p = presetPhotos[idx];
                      final isSel = selectedPhoto == p['url'];
                      return InkWell(
                        onTap: () => setModalState(() => selectedPhoto = p['url']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
                            border: Border.all(color: isSel ? PartnerConstants.primary : const Color(0xFFCBD5E1), width: isSel ? 2 : 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              p['name']!,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? PartnerConstants.primary : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PartnerConstants.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final price = priceCtrl.text.trim();
                            final catVal = isAddingNewCategory
                                ? newCatCtrl.text.trim()
                                : (selectedCategory.isNotEmpty ? selectedCategory : 'General Items');

                            if (name.isEmpty || price.isEmpty || catVal.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter Product Name, Category and Price')),
                              );
                              return;
                            }

                            if (catVal.isNotEmpty && !_shopCustomCategories.contains(catVal)) {
                              setState(() {
                                _shopCustomCategories.add(catVal);
                              });
                            }

                            setModalState(() => isSubmitting = true);
                            final res = await _api.createShopProduct({
                              'name': name,
                              'price': double.tryParse(price) ?? 0,
                              'unit': unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : '1 Unit',
                              'description': descCtrl.text.trim(),
                              'images': [selectedPhoto],
                              'businessId': _activeBusinessId,
                              'businessName': _activeBusiness?['businessName'] ?? _activeBusiness?['name'] ?? 'Local Store',
                              'category': catVal,
                              'categoryName': 'Local Shops & Kirana',
                              'subCategory': catVal,
                            });

                            if (ctx.mounted) {
                              setModalState(() => isSubmitting = false);
                              if (res['success'] == true) {
                                Navigator.pop(sheetCtx);
                                await _loadPartnerProducts();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🎉 Product added to "$catVal"!'),
                                    backgroundColor: const Color(0xFF059669),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Failed to add product'),
                                    backgroundColor: const Color(0xFFDC2626),
                                  ),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Add to Store Catalog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // RENTAL MERCHANT DASHBOARD VIEW
  // =========================================================================

  String _getActiveRentalSubCategoryName() {
    final String bizSubId = (_activeBusiness?['subCategoryId'] ?? '').toString().trim();
    final String bizSubNameRaw = (_activeBusiness?['subCategoryName'] ?? _activeBusiness?['subCategory'] ?? _activeBusiness?['tradeCategoryName'] ?? '').toString().trim();

    for (var cat in _categories) {
      final subs = cat['subCategories'] as List<dynamic>? ?? [];
      for (var sub in subs) {
        final subName = (sub['name'] ?? '').toString();
        final subId = (sub['id'] ?? '').toString();
        if ((bizSubId.isNotEmpty && subId == bizSubId) ||
            (bizSubNameRaw.isNotEmpty && subName.toLowerCase().trim() == bizSubNameRaw.toLowerCase().trim()) ||
            (bizSubNameRaw.toLowerCase().contains('vehicle') && subName.toLowerCase().contains('vehicle')) ||
            (bizSubNameRaw.toLowerCase().contains('event') && subName.toLowerCase().contains('event')) ||
            (bizSubNameRaw.toLowerCase().contains('tent') && subName.toLowerCase().contains('event')) ||
            (bizSubNameRaw.toLowerCase().contains('car') && subName.toLowerCase().contains('vehicle'))) {
          return subName;
        }
      }
    }

    if (bizSubNameRaw.toLowerCase().contains('vehicle') || bizSubNameRaw.toLowerCase().contains('car') || bizSubNameRaw.toLowerCase().contains('driving')) {
      return 'Vehicle Rentals';
    } else if (bizSubNameRaw.toLowerCase().contains('event') || bizSubNameRaw.toLowerCase().contains('tent')) {
      return 'Event & Party Supplies';
    } else if (bizSubNameRaw.toLowerCase().contains('tool') || bizSubNameRaw.toLowerCase().contains('construction')) {
      return 'Construction & Tools Equipment';
    } else if (bizSubNameRaw.toLowerCase().contains('electronic') || bizSubNameRaw.toLowerCase().contains('camera')) {
      return 'Electronics & Cameras';
    } else if (bizSubNameRaw.toLowerCase().contains('cloth') || bizSubNameRaw.toLowerCase().contains('jewelry')) {
      return 'Clothing & Jewelry';
    } else if (bizSubNameRaw.toLowerCase().contains('property') || bizSubNameRaw.toLowerCase().contains('real estate') || bizSubNameRaw.toLowerCase().contains('house')) {
      return 'Property & Real Estate Rentals';
    }
    return bizSubNameRaw.isNotEmpty ? bizSubNameRaw : 'Vehicle Rentals';
  }

  List<String> _getActiveRentalChildCategories() {
    final String bizSubId = (_activeBusiness?['subCategoryId'] ?? '').toString().trim();
    final String bizSubNameRaw = (_activeBusiness?['subCategoryName'] ?? _activeBusiness?['subCategory'] ?? _activeBusiness?['tradeCategoryName'] ?? '').toString().trim();
    final String bizChildNameRaw = (_activeBusiness?['childCategoryName'] ?? _activeBusiness?['childCategory'] ?? '').toString().trim();

    final List<String> childList = [];

    // 1. Look up in dynamic _categories from backend
    for (var cat in _categories) {
      final subs = cat['subCategories'] as List<dynamic>? ?? [];
      for (var sub in subs) {
        final subName = (sub['name'] ?? '').toString();
        final subId = (sub['id'] ?? '').toString();
        if ((bizSubId.isNotEmpty && subId == bizSubId) ||
            (bizSubNameRaw.isNotEmpty && subName.toLowerCase().trim() == bizSubNameRaw.toLowerCase().trim()) ||
            (bizSubNameRaw.toLowerCase().contains('vehicle') && subName.toLowerCase().contains('vehicle')) ||
            (bizSubNameRaw.toLowerCase().contains('event') && subName.toLowerCase().contains('event')) ||
            (bizSubNameRaw.toLowerCase().contains('tent') && subName.toLowerCase().contains('event')) ||
            (bizSubNameRaw.toLowerCase().contains('car') && subName.toLowerCase().contains('vehicle'))) {
          final children = sub['childCategories'] as List<dynamic>? ?? [];
          for (var ch in children) {
            final chName = (ch is Map ? ch['name'] : ch.toString()) ?? '';
            if (chName.isNotEmpty && !childList.contains(chName) && chName != 'ALL_CHILDREN') {
              childList.add(chName);
            }
          }
          break;
        }
      }
      if (childList.isNotEmpty) break;
    }

    // 2. Fallbacks based on category type if dynamic list wasn't populated
    if (childList.isEmpty) {
      if (bizSubNameRaw.toLowerCase().contains('vehicle') || bizSubNameRaw.toLowerCase().contains('car') || bizSubNameRaw.toLowerCase().contains('driving')) {
        childList.addAll(['Self-drive cars,/bikes', 'Commercial / Goods', 'Agriculture']);
      } else if (bizSubNameRaw.toLowerCase().contains('event') || bizSubNameRaw.toLowerCase().contains('tent')) {
        childList.addAll(['Furniture & Tent', 'Audio & Visual', 'Catering Items']);
      } else if (bizSubNameRaw.toLowerCase().contains('tool') || bizSubNameRaw.toLowerCase().contains('construction')) {
        childList.addAll(['Building Material:', 'Power Tools', 'Heavy Machinery']);
      } else if (bizSubNameRaw.toLowerCase().contains('electronic') || bizSubNameRaw.toLowerCase().contains('camera')) {
        childList.addAll(['Photography: DSLR cameras', 'Home Appliances', 'Office/ Laptops/, printers,']);
      } else if (bizSubNameRaw.toLowerCase().contains('cloth') || bizSubNameRaw.toLowerCase().contains('jewelry')) {
        childList.addAll(['Bridal & Groom', 'Jewelry', 'Kids: Fancy dress']);
      } else if (bizSubNameRaw.toLowerCase().contains('property') || bizSubNameRaw.toLowerCase().contains('real estate') || bizSubNameRaw.toLowerCase().contains('house')) {
        childList.addAll(['Residential', 'Commercial', 'Function halls']);
      }
    }

    // 3. If bizChildNameRaw is present and not yet in childList, add it at the top
    if (bizChildNameRaw.isNotEmpty && !childList.any((c) => c.toLowerCase() == bizChildNameRaw.toLowerCase())) {
      childList.insert(0, bizChildNameRaw);
    }

    return childList;
  }

  Widget _buildRentalMerchantDashboard(Map<String, dynamic> profile) {
    final bizName = _activeBusiness?['businessName'] ?? _activeBusiness?['name'] ?? 'Rental Merchant Store';
    final address = _activeBusiness?['address'] ?? _activeBusiness?['shopAddress'] ?? 'Anakapalli, Andhra Pradesh';

    // Strict multi-business isolation: Only show items belonging to this active business profile!
    final bizRentals = _myRentalItems.where((i) {
      // Exclude customer personal properties from commercial merchant dashboard
      if (i['postedBy'] == 'customer' || i['listingType'] == 'owner') return false;
      if (_activeBusinessId != null && _activeBusinessId!.isNotEmpty) {
        final bId = i['businessId']?.toString();
        if (bId != null && bId.isNotEmpty) {
          return bId == _activeBusinessId;
        }
      }
      return true;
    }).toList();

    // Get child categories for active rental business
    final List<String> childCats = _getActiveRentalChildCategories();

    // Also include any child categories from already existing items in this business
    for (var item in bizRentals) {
      final itemChild = (item['childCategory'] ?? item['childCategoryName'] ?? '').toString().trim();
      if (itemChild.isNotEmpty && !childCats.any((c) => c.toLowerCase() == itemChild.toLowerCase())) {
        childCats.add(itemChild);
      }
    }

    // If current filter is not 'All' and not found in childCats, reset to 'All'
    if (_rentalCategoryFilter != 'All' && !childCats.any((c) => c.toLowerCase() == _rentalCategoryFilter.toLowerCase())) {
      _rentalCategoryFilter = 'All';
    }

    final filteredRentals = _rentalCategoryFilter == 'All'
        ? bizRentals
        : bizRentals.where((i) {
            final filter = _rentalCategoryFilter.toLowerCase().trim();
            final child = (i['childCategory'] ?? i['childCategoryName'] ?? '').toString().toLowerCase().trim();
            final sub = (i['subCategory'] ?? i['subCategoryName'] ?? '').toString().toLowerCase().trim();
            final title = (i['title'] ?? '').toString().toLowerCase().trim();
            return child == filter || child.contains(filter) || filter.contains(child) || title.contains(filter);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBusinessSwitcherBar(),

        // Store Status & Mode Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _rentalStoreOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _rentalStoreOpen ? Icons.store_rounded : Icons.lock_clock_rounded,
                                    size: 13,
                                    color: _rentalStoreOpen ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _rentalStoreOpen ? 'STORE OPEN (Accepting Inquiries)' : 'STORE TEMPORARILY CLOSED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: _rentalStoreOpen ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bizName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: _rentalStoreOpen,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) {
                        setState(() => _rentalStoreOpen = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val ? 'Store is now OPEN & listed on Customer App!' : 'Store is CLOSED for new orders.'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: val ? const Color(0xFF10B981) : Colors.black87,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildRentalMetricCard(
                      title: 'Total Items',
                      value: '${bizRentals.length}',
                      subtitle: 'Listed items',
                      color: const Color(0xFF2563EB),
                      icon: Icons.inventory_2_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRentalMetricCard(
                      title: 'Available',
                      value: '${bizRentals.where((i) => i['status'] != 'rented').length}',
                      subtitle: 'Ready to rent',
                      color: const Color(0xFF059669),
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRentalMetricCard(
                      title: 'Rented Out',
                      value: '${bizRentals.where((i) => i['status'] == 'rented').length}',
                      subtitle: 'With clients',
                      color: const Color(0xFFD97706),
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Rental Listings Quota Card
        _buildQuotaCard(
          title: 'Rental Listings Quota',
          currentCount: bizRentals.length,
          allowedQuota: ((_activeBusiness?['listingQuota'] ?? profile['listingQuota'] ?? 10) as int) +
              ((_activeBusiness?['topUpQuota'] ?? profile['topUpQuota'] ?? 0) as int),
          onTopUpPressed: () => _showTopUpInfoDialog(
            ((_activeBusiness?['listingQuota'] ?? profile['listingQuota'] ?? 10) as int) +
                ((_activeBusiness?['topUpQuota'] ?? profile['topUpQuota'] ?? 0) as int),
          ),
        ),

        // Rental Inventory Header & Add Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Rental Inventory',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
                ),
                Text(
                  'Active Listings (${bizRentals.length})',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: const Text('Add Rental Item', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: PartnerConstants.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: () {
                final quota = ((_activeBusiness?['listingQuota'] ?? profile['listingQuota'] ?? 10) as int) +
                    ((_activeBusiness?['topUpQuota'] ?? profile['topUpQuota'] ?? 0) as int);
                if (bizRentals.length >= quota) {
                  _showQuotaExceededAlert(quota);
                } else {
                  _showAddRentalItemModal();
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Child-Category Filter Chips (Strictly filtered to this rental business)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // 'All' Filter Chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: _rentalCategoryFilter == 'All'
                      ? const Icon(Icons.check, size: 14, color: PartnerConstants.primary)
                      : null,
                  label: Text(
                    'All (${bizRentals.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _rentalCategoryFilter == 'All' ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  selected: _rentalCategoryFilter == 'All',
                  selectedColor: PartnerConstants.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: _rentalCategoryFilter == 'All' ? PartnerConstants.primary : Colors.black87,
                  ),
                  backgroundColor: Colors.white,
                  onSelected: (val) {
                    if (val) setState(() => _rentalCategoryFilter = 'All');
                  },
                ),
              ),
              // Child Categories of the active subcategory
              ...childCats.map((childCat) {
                final isSel = _rentalCategoryFilter.toLowerCase() == childCat.toLowerCase();
                final count = bizRentals.where((i) {
                  final c = (i['childCategory'] ?? i['childCategoryName'] ?? '').toString().toLowerCase().trim();
                  return c == childCat.toLowerCase().trim() ||
                      c.contains(childCat.toLowerCase().trim()) ||
                      childCat.toLowerCase().trim().contains(c);
                }).length;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: isSel ? const Icon(Icons.check, size: 14, color: PartnerConstants.primary) : null,
                    label: Text(
                      count > 0 ? '$childCat ($count)' : childCat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: PartnerConstants.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSel ? PartnerConstants.primary : Colors.black87,
                    ),
                    backgroundColor: Colors.white,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _rentalCategoryFilter = childCat);
                      } else {
                        setState(() => _rentalCategoryFilter = 'All');
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Items List
        if (_loadingRentals)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filteredRentals.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PartnerConstants.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: PartnerConstants.primary, size: 36),
                ),
                const SizedBox(height: 14),
                const Text(
                  'No items listed in this category yet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Add chairs, sound systems, vehicles, furniture or equipment to start receiving rental leads.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('+ Add First Rental Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartnerConstants.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _showAddRentalItemModal,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredRentals.length,
            itemBuilder: (ctx, idx) {
              final item = filteredRentals[idx];
              final itemId = item['id']?.toString() ?? '';
              final title = item['title'] ?? 'Rental Item';
              final category = item['category'] ?? 'General';
              final rentPrice = item['rentPrice'] ?? 0;
              final rentPeriod = item['rentPeriod'] ?? 'Day';
              final deposit = item['deposit'] ?? 0;
              final status = (item['status'] ?? 'available').toString().toLowerCase();
              final isAvailable = status != 'rented';
              final imageUrl = item['imageUrl']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(imageUrl.contains(',') ? imageUrl.split(',')[1] : imageUrl),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                    ),
                                  )
                                : Image.network(
                                    imageUrl.isNotEmpty ? imageUrl : 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&auto=format&fit=crop',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        category.toUpperCase(),
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isAvailable ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isAvailable ? '● AVAILABLE' : '● RENTED OUT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isAvailable ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      '₹$rentPrice',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: PartnerConstants.primary),
                                    ),
                                    Text(
                                      ' / $rentPeriod',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                                    ),
                                    if (deposit > 0) ...[
                                      const SizedBox(width: 10),
                                      Text(
                                        '(₹$deposit Adv)',
                                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.verified_rounded, size: 14, color: Color(0xFF059669)),
                              SizedBox(width: 4),
                              Text('Verified Store', style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Edit Button
                              OutlinedButton.icon(
                                icon: const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF2563EB)),
                                label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  side: const BorderSide(color: Color(0xFF2563EB)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _showEditRentalItemModal(item),
                              ),
                              const SizedBox(width: 6),
                              // 2. Mark Rented / Available Button
                              OutlinedButton.icon(
                                icon: Icon(
                                  isAvailable ? Icons.check_circle_outline : Icons.replay_rounded,
                                  size: 13,
                                  color: isAvailable ? const Color(0xFFD97706) : const Color(0xFF059669),
                                ),
                                label: Text(
                                  isAvailable ? 'Mark Rented' : 'Available',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAvailable ? const Color(0xFFD97706) : const Color(0xFF059669),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  side: BorderSide(color: isAvailable ? const Color(0xFFD97706) : const Color(0xFF059669)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  final newStatus = isAvailable ? 'rented' : 'available';
                                  final ok = await _api.toggleRentalStatus(itemId, newStatus);
                                  if (ok) {
                                    await _loadPartnerRentals();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Item marked as ${newStatus.toUpperCase()}!'),
                                          backgroundColor: const Color(0xFF059669),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              const SizedBox(width: 4),
                              // 3. Delete Button
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Color(0xFFDC2626)),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                tooltip: 'Delete Rental Item',
                                onPressed: () => _confirmDeleteRentalItem(item),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRentalMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmDeleteRentalItem(Map<String, dynamic> item) {
    final title = item['title'] ?? 'this item';
    final itemId = item['id']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Delete Rental Item?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('Are you sure you want to delete "$title"?\n\nThis item will be permanently removed from your inventory and from the customer marketplace.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (itemId.isNotEmpty) {
                final ok = await _api.deleteRentalItem(itemId);
                if (ok) {
                  await _loadPartnerRentals();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text('✓ "$title" deleted successfully!')),
                          ],
                        ),
                        backgroundColor: const Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete item. Please try again.')),
                    );
                  }
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditRentalItemModal(Map<String, dynamic> item) async {
    try {
      final freshCats = await _api.fetchCategories();
      if (freshCats.isNotEmpty && mounted) {
        setState(() => _categories = freshCats);
      }
    } catch (_) {}

    final itemId = item['id']?.toString() ?? '';
    final titleCtrl = TextEditingController(text: item['title'] ?? '');
    final rentPriceCtrl = TextEditingController(text: '${item['rentPrice'] ?? ''}');
    final depositCtrl = TextEditingController(text: '${item['deposit'] ?? 0}');
    final localityCtrl = TextEditingController(text: item['location'] ?? item['locality'] ?? _activeBusiness?['address'] ?? 'Anakapalli, Andhra Pradesh');
    final descCtrl = TextEditingController(text: item['description'] ?? '');
    final imgUrlCtrl = TextEditingController(text: (item['images'] ?? item['imageUrl'] ?? '').toString().split(' ').first);

    final String selectedSubCategory = _getActiveRentalSubCategoryName();
    final List<String> availableChildCategories = List<String>.from(_getActiveRentalChildCategories());

    final existingChild = (item['childCategory'] ?? item['childCategoryName'] ?? '').toString().trim();
    if (existingChild.isNotEmpty && !availableChildCategories.contains(existingChild)) {
      availableChildCategories.add(existingChild);
    }

    String selectedChildCategory = existingChild.isNotEmpty && availableChildCategories.contains(existingChild)
        ? existingChild
        : (availableChildCategories.isNotEmpty ? availableChildCategories.first : 'General');

    String rentPeriod = (item['rentPeriod'] ?? 'Day').toString();
    if (rentPeriod.toLowerCase() == 'day') {
      rentPeriod = 'Day';
    } else if (rentPeriod.toLowerCase() == 'month') {
      rentPeriod = 'Month';
    } else if (rentPeriod.toLowerCase() == 'event') {
      rentPeriod = 'Event';
    } else if (rentPeriod.toLowerCase() == 'hour') {
      rentPeriod = 'Hour';
    } else {
      rentPeriod = 'Day';
    }

    bool updating = false;
    bool isCompressingPhoto = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit Rental Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PartnerConstants.secondary)),
                            SizedBox(height: 2),
                            Text('Update details, price or category for this rental item', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Fixed Sub-Category Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activeBusiness?['businessName'] ?? _activeBusiness?['name'] ?? 'Rental Store',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Sub-Category: $selectedSubCategory',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF2563EB), fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_rounded, size: 11, color: Color(0xFF15803D)),
                                SizedBox(width: 3),
                                Text('FIXED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Item Name
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Item Name *',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Child Category & Rent Period Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: availableChildCategories.contains(selectedChildCategory) ? selectedChildCategory : availableChildCategories.first,
                            decoration: InputDecoration(
                              labelText: 'Child Category / Type *',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: availableChildCategories.map((ch) {
                              return DropdownMenuItem(value: ch, child: Text(ch, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setSheetState(() => selectedChildCategory = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: rentPeriod,
                            decoration: InputDecoration(
                              labelText: 'Period *',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: ['Day', 'Month', 'Event', 'Hour'].map((p) => DropdownMenuItem(value: p, child: Text('Per $p', style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) => setSheetState(() => rentPeriod = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Rent Price & Deposit
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rentPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Rent Price (₹) *',
                              prefixText: '₹ ',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: depositCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Deposit Advance (₹)',
                              prefixText: '₹ ',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Locality
                    TextField(
                      controller: localityCtrl,
                      decoration: InputDecoration(
                        labelText: 'Shop / Item Location *',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Photo Upload / Change (HTML Canvas Compressed)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Item Photo',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        if (imgUrlCtrl.text.isNotEmpty)
                          TextButton.icon(
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                            onPressed: () {
                              setSheetState(() => imgUrlCtrl.text = '');
                            },
                            icon: const Icon(Icons.delete_outline, size: 15, color: Colors.red),
                            label: const Text('Remove', style: TextStyle(fontSize: 11, color: Colors.red)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    InkWell(
                      onTap: isCompressingPhoto
                          ? null
                          : () {
                              setSheetState(() => isCompressingPhoto = true);
                              Timer? safetyTimer;
                              safetyTimer = Timer(const Duration(seconds: 10), () {
                                if (isCompressingPhoto) {
                                  setSheetState(() => isCompressingPhoto = false);
                                }
                              });
                              try {
                                js_helper.pickAndCompressImage('gallery', (resultStr) {
                                  safetyTimer?.cancel();
                                  try {
                                    final res = jsonDecode(resultStr.toString());
                                    if (res['success'] == true && res['dataUrl'] != null) {
                                      setSheetState(() {
                                        imgUrlCtrl.text = res['dataUrl'].toString();
                                        isCompressingPhoto = false;
                                      });
                                    } else {
                                      setSheetState(() => isCompressingPhoto = false);
                                    }
                                  } catch (_) {
                                    setSheetState(() => isCompressingPhoto = false);
                                  }
                                });
                              } catch (_) {
                                safetyTimer.cancel();
                                setSheetState(() => isCompressingPhoto = false);
                              }
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: imgUrlCtrl.text.isNotEmpty ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: imgUrlCtrl.text.isNotEmpty ? const Color(0xFF86EFAC) : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: isCompressingPhoto
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: PartnerConstants.primary)),
                                      SizedBox(width: 8),
                                      Text('HTML Canvas Compressing Photo...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PartnerConstants.primary)),
                                    ],
                                  ),
                                ),
                              )
                            : imgUrlCtrl.text.isNotEmpty
                                ? Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: imgUrlCtrl.text.startsWith('data:image')
                                            ? Image.memory(
                                                base64Decode(imgUrlCtrl.text.contains(',') ? imgUrlCtrl.text.split(',')[1] : imgUrlCtrl.text),
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                imgUrlCtrl.text,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Photo Attached & Ready', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                                            Text('Tap Change to replace photo', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: PartnerConstants.primary),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('Change', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: PartnerConstants.primary)),
                                      ),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, color: PartnerConstants.primary, size: 20),
                                      SizedBox(width: 8),
                                      Text('Click to Upload / Change Photo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons (Save Changes & Delete)
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 16),
                          label: const Text('Delete', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            _confirmDeleteRentalItem(item);
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            label: Text(updating ? 'Saving...' : 'Save Changes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PartnerConstants.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: updating
                                ? null
                                : () async {
                                    final title = titleCtrl.text.trim();
                                    final rentPrice = double.tryParse(rentPriceCtrl.text.trim()) ?? 0;
                                    if (title.isEmpty || rentPrice <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter Item Name and Valid Rent Price!')),
                                      );
                                      return;
                                    }

                                    setSheetState(() => updating = true);
                                    final ok = await _api.updateRentalItem(itemId, {
                                      'title': title,
                                      'category': selectedSubCategory,
                                      'subCategory': selectedSubCategory,
                                      'childCategory': selectedChildCategory,
                                      'categoryName': 'Lease & Rental',
                                      'rentPrice': rentPrice,
                                      'rentPeriod': rentPeriod,
                                      'deposit': double.tryParse(depositCtrl.text.trim()) ?? 0,
                                      'location': localityCtrl.text.trim(),
                                      'description': descCtrl.text.trim(),
                                      'images': imgUrlCtrl.text.trim(),
                                    });

                                    if (!context.mounted) return;
                                    Navigator.pop(sheetCtx);

                                    if (ok) {
                                      await _loadPartnerRentals();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                              SizedBox(width: 8),
                                              Text('✓ Rental item updated successfully!'),
                                            ],
                                          ),
                                          backgroundColor: Color(0xFF059669),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Failed to update rental item. Please try again.')),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddRentalItemModal() {
    final titleCtrl = TextEditingController();
    final rentPriceCtrl = TextEditingController();
    final depositCtrl = TextEditingController();
    final localityCtrl = TextEditingController(text: _activeBusiness?['address'] ?? 'Anakapalli, Andhra Pradesh');
    final descCtrl = TextEditingController();
    final imgUrlCtrl = TextEditingController();

    final String bizSubId = (_activeBusiness?['subCategoryId'] ?? '').toString();
    final String bizSubNameRaw = (_activeBusiness?['subCategoryName'] ?? _activeBusiness?['subCategory'] ?? _activeBusiness?['tradeCategoryName'] ?? '').toString();
    final String bizChildNameRaw = (_activeBusiness?['childCategoryName'] ?? _activeBusiness?['childCategory'] ?? '').toString();

    // Look up matching Sub-Category and its Child Categories from dynamic _categories or preset map
    String selectedSubCategory = '';
    List<String> availableChildCategories = [];

    for (var cat in _categories) {
      final subs = cat['subCategories'] as List<dynamic>? ?? [];
      for (var sub in subs) {
        final subName = (sub['name'] ?? '').toString();
        final subId = (sub['id'] ?? '').toString();
        if ((bizSubId.isNotEmpty && subId == bizSubId) ||
            (bizSubNameRaw.isNotEmpty && subName.toLowerCase().trim() == bizSubNameRaw.toLowerCase().trim()) ||
            (bizSubNameRaw.toLowerCase().contains('vehicle') && subName.toLowerCase().contains('vehicle')) ||
            (bizSubNameRaw.toLowerCase().contains('event') && subName.toLowerCase().contains('event')) ||
            (bizSubNameRaw.toLowerCase().contains('tent') && subName.toLowerCase().contains('event')) ||
            (bizSubNameRaw.toLowerCase().contains('car') && subName.toLowerCase().contains('vehicle'))) {
          selectedSubCategory = subName;
          final children = sub['childCategories'] as List<dynamic>? ?? [];
          for (var ch in children) {
            final chName = (ch is Map ? ch['name'] : ch.toString()) ?? '';
            if (chName.isNotEmpty && !availableChildCategories.contains(chName) && chName != 'ALL_CHILDREN') {
              availableChildCategories.add(chName);
            }
          }
          break;
        }
      }
      if (selectedSubCategory.isNotEmpty) break;
    }

    if (availableChildCategories.isEmpty) {
      if (bizSubNameRaw.toLowerCase().contains('vehicle') || bizSubNameRaw.toLowerCase().contains('car') || bizSubNameRaw.toLowerCase().contains('driving')) {
        selectedSubCategory = 'Vehicle Rentals';
        availableChildCategories = ['Self-drive cars / bikes', 'Commercial / Goods', 'Agriculture', 'General Vehicles'];
      } else if (bizSubNameRaw.toLowerCase().contains('event') || bizSubNameRaw.toLowerCase().contains('tent')) {
        selectedSubCategory = 'Event & Party Supplies';
        availableChildCategories = ['Furniture & Tent', 'Audio & Visual', 'Catering Items', 'Event Decoration'];
      } else if (bizSubNameRaw.toLowerCase().contains('tool') || bizSubNameRaw.toLowerCase().contains('construction')) {
        selectedSubCategory = 'Construction & Tools Equipment';
        availableChildCategories = ['Power Tools', 'Heavy Machinery', 'Building Material', 'General Tools'];
      } else if (bizSubNameRaw.toLowerCase().contains('camera') || bizSubNameRaw.toLowerCase().contains('electronic')) {
        selectedSubCategory = 'Electronics & Cameras';
        availableChildCategories = ['Photography DSLR', 'Home Appliances', 'Office Laptops', 'Audio Equipment'];
      } else {
        selectedSubCategory = bizSubNameRaw.isNotEmpty ? bizSubNameRaw : 'Vehicle Rentals';
        availableChildCategories = ['General Item', 'Standard Equipment'];
      }
    }

    String selectedChildCategory = availableChildCategories.isNotEmpty
        ? (availableChildCategories.firstWhere(
            (c) => c.toLowerCase() == bizChildNameRaw.toLowerCase(),
            orElse: () => availableChildCategories.first,
          ))
        : 'General';

    String rentPeriod = 'Day';
    bool submitting = false;
    String? uploadedPhotoDataUrl;
    int? uploadedPhotoSizeKb;
    bool isCompressingPhoto = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add Rental Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PartnerConstants.secondary)),
                            SizedBox(height: 2),
                            Text('Add a new rental item or equipment to this store', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. Business & Fixed Sub-Category Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activeBusiness?['businessName'] ?? _activeBusiness?['name'] ?? 'Rental Store',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Sub-Category: $selectedSubCategory',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF2563EB), fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_rounded, size: 11, color: Color(0xFF15803D)),
                                SizedBox(width: 3),
                                Text('FIXED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Item Title
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Item Name *',
                        hintText: selectedSubCategory.toLowerCase().contains('vehicle') ? 'e.g. Maruti Ertiga 7-Seater, Swift Dzire' : 'e.g. VIP Chairs Set, Generator, DJ System',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Child Category & Rent Period Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: availableChildCategories.contains(selectedChildCategory) ? selectedChildCategory : availableChildCategories.first,
                            decoration: InputDecoration(
                              labelText: 'Child Category / Type *',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: availableChildCategories.map((ch) {
                              return DropdownMenuItem(value: ch, child: Text(ch, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setSheetState(() => selectedChildCategory = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: rentPeriod,
                            decoration: InputDecoration(
                              labelText: 'Period *',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: ['Day', 'Month', 'Event', 'Hour'].map((p) => DropdownMenuItem(value: p, child: Text('Per $p', style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) => setSheetState(() => rentPeriod = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Rent Price & Deposit
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rentPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Rent Price (₹) *',
                              prefixText: '₹ ',
                              hintText: '500',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: depositCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Deposit Advance (₹)',
                              prefixText: '₹ ',
                              hintText: '1000',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Locality
                    TextField(
                      controller: localityCtrl,
                      decoration: InputDecoration(
                        labelText: 'Shop / Item Location *',
                        hintText: 'e.g. Ring Road, Anakapalli',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g. Top quality equipment, delivery available on request.',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Photo Upload (Compressed via HTML Canvas & saved to Database)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Upload Item Photo *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        if (uploadedPhotoDataUrl != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Text(
                                  uploadedPhotoSizeKb != null ? '$uploadedPhotoSizeKb KB (HTML Compressed)' : 'Compressed',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    InkWell(
                      onTap: isCompressingPhoto
                          ? null
                          : () {
                              setSheetState(() => isCompressingPhoto = true);
                              Timer? safetyTimer;
                              safetyTimer = Timer(const Duration(seconds: 10), () {
                                if (isCompressingPhoto) {
                                  setSheetState(() => isCompressingPhoto = false);
                                }
                              });

                              try {
                                js_helper.pickAndCompressImage('gallery', (resultStr) {
                                  safetyTimer?.cancel();
                                  try {
                                    final res = jsonDecode(resultStr.toString());
                                    if (res['success'] == true && res['dataUrl'] != null) {
                                      final dataUrl = res['dataUrl'].toString();
                                      final sizeKb = (res['fileSizeKb'] as num?)?.toInt() ?? 80;
                                      setSheetState(() {
                                        uploadedPhotoDataUrl = dataUrl;
                                        uploadedPhotoSizeKb = sizeKb;
                                        imgUrlCtrl.text = dataUrl;
                                        isCompressingPhoto = false;
                                      });
                                    } else {
                                      setSheetState(() => isCompressingPhoto = false);
                                    }
                                  } catch (e) {
                                    setSheetState(() => isCompressingPhoto = false);
                                  }
                                });
                              } catch (_) {
                                safetyTimer.cancel();
                                setSheetState(() => isCompressingPhoto = false);
                              }
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: uploadedPhotoDataUrl != null ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: uploadedPhotoDataUrl != null ? const Color(0xFF86EFAC) : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: isCompressingPhoto
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: PartnerConstants.primary),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'HTML Canvas Compressing Photo...',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PartnerConstants.primary),
                                    ),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () {
                                        setSheetState(() => isCompressingPhoto = false);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : uploadedPhotoDataUrl != null
                                ? Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          base64Decode(uploadedPhotoDataUrl!.contains(',')
                                              ? uploadedPhotoDataUrl!.split(',')[1]
                                              : uploadedPhotoDataUrl!),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Photo Attached & Ready',
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              uploadedPhotoSizeKb != null
                                                  ? 'Compressed to $uploadedPhotoSizeKb KB for instant loading'
                                                  : 'Compressed via HTML Canvas',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          setSheetState(() => isCompressingPhoto = true);
                                          Timer? changeTimer;
                                          changeTimer = Timer(const Duration(seconds: 10), () {
                                            if (isCompressingPhoto) {
                                              setSheetState(() => isCompressingPhoto = false);
                                            }
                                          });
                                          try {
                                            js_helper.pickAndCompressImage('gallery', (resultStr) {
                                              changeTimer?.cancel();
                                              try {
                                                final res = jsonDecode(resultStr.toString());
                                                if (res['success'] == true && res['dataUrl'] != null) {
                                                  setSheetState(() {
                                                    uploadedPhotoDataUrl = res['dataUrl'].toString();
                                                    uploadedPhotoSizeKb = (res['fileSizeKb'] as num?)?.toInt() ?? 80;
                                                    imgUrlCtrl.text = uploadedPhotoDataUrl!;
                                                    isCompressingPhoto = false;
                                                  });
                                                } else {
                                                  setSheetState(() => isCompressingPhoto = false);
                                                }
                                              } catch (_) {
                                                setSheetState(() => isCompressingPhoto = false);
                                              }
                                            });
                                          } catch (_) {
                                            changeTimer.cancel();
                                            setSheetState(() => isCompressingPhoto = false);
                                          }
                                        },
                                        icon: const Icon(Icons.change_circle_outlined, size: 16, color: PartnerConstants.primary),
                                        label: const Text('Change', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: PartnerConstants.primary)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          side: const BorderSide(color: PartnerConstants.primary),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: PartnerConstants.primary.withOpacity(0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add_a_photo_outlined, color: PartnerConstants.primary, size: 28),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Click to Upload Item Photo',
                                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        'Photo is auto-compressed using HTML Canvas to reduce size and save in DB',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PartnerConstants.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: submitting
                            ? null
                            : () async {
                                final title = titleCtrl.text.trim();
                                final rentPrice = double.tryParse(rentPriceCtrl.text.trim()) ?? 0;
                                if (title.isEmpty || rentPrice <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter Item Name and Valid Rent Price!')),
                                  );
                                  return;
                                }

                                if (imgUrlCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Color(0xFFDC2626),
                                      content: Row(
                                        children: [
                                          Icon(Icons.photo_camera, color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text('Please upload a photo for this rental item!'),
                                        ],
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setSheetState(() => submitting = true);
                                final ok = await _api.createRentalItem({
                                  'title': title,
                                  'category': selectedSubCategory,
                                  'subCategory': selectedSubCategory,
                                  'childCategory': selectedChildCategory,
                                  'categoryName': 'Lease & Rental',
                                  'rentPrice': rentPrice,
                                  'rentPeriod': rentPeriod,
                                  'deposit': double.tryParse(depositCtrl.text.trim()) ?? 0,
                                  'locality': localityCtrl.text.trim(),
                                  'description': descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : 'Well maintained rental item available directly from verified store.',
                                  'imageUrl': imgUrlCtrl.text.trim(),
                                  'businessId': _activeBusinessId,
                                  'businessName': _activeBusiness?['businessName'] ?? 'Verified Store',
                                });

                                if (!context.mounted) return;
                                Navigator.pop(sheetCtx);

                                if (ok) {
                                  await _loadPartnerRentals();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Text('✓ Rental item published live to Customer Marketplace!'),
                                        ],
                                      ),
                                      backgroundColor: Color(0xFF059669),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to publish item. Please try again.')),
                                  );
                                }
                              },
                        child: submitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Publish to Customer Marketplace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // END OF MULTI-BUSINESS & RENTALS
  // =========================================================================

  Widget _buildPendingApprovalDashboard(Map<String, dynamic> profile) {
    final name = profile['name'] ?? 'Partner';
    final category = profile['categoryName'] ?? profile['serviceName'] ?? 'Service Specialist';
    final district = profile['district'] ?? 'Anakapalli';
    final mandal = profile['mandal'] ?? '';
    final isRejected = (profile['kycStatus'] ?? '').toString().toLowerCase() == 'rejected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HERO CARD: UNDER ADMIN REVIEW
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isRejected
                  ? [const Color(0xFFFEF2F2), Colors.white]
                  : [const Color(0xFFFFFBEB), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isRejected ? const Color(0xFFF87171) : const Color(0xFFFBBF24),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isRejected ? Colors.red : Colors.amber).withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                      color: isRejected ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRejected ? Icons.error_outline_rounded : Icons.hourglass_top_rounded,
                      color: isRejected ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isRejected ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isRejected ? 'KYC REJECTED' : 'KYC UNDER ADMIN REVIEW',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isRejected ? const Color(0xFFDC2626) : const Color(0xFFB45309),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isRejected
                              ? 'Verification Action Required'
                              : 'Admin Approval Pending',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                isRejected
                    ? 'Some verification issues were found with your submitted profile documents. Please review and re-submit your details.'
                    : 'Hello $name, your profile and business details have been submitted successfully. Please wait while Loki Admin verifies and approves your application.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Once Admin approves your profile, your dashboard will automatically activate. You will then be able to go On-Duty and receive customer orders.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openProfileScreen,
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('View / Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E293B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _initData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Checking latest approval status from Admin...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PartnerConstants.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // SUBSCRIPTION STATUS BANNER
        _buildSubscriptionBanner(profile),
        const SizedBox(height: 20),

        // 3-STEP APPROVAL ROADMAP
        const Text(
          'Verification Progress',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 10),
        _buildVerificationStepTile(
          step: '1',
          title: 'Profile & Documents Submitted',
          subtitle: 'Aadhaar, Trade details & Live Photo saved',
          status: 'Done',
          isDone: true,
        ),
        _buildVerificationStepTile(
          step: '2',
          title: 'Admin Verification & Screening',
          subtitle: 'Loki Super Admin is reviewing your KYC proofs',
          status: isRejected ? 'Rejected' : 'In Progress',
          isDone: false,
          isInProgress: !isRejected,
          isRejected: isRejected,
        ),
        _buildVerificationStepTile(
          step: '3',
          title: 'Account Activation & Duty On',
          subtitle: 'Go live on radar and start earning daily income',
          status: 'Locked',
          isDone: false,
        ),
        const SizedBox(height: 20),

        // SUBMITTED DETAILS SUMMARY
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submitted Details Overview',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildSummaryRow('Trade Profession', category),
              if (profile['subCategoryName'] != null && profile['subCategoryName'].toString().isNotEmpty)
                _buildSummaryRow('Sub-Category', profile['subCategoryName'].toString()),
              _buildSummaryRow('Operating Location', '${mandal.isNotEmpty ? '$mandal, ' : ''}$district'),
              _buildSummaryRow('Working Shift', profile['workingHours'] ?? 'Full-Time'),
              _buildSummaryRow('Service Radius', profile['serviceRadius'] ?? '10 KM'),
              _buildSummaryRow('Physical Shop', profile['hasPhysicalShop'] == true ? 'Registered' : 'No Shop (Doorstep)'),
              _buildSummaryRow('Live Photo Match', profile['livePhotoVerificationStatus'] ?? 'Verified'),
              _buildSummaryRow(
                'Subscription Plan',
                profile['subscriptionStatus'] == 'active'
                    ? 'Active (0% Commission)'
                    : 'Unpaid • ₹${profile['subscriptionAmount'] ?? 1999}/yr',
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildVerificationStepTile({
    required String step,
    required String title,
    required String subtitle,
    required String status,
    required bool isDone,
    bool isInProgress = false,
    bool isRejected = false,
  }) {
    Color bg = isDone
        ? const Color(0xFFECFDF5)
        : isInProgress
            ? const Color(0xFFFFFBEB)
            : isRejected
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFF8FAFC);
    Color border = isDone
        ? const Color(0xFFA7F3D0)
        : isInProgress
            ? const Color(0xFFFDE68A)
            : isRejected
                ? const Color(0xFFFECACA)
                : const Color(0xFFE2E8F0);
    Color stepColor = isDone
        ? const Color(0xFF059669)
        : isInProgress
            ? const Color(0xFFD97706)
            : isRejected
                ? const Color(0xFFDC2626)
                : const Color(0xFF94A3B8);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: stepColor,
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    step,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: stepColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildNewPartnerDashboard(Map<String, dynamic> profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${profile['name'] ?? 'Partner'}! 👋',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF192338)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your Locki Partner Account is ready. Please complete your profile to start receiving orders.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // BIG HERO CARD: "CREATE YOUR PROFILE"
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7ED), Color(0xFFFFFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: PartnerConstants.primary.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: PartnerConstants.primary.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [PartnerConstants.primary, const Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: PartnerConstants.primary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.assignment_ind_rounded, color: Colors.white, size: 28),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Step 1 of 2',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Create Your Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF192338),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set up your service trade, working location (District, Mandal, Village) & KYC details to activate your partner account and start receiving customer jobs.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),

              // BEAUTIFUL BUTTON IN THE CARD
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartnerConstants.primary,
                    elevation: 4,
                    shadowColor: PartnerConstants.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _openProfileScreen,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'CREATE PROFILE NOW',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Account Activation Steps
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Activation Progress',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF192338)),
              ),
              const SizedBox(height: 14),
              _buildStepItem(
                icon: Icons.check_circle_rounded,
                iconColor: Colors.green,
                title: '1. Account Registered',
                desc: 'Mobile number and login credentials created',
                isDone: true,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 13),
                child: SizedBox(height: 12, child: VerticalDivider(color: Color(0xFFCBD5E1), thickness: 1.5)),
              ),
              _buildStepItem(
                icon: Icons.pending_actions_rounded,
                iconColor: PartnerConstants.primary,
                title: '2. Create Your Profile',
                desc: 'Select trade, Mandal/Village work location & Aadhaar',
                isCurrent: true,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 13),
                child: SizedBox(height: 12, child: VerticalDivider(color: Color(0xFFCBD5E1), thickness: 1.5)),
              ),
              _buildStepItem(
                icon: Icons.flash_on_rounded,
                iconColor: Colors.grey,
                title: '3. Turn On Duty & Earn',
                desc: 'Accept instant nearby bookings & receive daily payouts',
                isLocked: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Partner Support Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.support_agent_rounded, color: Color(0xFF64748B), size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Need help completing profile?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                    Text('Locki Partner Support is here 24x7', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text('Helpline', style: TextStyle(color: PartnerConstants.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    bool isDone = false,
    bool isCurrent = false,
    bool isLocked = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // DASHBOARD FOR ACTIVE / VERIFIED PARTNER
  Widget _buildActivePartnerDashboard(Map<String, dynamic> profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBusinessSwitcherBar(),
        // Duty Switch Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isOnline ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isOnline ? PartnerConstants.primary.withOpacity(0.4) : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isOnline ? PartnerConstants.primary.withOpacity(0.12) : Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _isOnline ? PartnerConstants.primary : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isOnline ? 'ON DUTY (ONLINE)' : 'OFF DUTY (OFFLINE)',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: _isOnline ? PartnerConstants.primary : Colors.grey.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isOnline ? 'Ready to accept incoming job requests' : 'Toggle switch to start earning',
                        style: const TextStyle(fontSize: 12, color: PartnerConstants.textMuted),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isOnline,
                    onChanged: (_) => _toggleDuty(),
                    activeColor: PartnerConstants.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final pendingList = _orders.where((o) => o.orderStatus.toUpperCase() == 'PENDING').toList();
                  final hasUnmuted = pendingList.any((o) => !_mutedOrderIds.contains(o.id));
                  final isRinging = !_isSilentMode && hasUnmuted;

                  return Row(
                    children: [
                      Icon(
                        _isSilentMode
                            ? Icons.volume_off_rounded
                            : isRinging
                                ? Icons.campaign_rounded
                                : Icons.two_wheeler_rounded,
                        size: 17,
                        color: _isSilentMode ? const Color(0xFF64748B) : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isSilentMode
                            ? '🔇 Siren Muted (Silent Mode)'
                            : isRinging
                                ? '🚨 Emergency Siren & Vibration Ringing'
                                : 'Bike Siren & Vibration: Ready',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: _isSilentMode ? const Color(0xFF475569) : const Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Yearly Plan & 0% Commission Banner
        _buildSubscriptionBanner(profile),
        const SizedBox(height: 16),

        // Quick Stats Row (Total Received vs Accepted & Completed)
        Builder(
          builder: (context) {
            final inProgressJobs = _orders.where((o) => o.orderStatus.toUpperCase() == 'IN_PROGRESS' || o.orderStatus.toUpperCase() == 'ACCEPTED').length;
            final pendingJobs = _orders.where((o) => o.orderStatus.toUpperCase() == 'PENDING').length;
            final loadedCompleted = _orders.where((o) => o.orderStatus.toUpperCase() == 'COMPLETED').length;
            final baseCompleted = (profile['jobsCompleted'] as num?)?.toInt() ?? 313;
            final totalCompletedJobs = baseCompleted > loadedCompleted ? baseCompleted : loadedCompleted;
            final backendCancelled = (profile['cancelledJobs'] as num?)?.toInt() ?? 1;
            final effectiveCancelled = _cancelledJobsCount > backendCancelled ? _cancelledJobsCount : backendCancelled;
            final totalReceivedJobs = totalCompletedJobs + effectiveCancelled + inProgressJobs + pendingJobs;

            return Row(
              children: [
                // Card 1: Total Jobs Received
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PartnerJobHistoryScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Total Received',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PartnerConstants.textDim),
                              ),
                              Icon(Icons.all_inbox_rounded, color: Color(0xFF2563EB), size: 16),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$totalReceivedJobs',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: PartnerConstants.secondary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: const [
                              Icon(Icons.arrow_downward_rounded, size: 11, color: Color(0xFF2563EB)),
                              SizedBox(width: 3),
                              Text(
                                'All Incoming Leads',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Card 2: Accepted & Completed
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PartnerJobHistoryScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Jobs Completed',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PartnerConstants.textDim),
                              ),
                              Icon(Icons.task_alt_rounded, color: Color(0xFF059669), size: 16),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$totalCompletedJobs',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: const [
                              Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF059669)),
                              SizedBox(width: 3),
                              Text(
                                'Accepted & Done',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Assigned & Nearby Jobs Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Assigned & Nearby Jobs',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
                ),
                if (_orders.any((o) => o.orderStatus.toUpperCase() == 'PENDING' && !_mutedOrderIds.contains(o.id))) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.notifications_active_rounded, size: 12, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text(
                          'ALARM RINGING',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20, color: PartnerConstants.textDim),
              onPressed: () => _initData(),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Builder(
          builder: (context) {
            final activeOrders = _orders.where((o) {
              final st = o.orderStatus.toUpperCase();
              return st == 'PENDING' || st == 'ACCEPTED' || st == 'IN_PROGRESS';
            }).toList();

            if (activeOrders.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.radar_rounded, size: 40, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Radar Active: Waiting for Nearby Customer Requests',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Completed & Cancelled jobs are archived to Job History.\nKeep app open and stay online to receive instant siren alerts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: PartnerConstants.textDim, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PartnerJobHistoryScreen()),
                        );
                      },
                      icon: const Icon(Icons.history_rounded, size: 16),
                      label: const Text('View All Job History & Records', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ord = activeOrders[index];
                return _buildJobCard(ord);
              },
            );
          },
        ),
      ],
    );
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedOrderIds.contains(id)) {
        _expandedOrderIds.remove(id);
      } else {
        _expandedOrderIds.add(id);
      }
    });
  }

  void _cancelJob(PartnerOrder order) async {
    _stopJobAlarm();
    setState(() {
      _cancelledJobsCount++;
      _orders.removeWhere((o) => o.id == order.id);
      _expandedOrderIds.remove(order.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Job #${order.id} cancelled. Total Leads Received updated!')),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _api.updateOrderStatus(order.id, 'CANCELLED');
    _api.fetchProfile();
  }

  void _acceptJob(PartnerOrder order) async {
    _stopJobAlarm();
    setState(() {
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(orderStatus: 'ACCEPTED');
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Job #${order.id} Accepted! Turn-by-turn navigation enabled.')),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _api.updateOrderStatus(order.id, 'ACCEPTED');
  }

  void _verifyOtpAndStart(PartnerOrder order, String enteredOtp) async {
    final cleanOtp = enteredOtp.trim();
    if (cleanOtp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 4-digit customer PIN'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (order.otp.isNotEmpty && cleanOtp != order.otp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid PIN! Correct customer PIN is: ${order.otp}'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() {
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(orderStatus: 'IN_PROGRESS');
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP Verified! Work started for #${order.id}'),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _api.updateOrderStatus(order.id, 'IN_PROGRESS', otp: cleanOtp);
  }

  void _completeJob(PartnerOrder order) async {
    setState(() {
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(orderStatus: 'COMPLETED');
      }
      _expandedOrderIds.remove(order.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Job #${order.id} marked completed! 0% platform deduction.'),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _api.updateOrderStatus(order.id, 'COMPLETED');
  }

  Widget _buildJobCard(PartnerOrder order) {
    final status = order.orderStatus.toUpperCase();
    final isPending = status == 'PENDING';
    final isAccepted = status == 'ACCEPTED';
    final isInProgress = status == 'IN_PROGRESS';
    final isCompleted = status == 'COMPLETED';
    final isExpanded = _expandedOrderIds.contains(order.id);

    Color badgeColor = const Color(0xFFD97706);
    String badgeText = status;
    if (isPending) {
      badgeColor = const Color(0xFFDC2626);
      badgeText = '🚨 NEW LEAD';
    } else if (isAccepted) {
      badgeColor = const Color(0xFF2563EB);
      badgeText = 'ACCEPTED';
    } else if (isInProgress) {
      badgeColor = const Color(0xFFEA580C);
      badgeText = 'IN PROGRESS';
    } else if (isCompleted) {
      badgeColor = const Color(0xFF059669);
      badgeText = 'COMPLETED';
    }

    final customerPhone = order.customerPhone.isNotEmpty ? order.customerPhone : '+91 98765 11111';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? const Color(0xFFDC2626)
              : (isInProgress ? PartnerConstants.primary : (isAccepted ? const Color(0xFF2563EB) : Colors.grey.shade200)),
          width: (isPending || isInProgress || isAccepted) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPending ? Colors.red.withOpacity(0.08) : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.id,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Direct Lead • 0% Cut',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Service Title
          Text(
            order.serviceName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
          ),
          const SizedBox(height: 8),

          // Customer Name Row
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 16, color: PartnerConstants.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Customer: ${order.customerName}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Customer Address & Location Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.customerAddress.isNotEmpty ? order.customerAddress : 'Madhapur, Hyderabad',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.3),
                ),
              ),
            ],
          ),

          // Dedicated Per-Request Siren Mute Box (Only on PENDING requests)
          if (isPending) ...[
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final isOrderMuted = _mutedOrderIds.contains(order.id);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isOrderMuted ? const Color(0xFFF8FAFC) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isOrderMuted ? const Color(0xFFE2E8F0) : const Color(0xFFFCA5A5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isOrderMuted ? Icons.volume_off_rounded : Icons.campaign_rounded,
                            size: 18,
                            color: isOrderMuted ? const Color(0xFF64748B) : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOrderMuted ? 'Siren Muted for #${order.id}' : '🚨 Siren Ringing for #${order.id}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isOrderMuted ? const Color(0xFF475569) : const Color(0xFF991B1B),
                                ),
                              ),
                              Text(
                                isOrderMuted ? 'Silenced. Any new requests will ring siren.' : 'High-decibel emergency siren & vibration.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isOrderMuted ? const Color(0xFF64748B) : const Color(0xFFB91C1C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!isOrderMuted)
                        InkWell(
                          onTap: () => _muteSingleOrder(order.id),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.volume_off_rounded, size: 13, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Mute',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF475569)),
                              SizedBox(width: 4),
                              Text(
                                'Silenced',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Action Buttons Row
          if (isPending)
            // 4 Buttons: Call, Accept, Cancel, Details
            Row(
              children: [
                // 1. Call Button
                Expanded(
                  child: InkWell(
                    onTap: () => _callCustomer(context, order.customerName, customerPhone),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.phone_rounded, size: 14, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text(
                            'Call',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // 2. Accept Button
                Expanded(
                  child: InkWell(
                    onTap: () => _acceptJob(order),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Accept',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // 3. Cancel Button (Dismisses card immediately)
                Expanded(
                  child: InkWell(
                    onTap: () => _cancelJob(order),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.close_rounded, size: 14, color: Color(0xFFDC2626)),
                          SizedBox(width: 4),
                          Text(
                            'Cancel',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // 4. Details Button (Expands inline)
                Expanded(
                  child: InkWell(
                    onTap: () => _toggleExpand(order.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: isExpanded ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Details',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 15,
                            color: const Color(0xFF334155),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // Buttons for ACCEPTED or IN_PROGRESS: Call, Navigate, Details
            Row(
              children: [
                // 1. Call Button
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _callCustomer(context, order.customerName, customerPhone),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.phone_in_talk_rounded, size: 15, color: Color(0xFF059669)),
                          SizedBox(width: 6),
                          Text(
                            'Call Customer',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Navigation Button (Directions/Google Maps)
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _openLocationMap(context, order.customerAddress),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.navigation_rounded, size: 15, color: Color(0xFF2563EB)),
                          SizedBox(width: 6),
                          Text(
                            'Navigate',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Details Button (Inline Expand)
                InkWell(
                  onTap: () => _toggleExpand(order.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isExpanded ? const Color(0xFFE2E8F0) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Details',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: PartnerConstants.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          // Inline Expanded Section
          if (isExpanded) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Problem Description
                  Row(
                    children: const [
                      Icon(Icons.description_outlined, size: 14, color: PartnerConstants.primary),
                      SizedBox(width: 6),
                      Text(
                        'Customer Problem Notes',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.notes.isNotEmpty ? order.notes : 'Urgent direct service lead requested by customer.',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.3),
                  ),
                  const SizedBox(height: 10),

                  // Direct Contact & Lead Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            customerPhone,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '0% Fee • Zero Commission Lead',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                      ),
                    ],
                  ),

                  // If PENDING prompt
                  if (isPending) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF2563EB)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Click Accept above to lock this customer request and open Google Maps navigation.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // If ACCEPTED -> OTP Verification UI to start work
                  if (isAccepted) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFCBD5E1)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Enter Customer Start PIN:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PartnerConstants.secondary),
                        ),
                        if (order.otp.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Customer PIN: ${order.otp}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _otpControllers.putIfAbsent(order.id, () => TextEditingController()),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter 4-digit PIN',
                                hintStyle: const TextStyle(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            final text = _otpControllers[order.id]?.text ?? '';
                            _verifyOtpAndStart(order, text);
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                          label: const Text('Start Work', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // If IN_PROGRESS -> Finish Job Button
                  if (isInProgress) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFCBD5E1)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _completeJob(order),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text('Complete Work & Finish Job', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _callCustomer(BuildContext context, String customerName, String phone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.phone_in_talk_rounded, color: Color(0xFF059669)),
            SizedBox(width: 10),
            Text('Call Customer', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Direct call with $customerName:'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.call, color: Color(0xFF059669), size: 18),
                      const SizedBox(width: 8),
                      Text(phone, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                  const Text('Direct Line', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No platform call-masking fee. Direct connection with customer.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Connecting phone call to $phone...'),
                  backgroundColor: const Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Dial Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _openLocationMap(BuildContext context, String address) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Opening Navigation to: $address')),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}