import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RiskColorMapper {
  const RiskColorMapper._();

  static Color colorFor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return AppColors.green;
      case 'medium':
        return AppColors.orange;
      case 'high':
        return AppColors.tangerine;
      case 'unknown':
      default:
        return AppColors.silver;
    }
  }

  static String labelForScore(int score) {
    if (score < 0 || score > 100) {
      return 'Unknown';
    }
    if (score <= 39) {
      return 'Low';
    }
    if (score <= 69) {
      return 'Medium';
    }
    return 'High';
  }
}
