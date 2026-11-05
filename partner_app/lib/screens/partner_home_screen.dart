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
    final profileCancelled = (_api.profile?['cancelledJobs'] as num?)?.toInt() ?? 1;
    setState(() {
      _orders = list;
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
    final isProfileComplete = _api.profile?['isProfileComplete'] == true;
    if (!isProfileComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create your profile first before going online!'),
          backgroundColor: Colors.orange,
        ),
      );
      _openProfileScreen();
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
                            isProfileComplete ? Icons.verified : Icons.assignment_ind_outlined,
                            color: isProfileComplete ? PartnerConstants.primary : const Color(0xFFD97706),
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              isProfileComplete ? (profile['serviceName'] ?? 'Verified Specialist') : 'Profile Pending',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isProfileComplete ? PartnerConstants.primary : const Color(0xFFD97706),
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
              color: isProfileComplete ? PartnerConstants.accentGold.withOpacity(0.15) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  isProfileComplete ? Icons.star : Icons.info_outline,
                  color: isProfileComplete ? PartnerConstants.accentGold : const Color(0xFFD97706),
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  isProfileComplete ? '${profile['rating'] ?? 4.8}' : 'New',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
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
                child: isProfileComplete
                    ? _buildActivePartnerDashboard(profile)
                    : _buildNewPartnerDashboard(profile),
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
    final isVerified = profile['isProfileComplete'] == true;

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
                  badge: isVerified ? 'Verified' : 'Pending',
                  badgeColor: isVerified ? PartnerConstants.statusOnline : const Color(0xFFD97706),
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

  void _showSubscriptionPlanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yearly Subscription Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Loki 0% Commission Model', style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('CURRENT MEMBERSHIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      SizedBox(height: 2),
                      Text('Annual Pro Specialist', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      Text('Renews: Nov 05, 2027 (365 Days Left)', style: TextStyle(fontSize: 11, color: Color(0xFF059669))),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const Text('Why Loki Yearly Subscription?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),

            _buildBenefitRow(Icons.money_off_csred_rounded, '0% Commission on Every Job', 'No 20%-30% per-order cuts like other apps. Keep 100% of customer pay.'),
            const SizedBox(height: 8),
            _buildBenefitRow(Icons.all_inclusive_rounded, 'Unlimited Customer Leads', 'No pay-per-lead charges. Accept unlimited nearby customer bookings.'),
            const SizedBox(height: 8),
            _buildBenefitRow(Icons.payments_outlined, 'Direct Customer Cash/UPI', 'Customers pay you directly upon service completion.'),
            const SizedBox(height: 8),
            _buildBenefitRow(Icons.verified_rounded, 'Verified Specialist Badge', 'Priority placement in local customer searches & instant alerts.'),
            const SizedBox(height: 14),

            // Plan Cost Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Annual Membership Fee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9A3412))),
                  Text('₹2,999 / Year', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFC2410C))),
                ],
              ),
            ),
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

  // DASHBOARD FOR NEW PARTNER (SHOWS BIG "CREATE YOUR PROFILE" CARD)
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

        // Yearly Plan & 0% Commission Active Banner
        InkWell(
          onTap: () => _showSubscriptionPlanDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
              boxShadow: [
                BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Row(
                        children: const [
                          Text(
                            'Yearly Subscription Active',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '• 0% Cut',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF059669)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: const [
                          Icon(Icons.calendar_month_outlined, size: 12, color: Color(0xFFB45309)),
                          SizedBox(width: 4),
                          Text(
                            'Valid Till: 05 Nov 2027 (365 Days Remaining)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
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
        ),
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
