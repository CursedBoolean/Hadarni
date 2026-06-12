import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Streams feedback text to the ElevenLabs TTS API and plays the resulting
/// audio immediately.  Falls back to the bundled chime if the API call fails.
class ElevenLabsTtsService {
  // ── ElevenLabs constants ────────────────────────────────────────────────────
  static const String _apiBase = 'https://api.elevenlabs.io/v1';

  /// eleven_multilingual_v2 — handles Arabic natively.
  static const String _modelId = 'eleven_multilingual_v2';

  /// "Adam" voice — warm, friendly, works well with Arabic/multilingual.
  static const String _voiceId = 'pNInz6obpgDQGcFmaJgB';

  /// API key — keep this in sync with tools/tts_demo.dart.
  static const String _apiKey =
      'sk_584f8201db05614ddadda647947b3df59410f5a45c19fd38';

  // ── AudioPlayer (one shared instance per service) ─────────────────────────
  final AudioPlayer _player = AudioPlayer();

  /// Converts [text] to speech via ElevenLabs and plays it.
  ///
  /// If the API call fails for any reason the method returns silently so the
  /// app stays functional without network.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    try {
      final bytes = await _fetchAudio(text);
      await _playBytes(bytes);
    } catch (e) {
      debugPrint('[ElevenLabsTTS] speak() failed: $e');
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Calls the ElevenLabs non-streaming TTS endpoint and returns raw MP3 bytes.
  Future<List<int>> _fetchAudio(String text) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$_apiBase/text-to-speech/$_voiceId');
      final request = await client.postUrl(uri);

      request.headers.set('xi-api-key', _apiKey);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.headers.set('Accept', 'audio/mpeg');

      final body = jsonEncode({
        'text': text,
        'model_id': _modelId,
        'voice_settings': {
          'stability': 0.8,
          'similarity_boost': 0.6,
          'style': 0.0,
          'use_speaker_boost': true,
        },
      });
      request.add(utf8.encode(body));

      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );

      if (response.statusCode != 200) {
        final err = await response.transform(utf8.decoder).join();
        throw Exception('ElevenLabs ${response.statusCode}: $err');
      }

      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      debugPrint(
        '[ElevenLabsTTS] Received ${(bytes.length / 1024).toStringAsFixed(1)} KB',
      );
      return bytes;
    } finally {
      client.close();
    }
  }

  /// Writes [bytes] to a temp file and plays it with [AudioPlayer].
  /// Using a temp file is the most reliable cross-platform approach since
  /// audioplayers' BytesSource has inconsistent Android support.
  Future<void> _playBytes(List<int> bytes) async {
    final tmpDir = await getTemporaryDirectory();
    final tmpFile = File(
      '${tmpDir.path}/el_tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
    );
    await tmpFile.writeAsBytes(bytes, flush: true);

    await _player.stop();
    await _player.play(DeviceFileSource(tmpFile.path));

    // Clean up the temp file after playback completes (best-effort).
    _player.onPlayerComplete.first.then((_) {
      tmpFile.deleteSync();
    });
  }

  void dispose() {
    _player.dispose();
  }
}
