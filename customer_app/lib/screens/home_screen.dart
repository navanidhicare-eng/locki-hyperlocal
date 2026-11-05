import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';
import '../services/api_service.dart';
import 'category_detail_screen.dart';
import 'coming_soon_screen.dart';
import 'login_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';
import 'quick_request_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static bool hasShownLoginPromo = false;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  List<ServiceCategory> _categories = [];
  List<ServiceItem> _trendingServices = [];
  bool _loading = true;
  bool _showAllCategories = false;

  late PageController _bannerController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  late PageController _adBannerController;
  int _currentAdIndex = 0;
  Timer? _adTimer;

  int _currentSpotlightIndex = 0;
  Timer? _spotlightTimer;

  final List<Map<String, dynamic>> _spotlightEvents = const [
    {
      'tag': '🌟 GRAND SHOWROOM OPENING',
      'title': 'Sri Krishna Jewellers',
      'offer': 'Flat 25% OFF on Making Charges + Free Gold Coin!',
      'description': 'Exclusive 916 Hallmark Gold & Diamond Collection. Grand opening celebration live today!',
      'location': 'Main Road, Madhapur (Opp. Metro Pillar 14)',
      'imageUrl': 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=900&auto=format&fit=crop&q=80',
      'badge': 'GOLD SHOP OPENING',
      'colors': [Color(0xFF381A00), Color(0xFFB45309), Color(0xFFD97706)],
      'cta': 'Explore Gold Offers',
      'icon': Icons.diamond_rounded,
    },
    {
      'tag': '🛍️ MEGA RETAIL LAUNCH',
      'title': 'South India Silk & Fashion Mall',
      'offer': 'Buy 1 Get 1 Free on Designer Silk Sarees',
      'description': 'Celebrity ribbon-cutting & inaugural mega discounts on all wedding collections & ethnic wear.',
      'location': 'Jubilee Hills Checkpost, Road No. 36',
      'imageUrl': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=900&auto=format&fit=crop&q=80',
      'badge': 'MALL OPENING',
      'colors': [Color(0xFF1E1B4B), Color(0xFF4338CA), Color(0xFF6366F1)],
      'cta': 'View Collections',
      'icon': Icons.shopping_bag_rounded,
    },
    {
      'tag': '🍽️ FOOD MEGA INAUGURATION',
      'title': 'Paradise Royal Dum Biryani',
      'offer': 'Complimentary Dessert & Buy 2 Get 1 Free',
      'description': 'Authentic Nizami flavors, family dining & royal ambience. Inaugural festive feast for all foodies!',
      'location': 'Hitec City, Cyber Towers Road',
      'imageUrl': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=900&auto=format&fit=crop&q=80',
      'badge': 'NEW BRANCH OPEN',
      'colors': [Color(0xFF310B0B), Color(0xFF991B1B), Color(0xFFDC2626)],
      'cta': 'Reserve Table / Order',
      'icon': Icons.restaurant_rounded,
    },
    {
      'tag': '⚡ SMART TECH SHOWROOM',
      'title': 'Croma Mega Electronics',
      'offer': 'Up to 50% OFF on 4K Smart TVs & Smartphones',
      'description': 'Exclusive inaugural zero-cost EMI + free soundbar with select appliances. Grand opening week!',
      'location': 'Inorbit Mall Road, Mindspace Circle',
      'imageUrl': 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?w=900&auto=format&fit=crop&q=80',
      'badge': 'TECH LAUNCH',
      'colors': [Color(0xFF0F172A), Color(0xFF0284C7), Color(0xFF0EA5E9)],
      'cta': 'Grab Electronics Deals',
      'icon': Icons.devices_rounded,
    },
  ];

  final List<Map<String, dynamic>> _adBanners = const [
    {
      'tag': '🔥 SPONSORED DEAL',
      'title': 'Deep Cleaning & Pest Control Fest',
      'subtitle': 'Up to 30% OFF on Full Home Disinfection',
      'badge': 'CODE: CLEAN30',
      'colors': [Color(0xFF0F172A), Color(0xFF2563EB)],
      'cta': 'Book Offer',
      'icon': Icons.cleaning_services_rounded,
    },
    {
      'tag': '⚡ EMERGENCY FIX',
      'title': 'Bike & Car Breakdown Assistance',
      'subtitle': 'Mechanic reaches in 15 mins with battery jumpstart',
      'badge': 'FLAT ₹100 OFF',
      'colors': [Color(0xFF1E293B), Color(0xFFEF4444)],
      'cta': 'Get Help',
      'icon': Icons.car_repair_rounded,
    },
    {
      'tag': '❄️ APPLIANCE CARE',
      'title': 'AC Gas Refill & Jet Foam Service',
      'subtitle': 'Pre-summer discount starts at just ₹399',
      'badge': 'LIMITED SLOTS',
      'colors': [Color(0xFF18181B), Color(0xFFD97706)],
      'cta': 'Grab Deal',
      'icon': Icons.ac_unit_rounded,
    },
    {
      'tag': '🛵 INSTANT DELIVERY',
      'title': 'Pick & Drop Anywhere in 30 Mins',
      'subtitle': 'Medicine, documents, groceries & tiffin delivery',
      'badge': 'FREE 1ST DROP',
      'colors': [Color(0xFF064E3B), Color(0xFF059669)],
      'cta': 'Order Pickup',
      'icon': Icons.delivery_dining_rounded,
    },
  ];

  final List<Map<String, dynamic>> _promoBanners = const [
    {
      'tag': '⚡ 30-MINUTES HYPERLOCAL PROMISE',
      'title': 'Need a Fix or Quick Delivery?',
      'subtitle': 'Verified professionals at your doorstep with safe OTP check',
      'colors': [Color(0xFF192338), Color(0xFFDE4915)],
      'cta': 'Book Now',
      'icon': Icons.bolt_rounded,
    },
    {
      'tag': '🎉 SPECIAL INTRO OFFER',
      'title': 'Flat ₹150 OFF on AC & Plumbing',
      'subtitle': 'Use coupon code LOKI150 on your first booking today',
      'colors': [Color(0xFF0F172A), Color(0xFF0284C7)],
      'cta': 'Claim Offer',
      'icon': Icons.local_offer_rounded,
    },
    {
      'tag': '🛡️ 100% SATISFACTION GUARANTEE',
      'title': 'Certified & Background Verified',
      'subtitle': 'Government Aadhaar & Police verified skilled technicians',
      'colors': [Color(0xFF064E3B), Color(0xFF059669)],
      'cta': 'Explore Fixes',
      'icon': Icons.verified_user_rounded,
    },
    {
      'tag': '🛍️ WORKSHOP & SPARE PARTS',
      'title': 'Local Workshops & Kirana Stores',
      'subtitle': 'Direct pickup or home drop from verified neighborhood workshops',
      'colors': [Color(0xFF4C1D95), Color(0xFF7C3AED)],
      'cta': 'View Shops',
      'icon': Icons.storefront_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _bannerController = PageController();
    _startBannerTimer();
    _adBannerController = PageController(viewportFraction: 0.78);
    _startAdTimer();
    _startSpotlightTimer();

    // Show Grand Opening Clothing Shop Popup on Login / Fresh App Entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted && !HomeScreen.hasShownLoginPromo) {
          HomeScreen.hasShownLoginPromo = true;
          _showClothingShopPopup(context);
        }
      });
    });
  }

  void _startSpotlightTimer() {
    _spotlightTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        setState(() {
          _currentSpotlightIndex = (_currentSpotlightIndex + 1) % _spotlightEvents.length;
        });
      }
    });
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final next = (_currentBannerIndex + 1) % _promoBanners.length;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _startAdTimer() {
    _adTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_adBannerController.hasClients) {
        final next = (_currentAdIndex + 1) % _adBanners.length;
        _adBannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _adTimer?.cancel();
    _adBannerController.dispose();
    _spotlightTimer?.cancel();
    super.dispose();
  }

  void _showClothingShopPopup(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Clothing Store Promo',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 380),
      transitionBuilder: (context, anim, secAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.75, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, anim, secAnim) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final screenHeight = MediaQuery.of(dialogContext).size.height;
        final dialogWidth = screenWidth > 420 ? 400.0 : (screenWidth * 0.92);
        final dialogMaxHeight = screenHeight * 0.88;

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(maxHeight: dialogMaxHeight),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: const Color(0xFFBE185D).withValues(alpha: 0.20),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Clothing Shop Banner Stack with Close Button
                    Stack(
                      children: [
                        // Fashion Imagery
                        SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: Image.network(
                            'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=900&auto=format&fit=crop&q=80',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF831843), Color(0xFFBE185D), Color(0xFFFB7185)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.shopping_bag_rounded, size: 70, color: Colors.white70),
                              ),
                            ),
                          ),
                        ),

                        // Gradient Shade
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),

                        // Prominent Close Button (Top Right)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(dialogContext).pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF1E293B),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Top-Left Grand Opening Badge
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFBE123C).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'GRAND SHOWROOM OPENING',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9.5,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom Store Title & Location on Image
                        Positioned(
                          bottom: 12,
                          left: 14,
                          right: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Kalanikethan Silks & Fashion Mall',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                  shadows: [
                                    Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1.5)),
                                  ],
                                ),
                              ),
                              SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.amber, size: 13),
                                  SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      'Main Road, Madhapur (Opp. Metro Pillar 118)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        shadows: [
                                          Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                                        ],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Body Details
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Big Discount Banner Box
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFF1F2), Color(0xFFFFFBEB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFBE123C),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'INAUGURAL EXCLUSIVE OFFER',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'FLAT 50% OFF',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF9F1239),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'On All Designer Sarees, Ethnic & Western Collections',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4C0519),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Promo Voucher Code Pill with Copy Action
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.confirmation_number_outlined, size: 15, color: AppConstants.primary),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'CODE: ',
                                        style: TextStyle(fontSize: 11, color: AppConstants.textMuted, fontWeight: FontWeight.w500),
                                      ),
                                      const Text(
                                        'LOKIFASHION50',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppConstants.primary, letterSpacing: 0.5),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () {
                                          Clipboard.setData(const ClipboardData(text: 'LOKIFASHION50'));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Voucher code LOKIFASHION50 copied!'),
                                              backgroundColor: AppConstants.accentEmerald,
                                              duration: Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: Text(
                                            'COPY',
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Highlights / Collections Pills
                          Row(
                            children: [
                              Expanded(child: _buildPromoPill('👗 Pure Silk Sarees', const Color(0xFFBE185D))),
                              const SizedBox(width: 6),
                              Expanded(child: _buildPromoPill('👔 Menswear & Suits', const Color(0xFF1D4ED8))),
                              const SizedBox(width: 6),
                              Expanded(child: _buildPromoPill('👶 Kids Festive Wear', const Color(0xFFD97706))),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Free Gift & Timings Note
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.card_giftcard_rounded, color: Color(0xFFB45309), size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '🎁 First 100 Walk-in Customers get a Free 22K Gold Coin + ₹500 Voucher!',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Primary Claim Button
                          ElevatedButton(
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: 'LOKIFASHION50'));
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 ₹500 Voucher Claimed! Use code LOKIFASHION50 at billing counter.'),
                                  backgroundColor: AppConstants.accentEmerald,
                                  duration: Duration(seconds: 4),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 3,
                              shadowColor: AppConstants.primary.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_mall_rounded, size: 17),
                                SizedBox(width: 6),
                                Text(
                                  'Claim ₹500 Voucher & Visit Store',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),

                          // Secondary Dismiss Text Button
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text(
                                'Maybe Later',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.textMuted,
                                ),
                              ),
                            ),
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
    );
  }

  Widget _buildPromoPill(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _loadData() async {
    setState(() => _loading = true);
    final cats = await _api.fetchCategories();
    final srvs = await _api.fetchServices();
    await _api.fetchPromotions();
    if (mounted) {
      setState(() {
        _categories = cats;
        _trendingServices = srvs;
        _loading = false;
      });
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // User Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
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
                      radius: 28,
                      backgroundColor: AppConstants.primary.withOpacity(0.25),
                      child: Text(
                        (_api.currentUser?['name'] != null && _api.currentUser!['name'].toString().isNotEmpty)
                            ? _api.currentUser!['name'].toString().substring(0, 1).toUpperCase()
                            : 'P',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _api.currentUser?['name'] ?? 'Prasad',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: AppConstants.accentGold, size: 16),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _api.currentUser?['phone'] ?? '+91 98765 11111',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _api.currentUser?['email'] ?? 'customer@loki.com',
                            style: const TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Loki Wallet Chip in Drawer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.account_balance_wallet_outlined, color: AppConstants.accentGold, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Loki Cash Balance',
                            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Text(
                        '₹750.00',
                        style: TextStyle(fontSize: 14, color: AppConstants.accentGold, fontWeight: FontWeight.bold),
                      ),
                    ],
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
                  icon: Icons.explore_outlined,
                  title: 'Explore Services',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'My Bookings & Orders',
                  badge: '2 Active',
                  badgeColor: AppConstants.primary,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Wallet & Payments',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.location_on_outlined,
                  title: 'Saved Addresses',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved: Flat 402, Green Meadows, Madhapur, Hyderabad')),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.local_offer_outlined,
                  title: 'Offers & Coupons',
                  badge: '50% OFF',
                  badgeColor: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Use coupon code LOKI50 on checkout!')),
                    );
                  },
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildDrawerItem(
                  icon: Icons.support_agent_outlined,
                  title: '24/7 Customer Support',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connecting with Loki Customer Support...')),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shield_outlined,
                  title: 'Safety & Verification FAQ',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All Loki technicians are Aadhaar & police verified.')),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings & Preferences',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  iconColor: Colors.red.shade400,
                  textColor: Colors.red.shade700,
                  onTap: () {
                    Navigator.pop(context);
                    _api.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (r) => false,
                    );
                  },
                ),
              ],
            ),
          ),

          // Drawer Footer
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Loki App v2.4.0', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                Text('Hyperlocal Network', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
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
      leading: Icon(icon, color: iconColor ?? const Color(0xFF64748B), size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor ?? const Color(0xFF192338),
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppConstants.primary).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor ?? AppConstants.primary),
              ),
            )
          : const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFCBD5E1)),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _buildScrollingBanners() {
    return Column(
      children: [
        SizedBox(
          height: 145,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _promoBanners.length,
            onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
            itemBuilder: (ctx, idx) {
              final b = _promoBanners[idx];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: b['colors'] as List<Color>,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (b['colors'][1] as Color).withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppConstants.accentGold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              b['tag'] as String,
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 9.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            b['title'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b['subtitle'] as String,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(b['icon'] as IconData, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            b['cta'] as String,
                            style: const TextStyle(
                              color: Color(0xFF192338),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Carousel Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promoBanners.length,
            (idx) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentBannerIndex == idx ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentBannerIndex == idx ? AppConstants.primary : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdScrollingBanners() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.campaign_rounded, color: AppConstants.primary, size: 20),
                SizedBox(width: 6),
                Text(
                  'Exclusive Deals & Offers',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppConstants.secondary),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppConstants.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Sponsored Ads',
                style: TextStyle(fontSize: 10, color: AppConstants.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 195,
          child: PageView.builder(
            controller: _adBannerController,
            itemCount: _adBanners.length,
            onPageChanged: (idx) => setState(() => _currentAdIndex = idx),
            itemBuilder: (ctx, idx) {
              final ad = _adBanners[idx];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: ad['colors'] as List<Color>,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (ad['colors'][1] as Color).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top row: Tag & Badge + Round Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ad['tag'] as String,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppConstants.accentGold,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ad['badge'] as String,
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(ad['icon'] as IconData, color: Colors.white, size: 20),
                        ),
                      ],
                    ),

                    // Middle: Bold Title & Subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ad['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          ad['subtitle'] as String,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Bottom: CTA Pill Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ad['cta'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.secondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 12, color: AppConstants.secondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _adBanners.length,
            (idx) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentAdIndex == idx ? 18 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: _currentAdIndex == idx ? AppConstants.primary : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryIconCard(ServiceCategory cat) {
    Widget iconWidget;

    // 1. Dynamic admin-uploaded iconUrl has highest priority
    if (cat.iconUrl != null && cat.iconUrl!.isNotEmpty) {
      if (cat.iconUrl!.startsWith('http://') || cat.iconUrl!.startsWith('https://')) {
        iconWidget = Image.network(
          cat.iconUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _getCategoryFallbackWidget(cat),
        );
      } else if (cat.iconUrl!.startsWith('assets/')) {
        iconWidget = Image.asset(
          cat.iconUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _getCategoryFallbackWidget(cat),
        );
      } else {
        iconWidget = _getCategoryFallbackWidget(cat);
      }
    } else {
      iconWidget = _getCategoryFallbackWidget(cat);
    }

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(7),
      alignment: Alignment.center,
      child: iconWidget,
    );
  }

  Widget _getCategoryFallbackWidget(ServiceCategory cat) {
    final isPlumbing = cat.id == 'cat_plumbing' || cat.name.toLowerCase().contains('plumb');
    final isElectrician = cat.id == 'cat_electrical' || cat.name.toLowerCase().contains('electr');
    final isDelivery = cat.id == 'cat_delivery' || cat.name.toLowerCase().contains('deliver');
    final isMechanic = cat.id == 'cat_mechanic' || cat.name.toLowerCase().contains('mechanic');
    final isShop = cat.id == 'cat_shops' || cat.name.toLowerCase().contains('shop') || cat.name.toLowerCase().contains('kirana');
    final isCleaning = cat.id == 'cat_cleaning' || cat.name.toLowerCase().contains('clean');
    final isAppliance = cat.id == 'cat_appliances' || cat.name.toLowerCase().contains('appliance');
    final isCable = cat.id == 'cat_bd22116b' || cat.name.toLowerCase().contains('cable');
    final isLeaseRental = cat.id == 'cat_ab5c5cd1' || cat.name.toLowerCase().contains('lease') || cat.name.toLowerCase().contains('rent');

    if (isPlumbing) {
      return Image.asset(
        'assets/images/plumbing_tap.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.plumbing, color: cat.color, size: 26),
      );
    } else if (isElectrician) {
      return Image.asset(
        'assets/images/electrician_bolt.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.bolt, color: cat.color, size: 26),
      );
    } else if (isDelivery) {
      return Image.asset(
        'assets/images/instant_delivery.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.delivery_dining, color: cat.color, size: 26),
      );
    } else if (isMechanic) {
      return Image.asset(
        'assets/images/mechanic_tools.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.build, color: cat.color, size: 26),
      );
    } else if (isShop) {
      return Image.asset(
        'assets/images/local_shop.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.storefront, color: cat.color, size: 26),
      );
    } else if (isCleaning) {
      return Image.asset(
        'assets/images/deep_cleaning.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.cleaning_services, color: cat.color, size: 26),
      );
    } else if (isAppliance) {
      return Image.asset(
        'assets/images/appliance_repairs.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.tv, color: cat.color, size: 26),
      );
    } else if (isCable) {
      return Image.asset(
        'assets/images/cable_technicians.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.router, color: cat.color, size: 26),
      );
    } else if (isLeaseRental) {
      return Image.asset(
        'assets/images/lease_rental.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.apartment, color: cat.color, size: 26),
      );
    } else {
      return Icon(cat.getIconData(), color: cat.color, size: 26);
    }
  }

  Widget _buildSpotlightBillboard() {
    final event = _spotlightEvents[_currentSpotlightIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Pulsing Live Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.stars_rounded, color: AppConstants.accentGold, size: 22),
                SizedBox(width: 6),
                Text(
                  'Local Spotlight & Grand Openings',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppConstants.secondary),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: AppConstants.accentEmerald.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.accentEmerald.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: AppConstants.accentEmerald, size: 7),
                  SizedBox(width: 4),
                  Text(
                    'LIVE TODAY',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: AppConstants.accentEmerald,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Single Large Card with AnimatedSwitcher for Photos & Text Change
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: Container(
            key: ValueKey<int>(_currentSpotlightIndex),
            width: double.infinity,
            height: 275,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: (event['colors'][1] as Color).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Background Image
                Image.network(
                  event['imageUrl'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: event['colors'] as List<Color>,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),

                // 2. Multi-layer Dark Gradient for Contrast
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.88),
                        Colors.black.withOpacity(0.65),
                        (event['colors'][0] as Color).withOpacity(0.70),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                ),

                // 3. Foreground Content
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Tag badge + Live event countdown / dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: AppConstants.accentGold,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(event['icon'] as IconData, color: Colors.black, size: 13),
                                const SizedBox(width: 5),
                                Text(
                                  event['tag'] as String,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentSpotlightIndex + 1} of ${_spotlightEvents.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      // Middle Section: Name, Special Offer & Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event['offer'] as String,
                              style: const TextStyle(
                                color: Color(0xFFFDE047),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            event['description'] as String,
                            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11.5, height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppConstants.accentRose, size: 13),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  event['location'] as String,
                                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Bottom Row: CTA Button + Slide Indicator Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (event['badge'] == 'MALL OPENING' || (event['title'] as String).contains('Silk') || (event['title'] as String).contains('Fashion')) {
                                _showClothingShopPopup(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Opening details for ${event['title']}!'),
                                    backgroundColor: AppConstants.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.celebration_rounded, size: 14),
                            label: Text(
                              event['cta'] as String,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppConstants.secondary,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          Row(
                            children: List.generate(
                              _spotlightEvents.length,
                              (idx) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                width: _currentSpotlightIndex == idx ? 16 : 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: _currentSpotlightIndex == idx ? Colors.white : Colors.white38,
                                  borderRadius: BorderRadius.circular(3),
                                ),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundLight,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppConstants.secondary, size: 26),
            tooltip: 'Open Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Image.asset(
              AppConstants.logoAsset,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: AppConstants.primary, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppConstants.primary, size: 15),
                      const SizedBox(width: 3),
                      const Flexible(
                        child: Text(
                          'Madhapur, Hyderabad',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.secondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 16),
                    ],
                  ),
                  const Text(
                    'Flat 402, Green Meadows',
                    style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppConstants.primary.withOpacity(0.1),
              child: const Icon(Icons.notifications_none, color: AppConstants.primary, size: 20),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. TOP SCROLLING BANNER CAROUSEL (Above Search Bar)
                    _buildScrollingBanners(),

                    const SizedBox(height: 14),

                    // 2. SEARCH BAR (Under Scrolling Banner as requested)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: AppConstants.textDim),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search plumber, electrician, delivery, mechanic...',
                              style: TextStyle(color: AppConstants.textDim, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.mic, color: AppConstants.primary, size: 18),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Quick Service Request Banner (Category -> Sub -> Child -> Problem Description)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QuickRequestScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFDE4915), Color(0xFFB8350B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDE4915).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '⚡ Quick Service Request (త్వరిత బుకింగ్)',
                                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Select category, describe problem & alert nearby experts',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Book Now ➔',
                                style: TextStyle(color: Color(0xFFDE4915), fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3. Categories Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'All Hyperlocal Services',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppConstants.secondary),
                        ),
                        if (_categories.length > 12)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showAllCategories = !_showAllCategories;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppConstants.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _showAllCategories ? 'See Less' : 'See All',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppConstants.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    _showAllCategories ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_right_rounded,
                                    size: 16,
                                    color: AppConstants.primary,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Text(
                            '${_categories.length} Verticals',
                            style: const TextStyle(fontSize: 12, color: AppConstants.primary, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Grid of Services (Animated Expansion for See All if > 12)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 6,
                          childAspectRatio: 0.86,
                        ),
                        itemCount: _showAllCategories
                            ? _categories.length
                            : (_categories.length > 12 ? 12 : _categories.length),
                        itemBuilder: (ctx, idx) {
                          final cat = _categories[idx];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            splashColor: AppConstants.primary.withOpacity(0.08),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                _buildCategoryIconCard(cat),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Text(
                                    cat.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppConstants.secondary,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Featured Local Spotlight / Grand Opening Billboard (Single Big Card with Auto-Changing Photos & Text)
                    _buildSpotlightBillboard(),

                    const SizedBox(height: 24),

                    // Ads & Deals Scrolling Banners Carousel (As requested: Replaces list of fixes)
                    _buildAdScrollingBanners(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
