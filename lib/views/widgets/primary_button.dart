import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Filled navy button used for main CTAs.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double width;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width = 260,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepNavy,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(text, style: AppTextStyles.buttonText),
      ),
    );
  }
}
