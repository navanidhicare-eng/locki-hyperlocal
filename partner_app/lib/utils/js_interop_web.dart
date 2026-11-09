// Web implementation
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void playAlarm() {
  try {
    js.context.callMethod('playLokiPartnerAlarm');
  } catch (e) {
    // ignore
  }
}

void stopAlarm() {
  try {
    js.context.callMethod('stopLokiPartnerAlarm');
  } catch (e) {
    // ignore
  }
}

void openLiveSelfieScanner(Function(String) onResult) {
  try {
    js.context.callMethod('lokiOpenLiveSelfieScanner', [
      (resultStr) => onResult(resultStr.toString()),
    ]);
  } catch (e) {
    // ignore
  }
}

void pickAndCompressImage(String sourceType, Function(String) onResult) {
  try {
    js.context.callMethod('lokiPickAndCompressImage', [
      sourceType,
      (resultStr) => onResult(resultStr.toString()),
    ]);
  } catch (e) {
    // ignore
  }
}
