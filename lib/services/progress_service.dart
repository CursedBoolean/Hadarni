import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/streak_model.dart';

/// Firestore CRUD operations for the streak progress document.
///
/// All streak data lives in a single document per user:
///   `users/{uid}/progress/streaks`
class ProgressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firestore path: users/{uid}/progress/streaks
  static DocumentReference _streaksDoc(String uid) =>
      _firestore.collection('users').doc(uid).collection('progress').doc('streaks');

  /// Fetches the user's streak data from Firestore.
  ///
  /// Returns `null` if the document doesn't exist yet (first-time user).
  static Future<StreakData?> fetchStreaks(String uid) async {
    final doc = await _streaksDoc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return StreakData.fromMap(doc.data()! as Map<String, dynamic>);
  }

  /// Writes the full streak data to Firestore (merge to avoid clobbering).
  static Future<void> saveStreaks(String uid, StreakData data) async {
    await _streaksDoc(uid).set(data.toMap(), SetOptions(merge: true));
  }

  /// Records a single attempt for a letter or word, persists to Firestore,
  /// and returns the updated [StreakData].
  ///
  /// [item] is the Arabic letter or word.
  /// [isLetter] distinguishes letters from words.
  /// [isCorrect] is the result from the Whisper ASR evaluation.
  /// [current] is the current in-memory streak state.
  static Future<StreakData> recordAttempt({
    required String uid,
    required String item,
    required bool isLetter,
    required bool isCorrect,
    required StreakData current,
  }) async {
    final updated = isLetter
        ? current.withLetterAttempt(item, isCorrect)
        : current.withWordAttempt(item, isCorrect);

    await saveStreaks(uid, updated);
    return updated;
  }
}
