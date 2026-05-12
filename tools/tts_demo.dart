/// ElevenLabs TTS Demo Script
///
/// Generates Arabic speech audio from text using the ElevenLabs API
/// and saves it to assets/audio/.
///
/// Usage:  dart run tools/tts_demo.dart
///
/// Requires the ELEVEN_TTS_KEY in the project root .env file.
library;

import 'dart:convert';
import 'dart:io';

const String _apiBase = 'https://api.elevenlabs.io/v1';

/// Multilingual v2 — supports Arabic natively
const String _modelId = 'eleven_multilingual_v2';

/// "Adam" voice — works well with multilingual/Arabic
const String _voiceId = 'pNInz6obpgDQGcFmaJgB';

Future<void> main() async {
  // ── Read API key from .env ──────────────────────────────
  final envFile = File('../.env');
  if (!envFile.existsSync()) {
    stderr.writeln('❌  .env file not found in project root.');
    exit(1);
  }

  final envContent = envFile.readAsStringSync();
  final match = RegExp(r'ELEVEN_TTS_KEY="?([^"\s]+)"?').firstMatch(envContent);
  if (match == null) {
    stderr.writeln('❌  ELEVEN_TTS_KEY not found in .env');
    exit(1);
  }
  final apiKey = match.group(1)!;
  stdout.writeln('✅  API key loaded.');

  // ── Ensure output directory exists ──────────────────────
  final outputDir = Directory('../assets/audio');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
    stdout.writeln('📁  Created assets/audio/');
  }

  // ── Demo texts to generate ─────────────────────────────
  final demos = <String, String>{"jeem": "جَ", "zay": "زَ"};

  // ── Generate each audio file ───────────────────────────
  for (final entry in demos.entries) {
    final filename = '${entry.key}.mp3';
    final text = entry.value;

    stdout.write('🔊  Generating "$text" → $filename ... ');

    try {
      final audioBytes = await _generateSpeech(
        apiKey: apiKey,
        text: text,
        voiceId: _voiceId,
        modelId: _modelId,
      );

      final outFile = File('${outputDir.path}/$filename');
      outFile.writeAsBytesSync(audioBytes);

      stdout.writeln(
        '✅  saved (${(audioBytes.length / 1024).toStringAsFixed(1)} KB)',
      );
    } catch (e) {
      stdout.writeln('❌  $e');
    }
  }

  stdout.writeln('\n🎉  Done! Audio files saved to assets/audio/');
}

/// Calls the ElevenLabs TTS endpoint and returns raw audio bytes (MP3).
Future<List<int>> _generateSpeech({
  required String apiKey,
  required String text,
  required String voiceId,
  required String modelId,
}) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse('$_apiBase/text-to-speech/$voiceId');
    final request = await client.postUrl(uri);

    // Headers
    request.headers.set('xi-api-key', apiKey);
    request.headers.set('Content-Type', 'application/json; charset=utf-8');
    request.headers.set('Accept', 'audio/mpeg');

    // Body — encode as UTF-8 bytes so Arabic characters are handled correctly
    final body = jsonEncode({
      'text': text,
      'model_id': modelId,
      'voice_settings': {'stability': 0.8, 'similarity_boost': 0.5},
    });
    request.add(utf8.encode(body));

    final response = await request.close();

    if (response.statusCode != 200) {
      final errorBody = await response.transform(utf8.decoder).join();
      throw Exception('API returned ${response.statusCode}: $errorBody');
    }

    // Collect all response bytes (audio data)
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
    }
    return bytes;
  } finally {
    client.close();
  }
}
