import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/risk_color_mapper.dart';
import '../../domain/entities/checkout_risk_result.dart';

class RiskResultCard extends StatelessWidget {
  const RiskResultCard({super.key, required this.result});

  final CheckoutRiskResult result;

  @override
  Widget build(BuildContext context) {
    final color = RiskColorMapper.colorFor(result.riskLevel);
    final isFallback = result.source.toLowerCase() == 'fallback';
    final riskPercent = (result.riskScore * 100).round();

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Risk Level: ${result.riskLevel}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Risk Score: $riskPercent%',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(result.recommendation),
            if (result.weatherCategory != null) ...[
              const SizedBox(height: 8),
              if (result.weatherSource?.toLowerCase() == 'fallback')
                const Text('Weather unavailable, using safe fallback.')
              else ...[
                Text(
                  'Current weather: ${_titleCase(result.weatherCategory!)}',
                ),
                if (result.weatherCondition?.isNotEmpty ?? false)
                  Text('Condition: ${result.weatherCondition}'),
              ],
            ],
            const SizedBox(height: 12),
            Text(
              'Source: ${result.source}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (isFallback) ...[
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.alabaster,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.silver),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 20, color: AppColors.dusk),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Prediction service unavailable. Laravel returned a fallback result, so checkout can proceed.',
                          style: TextStyle(color: AppColors.prussian),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _titleCase(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'Unknown';
  }

  return normalized[0].toUpperCase() + normalized.substring(1);
}
