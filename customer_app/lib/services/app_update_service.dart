import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';

class AppUpdateService {
  static const String currentVersion = '1.0.2';
  static const int currentBuildNumber = 3;
  static const String appId = 'customer_app';

  static bool _dialogShowing = false;
  static int? _dismissedBuildNumber;

  /// Check for updates silently on launch
  static Future<void> checkForUpdates(BuildContext context, {bool showNoUpdateToast = false}) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/app-updates/check?appId=$appId&buildNumber=$currentBuildNumber&version=$currentVersion');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final latestBuild = data['latestBuildNumber'] as int?;
        final isForce = data['isForceUpdate'] == true;

        if (data['success'] == true && data['hasUpdate'] == true && !_dialogShowing) {
          if (!isForce && _dismissedBuildNumber != null && _dismissedBuildNumber == latestBuild && !showNoUpdateToast) {
            return;
          }
          if (!context.mounted) return;
          _showUpdateDialog(context, data);
        } else if (showNoUpdateToast && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your Locki Customer App is up to date! (v$currentVersion)')),
          );
        }
      }
    } catch (e) {
      debugPrint('Customer AppUpdateService error: $e');
    }
  }

  static void _showUpdateDialog(BuildContext context, Map<String, dynamic> updateData) {
    _dialogShowing = true;
    final latestVer = updateData['latestVersion'] ?? 'New Version';
    final changelog = updateData['changelog'] ?? 'Improvements & bug fixes';
    final apkUrl = updateData['apkUrl']?.toString() ?? '';
    final isForce = updateData['isForceUpdate'] == true;

    showDialog(
      context: context,
      barrierDismissible: !isForce,
      builder: (ctx) => PopScope(
        canPop: !isForce,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.system_update_rounded, color: AppConstants.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Update Available!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text('Version v$latestVer', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('What\'s New:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  changelog,
                  style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please update to the latest version for the best experience.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            if (!isForce)
              TextButton(
                onPressed: () {
                  _dialogShowing = false;
                  _dismissedBuildNumber = updateData['latestBuildNumber'] as int?;
                  Navigator.pop(ctx);
                },
                child: const Text('Later', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
              label: const Text('Update Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                _dialogShowing = false;
                Navigator.pop(ctx);
                if (apkUrl.isNotEmpty) {
                  final uri = Uri.parse(apkUrl);
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {
                    try {
                      await launchUrl(uri);
                    } catch (_) {}
                  }
                }
              },
            ),
          ],
        ),
      ),
    ).then((_) => _dialogShowing = false);
  }
}

