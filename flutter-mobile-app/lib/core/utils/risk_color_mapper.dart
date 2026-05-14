import 'package:flutter/material.dart';

class RiskColorMapper {
  const RiskColorMapper._();

  static Color colorFor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.amber;
      case 'high':
        return Colors.red;
      case 'unknown':
      default:
        return Colors.grey;
    }
  }
}
