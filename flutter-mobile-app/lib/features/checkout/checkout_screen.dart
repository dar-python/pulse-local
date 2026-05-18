import 'package:flutter/material.dart';

import '../../core/data/mock_foodpulse_data.dart';
import '../../core/models/cart_item.dart';
import '../../core/models/restaurant.dart';
import '../../core/models/risk_info.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/risk_color_mapper.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/payment_tile.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/risk_chip.dart';
import '../../shared/widgets/risk_gauge.dart';
import '../checkout_risk/models/checkout_risk_request.dart';
import '../checkout_risk/models/risk_prediction_response.dart';
import '../foodpulse/models/foodpulse_order.dart';
import '../foodpulse/repositories/foodpulse_repository.dart';
import '../order/confirmed_screen.dart';
import 'repositories/foodpulse_checkout_risk_repository.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    Restaurant? restaurant,
    List<CartItem>? items,
    FoodPulseCheckoutRiskRepository? checkoutRiskRepository,
    FoodPulseRepository? foodPulseRepository,
  }) : _restaurant = restaurant,
       _items = items,
       _checkoutRiskRepository = checkoutRiskRepository,
       _foodPulseRepository = foodPulseRepository;

  final Restaurant? _restaurant;
  final List<CartItem>? _items;
  final FoodPulseCheckoutRiskRepository? _checkoutRiskRepository;
  final FoodPulseRepository? _foodPulseRepository;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _checkoutRiskRequest = CheckoutRiskRequest(
    riderToOrderRatio: 0.45,
    merchantPrepTime: 25,
    trafficCorridorIntensity: 'high',
    weatherCategory: 'rainy',
    deliveryDistanceKm: 4.2,
    addressComplexity: 'medium',
    paymentMethod: 'cod',
  );
  static const _deliveryAddress = FoodPulseDeliveryAddress(
    label: 'Marasbaras, Tacloban City',
    notes: 'Zone 7 · Leyte, Philippines',
  );

  late final Restaurant _restaurant;
  late final List<CartItem> _items;
  late final FoodPulseCheckoutRiskRepository _checkoutRiskRepository;
  FoodPulseRepository? _foodPulseRepository;
  String _paymentMethod = 'cod';
  bool _isRiskLoading = true;
  bool _isSubmittingOrder = false;
  RiskPredictionResponse? _riskPrediction;
  String? _riskErrorMessage;
  String? _orderErrorMessage;

  @override
  void initState() {
    super.initState();
    _restaurant = widget._restaurant ?? MockFoodPulseData.restaurants.first;
    _items = widget._items ?? MockFoodPulseData.defaultCart;
    _checkoutRiskRepository =
        widget._checkoutRiskRepository ??
        LaravelFoodPulseCheckoutRiskRepository();
    _loadCheckoutRisk();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _foodPulseRepository ??=
        widget._foodPulseRepository ??
        FoodPulseRepositoryScope.maybeOf(context) ??
        LaravelFoodPulseRepository();
  }

  @override
  Widget build(BuildContext context) {
    final risk = _displayRisk;
    final total = MockFoodPulseData.totalFor(_items);

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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fulfillment Risk Score',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
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
                        _isRiskLoading
                            ? const _RiskLoadingPill()
                            : RiskChip(risk: risk, dense: true),
                      ],
                    ),
                    Center(
                      child: _isRiskLoading
                          ? const _RiskLoadingGauge()
                          : RiskGauge(risk: risk),
                    ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FoodPulse Risk Advisories',
                      style: TextStyle(
                        color: AppColors.tangerine,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _AdvisoryLine(
                      icon: _riskAdvisoryIcon,
                      text: _primaryRiskAdvisory,
                    ),
                    const SizedBox(height: 8),
                    if (_secondaryRiskAdvisory != null) ...[
                      _AdvisoryLine(
                        icon: Icons.sync_alt_rounded,
                        text: _secondaryRiskAdvisory!,
                      ),
                      const SizedBox(height: 8),
                    ],
                    const _AdvisoryLine(
                      icon: Icons.schedule_rounded,
                      text:
                          'Adjusted ETA: 30–45 min due to high rider pressure',
                    ),
                    const SizedBox(height: 8),
                    const _AdvisoryLine(
                      icon: Icons.account_balance_wallet_rounded,
                      text: 'Prepayment recommended to secure your order slot',
                    ),
                    const SizedBox(height: 8),
                    const _AdvisoryLine(
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
              if (_orderErrorMessage != null) ...[
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
                          _orderErrorMessage!,
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
                const SizedBox(height: 12),
              ],
              PrimaryButton(
                label: _isSubmittingOrder
                    ? 'Placing Order...'
                    : 'Place Order · ₱$total',
                onPressed: _isSubmittingOrder ? null : _placeOrder,
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

  RiskInfo get _displayRisk {
    final prediction = _riskPrediction;
    if (prediction == null) {
      return RiskInfo.unknown;
    }

    final rawLevel = prediction.riskLevel.trim();
    final label = rawLevel.isEmpty
        ? RiskColorMapper.labelForScore(prediction.riskPercent)
        : rawLevel;

    return RiskInfo(
      score: prediction.riskPercent,
      label: label,
      color: RiskColorMapper.colorFor(label),
    );
  }

  IconData get _riskAdvisoryIcon {
    if (_riskErrorMessage != null) {
      return Icons.info_outline_rounded;
    }
    if (_isRiskLoading) {
      return Icons.hourglass_top_rounded;
    }
    if (_isLaravelFallback(_riskPrediction)) {
      return Icons.warning_amber_rounded;
    }
    return Icons.insights_rounded;
  }

  String get _primaryRiskAdvisory {
    if (_isRiskLoading) {
      return 'Calculating fulfillment risk through Laravel before checkout.';
    }
    if (_riskErrorMessage != null) {
      return 'Risk prediction is unavailable right now. You can still place your order.';
    }

    final prediction = _riskPrediction;
    if (_isLaravelFallback(prediction)) {
      return 'Fallback risk mode active. You can still place your order.';
    }

    return prediction?.recommendation ??
        'Risk prediction is unavailable right now. You can still place your order.';
  }

  String? get _secondaryRiskAdvisory {
    final errorMessage = _riskErrorMessage;
    if (errorMessage != null) {
      return errorMessage;
    }

    final prediction = _riskPrediction;
    if (prediction == null) {
      return null;
    }

    return 'Risk source: ${prediction.source}';
  }

  Future<void> _placeOrder() async {
    final repository = _foodPulseRepository ?? LaravelFoodPulseRepository();
    final request = CheckoutCartRequest(
      restaurant: _restaurant,
      items: _items,
      paymentMethod: _paymentMethod,
      deliveryAddress: _deliveryAddress,
    );

    setState(() {
      _isSubmittingOrder = true;
      _orderErrorMessage = null;
    });

    try {
      final checkoutResult = await repository.checkoutCart(request);
      final rawConfirmationResult = checkoutResult.usedFallback
          ? FoodPulseResult.fallback(
              OrderConfirmation.fromCheckout(checkoutResult.data),
              message:
                  checkoutResult.message ?? 'Using saved local checkout data.',
            )
          : await repository.fetchOrderConfirmation(
              checkoutResult.data.orderNumber,
            );
      final orderConfirmation = rawConfirmationResult.usedFallback
          ? OrderConfirmation.fromCheckout(checkoutResult.data)
          : rawConfirmationResult.data;

      if (!mounted) {
        return;
      }

      setState(() => _isSubmittingOrder = false);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ConfirmedScreen(
            orderConfirmation: orderConfirmation,
            fallbackMessage: rawConfirmationResult.usedFallback
                ? rawConfirmationResult.message
                : null,
          ),
        ),
      );
    } catch (_) {
      final fallbackCheckout = const FoodPulseFallbackRepository().checkout(
        request,
      );
      const message =
          'Laravel order checkout is unavailable. Using saved local checkout data so the demo can continue.';

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmittingOrder = false;
        _orderErrorMessage = message;
      });
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ConfirmedScreen(
            orderConfirmation: OrderConfirmation.fromCheckout(fallbackCheckout),
            fallbackMessage: message,
          ),
        ),
      );
    }
  }

  Future<void> _loadCheckoutRisk() async {
    try {
      final prediction = await _checkoutRiskRepository.predictRisk(
        _checkoutRiskRequest,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _riskPrediction = prediction;
        _riskErrorMessage = null;
        _isRiskLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _riskPrediction = null;
        _riskErrorMessage = _friendlyRiskError(error);
        _isRiskLoading = false;
      });
    }
  }

  String _friendlyRiskError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'Check the Laravel API connection and try again later.';
  }

  bool _isLaravelFallback(RiskPredictionResponse? prediction) {
    if (prediction == null) {
      return false;
    }

    return prediction.source.toLowerCase() == 'laravel-fallback' ||
        prediction.riskLevel.toLowerCase() == 'unknown';
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

class _RiskLoadingPill extends StatelessWidget {
  const _RiskLoadingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.silver.withAlpha(24),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.silver.withAlpha(70)),
      ),
      child: const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.silver,
        ),
      ),
    );
  }
}

class _RiskLoadingGauge extends StatelessWidget {
  const _RiskLoadingGauge();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 220,
      height: 124,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 3, color: AppColors.orange),
            SizedBox(height: 10),
            Text(
              'Calculating risk',
              style: TextStyle(
                color: AppColors.silver,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
