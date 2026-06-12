import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/progress_controller.dart';
import '../constants/app_colors.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/cloud_shape.dart';
import '../widgets/start_button.dart';
import '../widgets/word_picker_sheet.dart';
import 'learn_words_exercise_screen.dart';

/// Learn words intro screen with tappable cloud and start button.
class LearnWordsIntroScreen extends StatelessWidget {
  const LearnWordsIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>().progress;

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const AppTopBar(title: 'تعلم كلمات جديدة', showMenuButton: true),
          const Spacer(flex: 1),
          // Cloud shape — tappable to pick a word
          GestureDetector(
            onTap: () async {
              final word = await WordPickerSheet.show(
                context,
                wordProgress: progress.wordProgress,
              );
              if (word != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LearnWordsExerciseScreen(
                      initialWord: word,
                    ),
                  ),
                );
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CloudShape(width: 300, height: 210),
                // Hint text inside cloud
                Text(
                  'اختر كلمة',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
          // Start button — goes to default exercise
          Center(
            child: StartButton(
              text: 'ابدأ',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LearnWordsExerciseScreen(),
                  ),
                );
              },
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
