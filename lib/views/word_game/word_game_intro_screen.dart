import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/start_button.dart';
import 'word_game_screen.dart';

/// Word game intro screen with start button.
class WordGameIntroScreen extends StatelessWidget {
  const WordGameIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const AppTopBar(title: 'العب بالكلمات', showMenuButton: true),
          const Spacer(flex: 3),
          // Start button — centered
          Center(
            child: StartButton(
              text: 'ابدأ',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WordGameScreen(),
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
