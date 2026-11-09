// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<Map<String, double>?> getCurrentGpsCoordinates() async {
  try {
    final geo = html.window.navigator.geolocation;
    if (geo != null) {
      final pos = await geo.getCurrentPosition(
        enableHighAccuracy: true,
        timeout: const Duration(seconds: 10),
      );
      final lat = pos.coords?.latitude?.toDouble();
      final lng = pos.coords?.longitude?.toDouble();
      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng};
      }
    }
  } catch (e) {
    // Permission denied or timed out
  }
  return null;
}

