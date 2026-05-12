import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/primary_button.dart';
import '../widgets/outline_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Welcome / splash screen with background image, branding, and auth buttons.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/welcome_bg.jpg',
            fit: BoxFit.cover,
          ),
          // Dark overlay
          Container(color: AppColors.darkOverlay),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Brand title
                  const Text(
                    'هدّرني',
                    style: AppTextStyles.brandTitle,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 24),
                  // Motivational text
                  const Text(
                    'لا توجد إجابات خاطئة، فقط خطوات\nللأمامتعلم بوتيرتك، واحتفل بكل إنجاز\nصغير',
                    style: AppTextStyles.subtitle,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  const Spacer(flex: 3),
                  // Login button
                  PrimaryButton(
                    text: 'تسجيل الدخول',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Register button
                  OutlineAppButton(
                    text: 'إنشاء حساب',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
