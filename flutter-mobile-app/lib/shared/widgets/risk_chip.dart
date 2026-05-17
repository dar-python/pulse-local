import 'package:flutter/material.dart';

import '../../core/models/risk_info.dart';
import '../../core/theme/app_colors.dart';

class RiskChip extends StatelessWidget {
  const RiskChip({
    super.key,
    required this.risk,
    this.text,
    this.dense = false,
  });

  final RiskInfo risk;
  final String? text;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: risk.color.withAlpha(38),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: risk.color.withAlpha(70)),
      ),
      child: Text(
        text ?? risk.badgeLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: risk.color,
          fontSize: dense ? 9 : 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class FactorChip extends StatelessWidget {
  const FactorChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == AppColors.green ? AppColors.green : color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
