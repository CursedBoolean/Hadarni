/// Data model holding all dashboard progress stats.
/// Uses demo data until backend integration.
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

  /// Demo word set used until backend provides real data.
  static const List<String> demoWords = [
    'كأس', 'كتاب', 'قلم', 'باب', 'شمس', 'قمر', 'بيت', 'ماء',
  ];

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
    for (int i = 0; i < demoWords.length; i++) {
      wordProg[demoWords[i]] = progValues[i];
    }

    return ProgressModel(
      totalMinutesSpent: 47,
      lettersLearned: 8,
      totalLetters: 28,
      wordsLearned: 5,
      totalWords: demoWords.length,
      letterProgress: letterProg,
      wordProgress: wordProg,
    );
  }
}
