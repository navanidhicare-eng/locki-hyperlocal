import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PartnerConstants {
  static const String appName = 'Locki Partner';
  static const String appTagline = 'Earn More as a Hyperlocal Specialist';

  // API base url (Dynamic: works on PC localhost & Mobile on Wi-Fi IP)
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

  // Locki Brand Theme Colors
  static const Color primary = Color(0xFFDE4915); // Signature Locki Warm Vermilion / Burnt Orange
  static const Color primaryDark = Color(0xFFB8350B);
  static const Color primaryLight = Color(0xFFFF6D3A);
  static const Color primaryTint = Color(0xFFFFF2ED);
  static const Color secondary = Color(0xFF192338); // Locki Deep Charcoal Navy
  static const Color statusOnline = Color(0xFF10B981); // Duty ON Green
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentBlue = Color(0xFFDE4915);
  static const Color accentRose = Color(0xFFEF4444);
  static const Color backgroundLight = Color(0xFFFAF7F2); // Warm ivory matching logo
  static const Color cardLight = Colors.white;

  // Text Colors
  static const Color textMain = Color(0xFF192338);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDim = Color(0xFF94A3B8);

  // Brand Asset Paths
  static const String logoAsset = 'assets/images/locki-logo.png';
}
