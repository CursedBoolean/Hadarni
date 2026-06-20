import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Manages the Whisper ASR server lifecycle from the Flutter side.
///
/// Since Flutter cannot directly spawn Python processes, this service:
///   1. Checks whether the server is already running on startup.
///   2. Exposes [isServerUp] so the UI can show an appropriate status banner.
class WhisperServerManager extends ChangeNotifier {
  bool _isServerUp = false;
  bool _isChecking = false;

  /// Whether the Whisper ASR server is currently reachable.
  bool get isServerUp => _isServerUp;

  /// Whether a health-check is currently in progress.
  bool get isChecking => _isChecking;

  /// The base URL used for all Whisper requests.
  /// Updated automatically by tools/run_server.py — no manual editing needed.
  static const String _baseUrl = 'https://implant-clapper-straddle.ngrok-free.dev';

  /// Checks server health and updates [isServerUp].
  Future<void> checkServerHealth() async {
    if (_isChecking) return;
    _isChecking = true;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
            headers: {'ngrok-skip-browser-warning': 'true'},
          )
          .timeout(const Duration(seconds: 5));
      _isServerUp = response.statusCode == 200;
    } catch (_) {
      _isServerUp = false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Re-checks server health (e.g. after user taps "Retry").
  Future<void> retry() => checkServerHealth();
}
