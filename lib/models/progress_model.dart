import 'streak_model.dart';

/// Data model holding all dashboard progress stats.
class ProgressModel {
  final int totalMinutesSpent;
  final int lettersLearned;
  final int totalLetters;
  final int wordsLearned;
  final int totalWords;
  final Map<String, double> letterProgress; // letter → 0.0–1.0
  final Map<String, double> wordProgress;   // word  → 0.0–1.0

  const ProgressModel({
    required this.totalMinutesSpent,
    required this.lettersLearned,
    required this.totalLetters,
    required this.wordsLearned,
    required this.totalWords,
    required this.letterProgress,
    required this.wordProgress,
  });

  /// Overall completion percentage (0.0–1.0).
  double get overallProgress {
    final total = totalLetters + totalWords;
    if (total == 0) return 0;
    return (lettersLearned + wordsLearned) / total;
  }

  /// All 28 standard Arabic letters in order.
  static const List<String> arabicLetters = [
    'أ', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د',
    'ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط',
    'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م',
    'ن', 'ه', 'و', 'ي',
  ];

  /// All 22 words from objects.json.
  static const List<String> allWords = [
    'قَلَم',
    'كِتَاب',
    'بَاب',
    'شَجَرَة',
    'زَهْرَة',
    'سَمَاء',
    'بَحْر',
    'قِطّ',
    'كَلْب',
    'طَائِر',
    'سَمَكَة',
    'تُفَّاحَة',
    'مَاء',
    'حَلِيب',
    'سَيَّارَة',
    'بَيْت',
    'مَدْرَسَة',
    'كَأْس',
    'طَرِيق',
    'سَرِير',
    'كُرْسِيّ',
    'مِفْتَاح',
  ];

  /// Helper to strip diacritics for backward-compatible streak checks
  static String _stripDiacritics(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
  }

  /// Returns a demo instance with sample progress data.
  factory ProgressModel.demo() {
    final letterProg = <String, double>{};
    for (int i = 0; i < arabicLetters.length; i++) {
      // First 8 letters have varying progress, rest are 0
      if (i < 3) {
        letterProg[arabicLetters[i]] = 1.0;
      } else if (i < 5) {
        letterProg[arabicLetters[i]] = 0.7;
      } else if (i < 8) {
        letterProg[arabicLetters[i]] = 0.3;
      } else {
        letterProg[arabicLetters[i]] = 0.0;
      }
    }

    final wordProg = <String, double>{};
    final progValues = [1.0, 0.9, 0.75, 0.6, 0.4, 0.2, 0.1, 0.0];
    for (int i = 0; i < allWords.length; i++) {
      wordProg[allWords[i]] = i < progValues.length ? progValues[i] : 0.0;
    }

    return ProgressModel(
      totalMinutesSpent: 47,
      lettersLearned: 5, // Matching demo mastered count
      totalLetters: 28,
      wordsLearned: 3,
      totalWords: allWords.length,
      letterProgress: letterProg,
      wordProgress: wordProg,
    );
  }

  /// Creates a [ProgressModel] from live [StreakData].
  ///
  /// Pre-populates every Arabic letter and demo word with their streak-based
  /// progress values. Items not yet attempted default to 0.
  factory ProgressModel.fromStreakData(StreakData data) {
    // Build letter progress map — include all 28 letters
    final letterProg = <String, double>{};
    for (final letter in arabicLetters) {
      final streak = data.letters[letter];
      letterProg[letter] = streak?.progress ?? 0.0;
    }

    // Build word progress map — include all 22 words from objects.json
    final wordProg = <String, double>{};
    for (final word in allWords) {
      // Look up streak using both exact word (with diacritics) and stripped word (without)
      final streak = data.words[word] ?? data.words[_stripDiacritics(word)];
      wordProg[word] = streak?.progress ?? 0.0;
    }

    return ProgressModel(
      totalMinutesSpent: 0, // TODO: implement time tracking
      lettersLearned: data.lettersLearned,
      totalLetters: arabicLetters.length,
      wordsLearned: data.wordsLearned,
      totalWords: allWords.length,
      letterProgress: letterProg,
      wordProgress: wordProg,
    );
  }
}
