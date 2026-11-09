// Mobile (Android / iOS) native audio and vibration implementation
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

AudioPlayer? _mobileSirenPlayer;
bool _isPlaying = false;

void playAlarm() async {
  try {
    if (_isPlaying) return;
    _isPlaying = true;

    _mobileSirenPlayer ??= AudioPlayer();
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
    await _mobileSirenPlayer!.setReleaseMode(ReleaseMode.loop);
    await _mobileSirenPlayer!.setVolume(1.0);
    
    // Explicit continuous loop listener
    _mobileSirenPlayer!.onPlayerComplete.listen((_) {
      if (_isPlaying) {
        _mobileSirenPlayer?.play(AssetSource('audio/siren.wav'));
      }
    });

    await _mobileSirenPlayer!.play(AssetSource('audio/siren.wav'));

    // Continuous urgent vibration motor pattern (1.2s buzz, 100ms micro-gap, looping non-stop)
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(
        pattern: [0, 1200, 100, 1200, 100],
        repeat: 0,
      );
    }
  } catch (e) {
    // ignore
  }
}

void stopAlarm() async {
  try {
    _isPlaying = false;
    await _mobileSirenPlayer?.stop();
    Vibration.cancel();
  } catch (_) {}
}

void openLiveSelfieScanner(Function(String) onResult) {
  // Mobile fallback or camera scanner stub
}

void pickAndCompressImage(String sourceType, Function(String) onResult) {
  // Mobile image picker stub
}
