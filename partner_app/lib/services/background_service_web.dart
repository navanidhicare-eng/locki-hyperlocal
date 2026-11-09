// Web implementation (no-op)
import 'package:flutter/foundation.dart';

class BackgroundServiceHelper {
  static void initCommunicationPort() {}
  static Future<void> initService() async {}
  static Future<void> requestPermissions() async {}
  static Future<void> startService() async {}
  static Future<void> stopService() async {}
  static void stopAlarm({String? orderId, List<String>? orderIds}) {}
  static void unmuteOrder(String orderId) {}
  static void setSilentMode(bool enabled) {}
  static void addDataCallback(void Function(Object data) callback) {}
  static void removeDataCallback(void Function(Object data) callback) {}
}
