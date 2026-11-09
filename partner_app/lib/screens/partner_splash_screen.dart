import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/partner_api_service.dart';
import 'partner_auth_screen.dart';
import 'partner_main_nav_screen.dart';

class PartnerSplashScreen extends StatefulWidget {
  const PartnerSplashScreen({super.key});

  @override
  State<PartnerSplashScreen> createState() => _PartnerSplashScreenState();
}

class _PartnerSplashScreenState extends State<PartnerSplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _floatController;
  late AnimationController _progressController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _satelliteScale;
  late Animation<double> _contentSlide;
  late Animation<double> _contentFade;

  String _statusText = 'Connecting to Loki Partner Gateway...';
  Timer? _statusTimer1;
  Timer? _statusTimer2;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation (1200ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 2. Continuous floating breathing (2400ms repeating)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // 3. Progress bar animation (2300ms)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..forward();

    // Elastic Logo Scale
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Satellites Scale
    _satelliteScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.85, curve: Curves.elasticOut),
      ),
    );

    // Bottom content slide & fade
    _contentSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeIn),
      ),
    );

    _entranceController.forward();

    // Dynamic status text sequence
    _statusTimer1 = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _statusText = 'Syncing nearby service requests & daily payouts...';
        });
      }
    });

    _statusTimer2 = Timer(const Duration(milliseconds: 1750), () {
      if (mounted) {
        setState(() {
          _statusText = 'Ready! Welcome Locki Partner Specialist';
        });
      }
    });

    // Auto-navigate to next screen
    _navTimer = Timer(const Duration(milliseconds: 2400), _navigateNext);
  }

  void _navigateNext() async {
    if (!mounted) return;
    if (!PartnerApiService().isLoggedIn) {
      await PartnerApiService().initAuth();
    }
    if (!mounted) return;
    final loggedIn = PartnerApiService().isLoggedIn;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, anim, secAnim) =>
            loggedIn ? const PartnerMainNavScreen() : const PartnerAuthScreen(),
        transitionsBuilder: (context, animation, secAnim, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _statusTimer1?.cancel();
    _statusTimer2?.cancel();
    _navTimer?.cancel();
    _entranceController.dispose();
    _floatController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Widget _buildSatelliteBadge({
    required String assetPath,
    required String label,
    required Alignment alignment,
    required double floatPhase,
  }) {
    return Align(
      alignment: alignment,
      child: AnimatedBuilder(
        animation: Listenable.merge([_entranceController, _floatController]),
        builder: (context, child) {
          final floatOffset = math.sin((_floatController.value * 2 * math.pi) + floatPhase) * 6.0;
          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: Transform.scale(
              scale: _satelliteScale.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: PartnerConstants.primary.withOpacity(0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      assetPath,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.flash_on, color: PartnerConstants.primary, size: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: PartnerConstants.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Warm ambient background radial aura
          Positioned(
            top: size.height * 0.20,
            left: (size.width - 340) / 2,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                final scale = 1.0 + (_floatController.value * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          PartnerConstants.primary.withOpacity(0.15),
                          PartnerConstants.accentGold.withOpacity(0.06),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Central Interactive Stage (Logo + Orbiting 3D Badges)
          Center(
            child: SizedBox(
              width: 330,
              height: 290,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Pulsing Glow Wave Ring
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      return Container(
                        width: 220 + (_floatController.value * 28),
                        height: 115 + (_floatController.value * 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: PartnerConstants.primary.withOpacity(0.24 - (_floatController.value * 0.14)),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),

                  // Center Hero Locki Brand Logo Card
                  AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 220,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: PartnerConstants.primary.withOpacity(0.18),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: PartnerConstants.primary.withOpacity(0.22),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  PartnerConstants.logoAsset,
                                  height: 48,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: PartnerConstants.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Locki',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: PartnerConstants.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF4EF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFFD3C2)),
                                  ),
                                  child: const Text(
                                    'PARTNER FLEET',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: PartnerConstants.primary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Orbiting Floating 3D Service Badges
                  // Top-Left: Plumbing
                  _buildSatelliteBadge(
                    assetPath: 'assets/images/plumbing_tap.png',
                    label: 'Plumber',
                    alignment: const Alignment(-0.95, -0.90),
                    floatPhase: 0.0,
                  ),

                  // Top-Right: Electricians
                  _buildSatelliteBadge(
                    assetPath: 'assets/images/electrician_bolt.png',
                    label: 'Electrician',
                    alignment: const Alignment(0.95, -0.90),
                    floatPhase: math.pi * 0.5,
                  ),

                  // Bottom-Left: Delivery
                  _buildSatelliteBadge(
                    assetPath: 'assets/images/instant_delivery.png',
                    label: 'Delivery',
                    alignment: const Alignment(-0.95, 0.90),
                    floatPhase: math.pi,
                  ),

                  // Bottom-Right: Mechanics
                  _buildSatelliteBadge(
                    assetPath: 'assets/images/mechanic_tools.png',
                    label: 'Mechanic',
                    alignment: const Alignment(0.95, 0.90),
                    floatPhase: math.pi * 1.5,
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Presentation: Tagline, Badges & Dynamic Loading Bar
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return Opacity(
                  opacity: _contentFade.value,
                  child: Transform.translate(
                    offset: Offset(0, _contentSlide.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tagline Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.black.withOpacity(0.06)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.workspace_premium_rounded, color: PartnerConstants.primary, size: 16),
                              SizedBox(width: 6),
                              Text(
                                '0% Commission • Yearly Subscription • 100% Your Earnings',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: PartnerConstants.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Guarantee Badges (0% Commission, Yearly Plan, Direct Customer Pay)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMicroFeature(icon: Icons.money_off_csred_rounded, text: '0% Commission'),
                            const SizedBox(width: 12),
                            _buildMicroFeature(icon: Icons.calendar_today_rounded, text: 'Yearly Plan'),
                            const SizedBox(width: 12),
                            _buildMicroFeature(icon: Icons.payments_outlined, text: 'Direct Customer Pay'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Animated Progress Bar Capsule
                        SizedBox(
                          width: 140,
                          height: 4,
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _progressController.value,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(PartnerConstants.primary),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Dynamic Status Subtitle
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _statusText,
                            key: ValueKey<String>(_statusText),
                            style: const TextStyle(
                              fontSize: 11,
                              color: PartnerConstants.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroFeature({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: PartnerConstants.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: PartnerConstants.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

