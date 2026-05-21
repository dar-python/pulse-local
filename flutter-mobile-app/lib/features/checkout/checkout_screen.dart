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
    FoodPulseDeliveryAddress? deliveryAddress,
    String? initialPaymentMethod,
    FoodPulseCheckoutRiskRepository? checkoutRiskRepository,
    FoodPulseRepository? foodPulseRepository,
    ValueChanged<OrderConfirmation>? onOrderPlaced,
  }) : _restaurant = restaurant,
       _items = items,
       _deliveryAddress = deliveryAddress,
       _initialPaymentMethod = initialPaymentMethod,
       _checkoutRiskRepository = checkoutRiskRepository,
       _foodPulseRepository = foodPulseRepository,
       _onOrderPlaced = onOrderPlaced;

  final Restaurant? _restaurant;
  final List<CartItem>? _items;
  final FoodPulseDeliveryAddress? _deliveryAddress;
  final String? _initialPaymentMethod;
  final FoodPulseCheckoutRiskRepository? _checkoutRiskRepository;
  final FoodPulseRepository? _foodPulseRepository;
  final ValueChanged<OrderConfirmation>? _onOrderPlaced;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _defaultDeliveryAddress = FoodPulseDeliveryAddress(
    label: 'Marasbaras, Tacloban City',
    notes: 'Zone 7 · Leyte, Philippines',
  );

  late final Restaurant _restaurant;
  late final List<CartItem> _items;
  late FoodPulseDeliveryAddress _deliveryAddress;
  late final FoodPulseCheckoutRiskRepository _checkoutRiskRepository;
  FoodPulseRepository? _foodPulseRepository;
  String? _paymentMethod;
  bool _isRiskLoading = true;
  bool _isSubmittingOrder = false;
  String? _orderProgressLabel;
  RiskPredictionResponse? _riskPrediction;
  String? _riskErrorMessage;
  String? _orderErrorMessage;

  @override
  void initState() {
    super.initState();
    _restaurant = widget._restaurant ?? MockFoodPulseData.restaurants.first;
    _items = widget._items ?? MockFoodPulseData.defaultCart;
    _deliveryAddress = widget._deliveryAddress ?? _defaultDeliveryAddress;
    _paymentMethod = widget._initialPaymentMethod ?? 'cod';
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
                    _RiskSummary(
                      risk: risk,
                      isLoading: _isRiskLoading,
                      prediction: _riskPrediction,
                      errorMessage: _riskErrorMessage,
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
                      text: _simplifiedAdvisory,
                    ),
                    const SizedBox(height: 8),
                    _AdvisoryLine(
                      icon: Icons.schedule_rounded,
                      text: _etaAdvisory,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _SectionTitle('Delivery Address'),
              const SizedBox(height: 8),
              AppCard(
                onTap: _showDeliveryAddressSelector,
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.orange,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _deliveryAddress.label.trim().isEmpty
                                ? 'Delivery address missing'
                                : _deliveryAddress.label,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            (_deliveryAddress.notes?.trim().isNotEmpty ?? false)
                                ? _deliveryAddress.notes!
                                : 'Add delivery notes before checkout',
                            style: const TextStyle(
                              color: AppColors.silver,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _showDeliveryAddressSelector,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(44, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
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
                onTap: () => _selectPaymentMethod('gcash'),
              ),
              const SizedBox(height: 7),
              PaymentTile(
                label: 'Cash on Delivery',
                icon: Icons.payments_rounded,
                selected: _paymentMethod == 'cod',
                onTap: () => _selectPaymentMethod('cod'),
              ),
              const SizedBox(height: 7),
              PaymentTile(
                label: 'Credit / Debit Card',
                icon: Icons.credit_card_rounded,
                selected: _paymentMethod == 'card',
                onTap: () => _selectPaymentMethod('card'),
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
                label: _orderProgressLabel ?? 'Place Order · ₱$total',
                leading: _isSubmittingOrder ? const _ButtonSpinner() : null,
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

  List<RiskAdvisoryReason> get _topDelayReasons {
    return (_riskPrediction?.advisoryReasons ?? const <RiskAdvisoryReason>[])
        .where(
          (reason) => reason.isDelayReason && reason.label.trim().isNotEmpty,
        )
        .take(2)
        .toList(growable: false);
  }

  String get _simplifiedAdvisory {
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

    final advisoryMessage = prediction?.advisoryMessage.trim();
    if (advisoryMessage != null && advisoryMessage.isNotEmpty) {
      return advisoryMessage;
    }

    if (_displayRisk.label.toLowerCase() == 'low') {
      return 'Low risk. Conditions look favorable for this order.';
    }

    final reasons = _topDelayReasons;
    if (reasons.isEmpty) {
      return 'No major delay reason detected for this order.';
    }

    return 'Possible delay because of ${_reasonPhrase(reasons)}.';
  }

  String get _etaAdvisory {
    if (_isRiskLoading) {
      return 'ETA updates after Laravel finishes the checkout risk prediction.';
    }

    final etaRange = _etaRangeFromPrediction(_riskPrediction);
    if (etaRange == null) {
      return 'Adjusted ETA: 30-45 min while prediction is unavailable.';
    }

    return 'Adjusted ETA: $etaRange based on the current checkout risk.';
  }

  String _reasonPhrase(List<RiskAdvisoryReason> reasons) {
    final phrases = reasons
        .map((reason) {
          return switch (reason.code) {
            'stormy_weather' || 'rainy_weather' => 'bad weather',
            'heavy_traffic' => 'heavy traffic',
            'medium_traffic' => 'moderate traffic',
            'long_preparation' => 'longer preparation time',
            'long_distance' => 'a farther delivery address',
            'limited_rider_availability' => 'limited rider availability',
            'peak_hour' => 'peak-hour timing',
            _ => reason.label.toLowerCase().replaceAll('.', ''),
          };
        })
        .toList(growable: false);

    if (phrases.length == 1) {
      return phrases.single;
    }

    return '${phrases.first} and ${phrases[1]}';
  }

  void _selectPaymentMethod(String paymentMethod) {
    if (_paymentMethod == paymentMethod) {
      return;
    }

    setState(() => _paymentMethod = paymentMethod);
    _loadCheckoutRisk();
  }

  Future<void> _showDeliveryAddressSelector() async {
    final selected = await showModalBottomSheet<FoodPulseDeliveryAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeliveryAddressSheet(selectedAddress: _deliveryAddress),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() => _deliveryAddress = selected);
    _loadCheckoutRisk();
  }

  Future<void> _placeOrder() async {
    if (_isSubmittingOrder) {
      return;
    }

    final validationMessage = _checkoutValidationMessage();
    if (validationMessage != null) {
      setState(() => _orderErrorMessage = validationMessage);
      return;
    }

    if (_requiresHighRiskConfirmation) {
      final shouldContinue = await _showHighRiskWarning();
      if (shouldContinue != true) {
        return;
      }
    }

    await _submitOrder();
  }

  Future<void> _submitOrder() async {
    final repository = _foodPulseRepository ?? LaravelFoodPulseRepository();
    final request = CheckoutCartRequest(
      restaurant: _restaurant,
      items: _items,
      paymentMethod: _paymentMethod!,
      deliveryAddress: _deliveryAddress,
    );

    setState(() {
      _isSubmittingOrder = true;
      _orderProgressLabel = 'Placing Order...';
      _orderErrorMessage = null;
    });

    try {
      final checkoutResult = await repository.checkoutCart(request);
      if (!mounted) {
        return;
      }

      setState(() => _orderProgressLabel = 'Loading confirmation...');
      final rawConfirmationResult = checkoutResult.usedFallback
          ? FoodPulseResult.fallback(
              OrderConfirmation.fromCheckout(checkoutResult.data),
              message:
                  checkoutResult.message ?? 'Using saved local checkout data.',
            )
          : await repository.fetchOrderConfirmation(
              checkoutResult.data.orderNumber,
            );
      final checkoutOrderRisk =
          _orderRiskFromPrediction(_riskPrediction) ?? checkoutResult.data.risk;
      final checkoutEta =
          _etaRangeFromPrediction(_riskPrediction) ??
          OrderConfirmation.fromCheckout(checkoutResult.data).estimatedArrival;
      final checkoutConfirmation = OrderConfirmation.fromCheckout(
        checkoutResult.data,
      ).copyWith(risk: checkoutOrderRisk, estimatedArrival: checkoutEta);
      final orderConfirmation = rawConfirmationResult.usedFallback
          ? checkoutConfirmation
          : checkoutConfirmation.copyWith(
              status: rawConfirmationResult.data.status,
              estimatedArrival: _newerConfirmationEta(
                rawConfirmationResult.data.estimatedArrival,
                checkoutConfirmation.estimatedArrival,
              ),
              trackingSteps: rawConfirmationResult.data.trackingSteps.isEmpty
                  ? checkoutConfirmation.trackingSteps
                  : rawConfirmationResult.data.trackingSteps,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmittingOrder = false;
        _orderProgressLabel = null;
      });
      widget._onOrderPlaced?.call(orderConfirmation);
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
      final fallbackRisk =
          _orderRiskFromPrediction(_riskPrediction) ?? fallbackCheckout.risk;
      final fallbackConfirmation = OrderConfirmation.fromCheckout(
        fallbackCheckout,
      );
      final fallbackEta =
          _etaRangeFromPrediction(_riskPrediction) ??
          fallbackConfirmation.estimatedArrival;
      const message =
          'Laravel order checkout is unavailable. Using saved local checkout data so the demo can continue.';

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmittingOrder = false;
        _orderProgressLabel = null;
        _orderErrorMessage = null;
      });
      final orderConfirmation = fallbackConfirmation.copyWith(
        risk: fallbackRisk,
        estimatedArrival: fallbackEta,
      );
      widget._onOrderPlaced?.call(orderConfirmation);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ConfirmedScreen(
            orderConfirmation: orderConfirmation,
            fallbackMessage: message,
          ),
        ),
      );
    }
  }

  String? _checkoutValidationMessage() {
    if (_items.isEmpty) {
      return 'Add at least one item before checkout.';
    }
    if (_items.any((item) => item.quantity <= 0)) {
      return 'Cart item quantities must be positive.';
    }
    if (_restaurant.id <= 0 || _restaurant.name.trim().isEmpty) {
      return 'Choose a restaurant before checkout.';
    }
    if (_deliveryAddress.label.trim().isEmpty) {
      return 'Enter a delivery address before placing your order.';
    }
    if (_paymentMethod == null || _paymentMethod!.trim().isEmpty) {
      return 'Choose a payment method before placing your order.';
    }

    return null;
  }

  bool get _requiresHighRiskConfirmation {
    if (_isLaravelFallback(_riskPrediction)) {
      return false;
    }

    final risk = _displayRisk;
    return risk.label.toLowerCase() == 'high' || risk.score >= 70;
  }

  Future<bool?> _showHighRiskWarning() {
    final risk = _displayRisk;
    final recommendation =
        _riskPrediction?.recommendation ??
        'Expect possible ETA adjustments before the rider is assigned.';

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.prussian,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppColors.tangerine.withAlpha(110)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.tangerine.withAlpha(32),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.tangerine.withAlpha(88)),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.tangerine,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'High fulfillment risk',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${risk.score}% ${risk.label.toLowerCase()} risk detected before checkout.',
                style: const TextStyle(
                  color: AppColors.alabaster,
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                recommendation,
                style: const TextStyle(
                  color: AppColors.silver,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Review',
                style: TextStyle(
                  color: AppColors.silver,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Continue Order',
                style: TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadCheckoutRisk() async {
    setState(() {
      _isRiskLoading = true;
      _riskErrorMessage = null;
    });

    try {
      final prediction = await _checkoutRiskRepository.predictRisk(
        _checkoutRiskRequest(),
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

  CheckoutRiskRequest _checkoutRiskRequest() {
    return CheckoutRiskRequest.fromCheckoutContext(
      restaurant: _restaurant,
      items: _items,
      deliveryAddress: _deliveryAddress,
      paymentMethod: _paymentMethod ?? 'cod',
    );
  }

  String _friendlyRiskError(Object error) {
    if (error is ApiException) {
      return 'Risk prediction is unavailable right now. You can still place your order.';
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

  String? _etaRangeFromPrediction(RiskPredictionResponse? prediction) {
    if (prediction == null) {
      return null;
    }

    final etaRange = prediction.etaRange.trim();
    return etaRange.isEmpty ? null : etaRange;
  }

  String _newerConfirmationEta(String confirmationEta, String checkoutEta) {
    final normalizedEta = confirmationEta.trim();
    if (normalizedEta.isEmpty ||
        normalizedEta == '30-45 min' ||
        normalizedEta == '30–45 min') {
      return checkoutEta;
    }

    return normalizedEta;
  }

  FoodPulseOrderRisk? _orderRiskFromPrediction(
    RiskPredictionResponse? prediction,
  ) {
    if (prediction == null) {
      return null;
    }

    final rawLevel = prediction.riskLevel.trim();

    return FoodPulseOrderRisk(
      score: prediction.riskPercent,
      level: rawLevel.isEmpty
          ? RiskColorMapper.labelForScore(prediction.riskPercent)
          : rawLevel,
      recommendation: prediction.recommendation,
      advisoryMessage: prediction.advisoryMessage,
      advisoryReasons: prediction.advisoryReasons,
    );
  }
}

class _RiskSummary extends StatelessWidget {
  const _RiskSummary({
    required this.risk,
    required this.isLoading,
    required this.prediction,
    required this.errorMessage,
  });

  final RiskInfo risk;
  final bool isLoading;
  final RiskPredictionResponse? prediction;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final title = isLoading
        ? 'Risk calculation in progress'
        : errorMessage != null
        ? 'Risk service unavailable'
        : '${risk.label} fulfillment risk';
    final isFallback =
        prediction != null &&
        (prediction!.source.toLowerCase() == 'laravel-fallback' ||
            prediction!.riskLevel.toLowerCase() == 'unknown');
    final body = isLoading
        ? 'Laravel is calculating the checkout risk before order submission.'
        : errorMessage ??
              (isFallback
                  ? 'Fallback risk mode active. You can still place your order.'
                  : prediction?.recommendation ??
                        'Proceed with standard checkout handling.');
    final delayReasons =
        prediction?.advisoryReasons
            .where((reason) => reason.isDelayReason)
            .take(2)
            .toList(growable: false) ??
        const <RiskAdvisoryReason>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: risk.color.withAlpha(isLoading ? 16 : 24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: risk.color.withAlpha(52)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: risk.color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.alabaster,
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (prediction?.advisoryMessage.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              prediction!.advisoryMessage,
              style: const TextStyle(
                color: AppColors.alabaster,
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          for (final reason in delayReasons) ...[
            const SizedBox(height: 6),
            Text(
              reason.label,
              style: const TextStyle(
                color: AppColors.silver,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
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
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeliveryAddressSheet extends StatelessWidget {
  const _DeliveryAddressSheet({required this.selectedAddress});

  final FoodPulseDeliveryAddress selectedAddress;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      maxChildSize: 0.86,
      minChildSize: 0.42,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.prussian,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.silver.withAlpha(95),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Delivery Address',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Changing address recalculates fulfillment risk and ETA.',
                style: TextStyle(color: AppColors.silver, fontSize: 11),
              ),
              const SizedBox(height: 14),
              for (final address in MockFoodPulseData.savedAddresses) ...[
                _AddressOptionTile(
                  address: address,
                  selected: address.label == selectedAddress.label,
                  onTap: () => Navigator.pop(context, address),
                ),
                const SizedBox(height: 8),
              ],
              _AddressOptionTile(
                address: const FoodPulseDeliveryAddress(
                  tag: 'Current',
                  label: 'Current location',
                  notes: 'Tacloban City, Leyte',
                ),
                selected: selectedAddress.label == 'Current location',
                onTap: () => Navigator.pop(
                  context,
                  const FoodPulseDeliveryAddress(
                    tag: 'Current',
                    label: 'Current location',
                    notes: 'Tacloban City, Leyte',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddressOptionTile extends StatelessWidget {
  const _AddressOptionTile({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final FoodPulseDeliveryAddress address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: selected
          ? AppColors.orange.withAlpha(150)
          : AppColors.white.withAlpha(18),
      color: selected ? AppColors.orange.withAlpha(20) : null,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? AppColors.orange : AppColors.silver,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  address.notes ?? address.tag,
                  style: const TextStyle(
                    color: AppColors.silver,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.orange,
              size: 18,
            ),
          ],
        ],
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.prussian,
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
