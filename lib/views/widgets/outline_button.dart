import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Outlined button used for secondary CTAs.
class OutlineAppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double width;

  const OutlineAppButton({
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
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.deepNavy, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(text, style: AppTextStyles.buttonText),
      ),
    );
  }
}
