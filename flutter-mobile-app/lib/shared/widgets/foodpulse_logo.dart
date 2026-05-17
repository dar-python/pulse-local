import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class FoodPulseLogo extends StatelessWidget {
  const FoodPulseLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 34.0 : 58.0;
    final titleSize = compact ? 20.0 : 30.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            'FP',
            style: TextStyle(
              color: AppColors.prussian,
              fontSize: compact ? 14 : 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'FoodPulse',
          style: TextStyle(
            color: AppColors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
