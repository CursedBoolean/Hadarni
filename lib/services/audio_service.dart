import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service to handle playing audio prompts and recorded voice playbacks.
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  /// Plays a bundled asset audio file.
  /// [assetPath] should be relative to the `assets/` directory.
  /// Example: 'audio/letters/أ.mp3'
  Future<void> playAsset(String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Error playing asset $assetPath: $e');
    }
  }

  /// Plays an audio file from the device's local file system.
  /// Useful for playing back recorded audio.
  Future<void> playDeviceFile(String filePath) async {
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(filePath));
    } catch (e) {
      debugPrint('Error playing file $filePath: $e');
    }
  }

  /// Stops any currently playing audio.
  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
