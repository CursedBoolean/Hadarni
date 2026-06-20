import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Result returned by the Whisper ASR server.
class WhisperResult {
  final String transcript;
  final bool isCorrect;
  final String target;

  const WhisperResult({
    required this.transcript,
    required this.isCorrect,
    required this.target,
  });

  factory WhisperResult.fromJson(Map<String, dynamic> json) {
    return WhisperResult(
      transcript: json['transcript'] as String? ?? '',
      isCorrect: json['is_correct'] as bool? ?? false,
      target: json['target'] as String? ?? '',
    );
  }
}

/// Exception thrown when the server returns a non-200 response.
class WhisperServerException implements Exception {
  final int statusCode;
  final String message;
  const WhisperServerException(this.statusCode, this.message);
  @override
  String toString() => 'WhisperServerException($statusCode): $message';
}

/// HTTP client for the Whisper ASR FastAPI server.
///
/// [baseUrl] is updated automatically by `tools/run_server.py` each time
/// the server starts — no manual editing required.
///   • LAN mode   →  http://192.168.x.x:8000
///   • ngrok mode →  https://implant-clapper-straddle.ngrok-free.dev
class WhisperService {
  // Android emulator  → https://implant-clapper-straddle.ngrok-free.dev
  // iOS simulator     → https://implant-clapper-straddle.ngrok-free.dev
  // Physical device   → http://<YOUR_LAN_IP>:8000  (e.g. http://192.168.1.x:8000)
  static String baseUrl = 'https://implant-clapper-straddle.ngrok-free.dev';

  /// Sends [audioPath] to the server and checks it against [target].
  ///
  /// Throws [WhisperServerException] on a non-200 response,
  /// [TimeoutException] if the server takes longer than 30 s,
  /// or [SocketException] if the server is unreachable.
  static Future<WhisperResult> transcribe({
    required String audioPath,
    required String target,
  }) async {
    final uri = Uri.parse('$baseUrl/transcribe');

    final request = http.MultipartRequest('POST', uri)
      ..headers['ngrok-skip-browser-warning'] = 'true'
      ..fields['target'] = target
      ..files.add(await http.MultipartFile.fromPath('audio', audioPath));

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );

    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return WhisperResult.fromJson(json);
    }

    throw WhisperServerException(streamedResponse.statusCode, body);
  }

  /// Checks whether the server is reachable (GET /health).
  static Future<bool> isReachable() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {'ngrok-skip-browser-warning': 'true'},
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
