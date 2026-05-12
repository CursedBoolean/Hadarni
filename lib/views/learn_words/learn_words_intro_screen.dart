import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/start_button.dart';
import 'learn_words_exercise_screen.dart';

/// Learn words intro screen with start button.
class LearnWordsIntroScreen extends StatelessWidget {
  const LearnWordsIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const AppTopBar(title: 'تعلم كلمات جديدة', showMenuButton: true),
          const Spacer(flex: 3),
          // Start button — centered
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
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
