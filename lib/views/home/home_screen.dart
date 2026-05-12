import 'package:flutter/material.dart';
import '../../models/progress_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/progress_ring.dart';
import '../learn_letters/learn_letters_intro_screen.dart';
import '../learn_letters/learn_letters_exercise_screen.dart';
import '../learn_words/learn_words_intro_screen.dart';
import '../learn_words/learn_words_exercise_screen.dart';
import '../word_game/word_game_intro_screen.dart';

/// Home screen — dashboard with stats, progress, and activity navigation.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo data — swap with real data when backend is ready
    final progress = ProgressModel.demo();

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const AppTopBar(title: 'الصفحة الرئيسية', showMenuButton: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // ── Greeting ──
                  Text(
                    'مرحباً! 👋',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 26),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تابع تقدمك اليوم',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.white.withValues(alpha: 0.6),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 24),

                  // ── Summary stat cards ──
                  _StatCardRow(progress: progress),
                  const SizedBox(height: 24),

                  // ── Overall progress ──
                  _SectionHeader(title: 'التقدم العام'),
                  const SizedBox(height: 10),
                  _OverallProgressBar(progress: progress),
                  const SizedBox(height: 28),

                  // ── Letter progress ──
                  _SectionHeader(title: 'تقدم الحروف'),
                  const SizedBox(height: 10),
                  _HorizontalProgressChips(
                    items: progress.letterProgress,
                    onItemTap: (letter) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LearnLettersExerciseScreen(initialLetter: letter),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── Word progress ──
                  _SectionHeader(title: 'تقدم الكلمات'),
                  const SizedBox(height: 10),
                  _HorizontalProgressChips(
                    items: progress.wordProgress,
                    isWord: true,
                    onItemTap: (word) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LearnWordsExerciseScreen(initialWord: word),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      textDirection: TextDirection.rtl,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stat card row — 3 glassmorphic cards
// ─────────────────────────────────────────────────────────────
class _StatCardRow extends StatelessWidget {
  final ProgressModel progress;
  const _StatCardRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.timer_outlined,
            value: '${progress.totalMinutesSpent}',
            label: 'دقيقة',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.abc_rounded,
            value: '${progress.lettersLearned}/${progress.totalLetters}',
            label: 'حروف',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.menu_book_rounded,
            value: '${progress.wordsLearned}/${progress.totalWords}',
            label: 'كلمات',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.softBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.softBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.warmOrange, size: 26),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Overall progress bar
// ─────────────────────────────────────────────────────────────
class _OverallProgressBar extends StatelessWidget {
  final ProgressModel progress;
  const _OverallProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = progress.overallProgress;
    final pctText = '${(pct * 100).round()}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pctText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warmOrange,
                ),
              ),
              Text(
                'مكتمل',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.white.withValues(alpha: 0.6),
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.warmOrange,
              ),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Horizontal scrollable progress chips (letters or words)
// ─────────────────────────────────────────────────────────────
class _HorizontalProgressChips extends StatelessWidget {
  final Map<String, double> items;
  final bool isWord;
  final void Function(String) onItemTap;

  const _HorizontalProgressChips({
    required this.items,
    this.isWord = false,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final keys = items.keys.toList();

    return SizedBox(
      height: isWord ? 82 : 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: keys.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final key = keys[index];
          final value = items[key] ?? 0.0;
          return _ProgressChip(
            label: key,
            progress: value,
            isWord: isWord,
            onTap: () => onItemTap(key),
          );
        },
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final String label;
  final double progress;
  final bool isWord;
  final VoidCallback onTap;

  const _ProgressChip({
    required this.label,
    required this.progress,
    this.isWord = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = progress >= 1.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isWord ? 90 : 64,
        decoration: BoxDecoration(
          color: completed
              ? AppColors.warmOrange.withValues(alpha: 0.15)
              : AppColors.softBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: completed
                ? AppColors.warmOrange.withValues(alpha: 0.5)
                : AppColors.softBlue.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isWord ? 15 : 22,
                fontWeight: FontWeight.bold,
                color: completed ? AppColors.warmOrange : AppColors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            ProgressRing(progress: progress, size: 22, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Activity card (kept from original)
// ─────────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActivityCard({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.softBlue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.softBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: AppColors.warmOrange, size: 28),
          ],
        ),
      ),
    );
  }
}
