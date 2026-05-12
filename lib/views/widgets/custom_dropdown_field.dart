import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// RTL dropdown field with label above, styled to match text fields.
class CustomDropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.hint,
    this.value,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Align(
                alignment: Alignment.centerRight,
                child: Text(hint, style: AppTextStyles.fieldHint),
              ),
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.white,
              ),
              dropdownColor: AppColors.deepNavy,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  alignment: Alignment.centerRight,
                  child: Text(item, textDirection: TextDirection.rtl),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
