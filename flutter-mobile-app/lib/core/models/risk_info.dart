import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/risk_color_mapper.dart';

class RiskInfo {
  const RiskInfo({
    required this.score,
    required this.label,
    required this.color,
  });

  final int score;
  final String label;
  final Color color;

  String get displayLabel => '$label Risk';
  String get badgeLabel => '${label.toUpperCase()} RISK';

  static RiskInfo fromScore(int score) {
    final label = RiskColorMapper.labelForScore(score);
    return RiskInfo(
      score: score,
      label: label,
      color: RiskColorMapper.colorFor(label),
    );
  }

  static const unknown = RiskInfo(
    score: 0,
    label: 'Unknown',
    color: AppColors.silver,
  );
}
