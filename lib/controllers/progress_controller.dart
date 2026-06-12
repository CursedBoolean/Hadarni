import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/streak_model.dart';
import '../models/progress_model.dart';
import '../services/progress_service.dart';

/// Controller managing streak-based progress state.
///
/// Wraps [ProgressService] and exposes a reactive [ProgressModel]
/// for the dashboard via [ChangeNotifier].
class ProgressController extends ChangeNotifier {
  StreakData _streakData = StreakData.empty();
  bool _isLoaded = false;

  /// The computed [ProgressModel] for the dashboard.
  ///
  /// Falls back to demo data if progress hasn't been loaded yet.
  ProgressModel get progress =>
      _isLoaded ? ProgressModel.fromStreakData(_streakData) : ProgressModel.demo();

  /// Raw streak data (for detailed views if needed).
  StreakData get streakData => _streakData;

  /// Whether progress has been loaded from Firestore.
  bool get isLoaded => _isLoaded;

  /// The current user's UID, or null if not signed in.
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Loads streak data from Firestore for the current user.
  ///
  /// Call this after login / on app start.
  Future<void> loadProgress() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final data = await ProgressService.fetchStreaks(uid);
      _streakData = data ?? StreakData.empty();
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load progress: $e');
      // Keep using empty/demo data — don't crash the app
    }
  }

  /// Records a letter pronunciation attempt and persists to Firestore.
  Future<void> recordLetterAttempt(String letter, bool correct) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      _streakData = await ProgressService.recordAttempt(
        uid: uid,
        item: letter,
        isLetter: true,
        isCorrect: correct,
        current: _streakData,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to record letter attempt: $e');
    }
  }

  /// Records a word pronunciation attempt and persists to Firestore.
  Future<void> recordWordAttempt(String word, bool correct) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      _streakData = await ProgressService.recordAttempt(
        uid: uid,
        item: word,
        isLetter: false,
        isCorrect: correct,
        current: _streakData,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to record word attempt: $e');
    }
  }

  /// Resets local state (call on logout).
  void reset() {
    _streakData = StreakData.empty();
    _isLoaded = false;
    notifyListeners();
  }
}
