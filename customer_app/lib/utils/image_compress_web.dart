// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:js' as js;

void pickAndCompressImage(String sourceType, Function(Map<String, dynamic>) onResult) {
  try {
    js.context.callMethod('lokiPickAndCompressImage', [
      sourceType,
      (resultStr) {
        try {
          final data = jsonDecode(resultStr.toString());
          if (data is Map<String, dynamic>) {
            onResult(data);
          } else {
            onResult({'success': false, 'message': 'Invalid response'});
          }
        } catch (e) {
          onResult({'success': false, 'message': e.toString()});
        }
      },
    ]);
  } catch (e) {
    onResult({'success': false, 'message': e.toString()});
  }
}

