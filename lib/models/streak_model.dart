// Data models for streak-based progress tracking.
//
// [ItemStreak] tracks the current and best streak for a single letter or word.
// [StreakData] aggregates all letter and word streaks into a single object
// that maps directly to a Firestore document.

/// Mastery threshold — number of consecutive correct answers needed
/// to consider a letter/word "learned".
const int kMasteryThreshold = 3;

/// Streak data for a single letter or word.
class ItemStreak {
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastAttemptAt;

  const ItemStreak({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastAttemptAt,
  });

  /// Whether this item has reached the mastery threshold.
  bool get isMastered => bestStreak >= kMasteryThreshold;

  /// Progress value 0.0–1.0 for dashboard display.
  double get progress =>
      bestStreak >= kMasteryThreshold ? 1.0 : bestStreak / kMasteryThreshold;

  /// Returns a new [ItemStreak] after recording an attempt.
  ///
  /// If [correct] is true, the current streak increments and best streak
  /// is updated if the new value exceeds it.
  /// If [correct] is false, the current streak resets to 0.
  ItemStreak recordAttempt(bool correct) {
    if (correct) {
      final newCurrent = currentStreak + 1;
      return ItemStreak(
        currentStreak: newCurrent,
        bestStreak: newCurrent > bestStreak ? newCurrent : bestStreak,
        lastAttemptAt: DateTime.now(),
      );
    } else {
      return ItemStreak(
        currentStreak: 0,
        bestStreak: bestStreak,
        lastAttemptAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() => {
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      };

  factory ItemStreak.fromMap(Map<String, dynamic> map) {
    return ItemStreak(
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (map['bestStreak'] as num?)?.toInt() ?? 0,
      lastAttemptAt: map['lastAttemptAt'] != null
          ? DateTime.tryParse(map['lastAttemptAt'] as String)
          : null,
    );
  }
}

/// Aggregated streak data for all letters and words.
///
/// Maps directly to the Firestore document at `users/{uid}/progress/streaks`.
class StreakData {
  final Map<String, ItemStreak> letters;
  final Map<String, ItemStreak> words;
  final int totalAttempts;
  final DateTime updatedAt;

  const StreakData({
    required this.letters,
    required this.words,
    required this.totalAttempts,
    required this.updatedAt,
  });

  /// Empty starting state.
  factory StreakData.empty() => StreakData(
        letters: const {},
        words: const {},
        totalAttempts: 0,
        updatedAt: DateTime.now(),
      );

  /// Returns a copy with a letter attempt recorded.
  StreakData withLetterAttempt(String letter, bool correct) {
    final updated = Map<String, ItemStreak>.from(letters);
    final current = updated[letter] ?? const ItemStreak();
    updated[letter] = current.recordAttempt(correct);
    return StreakData(
      letters: updated,
      words: words,
      totalAttempts: totalAttempts + 1,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns a copy with a word attempt recorded.
  StreakData withWordAttempt(String word, bool correct) {
    final updated = Map<String, ItemStreak>.from(words);
    final current = updated[word] ?? const ItemStreak();
    updated[word] = current.recordAttempt(correct);
    return StreakData(
      letters: letters,
      words: updated,
      totalAttempts: totalAttempts + 1,
      updatedAt: DateTime.now(),
    );
  }

  /// Number of letters that have reached mastery.
  int get lettersLearned =>
      letters.values.where((s) => s.isMastered).length;

  /// Number of words that have reached mastery.
  int get wordsLearned =>
      words.values.where((s) => s.isMastered).length;

  Map<String, dynamic> toMap() => {
        'letters': letters.map((k, v) => MapEntry(k, v.toMap())),
        'words': words.map((k, v) => MapEntry(k, v.toMap())),
        'totalAttempts': totalAttempts,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory StreakData.fromMap(Map<String, dynamic> map) {
    final lettersRaw = map['letters'] as Map<String, dynamic>? ?? {};
    final wordsRaw = map['words'] as Map<String, dynamic>? ?? {};

    return StreakData(
      letters: lettersRaw.map(
        (k, v) => MapEntry(k, ItemStreak.fromMap(v as Map<String, dynamic>)),
      ),
      words: wordsRaw.map(
        (k, v) => MapEntry(k, ItemStreak.fromMap(v as Map<String, dynamic>)),
      ),
      totalAttempts: (map['totalAttempts'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
