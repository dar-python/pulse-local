import 'package:flutter/material.dart';

import '../../core/data/mock_foodpulse_data.dart';
import '../../core/models/risk_info.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';

class ConfirmedScreen extends StatelessWidget {
  const ConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final risk = RiskInfo.fromScore(MockFoodPulseData.checkoutRiskScore);

    return Scaffold(
      backgroundColor: AppColors.prussian,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: AppColors.green.withAlpha(32),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.green, width: 2),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.green,
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Order Confirmed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Order #${MockFoodPulseData.orderNumber}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.silver, fontSize: 12),
              ),
              const SizedBox(height: 5),
              const Text(
                'Est. Arrival: 30–45 min',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FoodPulse Risk Monitor',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Current risk score',
                            style: TextStyle(
                              color: AppColors.silver,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '${risk.score}% · adjusting ETA',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: risk.score / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.white.withAlpha(20),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Status',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 13),
                    _StatusRow(label: 'Order placed', done: true),
                    _StatusRow(label: 'Merchant preparing', done: true),
                    _StatusRow(label: 'Rider assigned', done: false),
                    _StatusRow(
                      label: 'Out for delivery',
                      done: false,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Back to Home',
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.done,
    this.isLast = false,
  });

  final String label;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.green : AppColors.silver;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.green.withAlpha(32)
                  : AppColors.white.withAlpha(13),
              shape: BoxShape.circle,
              border: Border.all(
                color: done ? AppColors.green : AppColors.white.withAlpha(28),
                width: 2,
              ),
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.more_horiz_rounded,
              color: color,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label - ${done ? 'done' : 'pending'}',
              style: TextStyle(
                color: done ? AppColors.white : AppColors.silver,
                fontSize: 13,
                fontWeight: done ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
