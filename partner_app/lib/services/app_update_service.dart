import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';

class AppUpdateService {
  static const String currentVersion = '1.0.0';
  static const int currentBuildNumber = 1;
  static const String appId = 'partner_app';

  static const _installerChannel = MethodChannel('com.locki.app/installer');
  static bool _dialogShowing = false;
  static int? _dismissedBuildNumber;

  /// Check for updates silently on launch
  static Future<void> checkForUpdates(BuildContext context, {bool showNoUpdateToast = false}) async {
    try {
      final uri = Uri.parse('${PartnerConstants.baseUrl}/app-updates/check?appId=$appId&buildNumber=$currentBuildNumber&version=$currentVersion');
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
            const SnackBar(content: Text('Your Locki Partner App is up to date! (v$currentVersion)')),
          );
        }
      }
    } catch (e) {
      debugPrint('Partner AppUpdateService error: $e');
    }
  }

  static void _showUpdateDialog(BuildContext context, Map<String, dynamic> updateData) {
    _dialogShowing = true;
    final latestVer = updateData['latestVersion'] ?? 'New Version';
    final changelog = updateData['changelog'] ?? 'Improvements & bug fixes';
    final apkUrl = updateData['apkUrl']?.toString() ?? '';
    final isForce = updateData['isForceUpdate'] == true;

    bool isDownloading = false;
    double progress = 0.0;
    String statusText = 'Preparing download...';
    String? errorMessage;
    String? downloadedFilePath;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> startInAppDownload() async {
            setDialogState(() {
              isDownloading = true;
              progress = 0.0;
              statusText = 'Starting download...';
              errorMessage = null;
            });

            try {
              if (kIsWeb || !Platform.isAndroid) {
                final uri = Uri.parse(apkUrl);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                _dialogShowing = false;
                if (ctx.mounted) Navigator.pop(ctx);
                return;
              }

              final String? savePath = await _installerChannel.invokeMethod<String>('getCacheApkPath');
              if (savePath == null) throw Exception("Failed to get cache file path");

              final client = http.Client();
              final request = http.Request('GET', Uri.parse(apkUrl));
              final response = await client.send(request);

              if (response.statusCode != 200) {
                throw Exception('Server error: HTTP ${response.statusCode}');
              }

              final totalBytes = response.contentLength ?? 0;
              final file = File(savePath);
              if (file.existsSync()) {
                file.deleteSync();
              }
              final sink = file.openWrite();

              int downloadedBytes = 0;
              await for (final chunk in response.stream) {
                sink.add(chunk);
                downloadedBytes += chunk.length;
                if (totalBytes > 0) {
                  final p = (downloadedBytes / totalBytes).clamp(0.0, 1.0);
                  final dlMb = (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
                  final totMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
                  setDialogState(() {
                    progress = p;
                    statusText = '$dlMb MB / $totMb MB (${(p * 100).toInt()}%)';
                  });
                }
              }

              await sink.flush();
              await sink.close();
              client.close();

              downloadedFilePath = savePath;
              setDialogState(() {
                progress = 1.0;
                statusText = 'Download complete! Opening installer...';
              });

              // Launch Android package installer
              await _installerChannel.invokeMethod('installApk', {'filePath': savePath});
            } catch (e) {
              debugPrint('In-app partner update download error: $e');
              setDialogState(() {
                isDownloading = false;
                errorMessage = 'Download failed: $e';
              });
            }
          }

          return PopScope(
            canPop: !isForce && !isDownloading,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: PartnerConstants.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDownloading ? Icons.downloading_rounded : Icons.system_update_rounded,
                      color: PartnerConstants.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDownloading ? 'Downloading Update...' : 'Partner App Update Available!',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Version v$latestVer',
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isDownloading && progress < 1.0) ...[
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
                      'Please update to ensure seamless orders and business tools.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ] else if (isDownloading || progress == 1.0) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(PartnerConstants.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        statusText,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'Downloading directly inside app. Please wait...',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                if (!isForce && !isDownloading && progress < 1.0)
                  TextButton(
                    onPressed: () {
                      _dialogShowing = false;
                      _dismissedBuildNumber = updateData['latestBuildNumber'] as int?;
                      Navigator.pop(ctx);
                    },
                    child: const Text('Later', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                if (!isDownloading && progress < 1.0)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                    label: const Text('Update Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PartnerConstants.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => startInAppDownload(),
                  ),
                if (progress == 1.0 && downloadedFilePath != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.install_mobile_rounded, size: 18, color: Colors.white),
                    label: const Text('Install Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      try {
                        await _installerChannel.invokeMethod('installApk', {'filePath': downloadedFilePath});
                      } catch (e) {
                        debugPrint('Install invoke error: $e');
                      }
                    },
                  ),
                if (errorMessage != null && !isDownloading) ...[
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_browser, size: 16),
                    label: const Text('Open in Browser', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      if (apkUrl.isNotEmpty) {
                        final uri = Uri.parse(apkUrl);
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ).then((_) => _dialogShowing = false);
  }
}
