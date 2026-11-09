import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = ApiService().currentUser;
    final userName = user?['name'] ?? 'Prasad';
    final userPhone = user?['phone'] ?? '+91 98765 11111';
    final userEmail = user?['email'] ?? 'customer@loki.com';
    final initial = (userName.isNotEmpty) ? userName.substring(0, 1).toUpperCase() : 'P';

    return Scaffold(
      backgroundColor: AppConstants.backgroundLight,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.secondary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppConstants.primary.withOpacity(0.12),
                    child: Text(initial, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.primary)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.secondary)),
                        const SizedBox(height: 4),
                        Text(userPhone, style: const TextStyle(fontSize: 13, color: AppConstants.textMuted)),
                        const SizedBox(height: 2),
                        Text(userEmail, style: const TextStyle(fontSize: 12, color: AppConstants.textDim)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Settings List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _tile(Icons.location_on_outlined, 'Manage Saved Addresses', 'Home, Office, Relatives'),
                  const Divider(height: 1),
                  _tile(Icons.verified_user_outlined, 'Locki Safety & Insurance Shield', 'Upto ₹10,000 damage protection guarantee'),
                  const Divider(height: 1),
                  _tile(Icons.support_agent_outlined, '24x7 Customer Support Hotline', 'Chat & Call assistance'),
                  const Divider(height: 1),
                  _tile(Icons.info_outline, 'About Locki Hyperlocal Super App', 'Version 1.0.0 (Fast & Secure)'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ApiService().logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text('Log Out of Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppConstants.backgroundLight, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppConstants.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppConstants.textMuted)),
      trailing: const Icon(Icons.chevron_right, color: AppConstants.textDim),
    );
  }
}
