import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'services/partner_api_service.dart';
import 'services/background_service.dart';
import 'screens/partner_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundServiceHelper.initCommunicationPort();
  await PartnerApiService().initAuth();
  await BackgroundServiceHelper.initService();
  runApp(const LokiPartnerApp());
}

class LokiPartnerApp extends StatelessWidget {
  const LokiPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Locki Partner App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: PartnerConstants.backgroundLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: PartnerConstants.primary,
          primary: PartnerConstants.primary,
          secondary: PartnerConstants.secondary,
        ),
      ),
      home: const PartnerSplashScreen(),
    );
  }
}
