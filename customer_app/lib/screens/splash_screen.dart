import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'main_nav_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _floatController;
  late AnimationController _progressController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _satelliteScale;
  late Animation<double> _contentSlide;
  late Animation<double> _contentFade;

  String _statusText = 'Locating nearby verified technicians...';
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

    // 2. Floating continuous breathing (2400ms repeating)
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
          _statusText = 'Syncing real-time availability in your area...';
        });
      }
    });

    _statusTimer2 = Timer(const Duration(milliseconds: 1750), () {
      if (mounted) {
        setState(() {
          _statusText = 'Ready! Welcome to Locki';
        });
      }
    });

    // Auto-navigate to next screen
    _navTimer = Timer(const Duration(milliseconds: 2400), _navigateNext);
  }

  void _navigateNext() async {
    if (!mounted) return;
    HomeScreen.hasShownLoginPromo = false;
    if (!ApiService().isLoggedIn) {
      await ApiService().initAuth();
    }
    if (!mounted) return;
    final loggedIn = ApiService().isLoggedIn;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, anim, secAnim) => loggedIn ? const MainNavScreen() : const LoginScreen(),
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
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primary.withValues(alpha: 0.10),
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
                      width: 26,
                      height: 26,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.flash_on, color: AppConstants.primary, size: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.secondary,
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
            top: size.height * 0.22,
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
                          AppConstants.primary.withValues(alpha: 0.14),
                          AppConstants.accentGold.withValues(alpha: 0.05),
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
                        width: 210 + (_floatController.value * 28),
                        height: 95 + (_floatController.value * 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppConstants.primary.withValues(alpha: 0.22 - (_floatController.value * 0.14)),
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
                            width: 200,
                            height: 80,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: AppConstants.primary.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppConstants.primary.withValues(alpha: 0.22),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              AppConstants.logoAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppConstants.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Locki',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: AppConstants.secondary,
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

                  // Orbiting Floating 3D Service Badges
                  // Top-Left: Plumbing
                  _buildSatelliteBadge(
                    assetPath: 'assets/images/plumbing_tap.png',
                    label: 'Plumbing',
                    alignment: const Alignment(-0.95, -0.90),
                    floatPhase: 0.0,
                  ),

                  // Top-Right: Electricians
                  _buildSatelliteBadge(
                    assetPath: 'assets/images/electrician_bolt.png',
                    label: 'Electricians',
                    alignment: const Alignment(0.95, -0.90),
                    floatPhase: math.pi * 0.5,
                  ),

                  // Bottom-Left: Instant Delivery
                  _buildSatelliteBadge(
                    assetPath: 'assets/images/instant_delivery.png',
                    label: 'Delivery',
                    alignment: const Alignment(-0.95, 0.90),
                    floatPhase: math.pi,
                  ),

                  // Bottom-Right: Mechanics
                  _buildSatelliteBadge(
                    assetPath: 'assets/images/mechanic_tools.png',
                    label: 'Mechanics',
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
                            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.bolt_rounded, color: AppConstants.primary, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'All Services at Your Doorstep in Minutes',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Guarantee Badges (30-Min, Verified, Fair Price)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMicroFeature(icon: Icons.timer_outlined, text: 'Fast Arrival'),
                            const SizedBox(width: 12),
                            _buildMicroFeature(icon: Icons.verified_user_outlined, text: 'Verified Pros'),
                            const SizedBox(width: 12),
                            _buildMicroFeature(icon: Icons.local_offer_outlined, text: 'Best Pricing'),
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
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primary),
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
                              color: AppConstants.textMuted,
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
        Icon(icon, size: 13, color: AppConstants.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: AppConstants.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
