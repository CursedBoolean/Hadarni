import 'package:flutter/material.dart';
import '../../models/progress_model.dart';
import '../constants/app_colors.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/cloud_shape.dart';
import '../widgets/start_button.dart';
import '../widgets/letter_picker_sheet.dart';
import 'learn_letters_exercise_screen.dart';

/// Learn letters intro screen with tappable cloud and start button.
class LearnLettersIntroScreen extends StatelessWidget {
  const LearnLettersIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo progress data — swap with real when backend is ready
    final progress = ProgressModel.demo();

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const AppTopBar(title: 'تعلم الحروف', showMenuButton: true),
          const Spacer(flex: 1),
          // Cloud shape — tappable to pick a letter
          GestureDetector(
            onTap: () async {
              final letter = await LetterPickerSheet.show(
                context,
                letterProgress: progress.letterProgress,
              );
              if (letter != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LearnLettersExerciseScreen(
                      initialLetter: letter,
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
                  'اختر حرفاً',
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
                    builder: (_) => const LearnLettersExerciseScreen(),
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
