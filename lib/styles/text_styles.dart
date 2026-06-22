import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body1 = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const body2 = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const code = TextStyle(
    fontFamily: 'Courier',
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const chipText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}