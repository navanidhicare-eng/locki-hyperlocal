import 'dart:js' as js;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/partner_order_model.dart';
import '../services/partner_api_service.dart';
import 'partner_job_detail_screen.dart';
import 'partner_auth_screen.dart';
import 'partner_profile_screen.dart';
import 'partner_wallet_screen.dart';
import 'partner_job_history_screen.dart';

class PartnerHomeScreen extends StatefulWidget {
  const PartnerHomeScreen({Key? key}) : super(key: key);

  @override
  State<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

class _PartnerHomeScreenState extends State<PartnerHomeScreen> {
  final PartnerApiService _api = PartnerApiService();
  bool _isOnline = false;
  List<PartnerOrder> _orders = [];
  List<dynamic> _categories = [];
  bool _loading = true;
  int _cancelledJobsCount = 1;
  final Set<String> _expandedOrderIds = {};
  final Map<String, TextEditingController> _otpControllers = {};
  bool _hasPlayedAlarm = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _stopJobAlarm();
    for (var c in _otpControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _triggerJobAlarm() {
    try {
      js.context.callMethod('playLokiPartnerAlarm');
    } catch (e) {
      debugPrint('Alarm sound error: $e');
    }
  }

  void _stopJobAlarm() {
    try {
      js.context.callMethod('stopLokiPartnerAlarm');
    } catch (e) {
      debugPrint('Stop alarm error: $e');
    }
  }

  void _initData() async {
    setState(() => _loading = true);
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
    await _api.fetchProfile();
    final list = await _api.fetchPartnerOrders();
    final cats = await _api.fetchCategories();
    final profileCancelled = (_api.profile?['cancelledJobs'] as num?)?.toInt() ?? 1;
    setState(() {
      _orders = list;
      _categories = cats;
      _isOnline = _api.profile?['isOnline'] ?? false;
      if (profileCancelled > _cancelledJobsCount) {
        _cancelledJobsCount = profileCancelled;
      }
      _loading = false;
    });

    final hasPending = list.any((o) => o.orderStatus.toUpperCase() == 'PENDING');
    if (hasPending && !_hasPlayedAlarm) {
      _hasPlayedAlarm = true;
      _triggerJobAlarm();
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
              onRefresh: () async => _initData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: !isProfileComplete
                    ? _buildNewPartnerDashboard(profile)
                    : (isApproved
                        ? _buildActivePartnerDashboard(profile)
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Duty alerts and notifications are active'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
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
                    ? 'మీ డాక్యుమెంట్లలో కొన్ని లోపాలు గుర్తించబడ్డాయి. దయచేసి ప్రొఫైల్ వివరాలు సరిచూసి మళ్లీ సబ్మిట్ చేయండి.'
                    : 'నమస్కారం ${name} గారూ, మీ ప్రొఫైల్ మరియు KYC డాక్యుమెంట్లు విజయవంతంగా సబ్మిట్ అయ్యాయి. Admin వెరిఫికేషన్ పూర్తయ్యే వరకు వేచి ఉండండి.',
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
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Admin అప్రూవల్ పూర్తయిన వెంటనే మీ అకౌంట్ ఆటోమేటిక్‌గా Active అవుతుంది. అప్పుడు మీరు On-Duty స్విచ్ ఆన్ చేసి కస్టమర్ ఆర్డర్లు తీసుకోవచ్చు.',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.two_wheeler_rounded, size: 17, color: Color(0xFFDC2626)),
                      SizedBox(width: 6),
                      Text(
                        'Bike Siren & Vibration: Ready',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          _triggerJobAlarm();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.two_wheeler, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('🚨 Ringing High-Decibel Bike Traffic Siren...'),
                                ],
                              ),
                              backgroundColor: Color(0xFFDC2626),
                              duration: Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.volume_up_rounded, size: 13, color: Color(0xFFDC2626)),
                              SizedBox(width: 3),
                              Text(
                                'Test Siren',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _stopJobAlarm(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.volume_off_rounded, size: 14, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ],
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
                if (_orders.any((o) => o.orderStatus.toUpperCase() == 'PENDING')) ...[
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

        // Incoming Alert Banner when PENDING order is waiting (Bike Traffic Siren Mode)
        if (_orders.any((o) => o.orderStatus.toUpperCase() == 'PENDING'))
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF2F2), Color(0xFFFFFBEB)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDC2626), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.red.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Text(
                                '🚨 BIKE TRAFFIC SIREN ACTIVE',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF991B1B)),
                              ),
                              SizedBox(width: 6),
                              Text(
                                '100% Vol',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            'High-decibel emergency siren & pocket vibration looping for road riding.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _triggerJobAlarm(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.volume_up_rounded, size: 15, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Play Loud Siren (సైరన్)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _stopJobAlarm(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.volume_off_rounded, size: 15, color: Color(0xFF475569)),
                              SizedBox(width: 6),
                              Text(
                                'Mute / Stop Siren',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
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
