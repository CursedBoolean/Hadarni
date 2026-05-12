import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// RTL text field with label above and translucent white styling.
class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final bool readOnly;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: AppColors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.fieldHint,
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.white, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
