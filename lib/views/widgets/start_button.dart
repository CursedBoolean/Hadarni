import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// "ابدأ" / "إنهاء" style button with orange border on light/transparent bg.
class StartButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double width;

  const StartButton({
    super.key,
    this.text = 'ابدأ',
    this.onPressed,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 70,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white.withValues(alpha: 0.08),
          side: const BorderSide(color: AppColors.warmOrange, width: 2.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(text, style: AppTextStyles.startButtonText),
      ),
    );
  }
}
