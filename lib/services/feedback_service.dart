import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sends pronunciation attempt data to the RAG feedback server and returns
/// an AI-generated feedback message for the child.
///
/// The payload mirrors the format used in tools/evaluate_ngrok.py exactly:
///   { target_letter, is_correct, child_name, spoken_text, streak, previous_mistakes }
///
/// The server is expected at [feedbackBaseUrl]/feedback (POST).
/// Change [feedbackBaseUrl] to your actual ngrok / LAN URL.
class FeedbackService {
  // ──────────────────────────────────────────────────────────────────────────
  // Set this to your ngrok URL or LAN address of the RAG/feedback server.
  // Example: 'https://xxxx.ngrok-free.app'
  // ──────────────────────────────────────────────────────────────────────────
  static const String feedbackBaseUrl = 'https://implant-clapper-straddle.ngrok-free.dev';

  /// Sends a pronunciation attempt to the feedback server.
  ///
  /// Returns the server's response JSON as a Map, or null if unreachable.
  ///
  /// Parameters:
  ///   [targetText]         Arabic letter or word that was targeted
  ///   [isCorrect]          Whether the child's pronunciation was accepted
  ///   [childName]          Child's display name (for personalised feedback)
  ///   [spokenText]         What Whisper transcribed (the spoken text)
  ///   [streak]             Current consecutive-correct streak count
  ///   [previousMistakes]   How many times this item was previously wrong
  static Future<Map<String, dynamic>?> sendFeedback({
    required String targetText,
    required bool isCorrect,
    required String childName,
    required String spokenText,
    int streak = 0,
    int previousMistakes = 0,
  }) async {
    try {
      final uri = Uri.parse('$feedbackBaseUrl/feedback');
      final payload = {
        'target_letter': targetText,
        'is_correct': isCorrect,
        'child_name': childName,
        'spoken_text': spokenText,
        'streak': streak,
        'previous_mistakes': previousMistakes,
      };

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[FeedbackService] Raw response: $decoded');
        return decoded;
      }
      debugPrint('[FeedbackService] Non-200 response: ${response.statusCode}');
      return null;
    } catch (e) {
      // Feedback is non-critical — log but don't rethrow
      debugPrint('[FeedbackService] Error sending feedback: $e');
      return null;
    }
  }

  /// Checks whether the feedback server is reachable.
  static Future<bool> isReachable() async {
    try {
      final response = await http
          .get(Uri.parse('$feedbackBaseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
