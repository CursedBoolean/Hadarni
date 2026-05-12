import 'package:flutter/material.dart';
import '../../models/progress_model.dart';
import '../constants/app_colors.dart';
import 'progress_ring.dart';

/// Modal bottom sheet displaying a grid of Arabic letters with progress rings.
/// Returns the selected letter when tapped.
class LetterPickerSheet extends StatelessWidget {
  final Map<String, double> letterProgress;

  const LetterPickerSheet({
    super.key,
    required this.letterProgress,
  });

  /// Shows the sheet and returns the selected letter, or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required Map<String, double> letterProgress,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LetterPickerSheet(letterProgress: letterProgress),
    );
  }

  @override
  Widget build(BuildContext context) {
    final letters = ProgressModel.arabicLetters;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          const Text(
            'اختر حرفاً للتمرين',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 20),
          // Letter grid
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: letters.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final letter = letters[index];
                  final progress = letterProgress[letter] ?? 0.0;
                  return _LetterCell(
                    letter: letter,
                    progress: progress,
                    onTap: () => Navigator.pop(context, letter),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LetterCell extends StatelessWidget {
  final String letter;
  final double progress;
  final VoidCallback onTap;

  const _LetterCell({
    required this.letter,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Colour intensity based on progress
    final bgOpacity = 0.08 + (progress * 0.15);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.softBlue.withValues(alpha: bgOpacity),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: progress >= 1.0
                ? AppColors.warmOrange.withValues(alpha: 0.7)
                : AppColors.softBlue.withValues(alpha: 0.25),
            width: progress >= 1.0 ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              letter,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: progress >= 1.0
                    ? AppColors.warmOrange
                    : AppColors.white,
              ),
            ),
            const SizedBox(height: 6),
            ProgressRing(
              progress: progress,
              size: 22,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
