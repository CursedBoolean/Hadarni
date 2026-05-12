import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle screenTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle brandTitle = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    color: AppColors.white,
    height: 1.6,
  );

  static const TextStyle fieldLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static const TextStyle fieldHint = TextStyle(
    fontSize: 14,
    color: AppColors.hintColor,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle linkText = TextStyle(
    fontSize: 14,
    color: AppColors.white,
  );

  static const TextStyle arabicLetter = TextStyle(
    fontSize: 80,
    fontWeight: FontWeight.bold,
    color: AppColors.warmOrange,
  );

  static const TextStyle wordLabel = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle startButtonText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.warmOrange,
  );
}
