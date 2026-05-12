import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Gradient background used across auth screens (login, register, additional info).
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.gradientBottom, AppColors.gradientTop],
        ),
      ),
      child: child,
    );
  }
}
