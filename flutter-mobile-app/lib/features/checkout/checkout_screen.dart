import 'package:flutter/material.dart';

import '../../core/data/mock_foodpulse_data.dart';
import '../../core/models/risk_info.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/payment_tile.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/risk_gauge.dart';
import '../order/confirmed_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'gcash';

  @override
  Widget build(BuildContext context) {
    final risk = RiskInfo.fromScore(MockFoodPulseData.checkoutRiskScore);
    final total = MockFoodPulseData.totalFor(MockFoodPulseData.defaultCart);

    return Scaffold(
      backgroundColor: AppColors.prussian,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                title: 'Checkout',
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 12),
              AppCard(
                borderColor: risk.color.withAlpha(80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fulfillment Risk Score',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Logistic Regression · Real-time Prediction.',
                                style: TextStyle(
                                  color: AppColors.silver,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        RiskChip(risk: risk, dense: true),
                      ],
                    ),
                    Center(child: RiskGauge(risk: risk)),
                    const Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        FactorChip(
                          label: 'High rider pressure',
                          color: AppColors.tangerine,
                        ),
                        FactorChip(
                          label: 'Moderate traffic',
                          color: AppColors.orange,
                        ),
                        FactorChip(
                          label: 'Merchant ready',
                          color: AppColors.green,
                        ),
                        FactorChip(
                          label: 'Rainy weather',
                          color: AppColors.tangerine,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                color: AppColors.tangerine.withAlpha(24),
                borderColor: AppColors.tangerine.withAlpha(52),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FoodPulse Risk Advisories',
                      style: TextStyle(
                        color: AppColors.tangerine,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 10),
                    _AdvisoryLine(
                      icon: Icons.schedule_rounded,
                      text:
                          'Adjusted ETA: 30–45 min due to high rider pressure',
                    ),
                    SizedBox(height: 8),
                    _AdvisoryLine(
                      icon: Icons.account_balance_wallet_rounded,
                      text: 'Prepayment recommended to secure your order slot',
                    ),
                    SizedBox(height: 8),
                    _AdvisoryLine(
                      icon: Icons.notifications_active_outlined,
                      text: 'Merchant alerted to begin preparation immediately',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _SectionTitle('Delivery Address'),
              const SizedBox(height: 8),
              const AppCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.orange,
                      size: 19,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marasbaras, Tacloban City',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Zone 7 · Leyte, Philippines',
                            style: TextStyle(
                              color: AppColors.silver,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _SectionTitle('Payment Method'),
              const SizedBox(height: 8),
              PaymentTile(
                label: 'GCash',
                icon: Icons.account_balance_wallet_rounded,
                selected: _paymentMethod == 'gcash',
                suggested: true,
                onTap: () => setState(() => _paymentMethod = 'gcash'),
              ),
              const SizedBox(height: 7),
              PaymentTile(
                label: 'Cash on Delivery',
                icon: Icons.payments_rounded,
                selected: _paymentMethod == 'cod',
                onTap: () => setState(() => _paymentMethod = 'cod'),
              ),
              const SizedBox(height: 7),
              PaymentTile(
                label: 'Credit / Debit Card',
                icon: Icons.credit_card_rounded,
                selected: _paymentMethod == 'card',
                onTap: () => setState(() => _paymentMethod = 'card'),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '₱$total',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Place Order · ₱$total',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ConfirmedScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Risk score is a decision-support tool, not a guarantee. Model recalculates every 3 min.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.silver,
                  fontSize: 10,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onBack,
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.arrow_back_rounded, color: AppColors.white),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _AdvisoryLine extends StatelessWidget {
  const _AdvisoryLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.tangerine, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.alabaster,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
