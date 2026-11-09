import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Locki Hyperlocal';
  static const String appTagline = 'All Services At Your Doorstep in Minutes';

  // API Configuration (Dynamic: works on PC localhost & Mobile on Wi-Fi IP)
  static String get baseUrl {
    if (kIsWeb) {
      try {
        final host = Uri.base.host;
        if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
          return 'http://$host:5000/api';
        }
      } catch (_) {}
      return 'http://localhost:5000/api';
    }
    return 'http://192.168.1.2:5000/api';
  }

  // Locki Brand Colors (Matching Official Locki Logo)
  static const Color primary = Color(0xFFDE4915); // Locki Warm Vermilion / Burnt Orange
  static const Color primaryDark = Color(0xFFB8350B);
  static const Color primaryLight = Color(0xFFFF6D3A);
  static const Color primaryTint = Color(0xFFFFF2ED); // Soft warm orange surface tint
  static const Color secondary = Color(0xFF192338); // Locki Midnight Charcoal Navy
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentRose = Color(0xFFEF4444);
  static const Color backgroundLight = Color(0xFFFAF7F2); // Warm ivory background matching logo
  static const Color cardLight = Colors.white;

  // Text Colors
  static const Color textMain = Color(0xFF192338);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDim = Color(0xFF94A3B8);

  // Brand Asset Paths
  static const String logoAsset = 'assets/images/locki-logo.png';
}
