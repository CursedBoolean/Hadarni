import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../constants/app_colors.dart';
import 'progress_ring.dart';

/// Modal bottom sheet displaying a grid of Arabic words from objects.json with their images and progress rings.
/// Returns the selected Arabic word when tapped.
class WordPickerSheet extends StatelessWidget {
  final Map<String, double> wordProgress;

  const WordPickerSheet({
    super.key,
    required this.wordProgress,
  });

  /// Shows the sheet and returns the selected word, or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required Map<String, double> wordProgress,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => WordPickerSheet(wordProgress: wordProgress),
    );
  }

  /// Loads the list of words from objects.json.
  Future<List<Map<String, dynamic>>> _loadObjects() async {
    final String jsonString =
        await rootBundle.loadString('lib/models/objects.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((item) => item as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadObjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: AppColors.softBlue),
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'تعذر تحميل الكلمات',
                  style: TextStyle(color: AppColors.white, fontSize: 16),
                ),
              ),
            );
          }

          final words = snapshot.data!;

          return Column(
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
                'اختر كلمة للتمرين',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              // Word grid
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: words.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (context, index) {
                      final item = words[index];
                      final arabic = item['arabic'] as String? ?? '';
                      final translit = item['transliteration'] as String? ?? '';
                      final picture = item['picture'] as String? ?? '';
                      final progress = wordProgress[arabic] ?? 0.0;

                      return _WordCell(
                        arabic: arabic,
                        translit: translit,
                        picture: picture,
                        progress: progress,
                        onTap: () => Navigator.pop(context, arabic),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _WordCell extends StatelessWidget {
  final String arabic;
  final String translit;
  final String picture;
  final double progress;
  final VoidCallback onTap;

  const _WordCell({
    required this.arabic,
    required this.translit,
    required this.picture,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgOpacity = 0.08 + (progress * 0.15);
    final isMastered = progress >= 1.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.softBlue.withValues(alpha: bgOpacity),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isMastered
                ? AppColors.warmOrange.withValues(alpha: 0.8)
                : AppColors.softBlue.withValues(alpha: 0.3),
            width: isMastered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isMastered ? AppColors.warmOrange : Colors.black)
                  .withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image container
              Expanded(
                child: Container(
                  color: AppColors.white.withValues(alpha: 0.05),
                  child: picture.isNotEmpty
                      ? Image.network(
                          picture,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.softBlue,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.softBlue,
                              size: 26,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: AppColors.softBlue,
                            size: 26,
                          ),
                        ),
                ),
              ),
              // Word Info & Progress Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    // Progress Indicator
                    ProgressRing(
                      progress: progress,
                      size: 20,
                      strokeWidth: 2.5,
                    ),
                    const SizedBox(width: 8),
                    // Word text & Transliteration
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            arabic,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isMastered ? AppColors.warmOrange : AppColors.white,
                            ),
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            translit,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.white.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
