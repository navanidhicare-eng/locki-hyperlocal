import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().initAuth();
  runApp(const LokiCustomerApp());
}

class LokiCustomerApp extends StatelessWidget {
  const LokiCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loki Hyperlocal Services',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppConstants.backgroundLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primary,
          primary: AppConstants.primary,
          secondary: AppConstants.secondary,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
