import 'package:flutter/material.dart';

import '../../core/data/mock_foodpulse_data.dart';
import '../../core/models/risk_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/risk_color_mapper.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../foodpulse/models/foodpulse_order.dart';
import '../foodpulse/repositories/foodpulse_repository.dart';

class ConfirmedScreen extends StatelessWidget {
  const ConfirmedScreen({
    super.key,
    OrderConfirmation? orderConfirmation,
    this.fallbackMessage,
  }) : _orderConfirmation = orderConfirmation;

  final OrderConfirmation? _orderConfirmation;
  final String? fallbackMessage;

  @override
  Widget build(BuildContext context) {
    final order =
        _orderConfirmation ??
        const FoodPulseFallbackRepository().orderConfirmation(
          MockFoodPulseData.orderNumber,
        );
    final risk = RiskInfo(
      score: order.risk.score,
      label: order.risk.level,
      color: RiskColorMapper.colorFor(order.risk.level),
    );
    final trackingSteps = order.trackingSteps.isEmpty
        ? const [
            FoodPulseTrackingStep(label: 'Order placed', done: true),
            FoodPulseTrackingStep(label: 'Merchant preparing', done: true),
            FoodPulseTrackingStep(label: 'Rider assigned', done: false),
            FoodPulseTrackingStep(label: 'Out for delivery', done: false),
          ]
        : order.trackingSteps;

    if (order.orderNumber.trim().isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.prussian,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Order confirmation is unavailable.',
                          style: TextStyle(
                            color: AppColors.silver,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
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
              Text(
                'Order #${order.orderNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.silver, fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                'Est. Arrival: ${order.estimatedArrival}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (fallbackMessage != null) ...[
                const SizedBox(height: 14),
                AppCard(
                  color: AppColors.tangerine.withAlpha(24),
                  borderColor: AppColors.tangerine.withAlpha(52),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.tangerine,
                        size: 18,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          fallbackMessage!,
                          style: const TextStyle(
                            color: AppColors.alabaster,
                            fontSize: 11,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              AppCard(
                borderColor: risk.color.withAlpha(64),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'FoodPulse Risk Monitor',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: risk.color.withAlpha(32),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: risk.color.withAlpha(72)),
                          ),
                          child: Text(
                            risk.badgeLabel,
                            style: TextStyle(
                              color: risk.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
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
                          '${risk.score}% - adjusting ETA',
                          style: TextStyle(
                            color: risk.color,
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
                        valueColor: AlwaysStoppedAnimation<Color>(risk.color),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.white.withAlpha(18),
                        ),
                      ),
                      child: Text(
                        order.risk.recommendation,
                        style: const TextStyle(
                          color: AppColors.alabaster,
                          fontSize: 11,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Status',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 13),
                    for (var index = 0; index < trackingSteps.length; index++)
                      _StatusRow(
                        label: trackingSteps[index].label,
                        done: trackingSteps[index].done,
                        isLast: index == trackingSteps.length - 1,
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
