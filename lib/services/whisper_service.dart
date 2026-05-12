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

/// HTTP client for the local Whisper ASR FastAPI server.
///
/// Server URL notes:
///   • Android emulator  →  http://10.0.2.2:8000  (loopback to host machine)
///   • iOS simulator     →  http://127.0.0.1:8000
///   • Physical device   →  http://`HOST_LAN_IP`:8000
///
/// Change [baseUrl] to match your development setup.
class WhisperService {
  static const String baseUrl = 'http://10.0.2.2:8000';

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
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
