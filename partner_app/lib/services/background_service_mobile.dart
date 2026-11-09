// Android & iOS Mobile Implementation using flutter_foreground_task
import 'dart:async';
import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../core/constants.dart';

// Top-level entry point for foreground task
@pragma('vm:entry-point')
void startBackgroundCallback() {
  FlutterForegroundTask.setTaskHandler(PartnerBackgroundTaskHandler());
}

class PartnerBackgroundTaskHandler extends TaskHandler {
  AudioPlayer? _player;
  bool _isAlarmPlaying = false;
  String? _lastNotifiedOrderId;
  final Set<String> _mutedOrderIds = {};

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _player = AudioPlayer();
    try {
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientExclusive,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.duckOthers},
        ),
      ));
    } catch (_) {}
    await _player?.setReleaseMode(ReleaseMode.loop);
    await _player?.setVolume(1.0);
    _player?.onPlayerComplete.listen((_) {
      if (_isAlarmPlaying) {
        _player?.play(AssetSource('audio/siren.wav'));
      }
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('locki_partner_token');
      if (token == null || token.isEmpty) return;

      final isSilentMode = prefs.getBool('locki_silent_mode') ?? false;

      final res = await http.get(
        Uri.parse('${PartnerConstants.baseUrl}/providers/my-orders'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List orders = data['orders'] ?? [];
        final pendingOrders = orders.where((o) => (o['orderStatus'] ?? '').toString().toUpperCase() == 'PENDING').toList();

        if (pendingOrders.isNotEmpty) {
          // Find any unmuted pending orders
          final unmutedOrders = pendingOrders.where((o) => !_mutedOrderIds.contains(o['id'])).toList();

          if (unmutedOrders.isNotEmpty) {
            final unmutedOrder = unmutedOrders.first;
            final orderId = unmutedOrder['id'] ?? 'Order';
            final sName = unmutedOrder['serviceName'] ?? unmutedOrder['categoryName'] ?? 'Service';

            // ONLY update notification, wake screen, and alert ONCE per unique unmuted order
            if (_lastNotifiedOrderId != orderId) {
              _lastNotifiedOrderId = orderId;

              // Update foreground notification
              FlutterForegroundTask.updateService(
                notificationTitle: '🚨 NEW CUSTOMER REQUEST: $sName',
                notificationText: '$orderId nearby! Tap to open and accept.',
                notificationButtons: [
                  const NotificationButton(id: 'btn_mute', text: 'MUTE SIREN'),
                ],
              );

              // Wake up device screen and show on lock screen
              FlutterForegroundTask.wakeUpScreen();
              FlutterForegroundTask.setOnLockScreenVisibility(true);

              // Send event to main UI
              FlutterForegroundTask.sendDataToMain({
                'action': 'NEW_PENDING_ORDER',
                'orderId': orderId,
                'count': pendingOrders.length,
              });
            }

            if (!isSilentMode && !_isAlarmPlaying) {
              _isAlarmPlaying = true;
              try {
                await _player?.play(AssetSource('audio/siren.wav'));
              } catch (_) {}
              try {
                final hasVibrator = await Vibration.hasVibrator();
                if (hasVibrator == true) {
                  Vibration.vibrate(
                    pattern: [0, 1200, 100, 1200, 100],
                    repeat: 0,
                  );
                }
              } catch (_) {}
            } else if (isSilentMode && _isAlarmPlaying) {
              _isAlarmPlaying = false;
              try {
                await _player?.stop();
              } catch (_) {}
              try {
                Vibration.cancel();
              } catch (_) {}
            }
          } else {
            // All currently pending orders are muted by partner!
            if (_isAlarmPlaying) {
              _isAlarmPlaying = false;
              try {
                await _player?.stop();
              } catch (_) {}
              try {
                Vibration.cancel();
              } catch (_) {}
            }
          }
        } else {
          // Reset when there are no pending orders
          _lastNotifiedOrderId = null;
          _mutedOrderIds.clear();
          if (_isAlarmPlaying) {
            _isAlarmPlaying = false;
            try {
              await _player?.stop();
            } catch (_) {}
            try {
              Vibration.cancel();
            } catch (_) {}
            FlutterForegroundTask.updateService(
              notificationTitle: 'Locki Partner: ON DUTY',
              notificationText: 'Online & scanning for customer requests...',
            );
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _isAlarmPlaying = false;
    try {
      await _player?.stop();
      _player?.dispose();
    } catch (_) {}
    try {
      Vibration.cancel();
    } catch (_) {}
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map && data['action'] == 'STOP_ALARM') {
      _isAlarmPlaying = false;
      final String? orderId = data['orderId']?.toString();
      if (orderId != null && orderId.isNotEmpty) {
        _mutedOrderIds.add(orderId);
      }
      if (data['orderIds'] is List) {
        for (final id in (data['orderIds'] as List)) {
          _mutedOrderIds.add(id.toString());
        }
      }
      if (_lastNotifiedOrderId != null) {
        _mutedOrderIds.add(_lastNotifiedOrderId!);
      }
      try {
        _player?.stop();
      } catch (_) {}
      try {
        Vibration.cancel();
      } catch (_) {}
    } else if (data is Map && data['action'] == 'UNMUTE_ORDER') {
      final String? orderId = data['orderId']?.toString();
      if (orderId != null && orderId.isNotEmpty) {
        _mutedOrderIds.remove(orderId);
      }
    } else if (data is Map && data['action'] == 'SET_SILENT_MODE') {
      final enabled = data['enabled'] == true;
      if (enabled && _isAlarmPlaying) {
        _isAlarmPlaying = false;
        try { _player?.stop(); } catch (_) {}
        try { Vibration.cancel(); } catch (_) {}
      }
    } else if (data is Map && data['action'] == 'RESET_MUTE') {
      _mutedOrderIds.clear();
      _isAlarmPlaying = false;
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'btn_mute') {
      _isAlarmPlaying = false;
      if (_lastNotifiedOrderId != null) {
        _mutedOrderIds.add(_lastNotifiedOrderId!);
      }
      try {
        _player?.stop();
      } catch (_) {}
      try {
        Vibration.cancel();
      } catch (_) {}
      FlutterForegroundTask.sendDataToMain({
        'action': 'ORDER_MUTED',
        if (_lastNotifiedOrderId != null) 'orderId': _lastNotifiedOrderId,
      });
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {}
}

class BackgroundServiceHelper {
  static void initCommunicationPort() {
    FlutterForegroundTask.initCommunicationPort();
  }

  static Future<void> initService() async {
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'locki_duty_channel',
          channelName: 'Locki Partner On-Duty Service',
          channelDescription: 'Maintains on-duty connection to receive instant leads with siren',
          channelImportance: NotificationChannelImportance.MAX,
          priority: NotificationPriority.MAX,
          visibility: NotificationVisibility.VISIBILITY_PUBLIC,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(4000),
          autoRunOnBoot: false,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
    } catch (_) {}
  }

  static Future<void> requestPermissions() async {
    try {
      final perm = await FlutterForegroundTask.checkNotificationPermission();
      if (perm != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    } catch (_) {}
    try {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    } catch (_) {}
  }

  static Future<void> startService() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      return;
    }
    await FlutterForegroundTask.startService(
      serviceId: 501,
      notificationTitle: 'Locki Partner: ON DUTY',
      notificationText: 'Online & scanning for customer requests...',
      notificationButtons: [
        const NotificationButton(id: 'btn_mute', text: 'MUTE SIREN'),
      ],
      callback: startBackgroundCallback,
    );
  }

  static Future<void> stopService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  static void stopAlarm({String? orderId, List<String>? orderIds}) {
    FlutterForegroundTask.sendDataToTask({
      'action': 'STOP_ALARM',
      if (orderId != null) 'orderId': orderId,
      if (orderIds != null) 'orderIds': orderIds,
    });
  }

  static void unmuteOrder(String orderId) {
    FlutterForegroundTask.sendDataToTask({
      'action': 'UNMUTE_ORDER',
      'orderId': orderId,
    });
  }

  static void setSilentMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('locki_silent_mode', enabled);
    } catch (_) {}
    FlutterForegroundTask.sendDataToTask({
      'action': 'SET_SILENT_MODE',
      'enabled': enabled,
    });
  }

  static void addDataCallback(void Function(Object data) callback) {
    FlutterForegroundTask.addTaskDataCallback(callback);
  }

  static void removeDataCallback(void Function(Object data) callback) {
    FlutterForegroundTask.removeTaskDataCallback(callback);
  }
}
